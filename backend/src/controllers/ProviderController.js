const { Op } = require('sequelize');
const sequelize = require('../config/database');
const { NguoiDung, HoSoNhanVien, CaLamViec, ViTien, LichSuViTien, DonDatLich, LichSuDoiLich } = require('../models');
const { getDurationInHours } = require('../utils/tinh_gia');
const { success, error } = require('../utils/phan_hoi');
const oCamManager = require('../sockets/o_cam_manager');

class ProviderController {
  async getProfile(req, res, next) {
    try {
      const providerId = req.user.MaNguoiDung;
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

      // Update user table
      const userUpdates = {};
      if (HoTenNguoiDung) userUpdates.HoTenNguoiDung = HoTenNguoiDung;
      if (DiaChi) userUpdates.DiaChi = DiaChi;
      if (SoDienThoai) userUpdates.SoDienThoai = SoDienThoai;
      if (GioiTinh) userUpdates.GioiTinh = GioiTinh;

      if (Object.keys(userUpdates).length > 0) {
        const user = await NguoiDung.findByPk(providerId);
        if (user) await user.update(userUpdates);
      }

      // Update hoso table
      const hosoUpdates = {};
      if (CCCD) hosoUpdates.CCCD = CCCD;
      if (TrangThaiHoatDong !== undefined) hosoUpdates.TrangThaiHoatDong = TrangThaiHoatDong;

      if (Object.keys(hosoUpdates).length > 0) {
        await hoso.update(hosoUpdates);
      }

      // Get updated profile
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
      return success(res, jobs, 'Lấy danh sách công việc thành công');
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

      // Trường hợp 1: Ca đã gán cho nhân viên này, đang chờ xác nhận (status 0)
      if (job.MaNhanVien === providerId && job.TrangThaiDonHang === 0) {
        // Nhân viên xác nhận nhận việc
      }
      // Trường hợp 2: Ca chưa có nhân viên, đang chờ nhận từ pool (status 1)
      else if (job.MaNhanVien === null && job.TrangThaiDonHang === 1) {
        // Nhân viên nhận từ bảng việc chung
      }
      else if (job.MaNhanVien !== null && job.MaNhanVien !== providerId) {
        return error(res, 'Công việc này đã có nhân viên khác nhận', 400);
      }
      else {
        return error(res, 'Trạng thái công việc không hợp lệ để nhận', 400);
      }

      console.log('ProviderID:', providerId);
      console.log('NgayLamViec:', job.NgayLamViec, typeof job.NgayLamViec);
      console.log('GioBatDau:', job.GioBatDau, typeof job.GioBatDau);
      console.log('GioKetThuc:', job.GioKetThuc, typeof job.GioKetThuc);
      
      // Kiểm tra xem nhân viên đã có ca làm việc nào trùng giờ trong ngày này chưa
      const conflictingJob = await CaLamViec.findOne({
        where: {
          MaCaLam: { [Op.ne]: job.MaCaLam },
          MaNhanVien: providerId,
          NgayLamViec: job.NgayLamViec,
          TrangThaiDonHang: { [Op.in]: [0, 1, 2] },
          GioBatDau: { [Op.lt]: job.GioKetThuc },
          GioKetThuc: { [Op.gt]: job.GioBatDau }
        }
      });
      
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

      // Nếu đơn đặt lịch tổng chưa có nhân viên, gán nhân viên này làm primary
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

  async startJob(req, res, next) {
    try {
      const providerId = req.user.MaNguoiDung;
      const caLamId = req.params.id;

      const job = await CaLamViec.findByPk(caLamId);
      if (!job || job.MaNhanVien !== providerId) {
        return error(res, 'Công việc không hợp lệ hoặc không thuộc về bạn', 400);
      }

      // Chỉ cho phép bắt đầu ca ở trạng thái 1 (đã nhận)
      if (job.TrangThaiDonHang !== 1) {
        return error(res, 'Chỉ có thể bắt đầu ca làm việc ở trạng thái đã nhận', 400);
      }

      // Kiểm tra thời gian bắt đầu ca (chỉ cho phép trước tối đa 10 phút)
      const now = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Ho_Chi_Minh' }));
      const [hours, minutes] = job.GioBatDau.split(':');
      const scheduledStart = new Date(now);
      scheduledStart.setHours(parseInt(hours), parseInt(minutes), 0, 0);
      
      const diffMinutes = (now - scheduledStart) / (1000 * 60);
      if (diffMinutes < -10) {
        return error(res, `Chỉ được phép bắt đầu ca trước giờ hẹn tối đa 10 phút. Ca làm của bạn bắt đầu lúc ${job.GioBatDau.substring(0,5)}.`, 400);
      }

      // Đánh dấu thời điểm bắt đầu thực tế
      await job.update({
        ThoiGianBatDauThucTe: now,
        NgayCapNhat: new Date()
      });

      // Gửi thông báo cho khách hàng
      oCamManager.guiThongBaoNguoiDung(job.MaKhachHang, {
        tieuDe: 'Nhân viên đã bắt đầu ca làm việc!',
        noiDung: `Nhân viên ${req.user.HoTenNguoiDung} đã bắt đầu ca làm việc lúc ${now.getHours().toString().padStart(2,'0')}:${now.getMinutes().toString().padStart(2,'0')}. Vui lòng không được thay đổi nhân viên.`,
        data: job
      });

      return success(res, job, 'Bắt đầu ca làm việc thành công');
    } catch (err) {
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

  async cancelJob(req, res, next) {
    try {
      const providerId = req.user.MaNguoiDung;
      const caLamId = req.params.id;

      const job = await CaLamViec.findByPk(caLamId);
      if (!job || job.MaNhanVien !== providerId) {
        return error(res, 'Công việc không hợp lệ hoặc không thuộc về bạn', 400);
      }

      if (job.TrangThaiDonHang !== 1) {
        return error(res, 'Chỉ có thể hủy ca làm việc đã nhận và chưa hoàn thành/hủy', 400);
      }

      const now = new Date();
      const jobStart = new Date(`${job.NgayLamViec}T${job.GioBatDau}+07:00`);
      
      const diffMs = jobStart - now;
      const diffMins = diffMs / (1000 * 60);

      if (diffMins < 30) {
        return error(res, 'Chỉ được phép hủy ca làm việc trước giờ bắt đầu ít nhất 30 phút.', 400);
      }

      const lyDoHuy = req.body.LyDoHuy || '';
      if (!lyDoHuy.trim()) {
        return error(res, 'Vui lòng nhập lý do hủy lịch', 400);
      }

      await job.update({
        MaNhanVien: null,
        TrangThaiDonHang: 1,
        LyDoHuy: `Nhân viên hủy lịch: ${lyDoHuy.trim()}`,
        NgayCapNhat: new Date()
      });

      oCamManager.guiThongBaoNguoiDung(job.MaKhachHang, {
        tieuDe: 'Nhân viên hủy ca làm việc!',
        noiDung: `Nhân viên ${req.user.HoTenNguoiDung} đã hủy nhận ca làm việc ngày ${job.NgayLamViec} của bạn. Lý do: ${lyDoHuy.trim()}. Ca làm việc đã được đưa lại bảng việc trống để người khác nhận.`,
        data: job
      });

      return success(res, null, 'Hủy lịch làm việc thành công. Ca làm việc đã được đưa lại bảng việc trống.');
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

      // Kiểm tra ngày và giờ làm việc: chỉ cho hoàn thành khi đã đến ngày và trước giờ kết thúc tối đa 15 phút
      const now = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Ho_Chi_Minh' }));
      const today = new Date(now);
      today.setHours(0, 0, 0, 0);
      const ngayLam = new Date(job.NgayLamViec);
      ngayLam.setHours(0, 0, 0, 0);
      if (today < ngayLam) {
        return error(res, `Chưa đến ngày làm việc (${job.NgayLamViec}). Không thể hoàn thành ca trước ngày hẹn.`, 400);
      }

      const [endHours, endMinutes] = job.GioKetThuc.split(':');
      const scheduledEnd = new Date(now);
      scheduledEnd.setHours(parseInt(endHours), parseInt(endMinutes), 0, 0);

      const diffMinutesToEnd = (scheduledEnd - now) / (1000 * 60);
      if (diffMinutesToEnd > 15) {
        return error(res, `Chỉ được phép hoàn thành ca làm trước giờ kết thúc tối đa 15 phút. Giờ kết thúc ca: ${job.GioKetThuc.substring(0,5)}.`, 400);
      }

      const splitProvider = parseInt(process.env.REVENUE_SPLIT_PROVIDER || 80);
      const splitSystem = parseInt(process.env.REVENUE_SPLIT_SYSTEM || 20);

      const tongTien = parseFloat(job.TongTien);
      const tienNhanVien = (tongTien * splitProvider) / 100;
      const tienSystem = (tongTien * splitSystem) / 100;

      tx = await sequelize.transaction();

      // 1. Cập nhật trạng thái ca làm việc → Hoàn thành (2), đặt NgayHoanThanh để tính 24h
      await job.update({
        TrangThaiDonHang: 2, // 2: Hoàn thành
        TienNhanVienNhan: tienNhanVien,
        TienHeThongNhan: tienSystem,
        NgayHoanThanh: new Date(),
        NgayCapNhat: new Date()
      }, { transaction: tx });

      // 2. Chỉ chuyển tiền phí hoa hồng hệ thống (20%) từ ví Tạm giữ (Escrow, LoaiVi=3) sang ví Admin.
      // Lương nhân viên (80%) giữ lại ví Tạm giữ để giải ngân tự động sau 24 giờ.
      const systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });

      if (systemWallet) {
        // Trừ phần phí hệ thống (20%) ra khỏi ví tạm giữ
        const newSysBalance = parseFloat(systemWallet.SoDu) - tienSystem;
        await systemWallet.update({ SoDu: newSysBalance }, { transaction: tx });

        // Cộng phần phí hệ thống vào ví Admin
        const adminUser = await NguoiDung.findOne({ where: { VaiTro: 3 } });
        if (adminUser) {
          const adminWallet = await ViTien.findOne({ where: { MaNguoiDung: adminUser.MaNguoiDung } });
          if (adminWallet) {
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
              NgayTao: new Date(),
              NoiDungGiaoDich: `Hoa hồng hệ thống 20% từ ca làm việc #${caLamId}.`
            }, { transaction: tx });
          }
        }
      }

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

      // 5. Gửi thông báo thời gian thực via Socket.IO
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

      return success(res, completedJob, 'Hoàn thành ca làm việc thành công. Đang tạm giữ tiền trong 24 giờ để kiểm tra khiếu nại.');
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
