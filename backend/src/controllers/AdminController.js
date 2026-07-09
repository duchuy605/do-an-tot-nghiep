const { Op } = require('sequelize');
const sequelize = require('../config/database');
const {
  NguoiDung,
  HoSoNhanVien,
  DonDatLich,
  CaLamViec,
  ViTien,
  DichVu,
  NgayDacBiet,
  QuyDinhKhungGio,
  LoaiGoi,
  KhieuNai,
  HinhThucXuLy,
  LichSuViTien,
  DatDichVu
} = require('../models');
const { success, error } = require('../utils/phan_hoi');
const oCamManager = require('../sockets/o_cam_manager');

class AdminController {
  // Quản lý Người dùng
  async getUsers(req, res, next) {
    try {
      const role = req.query.role ? parseInt(req.query.role) : null;
      const where = {};
      if (role) where.VaiTro = role;

      const users = await NguoiDung.findAll({
        where,
        attributes: { exclude: ['MatKhau'] },
        include: [{ model: HoSoNhanVien, as: 'HoSoNhanVien' }]
      });

      return success(res, users, 'Lấy danh sách người dùng thành công');
    } catch (err) {
      next(err);
    }
  }

  async getUserDetail(req, res, next) {
    try {
      const user = await NguoiDung.findByPk(req.params.id, {
        attributes: { exclude: ['MatKhau'] },
        include: [{ model: HoSoNhanVien, as: 'HoSoNhanVien' }]
      });

      if (!user) {
        return error(res, 'Người dùng không tồn tại', 404);
      }
      return success(res, user, 'Lấy chi tiết người dùng thành công');
    } catch (err) {
      next(err);
    }
  }

  async getUserStats(req, res, next) {
    try {
      const user = await NguoiDung.findByPk(req.params.id);
      if (!user) {
        return error(res, 'Người dùng không tồn tại', 404);
      }

      const stats = {};
      if (user.VaiTro === 1) { // Khách Hàng
        const wallet = await ViTien.findOne({ where: { MaNguoiDung: user.MaNguoiDung } });
        let totalDeposited = 0;
        if (wallet) {
          totalDeposited = await LichSuViTien.sum('SoTien', {
            where: { MaViDich: wallet.MaViTien, LoaiGiaoDich: 1 }
          }) || 0;
        }

        const totalShifts = await CaLamViec.count({ where: { MaKhachHang: user.MaNguoiDung } });

        const totalPaid = await CaLamViec.sum('TongTien', {
          where: { MaKhachHang: user.MaNguoiDung, TrangThaiDonHang: { [require('sequelize').Op.not]: 3 } }
        }) || 0;

        stats.totalDeposited = totalDeposited;
        stats.totalShifts = totalShifts;
        stats.totalPaid = totalPaid;
        
      } else if (user.VaiTro === 2) { // Nhân Viên
        const totalAccepted = await CaLamViec.count({ where: { MaNhanVien: user.MaNguoiDung } });
        
        const totalCompleted = await CaLamViec.count({ where: { MaNhanVien: user.MaNguoiDung, TrangThaiDonHang: 2 } });
        
        const totalEarned = await CaLamViec.sum('TienNhanVienNhan', {
          where: { MaNhanVien: user.MaNguoiDung, TrangThaiDonHang: 2 }
        }) || 0;

        stats.totalAccepted = totalAccepted;
        stats.totalCompleted = totalCompleted;
        stats.totalEarned = totalEarned;
      }

      return success(res, stats, 'Lấy thống kê người dùng thành công');
    } catch (err) {
      next(err);
    }
  }

  async updateUser(req, res, next) {
    try {
      const user = await NguoiDung.findByPk(req.params.id);
      if (!user) {
        return error(res, 'Người dùng không tồn tại', 404);
      }

      await user.update(req.body);
      
      const updatedUser = await NguoiDung.findByPk(req.params.id, {
        attributes: { exclude: ['MatKhau'] },
        include: [{ model: HoSoNhanVien, as: 'HoSoNhanVien' }]
      });

      return success(res, updatedUser, 'Cập nhật người dùng thành công');
    } catch (err) {
      next(err);
    }
  }

  async lockUser(req, res, next) {
    try {
      const user = await NguoiDung.findByPk(req.params.id);
      if (!user) {
        return error(res, 'Người dùng không tồn tại', 404);
      }

      await user.update({ TrangThaiTaiKhoan: 2 }); // 2: Locked
      return success(res, { success: true }, 'Khóa tài khoản thành công');
    } catch (err) {
      next(err);
    }
  }

