const { Op } = require('sequelize');
const sequelize = require('../config/database');
const { NguoiDung, HoSoNhanVien, CaLamViec, ViTien, LichSuViTien, DonDatLich, LichSuDoiLich } = require('../models');
const { getDurationInHours } = require('../utils/tinh_gia');
const { success, error } = require('../utils/phan_hoi');
const oCamManager = require('../sockets/o_cam_manager');
const { checkAndExecutePayoutsForProvider } = require('../utils/payout_helper');

class ProviderController {
  async getProfile(req, res, next) {
    try {
      const providerId = req.user.MaNguoiDung;

      // Tự động đối soát giải ngân khi tải thông tin cá nhân
      await checkAndExecutePayoutsForProvider(providerId);

      const provider = await NguoiDung.findByPk(providerId, {
        attributes: { exclude: ['MatKhau'] },
        include: [{ model: HoSoNhanVien, as: 'HoSoNhanVien' }]
      });

      if (!provider || provider.VaiTro !== 2) {
        return error(res, 'Hồ sơ nhân viên không tồn tại', 404);
      }
      return success(res, provider, 'Lấy hồ sơ nhân viên thành công');
    } catch (err) {
      next(err);
    }
  }

  async updateProfile(req, res, next) {
    try {
      const providerId = req.user.MaNguoiDung;
      const hoso = await HoSoNhanVien.findOne({ where: { MaNhanVien: providerId } });
      if (!hoso) {
        return error(res, 'Hồ sơ nhân viên không tồn tại', 404);
      }

      const { CCCD, TrangThaiHoatDong, HoTenNguoiDung, DiaChi, SoDienThoai, GioiTinh } = req.body;

      // Cập nhật bảng người dùng
      const userUpdates = {};
      if (HoTenNguoiDung) userUpdates.HoTenNguoiDung = HoTenNguoiDung;
      if (DiaChi) userUpdates.DiaChi = DiaChi;
      if (SoDienThoai) userUpdates.SoDienThoai = SoDienThoai;
      if (GioiTinh) userUpdates.GioiTinh = GioiTinh;

      if (Object.keys(userUpdates).length > 0) {
        const user = await NguoiDung.findByPk(providerId);
        if (user) await user.update(userUpdates);
      }

      // Cập nhật bảng hồ sơ
      const hosoUpdates = {};
      if (CCCD) hosoUpdates.CCCD = CCCD;
      if (TrangThaiHoatDong !== undefined) hosoUpdates.TrangThaiHoatDong = TrangThaiHoatDong;

      if (Object.keys(hosoUpdates).length > 0) {
        await hoso.update(hosoUpdates);
      }

      // Lấy thông tin hồ sơ đã cập nhật
      const updatedProvider = await NguoiDung.findByPk(providerId, {
        attributes: { exclude: ['MatKhau'] },
        include: [{ model: HoSoNhanVien, as: 'HoSoNhanVien' }]
      });

      return success(res, updatedProvider, 'Cập nhật hồ sơ nhân viên thành công');
    } catch (err) {
      next(err);
    }
  }

  async getJobs(req, res, next) {
    try {
      const providerId = req.user.MaNguoiDung;
      const jobs = await CaLamViec.findAll({
        where: {
          [Op.or]: [
            { MaNhanVien: providerId },
            { MaNhanVien: null, TrangThaiDonHang: 1 } // 1: Chờ nhận việc (đã thanh toán)
          ]
        },
        include: [
          { model: NguoiDung, as: 'KhachHang', attributes: ['HoTenNguoiDung', 'SoDienThoai'] },
          { model: DonDatLich, as: 'DonDatLich', attributes: ['MaDatLich', 'LoaiDatLich', 'SoBuoi', 'GiaGoi','TrangThai'] },
          {
            model: LichSuDoiLich,
            as: 'LichSuDoiLichs',
            where: { KetQua: 0 },
            required: false,
            include: [
              { model: NguoiDung, as: 'NguoiYeuCau', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'VaiTro'] },
              { model: NguoiDung, as: 'NguoiXuLy', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'VaiTro'] }
            ]
          }
        ],
        order: [['NgayLamViec', 'ASC'], ['GioBatDau', 'ASC']]
      });

