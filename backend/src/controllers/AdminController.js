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
      const finishedCaLam = await CaLamViec.findAll({ where: { TrangThaiDonHang: 2 } });
      
      const totalRevenue = finishedCaLam.reduce((sum, job) => sum + parseFloat(job.TongTien), 0);
      const systemEarnings = finishedCaLam.reduce((sum, job) => sum + parseFloat(job.TienHeThongNhan), 0);

      const metrics = {
        totalCustomers,
        totalProviders,
        totalBookings,
        totalRevenue, // Total gross sales
        systemEarnings, // System commission profit
        pendingBookings,
        completedBookings
      };

      return success(res, metrics, 'Lấy dữ liệu thống kê thành công');
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

      // Update complaint status
      await complaint.update({
        MaNguoiXuLy: adminId,
        MaHinhThucXuLy,
        TrangThaiXuLy: 2, // 2: Da giai quyet
        NgayXuLy: new Date()
      }, { transaction: tx });

      // Xử lý hoàn tiền bồi thường: If TenHinhThuc is "Hoàn tiền" or MaHinhThucXuLy is 1
      if (hinhThuc.TenHinhThuc.toLowerCase().includes('hoàn tiền') || hinhThuc.TenHinhThuc.toLowerCase().includes('hoan tien') || MaHinhThucXuLy === 1) {
        const caLam = await CaLamViec.findByPk(complaint.MaCaLam);
        if (caLam) {
          const hoanTienAmount = SoTienDenBu ? parseFloat(SoTienDenBu) : parseFloat(caLam.TongTien);

          if (hoanTienAmount > parseFloat(caLam.TongTien)) {
            throw new Error(`Số tiền đền bù (${hoanTienAmount}) không được vượt quá số tiền thực tế ca làm (${caLam.TongTien})`);
          }

          // Fetch client and system wallets
          const customerWallet = await ViTien.findOne({ where: { MaNguoiDung: complaint.MaNguoiGui } });
          const systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });

          if (customerWallet && systemWallet) {
            // Trừ tiền bồi thường từ ví hệ thống
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
              LoaiGiaoDich: 3, // 3: Hoan tien
              SoTien: hoanTienAmount,
              SoDuSau: newCustBalance,
              NgayTao: new Date()
            }, { transaction: tx });

            console.log(`[REFUND SUCCESS] Refunded ${hoanTienAmount} to customer #${complaint.MaNguoiGui} for CaLam #${caLam.MaCaLam}`);
          }
        }
      }

      await tx.commit();

      const updatedComplaint = await KhieuNai.findByPk(complaintId, {
        include: [
          { model: NguoiDung, as: 'NguoiGui', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'Email'] },
          { model: NguoiDung, as: 'NguoiBiKhieuNai', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'Email'] },
          { model: CaLamViec, as: 'CaLamViec' },
          { model: HinhThucXuLy, as: 'HinhThucXuLy' }
        ]
      });

      // Gửi thông báo thời gian thực via Socket.IO
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
}

module.exports = new AdminController();