  async unlockUser(req, res, next) {
    try {
      const user = await NguoiDung.findByPk(req.params.id);
      if (!user) {
        return error(res, 'Người dùng không tồn tại', 404);
      }

      await user.update({ TrangThaiTaiKhoan: 1 }); // 1: Active
      return success(res, { success: true }, 'Mở khóa tài khoản thành công');
    } catch (err) {
      next(err);
    }
  }

  // Quản lý Nhân viên
  async getProviders(req, res, next) {
    try {
      const providers = await NguoiDung.findAll({
        where: { VaiTro: 2 },
        attributes: { exclude: ['MatKhau'] },
        include: [{ model: HoSoNhanVien, as: 'HoSoNhanVien' }]
      });
      return success(res, providers, 'Lấy danh sách nhân viên thành công');
    } catch (err) {
      next(err);
    }
  }

  async approveProvider(req, res, next) {
    try {
      const hoso = await HoSoNhanVien.findOne({ where: { MaNhanVien: req.params.id } });
      if (!hoso) {
        return error(res, 'Hồ sơ nhân viên không tồn tại', 404);
      }

      await hoso.update({
        TrangThaiDuyet: 1, // Approved
        TrangThaiHoatDong: true,
        NgayDuyet: new Date()
      });

      return success(res, { success: true }, 'Duyệt hồ sơ nhân viên thành công');
    } catch (err) {
      next(err);
    }
  }

  async rejectProvider(req, res, next) {
    try {
      const hoso = await HoSoNhanVien.findOne({ where: { MaNhanVien: req.params.id } });
      if (!hoso) {
        return error(res, 'Hồ sơ nhân viên không tồn tại', 404);
      }

      await hoso.update({
        TrangThaiDuyet: 2, // Rejected
        TrangThaiHoatDong: false
      });

      return success(res, { success: true }, 'Từ chối hồ sơ nhân viên thành công');
    } catch (err) {
      next(err);
    }
  }

  // Quản lý Dịch vụ (CRUD)
  async createService(req, res, next) {
    try {
      const service = await DichVu.create(req.body);
      return success(res, service, 'Tạo dịch vụ thành công', 201);
    } catch (err) {
      next(err);
    }
  }

  async updateService(req, res, next) {
    try {
      const service = await DichVu.findByPk(req.params.id);
      if (!service) {
        return error(res, 'Dịch vụ không tồn tại', 404);
      }

      await service.update(req.body);
      return success(res, service, 'Cập nhật dịch vụ thành công');
    } catch (err) {
      next(err);
    }
  }

  async deleteService(req, res, next) {
    try {
      const service = await DichVu.findByPk(req.params.id);
      if (!service) {
        return error(res, 'Dịch vụ không tồn tại', 404);
      }

      // Xóa mềm by updating status
      await service.update({ TrangThai: false });
      return success(res, null, 'Xóa dịch vụ thành công (Soft delete)');
    } catch (err) {
      next(err);
    }
  }

  async getServices(req, res, next) {
    try {
      const services = await DichVu.findAll();
      return success(res, services, 'Lấy danh sách dịch vụ thành công');
    } catch (err) {
      next(err);
    }
  }

  // Bookings Management
  async getBookings(req, res, next) {
    try {
      const bookings = await DonDatLich.findAll({
        include: [
          { model: NguoiDung, as: 'KhachHang', attributes: ['HoTenNguoiDung', 'Email', 'SoDienThoai'] },
          { model: NguoiDung, as: 'NhanVien', attributes: ['HoTenNguoiDung', 'SoDienThoai'] },
          { model: CaLamViec, as: 'CaLamViecs' }
        ],
        order: [['MaDatLich', 'DESC']]
      });
      return success(res, bookings, 'Lấy danh sách đơn đặt lịch thành công');
    } catch (err) {
      next(err);
    }
  }

  async getBookingDetail(req, res, next) {
    try {
      const booking = await DonDatLich.findByPk(req.params.id, {
        include: [
          { model: NguoiDung, as: 'KhachHang', attributes: { exclude: ['MatKhau'] } },
          { model: NguoiDung, as: 'NhanVien', attributes: { exclude: ['MatKhau'] } },
          { model: LoaiGoi, as: 'LoaiGoi' },
          { model: DatDichVu, as: 'DatDichVus', include: [{ model: DichVu, as: 'DichVu' }] },
          { model: CaLamViec, as: 'CaLamViecs' }
        ]
      });

      if (!booking) {
        return error(res, 'Đơn đặt lịch không tồn tại', 404);
      }
      return success(res, booking, 'Lấy chi tiết đơn đặt lịch thành công');
    } catch (err) {
      next(err);
    }
  }