      // Lọc bỏ những ca làm việc trống mà nhân viên này đã bị chặn (do khách hàng đổi nhân viên)
      const filteredJobs = jobs.filter(job => {
        if (job.TrangThaiDonHang === 1 && job.MaNhanVien === null) {
          if (job.LyDoHuy && job.LyDoHuy.startsWith('BLOCKED:')) {
            const blockedIds = job.LyDoHuy.replace('BLOCKED:', '').split(',');
            if (blockedIds.includes(providerId.toString())) {
              return false; // Bị chặn, không hiển thị
            }
          }
        }
        return true;
      });

      return success(res, filteredJobs, 'Lấy danh sách công việc thành công');
    } catch (err) {
      next(err);
    }
  }

  async getJobDetail(req, res, next) {
    try {
      const providerId = req.user.MaNguoiDung;
      const job = await CaLamViec.findByPk(req.params.id, {
        include: [
          { model: NguoiDung, as: 'KhachHang', attributes: ['HoTenNguoiDung', 'SoDienThoai', 'DiaChi'] }
        ]
      });

      if (!job) {
        return error(res, 'Công việc không tồn tại', 404);
      }

      if (job.MaNhanVien !== null && job.MaNhanVien !== providerId) {
        return error(res, 'Bạn không có quyền xem công việc này', 403);
      }

      return success(res, job, 'Lấy chi tiết công việc thành công');
    } catch (err) {
      next(err);
    }
  }

  async acceptJob(req, res, next) {
    let tx;
    try {
      const providerId = req.user.MaNguoiDung;
      const caLamId = req.params.id;

      const job = await CaLamViec.findByPk(caLamId);
      if (!job) {
        return error(res, 'Công việc không tồn tại', 404);
      }

      // Kiểm tra hồ sơ nhân viên phải được duyệt & đang hoạt động
      const hoso = await HoSoNhanVien.findOne({ where: { MaNhanVien: providerId } });
      if (!hoso || hoso.TrangThaiDuyet !== 1 || !hoso.TrangThaiHoatDong) {
        return error(res, 'Hồ sơ của bạn chưa được Admin duyệt hoặc trạng thái hoạt động đang tắt', 400);
      }

      // Kiểm tra xem nhân viên này có bị khách hàng chặn không (vì đổi/từ chối trước đó)
      if (job.LyDoHuy && job.LyDoHuy.startsWith('BLOCKED:')) {
        const blockedIds = job.LyDoHuy.replace('BLOCKED:', '').split(',');
        if (blockedIds.includes(providerId.toString())) {
          return error(res, 'Bạn không thể nhận ca làm việc này vì khách hàng đã đổi hoặc từ chối bạn trước đó.', 403);
        }
      }

      // Trường hợp 1: Ca đã gán cho nhân viên này, đang chờ xác nhận (status 0)
      if (job.MaNhanVien === providerId && job.TrangThaiDonHang === 0) {
        // Nhân viên xác nhận nhận việc
      }
      // Trường hợp 2: Ca chưa có nhân viên, đang chờ nhận từ pool chung (trạng thái 1)
      else if (job.MaNhanVien === null && job.TrangThaiDonHang === 1) {
        // Nhân viên nhận từ bảng việc chung
      }
      else if (job.MaNhanVien !== null && job.MaNhanVien !== providerId) {
        return error(res, 'Công việc này đã có nhân viên khác nhận', 400);
      }
      else {
        return error(res, 'Trạng thái công việc không hợp lệ để nhận', 400);
      }

      console.log('--- GỠ LỖI NHẬN CA LÀM ---');
      console.log('Mã nhân viên:', providerId);
      console.log('Ngày làm việc:', job.NgayLamViec, typeof job.NgayLamViec);
      console.log('Giờ bắt đầu:', job.GioBatDau, typeof job.GioBatDau);
      console.log('Giờ kết thúc:', job.GioKetThuc, typeof job.GioKetThuc);
      
      // KIỂM TRA TRÙNG LỊCH LÀM VIỆC (QUAN TRỌNG CHO BẢO VỆ ĐỒ ÁN)
      // Để phát hiện 2 ca làm việc có trùng thời gian hay không (overlap), ta sử dụng thuật toán kiểm tra khoảng thời gian.
      // Giả sử:
      // - Ca làm mới đang định nhận có thời gian từ [job.GioBatDau, job.GioKetThuc].
      // - Ca làm cũ đã nhận (conflictingJob) có thời gian từ [GioBatDau (cũ), GioKetThuc (cũ)].
      // Hai khoảng thời gian (A, B) và (C, D) sẽ giao nhau (trùng lịch) khi và chỉ khi: A < D VÀ B > C.
      // Áp dụng vào truy vấn (query) CSDL:
      // - GioBatDau của ca cũ < job.GioKetThuc (Tức là ca cũ phải bắt đầu trước khi ca mới kết thúc)
      // - GioKetThuc của ca cũ > job.GioBatDau (Tức là ca cũ phải kết thúc sau khi ca mới đã bắt đầu)
      // Nếu đồng thời thỏa mãn cả hai điều kiện trên trên cùng một ngày làm việc (NgayLamViec) và ca cũ 
      // chưa bị hủy hay hoàn thành (TrangThaiDonHang đang là 0 hoặc 1), thì chắc chắn xảy ra xung đột.
      // Chúng ta cũng dùng { [Op.ne]: job.MaCaLam } để bỏ qua chính ca làm đang xét (nếu cập nhật lại).
      const conflictingJob = await CaLamViec.findOne({
        where: {
          MaCaLam: { [Op.ne]: job.MaCaLam },
          MaNhanVien: providerId,
          NgayLamViec: job.NgayLamViec,
          TrangThaiDonHang: { [Op.in]: [0, 1] },
          GioBatDau: { [Op.lt]: job.GioKetThuc },
          GioKetThuc: { [Op.gt]: job.GioBatDau }
        }
      });
      console.log('Đã tìm thấy ca trùng lặp:', conflictingJob ? conflictingJob.MaCaLam : 'KHÔNG CÓ');
      console.log('------------------------');
      
      if (conflictingJob) {
        return error(res, `Bạn đã có lịch làm việc vào ngày ${job.NgayLamViec} từ ${conflictingJob.GioBatDau} đến ${conflictingJob.GioKetThuc}. Không thể nhận thêm ca bị trùng giờ.`, 400);
      }

      tx = await sequelize.transaction();

      // Gán nhân viên vào ca làm, giữ TrangThaiDonHang = 1 (đã nhận / đang chờ thực hiện)
      await job.update({
        MaNhanVien: providerId,
        TrangThaiDonHang: 1,
        NgayCapNhat: new Date()
      }, { transaction: tx });

      // Nếu đơn đặt lịch tổng chưa có nhân viên, gán nhân viên này làm nhân viên chính
      const booking = await DonDatLich.findByPk(job.MaDatLich);
      if (booking && !booking.MaNhanVien) {
        await booking.update({ MaNhanVien: providerId }, { transaction: tx });
      }

      await tx.commit();

      const updatedJob = await CaLamViec.findByPk(caLamId);

      // Gửi thông báo thời gian thực cho khách hàng
      oCamManager.guiThongBaoNguoiDung(job.MaKhachHang, {
        tieuDe: 'Nhân viên nhận ca làm việc!',
        noiDung: `Nhân viên ${req.user.HoTenNguoiDung} đã nhận ca làm việc ngày ${job.NgayLamViec} của bạn.`,
        data: updatedJob
      });

      return success(res, updatedJob, 'Nhận ca làm việc thành công');
    } catch (err) {
      if (tx) await tx.rollback();
      next(err);
    }
  }

  async rejectJob(req, res, next) {
    try {
      const providerId = req.user.MaNguoiDung;
      const caLamId = req.params.id;

      const job = await CaLamViec.findByPk(caLamId);
      if (!job || job.MaNhanVien !== providerId) {
        return error(res, 'Công việc không hợp lệ hoặc không thuộc về bạn', 400);
      }

      // Cho phép từ chối ca ở trạng thái 0 (chờ xác nhận) hoặc 1 (đã nhận)
      if (job.TrangThaiDonHang !== 0 && job.TrangThaiDonHang !== 1) {
        return error(res, 'Chỉ có thể từ chối ca làm việc chưa bắt đầu/hoàn thành', 400);
      }

      // Yêu cầu lý do từ chối
      const lyDoTuChoi = req.body.LyDoHuy || '';
      if (!lyDoTuChoi.trim()) {
        return error(res, 'Vui lòng nhập lý do từ chối', 400);
      }

      // Hủy phân công, đưa lại danh sách chờ nhận để nhân viên khác có thể nhận
      await job.update({
        MaNhanVien: null,
        TrangThaiDonHang: 1, // Đưa về trạng thái chờ nhận việc
        LyDoHuy: `Nhân viên từ chối: ${lyDoTuChoi.trim()}`,
        NgayCapNhat: new Date()
      });

      // Gửi thông báo cho khách hàng

      oCamManager.guiThongBaoNguoiDung(job.MaKhachHang, {
        tieuDe: 'Nhân viên từ chối ca làm việc',
        noiDung: `Nhân viên ${req.user.HoTenNguoiDung} đã từ chối ca làm việc ngày ${job.NgayLamViec}. Lý do: ${lyDoTuChoi.trim()}. Ca làm đang chờ nhân viên khác nhận.`,
        data: job
      });

      return success(res, null, 'Từ chối công việc thành công. Ca làm việc đã được đưa lại danh sách chờ nhận.');
    } catch (err) {
      next(err);
    }
  }

  // ============================================================
  // POST /provider/jobs/:id/complete - Hoàn thành ca làm + chia hoa hồng 80/20
  // 80% lương → ví nhân viên dọn dẹp
  // 20% hoa hồng → ví hệ thống Admin
  // ============================================================
  async completeJob(req, res, next) {
    let tx;
    try {
      const providerId = req.user.MaNguoiDung;
      const caLamId = req.params.id;

      const job = await CaLamViec.findByPk(caLamId);
      if (!job || job.MaNhanVien !== providerId) {
        return error(res, 'Công việc không hợp lệ hoặc không thuộc về bạn', 400);
      }

      if (job.TrangThaiDonHang !== 1) {
        return error(res, 'Chỉ có thể hoàn thành ca làm việc đang ở trạng thái đã nhận', 400);
      }

      // Kiểm tra ngày giờ làm việc: chỉ cho hoàn thành khi đã qua thời gian kết thúc ca làm
      const now = new Date();
      // job.NgayLamViec có dạng 'YYYY-MM-DD', job.GioKetThuc có dạng 'HH:mm:ss' hoặc 'HH:mm'
      const endDateTimeString = `${job.NgayLamViec}T${job.GioKetThuc}`;
      const endDateTime = new Date(endDateTimeString);

      if (now < endDateTime) {
        return error(res, `Chưa đến thời gian kết thúc ca làm (${job.GioKetThuc} ngày ${job.NgayLamViec}). Không thể hoàn thành công việc sớm.`, 400);
      }

      const splitProvider = parseInt(process.env.REVENUE_SPLIT_PROVIDER || 80);
      const splitSystem = parseInt(process.env.REVENUE_SPLIT_SYSTEM || 20);

      const tongTien = parseFloat(job.TongTien);
      const tienNhanVien = (tongTien * splitProvider) / 100;
      const tienSystem = (tongTien * splitSystem) / 100;

      tx = await sequelize.transaction();

      // 1. Cập nhật trạng thái ca làm việc → Hoàn thành (2) và ghi nhận số tiền chờ thanh toán
      await job.update({
        TrangThaiDonHang: 2, // 2: Hoàn thành
        TienNhanVienNhan: tienNhanVien,
        TienHeThongNhan: tienSystem,
        TongTienTre: tienNhanVien,
        DaThanhToan: false,
        NgayCapNhat: now,
        NgayHoanThanh: now
      }, { transaction: tx });

      // 2. Chuyển tiền hoa hồng (20%) cho Admin, giữ tiền lương (80%) trong ví Tạm giữ
      const systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });
      const adminUser = await NguoiDung.findOne({ where: { VaiTro: 3 } });
      
      if (systemWallet && adminUser) {
        const adminWallet = await ViTien.findOne({ where: { MaNguoiDung: adminUser.MaNguoiDung } });
        if (adminWallet) {
          // Trừ 20% hoa hồng khỏi ví Tạm giữ hệ thống
          const newSysBalance = parseFloat(systemWallet.SoDu) - tienSystem;
          await systemWallet.update({ SoDu: newSysBalance }, { transaction: tx });

          // Cộng 20% hoa hồng vào ví Admin
          const newAdminBalance = parseFloat(adminWallet.SoDu) + tienSystem;
          await adminWallet.update({ SoDu: newAdminBalance }, { transaction: tx });

          // Ghi lịch sử giao dịch hoa hồng hệ thống
          await LichSuViTien.create({
            MaViNguon: systemWallet.MaViTien,
            MaViDich: adminWallet.MaViTien,
            MaCaLam: caLamId,
            LoaiGiaoDich: 5, // 5: Hoa hồng hệ thống
            SoTien: tienSystem,
            SoDuSau: newAdminBalance,
            NgayTao: new Date()
          }, { transaction: tx });
        }
      }

      // Lưu ý: Không cộng tiền vào ví nhân viên lúc này (tiền nhân viên sẽ được thanh toán vào cuối tuần qua cron/admin)

      // 3. Cập nhật tích lũy hồ sơ nhân viên (số giờ + số đơn hoàn thành)
      const hoso = await HoSoNhanVien.findOne({ where: { MaNhanVien: providerId } });
      if (hoso) {
        const duration = getDurationInHours(job.GioBatDau, job.GioKetThuc);
        const newHours = parseInt(hoso.SoGioLamViec || 0) + Math.ceil(duration);
        const newCompletedOrders = parseInt(hoso.TongDanhGia || 0); // TongDanhGia dùng cho số đánh giá, không phải đơn hoàn thành
        await hoso.update({ SoGioLamViec: newHours }, { transaction: tx });
      }

      // 4. Kiểm tra toàn bộ ca làm trong đơn đã hoàn thành/hủy chưa
      const siblingJobs = await CaLamViec.findAll({ where: { MaDatLich: job.MaDatLich }, transaction: tx });
      const allFinished = siblingJobs.every(j => j.TrangThaiDonHang === 2 || j.TrangThaiDonHang === 3);
      if (allFinished) {
        const booking = await DonDatLich.findByPk(job.MaDatLich);
        if (booking) {
          await booking.update({ TrangThai: 3 }, { transaction: tx }); // 3: Hoàn thành tất cả ca
        }
      }

      await tx.commit();

      const completedJob = await CaLamViec.findByPk(caLamId);

      // 5. Gửi thông báo thời gian thực qua Socket.IO
      oCamManager.guiThongBaoNguoiDung(job.MaKhachHang, {
        tieuDe: 'Ca làm việc đã hoàn thành!',
        noiDung: `Nhân viên ${req.user.HoTenNguoiDung} đã hoàn thành ca làm việc ngày ${job.NgayLamViec} của bạn. Vui lòng đánh giá.`,
        data: completedJob
      });

      oCamManager.guiThongBaoAdmin({
        tieuDe: 'Ca làm việc đã hoàn thành!',
        noiDung: `Nhân viên ${req.user.HoTenNguoiDung} đã hoàn thành ca làm việc #${job.MaCaLam} cho khách hàng #${job.MaKhachHang}`,
        data: completedJob
      });

      return success(res, completedJob, 'Hoàn thành ca làm việc thành công. Tiền đã được chia.');
    } catch (err) {
      if (tx) await tx.rollback();
      next(err);
    }
  }

  // ============================================================
  // POST /provider/wallet/withdraw - Rút tiền từ ví nhân viên
  // ============================================================
  async withdrawWallet(req, res, next) {
    let tx;
    try {
      const providerId = req.user.MaNguoiDung;
      const { SoTien } = req.body;
      const amount = parseFloat(SoTien);

      if (!amount || amount <= 0) {
        return error(res, 'Số tiền rút phải lớn hơn 0', 400);
      }
      if (amount > 10000000) {
        return error(res, 'Số tiền rút tối đa mỗi lần là 10.000.000 VNĐ', 400);
      }

      let wallet = await ViTien.findOne({ where: { MaNguoiDung: providerId } });
      if (!wallet) {
        // Tự tạo ví cho nhân viên nếu chưa có
        wallet = await ViTien.create({
          MaNguoiDung: providerId,
          SoDu: 0,
          LoaiVi: 2, // 2: nhân viên
          TrangThai: true
        });
      }

      const currentBalance = parseFloat(wallet.SoDu);
      if (amount > currentBalance) {
        return error(res, 'Số dư ví không đủ để rút', 400);
      }

      tx = await sequelize.transaction();

      const newBalance = currentBalance - amount;
      await wallet.update({ SoDu: newBalance }, { transaction: tx });

      await LichSuViTien.create({
        MaViNguon: wallet.MaViTien,
        MaViDich: wallet.MaViTien,
        LoaiGiaoDich: 6, // 6: Rút tiền
        SoTien: amount,
        SoDuSau: newBalance,
        NgayTao: new Date()
      }, { transaction: tx });

      await tx.commit();

      return success(res, { newBalance }, 'Rút tiền từ ví thành công');
    } catch (err) {
      if (tx) await tx.rollback();
      next(err);
    }
  }
}

module.exports = new ProviderController();