  async updateBookingStatus(req, res, next) {
    try {
      const booking = await DonDatLich.findByPk(req.params.id);
      if (!booking) {
        return error(res, 'Đơn đặt lịch không tồn tại', 404);
      }

      await booking.update({ TrangThai: req.body.TrangThai });
      
      const updatedBooking = await DonDatLich.findByPk(req.params.id, {
        include: [
          { model: NguoiDung, as: 'KhachHang', attributes: { exclude: ['MatKhau'] } },
          { model: NguoiDung, as: 'NhanVien', attributes: { exclude: ['MatKhau'] } },
          { model: LoaiGoi, as: 'LoaiGoi' },
          { model: DatDichVu, as: 'DatDichVus', include: [{ model: DichVu, as: 'DichVu' }] },
          { model: CaLamViec, as: 'CaLamViecs' }
        ]
      });

      return success(res, updatedBooking, 'Cập nhật trạng thái đơn đặt lịch thành công');
    } catch (err) {
      next(err);
    }
  }

  // Quản lý Ngày đặc biệt (CRUD)
  async getSpecialDays(req, res, next) {
    try {
      const days = await NgayDacBiet.findAll();
      return success(res, days, 'Lấy danh sách ngày đặc biệt thành công');
    } catch (err) {
      next(err);
    }
  }

  async createSpecialDay(req, res, next) {
    try {
      const day = await NgayDacBiet.create(req.body);
      return success(res, day, 'Thêm ngày đặc biệt thành công', 201);
    } catch (err) {
      next(err);
    }
  }

  async updateSpecialDay(req, res, next) {
    try {
      const day = await NgayDacBiet.findByPk(req.params.id);
      if (!day) {
        return error(res, 'Ngày đặc biệt không tồn tại', 404);
      }

      await day.update(req.body);
      return success(res, day, 'Cập nhật ngày đặc biệt thành công');
    } catch (err) {
      next(err);
    }
  }

  async deleteSpecialDay(req, res, next) {
    try {
      const day = await NgayDacBiet.findByPk(req.params.id);
      if (!day) {
        return error(res, 'Ngày đặc biệt không tồn tại', 404);
      }

      await day.destroy();
      return success(res, null, 'Xóa ngày đặc biệt thành công');
    } catch (err) {
      next(err);
    }
  }

  // Quản lý Khung giờ (CRUD)
  async getTimeSlots(req, res, next) {
    try {
      const slots = await QuyDinhKhungGio.findAll();
      return success(res, slots, 'Lấy danh sách khung giờ thành công');
    } catch (err) {
      next(err);
    }
  }

  async createTimeSlot(req, res, next) {
    try {
      const slot = await QuyDinhKhungGio.create(req.body);
      return success(res, slot, 'Thêm khung giờ thành công', 201);
    } catch (err) {
      next(err);
    }
  }

  async updateTimeSlot(req, res, next) {
    try {
      const slot = await QuyDinhKhungGio.findByPk(req.params.id);
      if (!slot) {
        return error(res, 'Khung giờ không tồn tại', 404);
      }

      await slot.update(req.body);
      return success(res, slot, 'Cập nhật khung giờ thành công');
    } catch (err) {
      next(err);
    }
  }

  async deleteTimeSlot(req, res, next) {
    try {
      const slot = await QuyDinhKhungGio.findByPk(req.params.id);
      if (!slot) {
        return error(res, 'Khung giờ không tồn tại', 404);
      }

      await slot.destroy();
      return success(res, null, 'Xóa khung giờ thành công');
    } catch (err) {
      next(err);
    }
  }

  // Packages Management (CRUD)
  async getPackages(req, res, next) {
    try {
      const packages = await LoaiGoi.findAll();
      return success(res, packages, 'Lấy danh sách gói thành công');
    } catch (err) {
      next(err);
    }
  }

  async createPackage(req, res, next) {
    try {
      const pkg = await LoaiGoi.create(req.body);
      return success(res, pkg, 'Thêm gói thành công', 201);
    } catch (err) {
      next(err);
    }
  }

  async updatePackage(req, res, next) {
    try {
      const pkg = await LoaiGoi.findByPk(req.params.id);
      if (!pkg) {
        return error(res, 'Gói không tồn tại', 404);
      }

      await pkg.update(req.body);
      return success(res, pkg, 'Cập nhật gói thành công');
    } catch (err) {
      next(err);
    }
  }

  async deletePackage(req, res, next) {
    try {
      const pkg = await LoaiGoi.findByPk(req.params.id);
      if (!pkg) {
        return error(res, 'Gói không tồn tại', 404);
      }

      await pkg.destroy();
      return success(res, null, 'Xóa gói thành công');
    } catch (err) {
      next(err);
    }
  }

  // Báo cáo thống kê Dashboard Metrics
  async getDashboard(req, res, next) {
    try {
      const totalCustomers = await NguoiDung.count({ where: { VaiTro: 1 } });
      const totalProviders = await NguoiDung.count({ where: { VaiTro: 2 } });
      const totalBookings = await DonDatLich.count();
      
      const completedBookings = await DonDatLich.count({ where: { TrangThai: 2 } });
      const pendingBookings = await CaLamViec.count({ where: { TrangThaiDonHang: 1, MaNhanVien: null } });
      
      // Thống kê ca làm việc (theo trạng thái)
      const shiftCounts = await CaLamViec.findAll({
        attributes: ['TrangThaiDonHang', [sequelize.fn('COUNT', sequelize.col('MaCaLam')), 'count']],
        group: ['TrangThaiDonHang']
      });
      
      let shiftStats = {
        pending: 0,
        accepted: 0,
        completed: 0,
        cancelled: 0
      };
      
      shiftCounts.forEach(item => {
        const status = item.TrangThaiDonHang;
        const count = parseInt(item.get('count'), 10);
        if (status === 0) shiftStats.pending = count;
        if (status === 1) shiftStats.accepted = count;
        if (status === 2) shiftStats.completed = count;
        if (status === 3) shiftStats.cancelled = count;
      });

      // Thống kê ca làm việc theo tuần (4 tuần gần nhất)
      const fourWeeksAgo = new Date();
      fourWeeksAgo.setDate(fourWeeksAgo.getDate() - 28);
      
      const recentShifts = await CaLamViec.findAll({
        where: {
          NgayLamViec: { [Op.gte]: fourWeeksAgo }
        },
        attributes: ['NgayLamViec']
      });

      let weeklyShifts = [
        { label: 'Tuần này', count: 0 },
        { label: 'Tuần trước', count: 0 },
        { label: '2 tuần trước', count: 0 },
        { label: '3 tuần trước', count: 0 }
      ];

      const now = new Date();
      recentShifts.forEach(shift => {
        const shiftDate = new Date(shift.NgayLamViec);
        const diffTime = Math.abs(now - shiftDate);
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays <= 7) {
          weeklyShifts[0].count++;
        } else if (diffDays <= 14) {
          weeklyShifts[1].count++;
        } else if (diffDays <= 21) {
          weeklyShifts[2].count++;
        } else if (diffDays <= 28) {
          weeklyShifts[3].count++;
        }
      });
      weeklyShifts = weeklyShifts.reverse();

      // Thống kê dòng tiền
      const cashFlowData = await LichSuViTien.findAll({
        attributes: ['LoaiGiaoDich', [sequelize.fn('SUM', sequelize.col('SoTien')), 'totalAmount']],
        group: ['LoaiGiaoDich']
      });
      
      let cashFlowStats = {
        deposit: 0, // 1: nạp tiền
        payment: 0, // 2: thanh toán
        refund: 0, // 3: hoàn tiền
        payout: 0  // 4: trả lương / rút tiền
      };
      
      cashFlowData.forEach(item => {
        const type = item.LoaiGiaoDich;
        const amount = parseFloat(item.get('totalAmount') || 0);
        if (type === 1) cashFlowStats.deposit += amount;
        if (type === 2) cashFlowStats.payment += amount;
        if (type === 3) cashFlowStats.refund += amount;
        if (type === 4) cashFlowStats.payout += amount;
      });

      const finishedCaLam = await CaLamViec.findAll({ where: { TrangThaiDonHang: 2 } });
      const totalRevenue = finishedCaLam.reduce((sum, job) => sum + parseFloat(job.TongTien), 0);
      const systemEarnings = finishedCaLam.reduce((sum, job) => sum + parseFloat(job.TienHeThongNhan), 0);

      const metrics = {
        totalCustomers,
        totalProviders,
        totalBookings,
        totalRevenue,
        systemEarnings,
        pendingBookings,
        completedBookings,
        shiftStats,
        cashFlowStats,
        weeklyShifts
      };

      return success(res, metrics, 'Lấy dữ liệu thống kê thành công');
    } catch (err) {
      next(err);
    }
  }

  // Lịch sử hoa hồng hệ thống
  async getSystemEarningsHistory(req, res, next) {
    try {
      const history = await CaLamViec.findAll({
        where: {
          TrangThaiDonHang: 2, // Hoàn thành
          TienHeThongNhan: { [Op.gt]: 0 }
        },
        include: [
          {
            model: NguoiDung,
            as: 'KhachHang',
            attributes: ['HoTenNguoiDung', 'SoDienThoai']
          },
          {
            model: NguoiDung,
            as: 'NhanVien',
            attributes: ['HoTenNguoiDung', 'SoDienThoai']
          }
        ],
        order: [['NgayHoanThanh', 'DESC'], ['NgayLamViec', 'DESC']],
        attributes: ['MaCaLam', 'NgayLamViec', 'GioBatDau', 'GioKetThuc', 'TienHeThongNhan', 'NgayHoanThanh']
      });

      return success(res, history, 'Lấy lịch sử hoa hồng thành công');
    } catch (err) {
      next(err);
    }
  }

  // Lịch sử doanh thu gộp (Gross Revenue)
  async getGrossRevenueHistory(req, res, next) {
    try {
      const history = await CaLamViec.findAll({
        where: {
          TrangThaiDonHang: 2, // Hoàn thành
          TongTien: { [Op.gt]: 0 }
        },
        include: [
          {
            model: NguoiDung,
            as: 'KhachHang',
            attributes: ['HoTenNguoiDung', 'SoDienThoai']
          },
          {
            model: NguoiDung,
            as: 'NhanVien',
            attributes: ['HoTenNguoiDung', 'SoDienThoai']
          }
        ],
        order: [['NgayHoanThanh', 'DESC'], ['NgayLamViec', 'DESC']],
        attributes: ['MaCaLam', 'NgayLamViec', 'GioBatDau', 'GioKetThuc', 'TongTien', 'NgayHoanThanh']
      });

      return success(res, history, 'Lấy lịch sử doanh thu gộp thành công');
    } catch (err) {
      next(err);
    }
  }

  // Complaint Processing
  async getComplaints(req, res, next) {
    try {
      const complaints = await KhieuNai.findAll({
        include: [
          { model: NguoiDung, as: 'NguoiGui', attributes: ['HoTenNguoiDung', 'Email', 'SoDienThoai'] },
          { model: NguoiDung, as: 'NguoiBiKhieuNai', attributes: ['HoTenNguoiDung', 'SoDienThoai'] },
          { model: CaLamViec, as: 'CaLamViec' },
          { model: HinhThucXuLy, as: 'HinhThucXuLy' }
        ],
        order: [['MaKhieuNai', 'DESC']]
      });
      return success(res, complaints, 'Lấy danh sách khiếu nại thành công');
    } catch (err) {
      next(err);
    }
  }

  async processComplaint(req, res, next) {
    try {
      const adminId = req.user.MaNguoiDung;
      const complaintId = req.params.id;

      const complaint = await KhieuNai.findByPk(complaintId);
      if (!complaint) {
        return error(res, 'Khiếu nại không tồn tại', 404);
      }

      await complaint.update({
        MaNguoiXuLy: adminId,
        TrangThaiXuLy: 1 // 1: Dang xu ly
      });

      const updated = await KhieuNai.findByPk(complaintId, {
        include: [
          { model: NguoiDung, as: 'NguoiGui', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'Email'] },
          { model: NguoiDung, as: 'NguoiBiKhieuNai', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'Email'] },
          { model: CaLamViec, as: 'CaLamViec' },
          { model: HinhThucXuLy, as: 'HinhThucXuLy' }
        ]
      });

      return success(res, updated, 'Cập nhật trạng thái đang xử lý khiếu nại');
    } catch (err) {
      next(err);
    }
  }

  // ============================================================
  // POST /complaints/:id/resolve - Xử lý khiếu nại (Hoàn tiền / Phạt tiền)
  // Giải thích logic Phạt tiền nhân viên và Hoàn tiền cho khách hàng:
  // 1. Kiểm tra Hình thức xử lý: Nếu Admin chọn hình thức là "Hoàn tiền" (hoặc ID = 1), hệ thống sẽ tiến hành trừ tiền nhân viên và cộng tiền cho khách.
  // 2. Tính toán mức tiền phạt:
  //    - Số tiền đền bù (hoanTienAmount) có thể do Admin nhập tay. Nếu không nhập, hệ thống mặc định phạt 20% số tiền thù lao mà nhân viên nhận được từ ca làm đó.
  //    - Mức phạt tối đa (providerPenalty) bị giới hạn không vượt quá thù lao thực tế nhân viên nhận được (để bảo vệ nhân viên không bị phạt lạm vào tiền túi).
  // 3. Xử lý trừ tiền nhân viên (Phạt tiền):
  //    - Trường hợp 1 (Đã thanh toán): Tiền đã vào ví nhân viên. Hệ thống sẽ TRỪ TIỀN trực tiếp từ ví nhân viên (ViTien của nhân viên) và CỘNG VÀO ví hệ thống. Ghi nhận lịch sử giao dịch loại 4 (Trừ tiền phạt).
  //    - Trường hợp 2 (Chưa thanh toán): Tiền vẫn đang treo (TongTienTre). Hệ thống sẽ TRỪ BỚT số tiền chờ duyệt này (nhân viên sẽ nhận ít tiền hơn khi đối soát). Tiền thực chất vẫn đang nằm trong ví hệ thống.
  // 4. Xử lý hoàn tiền cho khách hàng:
  //    - Hệ thống lấy tiền từ ví hệ thống (đã được bù vào từ tiền phạt của nhân viên) để CỘNG TRẢ LẠI vào ví của khách hàng. Ghi nhận lịch sử giao dịch loại 3 (Hoàn tiền).
  // 5. Kết thúc: Cập nhật trạng thái khiếu nại thành "Đã giải quyết" (TrangThaiXuLy = 2), tự động kích hoạt đối soát cho nhân viên (nếu đủ điều kiện), và gửi thông báo cho khách hàng qua Socket.IO.
  // ============================================================
  async resolveComplaint(req, res, next) {
    let tx;
    try {
      const adminId = req.user.MaNguoiDung;
      const complaintId = req.params.id;
      const { MaHinhThucXuLy, SoTienDenBu } = req.body;

      const complaint = await KhieuNai.findByPk(complaintId);
      if (!complaint) {
        return error(res, 'Khiếu nại không tồn tại', 404);
      }

      if (complaint.TrangThaiXuLy === 2) {
        return error(res, 'Khiếu nại đã được giải quyết từ trước', 400);
      }

      const hinhThuc = await HinhThucXuLy.findByPk(MaHinhThucXuLy);
      if (!hinhThuc) {
        return error(res, 'Hình thức xử lý không hợp lệ', 400);
      }

      tx = await sequelize.transaction();

      // Cập nhật trạng thái khiếu nại
      await complaint.update({
        MaNguoiXuLy: adminId,
        MaHinhThucXuLy,
        TrangThaiXuLy: 2, // 2: Đã giải quyết
        NgayXuLy: new Date()
      }, { transaction: tx });

      // Xử lý hoàn tiền bồi thường: Nếu hình thức là "Hoàn tiền" (hoặc ID là 1)
      if (hinhThuc.TenHinhThuc.toLowerCase().includes('hoàn tiền') || hinhThuc.TenHinhThuc.toLowerCase().includes('hoan tien') || MaHinhThucXuLy === 1) {
        const caLam = await CaLamViec.findByPk(complaint.MaCaLam);
        if (caLam) {
          const providerReceived = parseFloat(caLam.TongTien) - (parseFloat(caLam.TienHeThongNhan) || 0);
          const defaultPenalty = providerReceived * 0.20; // 20% số tiền nhân viên nhận được
          
          const hoanTienAmount = SoTienDenBu ? parseFloat(SoTienDenBu) : defaultPenalty;

          if (hoanTienAmount > parseFloat(caLam.TongTien)) {
            throw new Error(`Số tiền đền bù (${hoanTienAmount}) không được vượt quá số tiền thực tế ca làm (${caLam.TongTien})`);
          }

          // Lấy thông tin các ví tiền liên quan
          const customerWallet = await ViTien.findOne({ where: { MaNguoiDung: complaint.MaNguoiGui } });
          const systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });
          const providerWallet = await ViTien.findOne({ where: { MaNguoiDung: complaint.MaNguoiBiKhieuNai } });

          if (customerWallet && systemWallet && providerWallet) {
            let providerPenalty = 0;

            if (caLam.DaThanhToan) {
              // Trường hợp 1: Đã thanh toán -> Trừ tiền trực tiếp từ ví nhân viên
              providerPenalty = Math.min(hoanTienAmount, providerReceived);
              
              const newProvBalance = parseFloat(providerWallet.SoDu) - providerPenalty;
              await providerWallet.update({ SoDu: newProvBalance }, { transaction: tx });
              
              systemWallet.SoDu = parseFloat(systemWallet.SoDu) + providerPenalty;
              await systemWallet.save({ transaction: tx });

              await LichSuViTien.create({
                MaViNguon: providerWallet.MaViTien,
                MaViDich: systemWallet.MaViTien,
                MaCaLam: caLam.MaCaLam,
                MaKhieuNai: complaintId,
                LoaiGiaoDich: 4, // 4: Trừ tiền phạt
                SoTien: providerPenalty,
                SoDuSau: newProvBalance,
                NgayTao: new Date()
              }, { transaction: tx });
            } else if (caLam.TongTienTre !== null) {
              // Trường hợp 2: Chưa thanh toán -> Trừ bớt tiền đang chờ duyệt (pending payout) của nhân viên
              const currentPending = parseFloat(caLam.TongTienTre);
              providerPenalty = Math.min(hoanTienAmount, currentPending);
              const remainingPending = currentPending - providerPenalty;
              await caLam.update({ TongTienTre: remainingPending }, { transaction: tx });
            }

            // Trừ tiền bồi thường từ ví hệ thống để hoàn cho khách
            const newSysBalance = parseFloat(systemWallet.SoDu) - hoanTienAmount;
            await systemWallet.update({ SoDu: newSysBalance }, { transaction: tx });

            // Cộng tiền bồi thường hoàn lại vào ví Khách hàng
            const newCustBalance = parseFloat(customerWallet.SoDu) + hoanTienAmount;
            await customerWallet.update({ SoDu: newCustBalance }, { transaction: tx });

            // Ghi nhật ký giao dịch hoàn tiền bồi thường
            await LichSuViTien.create({
              MaViNguon: systemWallet.MaViTien,
              MaViDich: customerWallet.MaViTien,
              MaCaLam: caLam.MaCaLam,
              MaKhieuNai: complaintId,
              LoaiGiaoDich: 3, // 3: Hoàn tiền
              SoTien: hoanTienAmount,
              SoDuSau: newCustBalance,
              NgayTao: new Date()
            }, { transaction: tx });

            console.log(`[HOÀN TIỀN THÀNH CÔNG] Đã hoàn ${hoanTienAmount} cho khách hàng #${complaint.MaNguoiGui} từ ca làm #${caLam.MaCaLam}`);
          }
        }
      }

      await tx.commit();

      // Tự động đối soát và giải ngân cho nhân viên ngay khi khiếu nại được giải quyết xong (nếu đủ điều kiện)
      const caLam = await CaLamViec.findByPk(complaint.MaCaLam);
      if (caLam && caLam.MaNhanVien) {
        try {
          const { checkAndExecutePayoutsForProvider } = require('../utils/payout_helper');
          await checkAndExecutePayoutsForProvider(caLam.MaNhanVien);
        } catch (payoutErr) {
          console.error('[LỖI ĐỐI SOÁT KHI GIẢI QUYẾT KHIẾU NẠI]:', payoutErr.message);
        }
      }

      const updatedComplaint = await KhieuNai.findByPk(complaintId, {
        include: [
          { model: NguoiDung, as: 'NguoiGui', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'Email'] },
          { model: NguoiDung, as: 'NguoiBiKhieuNai', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'Email'] },
          { model: CaLamViec, as: 'CaLamViec' },
          { model: HinhThucXuLy, as: 'HinhThucXuLy' }
        ]
      });

      // Gửi thông báo thời gian thực qua Socket.IO cho khách hàng
      oCamManager.guiThongBaoNguoiDung(complaint.MaNguoiGui, {
        tieuDe: 'Khiếu nại đã được xử lý!',
        noiDung: `Khiếu nại #${complaint.MaKhieuNai} của bạn đã được Admin xử lý.`,
        data: updatedComplaint
      });

      return success(res, updatedComplaint, 'Xử lý và hoàn thành khiếu nại thành công');
    } catch (err) {
      if (tx) await tx.rollback();
      next(err);
    }
  }

  // Lấy danh sách hình thức xử lý khiếu nại
  async getResolutionTypes(req, res, next) {
    try {
      const types = await HinhThucXuLy.findAll();
      return success(res, types, 'Lấy danh sách hình thức xử lý thành công');
    } catch (err) {
      next(err);
    }
  }

  // ============================================================
  // Tự động thanh toán lương (Gọi qua Cron Job)
  // ============================================================
  async executeAutomaticPayouts() {
    let tx;
    try {
      const seventyTwoHoursAgo = new Date(Date.now() - 72 * 60 * 60 * 1000);
      const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

      // Lấy tất cả các ca làm việc hoàn thành, chưa thanh toán
      const pendingShifts = await CaLamViec.findAll({
        where: {
          TrangThaiDonHang: 2, // Hoàn thành
          DaThanhToan: false
        },
        include: [{
          model: KhieuNai,
          as: 'KhieuNais',
          required: false
        }]
      });

      // Lọc các ca làm đủ điều kiện 24h / 72h
      const validShifts = pendingShifts.filter(shift => {
        const hasComplaints = shift.KhieuNais && shift.KhieuNais.length > 0;
        
        // Tính số tiền: nếu TongTienTre null/0, dùng TienNhanVienNhan
        const amount = shift.TongTienTre !== null ? parseFloat(shift.TongTienTre) : parseFloat(shift.TienNhanVienNhan);
        if (!(amount > 0)) return false;

        // Tính thời gian: NgayHoanThanh -> NgayCapNhat -> NgayLamViec
        let finishDate;
        if (shift.NgayHoanThanh) {
          finishDate = new Date(shift.NgayHoanThanh);
        } else if (shift.NgayCapNhat) {
          finishDate = new Date(shift.NgayCapNhat);
        } else {
          finishDate = new Date(shift.NgayLamViec + 'T' + shift.GioKetThuc);
        }

        if (hasComplaints) {
          // Nếu có khiếu nại, phải giữ đủ 72 giờ
          if (finishDate > seventyTwoHoursAgo) return false;
          
          // Và tất cả khiếu nại phải được giải quyết (TrangThaiXuLy = 2) mới được nhận tiền còn lại
          const allResolved = shift.KhieuNais.every(k => k.TrangThaiXuLy === 2);
          if (!allResolved) return false;
        } else {
          // Nếu không có khiếu nại, giữ đủ 24 giờ
          if (finishDate > twentyFourHoursAgo) return false;
        }

        return true;
      });

      if (validShifts.length === 0) {
        return { success: true, data: null, message: 'Không có ca làm việc nào đủ điều kiện thanh toán.' };
      }

      // Group by MaNhanVien
      const payoutsByProvider = {};
      for (const shift of validShifts) {
        if (!shift.MaNhanVien) continue;
        const providerId = shift.MaNhanVien;
        if (!payoutsByProvider[providerId]) {
          payoutsByProvider[providerId] = {
            totalAmount: 0,
            shifts: []
          };
        }
        const shiftAmount = shift.TongTienTre !== null ? parseFloat(shift.TongTienTre) : parseFloat(shift.TienNhanVienNhan);
        payoutsByProvider[providerId].totalAmount += shiftAmount;
        payoutsByProvider[providerId].shifts.push({ shift, amount: shiftAmount });
      }

      tx = await sequelize.transaction();

      const systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });
      if (!systemWallet) {
        throw new Error('Không tìm thấy ví hệ thống để giải ngân.');
      }

      let totalPayoutAll = 0;
      let payoutCount = 0;

      for (const providerId of Object.keys(payoutsByProvider)) {
        const payout = payoutsByProvider[providerId];
        const providerWallet = await ViTien.findOne({ where: { MaNguoiDung: providerId } });
        
        if (providerWallet) {
          totalPayoutAll += payout.totalAmount;
          
          // 1. Cộng tiền vào ví nhân viên
          const newProvBalance = parseFloat(providerWallet.SoDu) + payout.totalAmount;
          await providerWallet.update({ SoDu: newProvBalance }, { transaction: tx });

          // 2. Ghi một giao dịch tổng cho nhân viên
          await LichSuViTien.create({
            MaViNguon: systemWallet.MaViTien,
            MaViDich: providerWallet.MaViTien,
            MaCaLam: null, // Multiple shifts, so leave null
            LoaiGiaoDich: 4, // 4: Trả lương nhân viên
            SoTien: payout.totalAmount,
            SoDuSau: newProvBalance,
            NgayTao: new Date(),
            NoiDungGiaoDich: `Thanh toán lương tuần cho ${payout.shifts.length} ca làm việc.`
          }, { transaction: tx });

          // 3. Mark all shifts as paid
          for (const item of payout.shifts) {
            await item.shift.update({ DaThanhToan: true, TongTienTre: item.amount }, { transaction: tx });
          }
          
          payoutCount++;
        }
      }

      // 4. Trừ tổng tiền khỏi ví hệ thống
      const newSysBalance = parseFloat(systemWallet.SoDu) - totalPayoutAll;
      await systemWallet.update({ SoDu: newSysBalance }, { transaction: tx });

      await tx.commit();

      return {
        success: true,
        data: {
          providersPaid: payoutCount,
          totalAmount: totalPayoutAll,
          shiftsProcessed: validShifts.length
        },
        message: 'Thanh toán tự động thành công.'
      };
    } catch (err) {
      if (tx) await tx.rollback();
      throw err;
    }
  }
}

module.exports = new AdminController();
