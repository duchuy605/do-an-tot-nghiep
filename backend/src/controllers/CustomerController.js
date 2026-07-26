const { Op } = require('sequelize');
const sequelize = require('../config/database');
const {
  NguoiDung,
  HoSoNhanVien,
  DichVu,
  DonDatLich,
  CaLamViec,
  ViTien,
  LichSuViTien,
  DanhGia,
  KhieuNai,
  DatDichVu,
  NgayDacBiet,
  QuyDinhGia,
  QuyDinhKhungGio,
  LoaiGoi,
  LichSuDoiLich
} = require('../models');
const { getDurationInHours, getDayOfWeekVN, checkTimeInSlot } = require('../utils/tinh_gia');
const { success, error } = require('../utils/phan_hoi');
const { createBookingSchema } = require('../validators/booking.validator');
const { createReviewSchema, createComplaintSchema, rescheduleShiftSchema } = require('../validators/others.validator');
const oCamManager = require('../sockets/o_cam_manager');
const { checkAndExecutePayoutsForProvider } = require('../utils/payout_helper');

class CustomerController {
  constructor() {
    this.calculatePriceDetails = this.calculatePriceDetails.bind(this);
    this.previewBookingPrice = this.previewBookingPrice.bind(this);
    this.createBooking = this.createBooking.bind(this);
    this.getBookings = this.getBookings.bind(this);
    this.getBookingDetail = this.getBookingDetail.bind(this);
    this.cancelBooking = this.cancelBooking.bind(this);
    this.payBooking = this.payBooking.bind(this);
    this.topupWallet = this.topupWallet.bind(this);
    this.getWallet = this.getWallet.bind(this);
    this.getWalletHistory = this.getWalletHistory.bind(this);
    this.createReview = this.createReview.bind(this);
    this.createComplaint = this.createComplaint.bind(this);
    this.getPackages = this.getPackages.bind(this);
    this.rescheduleShift = this.rescheduleShift.bind(this);
    this.respondRescheduleShift = this.respondRescheduleShift.bind(this);
    this.changeProvider = this.changeProvider.bind(this);
    this.getProviderBusyDates = this.getProviderBusyDates.bind(this);
  }

  // Hàm tiện ích hỗ trợ tính giá chi tiết buổi làm
  async calculatePriceDetails(bookingData) {
    const { DichVus, NgayBatDau, NgayKetThuc, ThuTrongTuan, GioBatDau, GioKetThuc, MaLoaiGoi } = bookingData;
    const selectedProviderId = bookingData.MaNhanVien || null;

    // 1. Lấy đơn giá dịch vụ - phân biệt dịch vụ chính và dịch vụ phụ
    let mainServiceRate = 0;      // Giá dịch vụ chính (nhân × tổng giờ)
    let additionalServiceRate = 0; // Giá dịch vụ phụ (chỉ tính 1 giờ)
    const serviceDetails = [];
    for (const item of DichVus) {
      const sv = await DichVu.findByPk(item.MaDichVu);
      if (!sv || !sv.TrangThai) {
        throw new Error(`Dịch vụ với ID ${item.MaDichVu} không khả dụng`);
      }
      serviceDetails.push({ service: sv, quantity: item.SoLuong, isMain: item.LaDichVuChinh !== false });
      if (item.LaDichVuChinh !== false) {
        // Dịch vụ chính: giá sẽ được nhân với tổng số giờ
        mainServiceRate += parseFloat(sv.DonGia) * item.SoLuong;
      } else {
        // Dịch vụ phụ: chỉ tính 1 giờ cố định
        additionalServiceRate += parseFloat(sv.DonGia) * item.SoLuong;
      }
    }

    // 2. Tính số giờ làm việc thực tế
    const startHour = parseInt(GioBatDau.split(':')[0]);
    const endHour = parseInt(GioKetThuc.split(':')[0]);
    const endMinute = parseInt(GioKetThuc.split(':')[1] || 0);

    if (startHour < 6 || endHour > 22 || (endHour === 22 && endMinute > 0)) {
      throw new Error('Thời gian hoạt động của ứng dụng là từ 06:00 đến 22:00. Vui lòng chọn khung giờ khác.');
    }

    const duration = getDurationInHours(GioBatDau, GioKetThuc);
    if (duration <= 0) {
      throw new Error('Giờ kết thúc phải sau giờ bắt đầu');
    }

    const detailedServices = serviceDetails.map(item => {
      const hours = item.isMain ? duration : 1;
      const totalServicePrice = parseFloat(item.service.DonGia) * item.quantity * hours;
      return {
        serviceName: item.service.TenDichVu,
        hours: hours,
        price: totalServicePrice,
        isMain: item.isMain
      };
    });

    // 3. Tạo danh sách các ngày làm việc thực tế
    const start = new Date(NgayBatDau);
    const dates = [];

    if (bookingData.LoaiDatLich === 2 && (!ThuTrongTuan || ThuTrongTuan.trim() === '')) {
      throw new Error('Vui lòng chọn ít nhất một ngày trong tuần để đặt lịch định kỳ');
    }

    const end = bookingData.LoaiDatLich === 2 ? new Date(NgayKetThuc) : new Date(start);
    const daysFilter = ThuTrongTuan ? ThuTrongTuan.split(',').map(s => s.trim().toUpperCase()) : [];

    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      const dateStr = d.toISOString().split('T')[0];
      const dayVN = getDayOfWeekVN(dateStr);
      
      if (bookingData.LoaiDatLich === 2 && daysFilter.length > 0 && !daysFilter.includes(dayVN)) {
        continue;
      }
      dates.push(dateStr);
    }

    if (dates.length === 0) {
      throw new Error('Không có ngày làm việc nào phù hợp trong khoảng thời gian đã chọn');
    }

    // 4. Tra cứu hệ số quy định trong CSDL
    const specialDays = await NgayDacBiet.findAll();
    const priceRules = await QuyDinhGia.findAll();
    const timeSlots = await QuyDinhKhungGio.findAll();
    const packageInfo = MaLoaiGoi ? await LoaiGoi.findByPk(MaLoaiGoi) : null;

    // Tìm quy định giá có số giờ gần nhất với duration của ca làm
    let matchedPriceRule = null;
    let minDiff = Infinity;
    for (const rule of priceRules) {
      const diff = Math.abs(parseFloat(rule.SoGio) - duration);
      if (diff < minDiff) {
        minDiff = diff;
        matchedPriceRule = rule;
      }
    }

    const durationCoeff = matchedPriceRule ? parseFloat(matchedPriceRule.HeSoGiamGia) : 1.0;
    const defaultWeekendCoeff = matchedPriceRule ? parseFloat(matchedPriceRule.HeSoT7CN) : 1.2;

    let timeSlotCoeff = 1.0;
    for (const slot of timeSlots) {
      if (checkTimeInSlot(GioBatDau, slot.GioBatDau, slot.GioKetThuc)) {
        timeSlotCoeff = parseFloat(slot.HeSoGia);
        break;
      }
    }

    let packageDiscountPercent = 0.0;
    if (packageInfo && packageInfo.TrangThai === 1) {
      packageDiscountPercent = parseFloat(packageInfo.PhanTramGiamGia);
    }

    let totalBookingPrice = 0;
    const sessionDetails = [];

    for (const dateStr of dates) {
      let specialDayCoeff = 1.0;
      const spDay = specialDays.find(sd => sd.Ngay === dateStr);
      if (spDay) {
        specialDayCoeff = parseFloat(spDay.HeSoGia);
      }

      let weekendCoeff = 1.0;
      const dayOfWeek = getDayOfWeekVN(dateStr);
      // Đặt định kỳ: không tính hệ số khung giờ và hệ số T7/CN
      const isRecurring = bookingData.LoaiDatLich === 2;
      if (!isRecurring && (dayOfWeek === '7' || dayOfWeek === 'CN')) {
        weekendCoeff = defaultWeekendCoeff;
      }
      const effectiveTimeSlotCoeff = isRecurring ? 1.0 : timeSlotCoeff;

      // Tính giá: dịch vụ chính × tổng giờ + dịch vụ phụ × 1 giờ
      const mainPrice = mainServiceRate * duration * durationCoeff;
      const additionalPrice = additionalServiceRate * 1 * durationCoeff; // Chỉ 1 giờ
      const sessionBasePrice = mainPrice + additionalPrice;
      let sessionFinalPrice = sessionBasePrice * specialDayCoeff * effectiveTimeSlotCoeff * weekendCoeff;

      if (packageDiscountPercent > 0) {
        sessionFinalPrice = sessionFinalPrice * (1 - packageDiscountPercent / 100);
      }

      // Phụ thu 10% khi chọn nhân viên cụ thể
      if (selectedProviderId) {
        sessionFinalPrice = sessionFinalPrice * 1.1;
      }

      const roundedPrice = Math.round(sessionFinalPrice / 1000) * 1000;

      sessionDetails.push({
        NgayLamViec: dateStr,
        GioBatDau,
        GioKetThuc,
        MoTaCa: `${dates.indexOf(dateStr) + 1}/${dates.length}`,
        TongTien: roundedPrice,
        BasePrice: sessionBasePrice,
        HeSoDacBiet: specialDayCoeff,
        HeSoKhungGio: timeSlotCoeff,
        HeSoCuoiTuan: weekendCoeff
      });

      totalBookingPrice += roundedPrice;
    }

    return {
      totalBookingPrice,
      sessionDetails,
      detailedServices,
      baseRatePerHour: mainServiceRate + additionalServiceRate,
      duration,
      totalSessions: dates.length,
      packageDiscountPercent,
      providerSurchargePercent: selectedProviderId ? 10 : 0
    };
  }

  // ============================================================
  // POST /bookings/preview - Xem trước giá đơn đặt lịch
  // Dùng cùng logic calculatePriceDetails nhưng KHÔNG tạo đơn
  // ============================================================
  async previewBookingPrice(req, res, next) {
    try {
      const bookingData = req.body;
      const calculation = await this.calculatePriceDetails(bookingData);
      
      return success(res, {
        totalPrice: calculation.totalBookingPrice,
        baseRatePerHour: calculation.baseRatePerHour,
        duration: calculation.duration,
        detailedServices: calculation.detailedServices,
        totalSessions: calculation.totalSessions,
        packageDiscountPercent: calculation.packageDiscountPercent,
        providerSurchargePercent: calculation.providerSurchargePercent,
        sessionDetails: calculation.sessionDetails
      }, 'Tính giá thành công');
    } catch (err) {
      return error(res, err.message || 'Lỗi khi tính giá', 400);
    }
  }

  async getServices(req, res, next) {
    try {
      const services = await DichVu.findAll({ where: { TrangThai: true } });
      return success(res, services, 'Lấy danh sách dịch vụ thành công');
    } catch (err) {
      next(err);
    }
  }

  async getPackages(req, res, next) {
    try {
      const packages = await LoaiGoi.findAll({ where: { TrangThai: 1 } });
      return success(res, packages, 'Lấy danh sách gói thành công');
    } catch (err) {
      next(err);
    }
  }

  async getServiceDetail(req, res, next) {
    try {
      const service = await DichVu.findByPk(req.params.id);
      if (!service) {
        return error(res, 'Dịch vụ không tồn tại', 404);
      }
      return success(res, service, 'Lấy chi tiết dịch vụ thành công');
    } catch (err) {
      next(err);
    }
  }

  async getProviders(req, res, next) {
    try {
      const providers = await NguoiDung.findAll({
        where: { VaiTro: 2, TrangThaiTaiKhoan: 1 },
        attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'Email', 'SoDienThoai', 'GioiTinh', 'AnhDaiDien'],
        include: [
          {
            model: HoSoNhanVien,
            as: 'HoSoNhanVien',
            where: { TrangThaiDuyet: 1, TrangThaiHoatDong: true }
          }
        ]
      });
      return success(res, providers, 'Lấy danh sách nhân viên thành công');
    } catch (err) {
      next(err);
    }
  }

  async getProviderDetail(req, res, next) {
    try {
      const provider = await NguoiDung.findOne({
        where: { MaNguoiDung: req.params.id, VaiTro: 2 },
        attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'Email', 'SoDienThoai', 'GioiTinh', 'AnhDaiDien', 'DiaChi'],
        include: [{ model: HoSoNhanVien, as: 'HoSoNhanVien' }]
      });
      if (!provider) {
        return error(res, 'Không tìm thấy thông tin nhân viên này', 404);
      }
      return success(res, provider, 'Lấy chi tiết nhân viên thành công');
    } catch (err) {
      next(err);
    }
  }

  async getProviderBusyDates(req, res, next) {
    try {
      const providerId = req.params.id;
      const shifts = await CaLamViec.findAll({
        where: {
          MaNhanVien: providerId,
          TrangThaiDonHang: { [Op.in]: [0, 1] } // Chỉ lấy ca đang chờ hoặc đã nhận
        },
        attributes: ['MaCaLam', 'NgayLamViec', 'GioBatDau', 'GioKetThuc'],
        order: [['NgayLamViec', 'ASC']]
      });

      const busyDates = shifts.map(s => {
        // Đảm bảo date dạng 'YYYY-MM-DD'
        const d = s.NgayLamViec instanceof Date
          ? s.NgayLamViec.toISOString().substring(0, 10)
          : String(s.NgayLamViec).substring(0, 10);
        // Đảm bảo time dạng 'HH:mm' (cắt bỏ giây nếu có)
        const start = String(s.GioBatDau || '00:00').substring(0, 5);
        const end   = String(s.GioKetThuc || '00:00').substring(0, 5);
        return { id: s.MaCaLam, date: d, start, end };
      });

      return success(res, busyDates, 'Lấy lịch bận của nhân viên thành công');
    } catch (err) {
      next(err);
    }
  }

  // ============================================================
  // POST /bookings - Tạo đơn đặt lịch + Thanh toán (ATOMIC)
  // Chỉ khi thanh toán thành công mới lưu đơn đặt lịch vào database.
  // Nếu ví không đủ tiền → không tạo gì cả, trả về lỗi.
  // Giải thích logic Đặt Lịch (Booking Logic):
  // 1. Kiểm tra số dư ví (Ví Khách Hàng) trước khi thực hiện giao dịch (Transaction).
  // 2. Chuyển đổi trạng thái ví: Trừ tiền ví khách hàng, cộng tiền vào ví tạm giữ (Escrow) của hệ thống.
  // 3. Tạo bản ghi DonDatLich với TrangThai = 2 (Đã thanh toán). Đơn đặt lịch chứa thông tin tổng quan (định kỳ hoặc một lần).
  // 4. Nếu là lịch định kỳ (Recurring jobs), hệ thống tự động tách thành nhiều ca làm việc (CaLamViec) tương ứng với số buổi.
  // 5. Kiểm tra xung đột lịch (Conflict checking): Nếu khách hàng chọn đích danh 1 nhân viên, hệ thống sẽ duyệt qua từng ca làm việc và kiểm tra trong bảng CaLamViec xem nhân viên đó có ca nào trùng lấp thời gian (GioBatDau - GioKetThuc) vào cùng NgayLamViec hay không. Nếu trùng, rollback toàn bộ transaction.
  // 6. Chuyển đổi trạng thái ca làm việc (State transitions): Nếu chọn nhân viên cụ thể -> TrangThaiDonHang = 0 (Chờ xác nhận từ nhân viên). Nếu không chọn nhân viên -> TrangThaiDonHang = 1 (Chờ nhận việc trên bảng tin chung).
  // 7. Hoàn tất transaction và gửi thông báo theo thời gian thực (Real-time notification).
  // ============================================================
  async createBooking(req, res, next) {
    let tx;
    try {
      const { error: valError } = createBookingSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const customerId = req.user.MaNguoiDung;
      const bookingData = req.body;

      // 1. Tính toán chi phí đơn
      const calculation = await this.calculatePriceDetails(bookingData);
      const price = calculation.totalBookingPrice;

      // 2. Kiểm tra ví TRƯỚC khi bắt đầu transaction
      const wallet = await ViTien.findOne({ where: { MaNguoiDung: customerId } });
      if (!wallet) {
        return error(res, 'Không tìm thấy ví tiền. Vui lòng liên hệ hỗ trợ.', 404);
      }
      if (parseFloat(wallet.SoDu) < price) {
        return error(res, 'Số dư ví không đủ để thanh toán. Vui lòng nạp thêm tiền.', 400, {
          SoDuHienTai: parseFloat(wallet.SoDu),
          SoTienCanTra: price,
          SoTienThieu: price - parseFloat(wallet.SoDu)
        });
      }

      tx = await sequelize.transaction();

      // 3. Trừ tiền ví khách hàng
      const newBalance = parseFloat(wallet.SoDu) - price;
      await wallet.update({ SoDu: newBalance }, { transaction: tx });

      // 4. Cộng tiền vào ví tạm giữ hệ thống (Escrow)
      const systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });
      if (systemWallet) {
        const newSysBalance = parseFloat(systemWallet.SoDu) + price;
        await systemWallet.update({ SoDu: newSysBalance }, { transaction: tx });
      }

      // 5. Tạo đơn đặt lịch chính - trạng thái ĐÃ THANH TOÁN (TrangThai = 2)
      const booking = await DonDatLich.create({
        MaKhachHang: customerId,
        MaNhanVien: bookingData.MaNhanVien || null,
        MaLoaiGoi: bookingData.MaLoaiGoi || null,
        NgayBatDau: bookingData.NgayBatDau,
        NgayKetThuc: bookingData.NgayKetThuc,
        ThuTrongTuan: bookingData.ThuTrongTuan,
        LoaiDatLich: bookingData.LoaiDatLich,
        GiaGoi: price,
        SoBuoi: calculation.totalSessions,
        DiaChiLamViec: bookingData.DiaChiLamViec,
        GioBatDau: bookingData.GioBatDau,
        GioKetThuc: bookingData.GioKetThuc,
        MoTaCongViec: bookingData.MoTaCongViec,
        TrangThai: 2 // 2: Đã thanh toán (Active)
      }, { transaction: tx });

      // 6. Lưu chi tiết các dịch vụ được chọn
      for (const item of bookingData.DichVus) {
        const sv = await DichVu.findByPk(item.MaDichVu);
        if (!sv) throw new Error(`Dịch vụ với ID ${item.MaDichVu} không tồn tại`);
        // Dịch vụ chính × tổng giờ, dịch vụ phụ × 1 giờ
        const soGioTinh = (item.LaDichVuChinh !== false) ? calculation.duration : 1;
        const subtotal = sv.DonGia * item.SoLuong * soGioTinh;
        await DatDichVu.create({
          MaDatLich: booking.MaDatLich,
          MaDichVu: item.MaDichVu,
          DonGia: sv.DonGia,
          SoLuong: item.SoLuong,
          PhuPhi: 0,
          ThanhTien: subtotal
        }, { transaction: tx });
      }

      // 7. Kiểm tra trùng lịch nhân viên (nếu chọn nhân viên cụ thể)
      if (bookingData.MaNhanVien) {
        for (const session of calculation.sessionDetails) {
          const conflicting = await CaLamViec.findOne({
            where: {
              MaNhanVien: bookingData.MaNhanVien,
              NgayLamViec: session.NgayLamViec,
              TrangThaiDonHang: { [Op.in]: [0, 1] }, // Chờ xác nhận hoặc đã nhận
              [Op.or]: [
                { GioBatDau: { [Op.lt]: session.GioKetThuc }, GioKetThuc: { [Op.gt]: session.GioBatDau } }
              ]
            },
            transaction: tx
          });
          if (conflicting) {
            await tx.rollback();
            return error(res, `Nhân viên đã có lịch vào ngày ${session.NgayLamViec} (${conflicting.GioBatDau} - ${conflicting.GioKetThuc}). Vui lòng chọn thời gian khác.`, 400);
          }
        }
      }

      // 8. Tách các ca làm chi tiết
      const serviceNames = [];
      for (const item of bookingData.DichVus) {
        const sv = await DichVu.findByPk(item.MaDichVu);
        serviceNames.push(sv.TenDichVu);
      }
      const serviceString = serviceNames.join(', ');

      // Nếu chỉ định nhân viên: trạng thái 0 (chờ xác nhận), ngược lại: 1 (chờ nhận việc)
      const trangThaiCa = bookingData.MaNhanVien ? 0 : 1;

      for (const session of calculation.sessionDetails) {
        await CaLamViec.create({
          MaKhachHang: customerId,
          MaDatLich: booking.MaDatLich,
          MaNhanVien: bookingData.MaNhanVien || null,
          GioBatDau: session.GioBatDau,
          GioKetThuc: session.GioKetThuc,
          NgayLamViec: session.NgayLamViec,
          TongTien: session.TongTien,
          DiaChiLamViec: bookingData.DiaChiLamViec,
          MoTaCongViec: ` ${bookingData.MoTaCongViec || ''}`,
          NgayDat: new Date(),
          TienNhanVienNhan: 0,
          TienHeThongNhan: 0,
          DichVu: serviceString,
          TrangThaiDonHang: trangThaiCa
        }, { transaction: tx });
      }

      // 8. Ghi lịch sử giao dịch thanh toán
      await LichSuViTien.create({
        MaViNguon: wallet.MaViTien,
        MaViDich: systemWallet ? systemWallet.MaViTien : null,
        MaDatLich: booking.MaDatLich,
        LoaiGiaoDich: 2, // 2: Thanh toán
        SoTien: price,
        SoDuSau: newBalance,
        NgayTao: new Date()
      }, { transaction: tx });

      await tx.commit();
      tx = null; // Đánh dấu đã commit, tránh rollback trong catch

      // 9. Gửi thông báo thời gian thực (không ảnh hưởng transaction)
      try {
        if (bookingData.MaNhanVien) {
          // Gửi thông báo cho nhân viên được chỉ định để xác nhận
          oCamManager.guiThongBaoNguoiDung(bookingData.MaNhanVien, {
            tieuDe: 'Bạn có yêu cầu công việc mới!',
            noiDung: `Khách hàng ${req.user.HoTenNguoiDung} yêu cầu bạn thực hiện đơn #${booking.MaDatLich}. Vui lòng xác nhận nhận việc.`,
            data: booking
          });
        } else {
          // Gửi thông báo chung cho tất cả nhân viên
          oCamManager.guiThongBaoAdminVaNhanVien({
            tieuDe: 'Có đơn đặt lịch mới cần nhận!',
            noiDung: `Khách hàng ${req.user.HoTenNguoiDung} vừa đặt và thanh toán đơn #${booking.MaDatLich}`,
            data: booking
          });
        }

        // Gửi thông báo cho khách hàng
        const userId = customerId;
        oCamManager.guiThongBaoNguoiDung(userId, {
          tieuDe: 'Đặt lịch thành công!',
          noiDung: `Đơn #${booking.MaDatLich} đã được tạo và thanh toán ${price.toLocaleString('vi-VN')} đ. Số dư còn lại: ${newBalance.toLocaleString('vi-VN')} đ`,
          data: booking
        });
      } catch (notifErr) {
        console.error('[LỖI THÔNG BÁO]', notifErr.message);
      }

      // Tải đầy đủ thông tin đơn đặt lịch để phản hồi về cho client
      let fullBooking = booking;
      try {
        fullBooking = await DonDatLich.findByPk(booking.MaDatLich, {
          include: [
            { model: DatDichVu, as: 'DatDichVus', include: [{ model: DichVu, as: 'DichVu' }] },
            { model: CaLamViec, as: 'CaLamViecs' }
          ]
        });
      } catch (loadErr) {
        console.error('[LỖI TẢI ĐƠN ĐẶT LỊCH]', loadErr.message);
      }

      return success(res, {
        booking: fullBooking,
        newBalance,
        totalPaid: price
      }, 'Đặt lịch và thanh toán thành công!', 201);
    } catch (err) {
      if (tx) await tx.rollback();
      next(err);
    }
  }

  async getBookings(req, res, next) {
    try {
      const customerId = req.user.MaNguoiDung;
      const bookings = await DonDatLich.findAll({
        where: { MaKhachHang: customerId },
        include: [
          { model: DatDichVu, as: 'DatDichVus', include: [{ model: DichVu, as: 'DichVu' }] },
          { model: CaLamViec, as: 'CaLamViecs', include: [
            { model: DanhGia, as: 'DanhGia' },
            { model: KhieuNai, as: 'KhieuNais' }
          ] }
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
      const customerId = req.user.MaNguoiDung;
      const booking = await DonDatLich.findByPk(req.params.id, {
        include: [
          { model: NguoiDung, as: 'KhachHang', attributes: { exclude: ['MatKhau'] } },
          { model: NguoiDung, as: 'NhanVien', attributes: { exclude: ['MatKhau'] } },
          { model: LoaiGoi, as: 'LoaiGoi' },
          { model: DatDichVu, as: 'DatDichVus', include: [{ model: DichVu, as: 'DichVu' }] },
          { model: CaLamViec, as: 'CaLamViecs', include: [
            { model: NguoiDung, as: 'NhanVien', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'SoDienThoai', 'AnhDaiDien'] },
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
          ] }
        ]
      });

      if (!booking) {
        return error(res, 'Đơn đặt lịch không tồn tại', 404);
      }
      // Customer chỉ xem đơn của mình, Provider/Admin xem được tất cả
      const userRole = req.user.VaiTro;
      if (userRole === 1 && booking.MaKhachHang !== customerId) {
        return error(res, 'Bạn không có quyền xem đơn này', 403);
      }
      return success(res, booking, 'Lấy chi tiết đơn đặt lịch thành công');
    } catch (err) {
      next(err);
    }
  }

  // ============================================================
  // DELETE /bookings/:id - Hủy đơn đặt lịch (luôn hoàn tiền)
  // Vì booking chỉ tạo khi thanh toán thành công (TrangThai=2),
  // nên hủy đơn sẽ luôn hoàn tiền từ Escrow về ví khách hàng.
  // ============================================================
  async cancelBooking(req, res, next) {
    let tx;
    try {
      const customerId = req.user.MaNguoiDung;
      const bookingId = req.params.id;

      const booking = await DonDatLich.findByPk(bookingId);
      if (!booking || booking.MaKhachHang !== customerId) {
        return error(res, 'Đơn đặt lịch không tồn tại', 404);
      }

      // Chỉ cho phép hủy đơn đang hoạt động (TrangThai = 2)
      if (booking.TrangThai !== 2) {
        return error(res, 'Đơn hàng không ở trạng thái có thể hủy (đã hoàn thành hoặc đã hủy trước đó)', 400);
      }

      // Yêu cầu lý do hủy
      const lyDoHuy = req.body.LyDoHuy;
      if (!lyDoHuy || lyDoHuy.trim() === '') {
        return error(res, 'Vui lòng nhập lý do hủy đơn', 400);
      }

      tx = await sequelize.transaction();

      // Lấy tất cả ca làm việc chưa hoàn thành (0, 1) thuộc booking này để kiểm tra phạt
      const activeJobs = await CaLamViec.findAll({
        where: { MaDatLich: bookingId, TrangThaiDonHang: { [Op.in]: [0, 1] } }
      });

      let totalPenalty = 0;
      let penalties = []; // Lưu danh sách nhân viên được nhận bồi thường
      const now = new Date();

      for (let job of activeJobs) {
        // Chỉ phạt nếu ca làm ĐÃ CÓ nhân viên nhận
        if (job.MaNhanVien) {
          const jobStartStr = `${job.NgayLamViec}T${job.GioBatDau}`;
          const jobStartTime = new Date(jobStartStr);
          // Khoảng thời gian từ hiện tại đến lúc ca bắt đầu (tính bằng phút)
          const diffMins = (jobStartTime - now) / 1000 / 60;
          
          // Phạt 10% nếu hủy sát giờ (<= 15 phút) hoặc đã qua giờ bắt đầu
          if (diffMins <= 15) {
            const penalty = parseFloat(job.TongTien) * 0.10;
            totalPenalty += penalty;
            penalties.push({
              providerId: job.MaNhanVien,
              jobId: job.MaCaLam,
              amount: penalty
            });
          }
        }
      }

      // Nếu đã thanh toán (TrangThai = 2), thực hiện hoàn tiền và chia tiền bồi thường
      if (booking.TrangThai === 2) {
        const price = parseFloat(booking.GiaGoi);
        // Khách hàng nhận phần còn lại sau khi trừ tiền bồi thường cho nhân viên
        const refundAmount = price - totalPenalty; 
        
        const customerWallet = await ViTien.findOne({ where: { MaNguoiDung: customerId } });
        const systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });

        if (customerWallet && systemWallet) {
          // Trừ toàn bộ tiền từ ví tạm giữ hệ thống (Escrow)
          const newSysBalance = parseFloat(systemWallet.SoDu) - price;
          await systemWallet.update({ SoDu: newSysBalance }, { transaction: tx });

          // Cộng tiền hoàn lại vào ví khách hàng (đã trừ phí phạt)
          const newCustBalance = parseFloat(customerWallet.SoDu) + refundAmount;
          await customerWallet.update({ SoDu: newCustBalance }, { transaction: tx });

          // Ghi lịch sử giao dịch hoàn tiền cho khách (Loại 3: Hoàn tiền)
          await LichSuViTien.create({
            MaViNguon: systemWallet.MaViTien,
            MaViDich: customerWallet.MaViTien,
            MaDatLich: bookingId,
            LoaiGiaoDich: 3, 
            SoTien: refundAmount,
            SoDuSau: newCustBalance,
            NgayTao: new Date()
          }, { transaction: tx });

          // Phân bổ tiền bồi thường cho các nhân viên bị hủy ca sát giờ
          for (let p of penalties) {
            const providerWallet = await ViTien.findOne({ where: { MaNguoiDung: p.providerId } });
            if (providerWallet) {
              const newProvBalance = parseFloat(providerWallet.SoDu) + p.amount;
              await providerWallet.update({ SoDu: newProvBalance }, { transaction: tx });

              // Loại 5: Nhận bồi thường/thưởng
              await LichSuViTien.create({
                MaViNguon: systemWallet.MaViTien,
                MaViDich: providerWallet.MaViTien,
                MaDatLich: bookingId,
                LoaiGiaoDich: 5, 
                SoTien: p.amount,
                SoDuSau: newProvBalance,
                NgayTao: new Date()
              }, { transaction: tx });

              // Thông báo cho nhân viên được bồi thường
              oCamManager.guiThongBaoNguoiDung(p.providerId, {
                tieuDe: 'Bồi thường hủy ca sát giờ',
                noiDung: `Khách hàng đã hủy ca làm #${p.jobId} sát giờ. Bạn được bồi thường ${p.amount.toLocaleString('vi-VN')} đ vào ví.`
              });
            }
          }
        }
      }

      // Cập nhật trạng thái đơn đặt lịch → Đã hủy (0)
      await booking.update({ TrangThai: 0 }, { transaction: tx });

      // Cập nhật tất cả ca làm việc chưa hoàn thành → Đã hủy (3)
      await CaLamViec.update(
        { TrangThaiDonHang: 3, LyDoHuy: lyDoHuy.trim() },
        { where: { MaDatLich: bookingId, TrangThaiDonHang: { [Op.in]: [0, 1] } }, transaction: tx }
      );

      await tx.commit();

      // Gửi thông báo hoàn tiền cho khách hàng
      const price = parseFloat(booking.GiaGoi);
      oCamManager.guiThongBaoNguoiDung(customerId, {
        tieuDe: 'Đơn đặt lịch đã bị hủy',
        noiDung: `Đơn #${bookingId} đã được hủy. Số tiền ${price.toLocaleString('vi-VN')} đ đã được hoàn về ví của bạn.`,
      });

      return success(res, null, 'Hủy đơn đặt lịch thành công. Tiền đã được hoàn về ví của bạn.');
    } catch (err) {
      if (tx) await tx.rollback();
      next(err);
    }
  }

  // ============================================================
  // POST /bookings/shifts/:id/reschedule - Yêu cầu đổi lịch ca làm việc
  // Giải thích logic Đổi Lịch (Reschedule Logic):
  // 1. Kiểm tra quyền hạn: Chỉ Khách Hàng sở hữu ca làm hoặc Nhân Viên đang được phân công mới có quyền gửi yêu cầu đổi lịch.
  // 2. Kiểm tra trạng thái hợp lệ (State transitions): Ca làm việc phải ở trạng thái 0 (Chờ xác nhận) hoặc 1 (Đã nhận việc/Đang thực hiện). Không thể đổi ca đã hoàn thành hoặc đã hủy.
  // 3. Kiểm tra thông tin giờ kết thúc: Nếu không truyền lên, hệ thống tự động tính toán dựa trên tổng giờ quy định của các dịch vụ trong đơn (Recurring jobs logic).
  // 4. Kiểm tra thời gian hợp lệ: Thời gian bắt đầu mới phải cách hiện tại ít nhất 30 phút để đảm bảo tính khả thi.
  // 5. Kiểm tra xung đột lịch (Conflict checking): Nếu ca có nhân viên, hệ thống kiểm tra xem nhân viên đó có lịch làm việc nào khác trùng với khoảng thời gian mới (GioBatDauMoi -> GioKetThucMoi) trong cùng NgayLamViec không. Nếu trùng, từ chối đổi lịch.
  // 6. Tạo yêu cầu: Lưu vào bảng LichSuDoiLich với KetQua = 0 (Chờ xử lý) và gửi thông báo cho phía còn lại. Phía còn lại (Khách Hàng hoặc Nhân Viên) phải đồng ý thì lịch mới chính thức thay đổi.
  // ============================================================
  async rescheduleShift(req, res, next) {
    try {
      const { error: valError } = rescheduleShiftSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const userId = req.user.MaNguoiDung;
      const userRole = req.user.VaiTro;
      const caLamId = req.params.id;
      const { NgayLamViec, GioBatDau, LyDo } = req.body;
      let { GioKetThuc } = req.body;

      const job = await CaLamViec.findByPk(caLamId, {
        include: [{ model: DonDatLich, as: 'DonDatLich' }]
      });
      if (!job) {
        return error(res, 'Ca làm việc không tồn tại', 404);
      }

      const isCustomerOwner = userRole === 1 && job.MaKhachHang === userId;
      const isAssignedProvider = userRole === 2 && job.MaNhanVien === userId;
      if (!isCustomerOwner && !isAssignedProvider) {
        return error(res, 'Bạn không có quyền đổi ca làm việc này', 403);
      }

      if (![0, 1].includes(job.TrangThaiDonHang)) {
        return error(res, 'Chỉ có thể đổi ca đang chờ xác nhận hoặc đang thực hiện', 400);
      }

      const targetUserId = isCustomerOwner ? job.MaNhanVien : job.MaKhachHang;
      if (!targetUserId) {
        return error(res, 'Ca làm việc chưa có nhân viên nên chưa thể gửi yêu cầu đổi lịch', 400);
      }

      // Kiểm tra nếu thời gian mới không thay đổi so với thời gian cũ
      const oldStartStr = `${job.GioBatDau}`;
      const newStartStr = `${GioBatDau.length === 5 ? GioBatDau + ':00' : GioBatDau}`;
      if (NgayLamViec === job.NgayLamViec && newStartStr === oldStartStr) {
        return error(res, 'Vui lòng chọn ngày hoặc giờ khác với lịch hiện tại', 400);
      }

      // Nếu không truyền GioKetThuc, tự tính từ thời lượng của ca làm cũ
      if (!GioKetThuc) {
        let durationHours = getDurationInHours(job.GioBatDau, job.GioKetThuc);
        if (durationHours <= 0) durationHours = 1;

        // Tính GioKetThuc = GioBatDau + durationHours
        const [h, m] = GioBatDau.split(':').map(Number);
        const totalMinutes = h * 60 + (m || 0) + Math.round(durationHours * 60);
        const endH = Math.floor(totalMinutes / 60).toString().padStart(2, '0');
        const endM = (totalMinutes % 60).toString().padStart(2, '0');
        GioKetThuc = `${endH}:${endM}:00`;
      }

      const duration = getDurationInHours(GioBatDau, GioKetThuc);
      if (duration <= 0) {
        return error(res, 'Giờ kết thúc phải sau giờ bắt đầu', 400);
      }

      const startHour = parseInt(GioBatDau.split(':')[0]);
      const endHour = parseInt(GioKetThuc.split(':')[0]);
      const endMinute = parseInt(GioKetThuc.split(':')[1] || 0);

      if (startHour < 6 || endHour > 22 || (endHour === 22 && endMinute > 0)) {
        return error(res, 'Thời gian hoạt động của ứng dụng là từ 06:00 đến 22:00. Vui lòng chọn khung giờ khác.', 400);
      }

      const newStart = new Date(`${NgayLamViec}T${GioBatDau.length === 5 ? `${GioBatDau}:00` : GioBatDau}`);
      const newEnd = new Date(`${NgayLamViec}T${GioKetThuc.length === 5 ? `${GioKetThuc}:00` : GioKetThuc}`);
      if (Number.isNaN(newStart.getTime()) || Number.isNaN(newEnd.getTime())) {
        return error(res, 'Ngày hoặc giờ làm việc không hợp lệ', 400);
      }

      const minStartTime = new Date(Date.now() + 30 * 60 * 1000);
      if (newStart < minStartTime) {
        return error(res, 'Thời gian bắt đầu mới phải cách hiện tại ít nhất 30 phút', 400);
      }

      if (job.MaNhanVien) {
        const conflicting = await CaLamViec.findOne({
          where: {
            MaCaLam: { [Op.ne]: job.MaCaLam },
            MaNhanVien: job.MaNhanVien,
            NgayLamViec,
            TrangThaiDonHang: { [Op.in]: [0, 1] },
            [Op.or]: [
              { GioBatDau: { [Op.lt]: GioKetThuc }, GioKetThuc: { [Op.gt]: GioBatDau } }
            ]
          }
        });

        if (conflicting) {
          return error(res, `Nhân viên đã có lịch vào ngày ${NgayLamViec} (${conflicting.GioBatDau} - ${conflicting.GioKetThuc}). Vui lòng chọn thời gian khác.`, 400);
        }
      }

      const existingPendingRequest = await LichSuDoiLich.findOne({
        where: {
          MaCaLam: job.MaCaLam,
          KetQua: 0
        }
      });
      if (existingPendingRequest) {
        return error(res, 'Ca làm việc này đang có yêu cầu đổi lịch chờ phản hồi', 400);
      }

      const request = await LichSuDoiLich.create({
        MaCaLam: job.MaCaLam,
        MaNguoiXuLy: targetUserId,
        MaNguoiYeuCau: userId,
        MaNhanVienMoi: job.MaNhanVien,
        MaNhanVienCu: job.MaNhanVien,
        NgayMoi: newStart,
        GioBatDauMoi: newStart,
        GioKetThucMoi: newEnd,
        KetQua: 0,
        NgayDoi: new Date()
      });

      const requesterName = req.user.HoTenNguoiDung || 'Người dùng';
      const reasonText = LyDo && LyDo.trim() ? ` Lý do: ${LyDo.trim()}` : '';
      oCamManager.guiThongBaoNguoiDung(targetUserId, {
        tieuDe: 'Có yêu cầu đổi ca làm việc',
        noiDung: `${requesterName} yêu cầu đổi ca #${job.MaCaLam} từ ${job.NgayLamViec} ${job.GioBatDau}-${job.GioKetThuc} sang ${NgayLamViec} ${GioBatDau}-${GioKetThuc}.${reasonText}`,
        data: request
      });

      return success(res, request, 'Đã gửi yêu cầu đổi ca. Vui lòng chờ người còn lại đồng ý hoặc từ chối.', 201);
    } catch (err) {
      next(err);
    }
  }

  // ============================================================
  // POST /bookings/shifts/reschedule/:id/respond - Phản hồi yêu cầu đổi lịch
  // Giải thích logic Phản Hồi Đổi Lịch (Respond Reschedule Logic):
  // 1. Kiểm tra trạng thái: Đảm bảo yêu cầu đang ở trạng thái chờ (KetQua = 0) và ca làm việc chưa bị hủy hay hoàn thành.
  // 2. Chuyển đổi trạng thái (State transitions) khi TỪ CHỐI (DongY = false):
  //    - Nếu Nhân Viên từ chối: Yêu cầu bị hủy (KetQua = 2). Ca làm việc bị gỡ khỏi nhân viên này (MaNhanVien = null), chuyển trạng thái về 1 (Chờ nhận việc trên bảng tin chung) với ngày giờ mới do khách hàng yêu cầu.
  //    - Nếu Khách Hàng từ chối: Yêu cầu bị hủy (KetQua = 2). Ca làm việc giữ nguyên ngày giờ và nhân viên cũ.
  // 3. Chuyển đổi trạng thái khi ĐỒNG Ý (DongY = true):
  //    - Kiểm tra lại xung đột lịch (Conflict checking) một lần nữa trước khi cập nhật.
  //    - Cập nhật NgayLamViec, GioBatDau, GioKetThuc mới vào bảng CaLamViec.
  //    - Cập nhật yêu cầu thành công (KetQua = 1).
  // 4. Đồng bộ ngày tháng (Recurring logic): Nếu đơn đặt lịch chỉ có duy nhất 1 ca làm việc (đơn lẻ), cập nhật luôn thời gian mới vào bảng DonDatLich để đồng bộ.
  // ============================================================
  async respondRescheduleShift(req, res, next) {
    let tx;
    try {
      const userId = req.user.MaNguoiDung;
      const requestId = req.params.id;
      const { DongY } = req.body;

      if (typeof DongY !== 'boolean') {
        return error(res, 'Vui lòng chọn đồng ý hoặc từ chối yêu cầu đổi lịch', 400);
      }

      const request = await LichSuDoiLich.findByPk(requestId, {
        include: [{ model: CaLamViec, as: 'CaLamViec' }]
      });
      if (!request) {
        return error(res, 'Yêu cầu đổi lịch không tồn tại', 404);
      }

      const isResponder = request.MaNguoiXuLy === userId;
      const isRequesterCanceling = request.MaNguoiYeuCau === userId && DongY === false;

      if (!isResponder && !isRequesterCanceling) {
        return error(res, 'Bạn không có quyền phản hồi hoặc hủy yêu cầu đổi lịch này', 403);
      }

      if (request.KetQua !== 0) {
        return error(res, 'Yêu cầu đổi lịch này đã được phản hồi hoặc hủy trước đó', 400);
      }

      const job = request.CaLamViec;
      if (!job) {
        return error(res, 'Ca làm việc không tồn tại', 404);
      }

      if (![0, 1].includes(job.TrangThaiDonHang)) {
        return error(res, 'Chỉ có thể xử lý yêu cầu đổi lịch cho ca chưa hoàn thành hoặc chưa hủy', 400);
      }
      const ngayMoi = (request.NgayMoi instanceof Date) 
        ? request.NgayMoi.toISOString().split('T')[0] 
        : request.NgayMoi.split('T')[0].split(' ')[0];
      const gioBatDauMoi = request.GioBatDauMoi;
      const gioKetThucMoi = request.GioKetThucMoi;

      if (DongY && job.MaNhanVien) {
        const conflicting = await CaLamViec.findOne({
          where: {
            MaCaLam: { [Op.ne]: job.MaCaLam },
            MaNhanVien: job.MaNhanVien,
            NgayLamViec: ngayMoi,
            TrangThaiDonHang: { [Op.in]: [0, 1] },
            [Op.or]: [
              { GioBatDau: { [Op.lt]: gioKetThucMoi }, GioKetThuc: { [Op.gt]: gioBatDauMoi } }
            ]
          }
        });

        if (conflicting) {
          return error(res, `Nhân viên đã có lịch vào ngày ${ngayMoi} (${conflicting.GioBatDau} - ${conflicting.GioKetThuc}). Không thể đồng ý yêu cầu này.`, 400);
        }
      }

      tx = await sequelize.transaction();

      if (!DongY) {
        await request.update({ KetQua: 2, NgayDoi: new Date() }, { transaction: tx });
        
        if (isRequesterCanceling) {
          // Người yêu cầu tự hủy yêu cầu của mình -> giữ nguyên lịch cũ
          await tx.commit();
          tx = null;

          oCamManager.guiThongBaoNguoiDung(request.MaNguoiXuLy, {
            tieuDe: 'Yêu cầu đổi ca đã bị hủy',
            noiDung: `Người dùng đã hủy yêu cầu đổi ca #${job.MaCaLam}. Lịch làm việc vẫn giữ nguyên như cũ.`,
            data: request
          });

          return success(res, request, 'Đã hủy yêu cầu đổi lịch thành công.');
        } else if (req.user.VaiTro === 2) {
          // Nhân viên từ chối -> chuyển ca làm về bảng việc trống và cập nhật ngày giờ mới
          await job.update({
            MaNhanVien: null,
            TrangThaiDonHang: 1, // 1: Chờ nhận việc
            NgayLamViec: ngayMoi,
            GioBatDau: gioBatDauMoi,
            GioKetThuc: gioKetThucMoi,
            NgayCapNhat: new Date()
          }, { transaction: tx });

          await tx.commit();
          tx = null;

          oCamManager.guiThongBaoNguoiDung(request.MaNguoiYeuCau, {
            tieuDe: 'Nhân viên đã từ chối đổi ca',
            noiDung: `Nhân viên đã từ chối yêu cầu đổi ca #${job.MaCaLam}. Ca làm việc đã được đưa lại lên bảng việc trống với ngày giờ mới để nhân viên khác nhận.`,
            data: request
          });

          return success(res, request, 'Đã từ chối yêu cầu đổi ca. Ca làm việc đã chuyển về chờ nhận.');
        } else {
          // Khách hàng từ chối -> giữ nguyên lịch cũ và nhân viên cũ
          await tx.commit();
          tx = null;

          oCamManager.guiThongBaoNguoiDung(request.MaNguoiYeuCau, {
            tieuDe: 'Yêu cầu đổi ca bị từ chối',
            noiDung: `Khách hàng đã từ chối yêu cầu đổi ca #${job.MaCaLam}. Vui lòng thực hiện ca làm đúng lịch cũ hoặc hủy ca nếu không thể làm.`,
            data: request
          });

          return success(res, request, 'Đã từ chối yêu cầu đổi ca. Lịch làm việc được giữ nguyên.');
        }
      }

      await job.update({
        NgayLamViec: ngayMoi,
        GioBatDau: gioBatDauMoi,
        GioKetThuc: gioKetThucMoi,
        NgayCapNhat: new Date()
      }, { transaction: tx });

      await request.update({ KetQua: 1, NgayDoi: new Date() }, { transaction: tx });

      const siblingJobs = await CaLamViec.findAll({
        where: { MaDatLich: job.MaDatLich },
        transaction: tx
      });
      const booking = await DonDatLich.findByPk(job.MaDatLich, { transaction: tx });
      if (booking && siblingJobs.length === 1) {
        await booking.update({
          NgayBatDau: ngayMoi,
          NgayKetThuc: ngayMoi,
          GioBatDau: gioBatDauMoi,
          GioKetThuc: gioKetThucMoi
        }, { transaction: tx });
      }

      await tx.commit();
      tx = null;

      const updatedJob = await CaLamViec.findByPk(job.MaCaLam, {
        include: [{ model: NguoiDung, as: 'NhanVien', attributes: ['MaNguoiDung', 'HoTenNguoiDung', 'SoDienThoai', 'AnhDaiDien'] }]
      });

      oCamManager.guiThongBaoNguoiDung(request.MaNguoiYeuCau, {
        tieuDe: 'Yêu cầu đổi ca được đồng ý',
        noiDung: `${req.user.HoTenNguoiDung || 'Người dùng'} đã đồng ý đổi ca #${job.MaCaLam} sang ${ngayMoi} ${gioBatDauMoi}-${gioKetThucMoi}.`,
        data: updatedJob
      });

      return success(res, updatedJob, 'Đã đồng ý yêu cầu đổi ca và cập nhật lịch làm việc');
    } catch (err) {
      if (tx) await tx.rollback();
      next(err);
    }
  }

  // ============================================================
  // PATCH /bookings/shifts/:id/change-provider
  // Khách hàng yêu cầu đổi nhân viên (chỉ khi hệ thống tự gán)
  // Gỡ nhân viên hiện tại → ca quay về bảng tin cho NV khác nhận
  // ============================================================
  async changeProvider(req, res, next) {
    try {
      const userId = req.user.MaNguoiDung;
      const caLamId = req.params.id;

      const job = await CaLamViec.findByPk(caLamId, {
        include: [
          { model: DonDatLich, as: 'DonDatLich' },
          { model: NguoiDung, as: 'NhanVien', attributes: ['MaNguoiDung', 'HoTenNguoiDung'] }
        ]
      });
      if (!job) {
        return error(res, 'Ca làm việc không tồn tại', 404);
      }

      if (job.MaKhachHang !== userId) {
        return error(res, 'Bạn không có quyền đổi nhân viên cho ca này', 403);
      }

      if (![0, 1].includes(job.TrangThaiDonHang)) {
        return error(res, 'Chỉ có thể đổi nhân viên cho ca chưa hoàn thành', 400);
      }

      if (!job.MaNhanVien) {
        return error(res, 'Ca làm việc chưa có nhân viên', 400);
      }


      const oldProviderName = job.NhanVien ? job.NhanVien.HoTenNguoiDung : 'Nhân viên';
      const oldProviderId = job.MaNhanVien;

      // Trích xuất và cập nhật danh sách nhân viên bị chặn
      let blockedList = [];
      if (job.LyDoHuy && job.LyDoHuy.startsWith('BLOCKED:')) {
        blockedList = job.LyDoHuy.replace('BLOCKED:', '').split(',');
      }
      if (!blockedList.includes(oldProviderId.toString())) {
        blockedList.push(oldProviderId.toString());
      }
      const newLyDoHuy = `BLOCKED:${blockedList.join(',')}`;

      // Gỡ nhân viên, chuyển ca về trạng thái chờ nhận (1) và lưu block list
      await job.update({
        MaNhanVien: null,
        TrangThaiDonHang: 1,
        NgayCapNhat: new Date(),
        LyDoHuy: newLyDoHuy
      });

      // Gửi thông báo cho nhân viên cũ
      oCamManager.guiThongBaoNguoiDung(oldProviderId, {
        tieuDe: 'Bạn đã bị gỡ khỏi ca làm việc',
        noiDung: `Khách hàng ${req.user.HoTenNguoiDung || 'Khách hàng'} đã yêu cầu đổi nhân viên cho ca #${job.MaCaLam}. Ca này đã được chuyển về bảng tin.`,
        data: job
      });

      // Gửi thông báo cho tất cả nhân viên về ca mới
      oCamManager.guiThongBaoAdminVaNhanVien({
        tieuDe: 'Có ca làm việc cần nhận!',
        noiDung: `Ca #${job.MaCaLam} ngày ${job.NgayLamViec} (${job.GioBatDau}-${job.GioKetThuc}) đang cần nhân viên nhận.`,
        data: job
      });

      return success(res, job, `Đã gỡ nhân viên ${oldProviderName} khỏi ca. Ca đang chờ nhân viên mới nhận.`);
    } catch (err) {
      next(err);
    }
  }

  // ============================================================
  // POST /payments - Thanh toán đơn hàng giúp việc qua số dư ví
  // Trừ tiền ví khách hàng → Chuyển sang ví tạm giữ Escrow
  // Cập nhật trạng thái đơn: 1 → 2 (Đã thanh toán)
  // Cập nhật ca làm: 0 → 1 (Chờ nhận việc)
  // ============================================================
  async payBooking(req, res, next) {
    let tx;
    try {
      const customerId = req.user.MaNguoiDung;
      const { MaDatLich } = req.body;

      const booking = await DonDatLich.findByPk(MaDatLich);
      if (!booking || booking.MaKhachHang !== customerId) {
        return error(res, 'Đơn đặt lịch không tồn tại', 404);
      }

      // Kiểm tra đơn phải ở trạng thái Pending (1) - chưa thanh toán
      if (booking.TrangThai !== 1) {
        if (booking.TrangThai === 2) {
          return error(res, 'Đơn hàng đã được thanh toán trước đó', 400);
        }
        return error(res, 'Đơn hàng không ở trạng thái chờ thanh toán', 400);
      }

      const price = parseFloat(booking.GiaGoi);

      const wallet = await ViTien.findOne({ where: { MaNguoiDung: customerId } });
      if (!wallet) {
        return error(res, 'Không tìm thấy ví tiền của khách hàng', 404);
      }

      if (parseFloat(wallet.SoDu) < price) {
        return error(res, 'Số dư ví không đủ để thanh toán đơn đặt lịch này. Vui lòng nạp thêm tiền.', 400);
      }

      tx = await sequelize.transaction();

      // Trừ số dư ví tiền của Khách hàng
      const newBalance = parseFloat(wallet.SoDu) - price;
      await wallet.update({ SoDu: newBalance }, { transaction: tx });

      // Tìm ví Tạm giữ của hệ thống (LoaiVi = 3)
      const systemWallet = await ViTien.findOne({ where: { LoaiVi: 3 } });
      if (systemWallet) {
        const newSysBalance = parseFloat(systemWallet.SoDu) + price;
        await systemWallet.update({ SoDu: newSysBalance }, { transaction: tx });
      }

      // Lưu nhật ký giao dịch ví tiền
      const log = await LichSuViTien.create({
        MaViNguon: wallet.MaViTien,
        MaViDich: systemWallet ? systemWallet.MaViTien : null,
        MaDatLich,
        LoaiGiaoDich: 2, // 2: Thanh toán
        SoTien: price,
        SoDuSau: newBalance,
        NgayTao: new Date()
      }, { transaction: tx });

      // Cập nhật trạng thái đơn đặt lịch → Đã thanh toán (2)
      await booking.update({ TrangThai: 2 }, { transaction: tx });

      // Cập nhật ca làm việc: Chờ xác nhận (0) → Chờ nhận việc (1)
      await CaLamViec.update(
        { TrangThaiDonHang: 1 }, // 1: Chờ nhận việc (đã thanh toán)
        { where: { MaDatLich, TrangThaiDonHang: 0 }, transaction: tx }
      );

      await tx.commit();

      // Gửi thông báo thời gian thực sau khi thanh toán thành công
      oCamManager.guiThongBaoAdminVaNhanVien({
        tieuDe: 'Có đơn đặt lịch mới cần nhận!',
        noiDung: `Khách hàng ${req.user.HoTenNguoiDung} vừa thanh toán đơn đặt lịch #${booking.MaDatLich}`,
        data: booking
      });

      return success(res, { newBalance, transactionId: log.MaGiaoDich }, 'Thanh toán đơn hàng thành công');
    } catch (err) {
      if (tx) await tx.rollback();
      next(err);
    }
  }

  async topupWallet(req, res, next) {
    try {
      const customerId = req.user.MaNguoiDung;
      const { SoTien } = req.body;

      if (SoTien < 100000) {
        return error(res, 'Số tiền nạp tối thiểu mỗi lần là 100.000 VNĐ', 400);
      }
      if (SoTien > 10000000) {
        return error(res, 'Số tiền nạp tối đa mỗi lần là 10.000.000 VNĐ', 400);
      }

      const wallet = await ViTien.findOne({ where: { MaNguoiDung: customerId } });
      if (!wallet) {
        return error(res, 'Không tìm thấy ví tiền của người dùng', 404);
      }

      const newBalance = parseFloat(wallet.SoDu) + parseFloat(SoTien);
      await wallet.update({ SoDu: newBalance });

      const transaction = await LichSuViTien.create({
        MaViNguon: null,
        MaViDich: wallet.MaViTien,
        LoaiGiaoDich: 1, // 1: Nạp tiền
        SoTien,
        SoDuSau: newBalance,
        NgayTao: new Date()
      });

      return success(res, { SoDuMoi: newBalance, transaction }, 'Nạp tiền vào ví thành công');
    } catch (err) {
      next(err);
    }
  }

  async getWallet(req, res, next) {
    try {
      const customerId = req.user.MaNguoiDung;
      
      // Nếu là nhân viên, tự động đối soát và giải ngân các ca làm đủ điều kiện trước khi lấy ví
      if (req.user.VaiTro === 2) {
        await checkAndExecutePayoutsForProvider(customerId);
      }

      const wallet = await ViTien.findOne({ where: { MaNguoiDung: customerId } });
      if (!wallet) {
        return error(res, 'Không tìm thấy ví của người dùng', 404);
      }
      return success(res, wallet, 'Lấy số dư ví thành công');
    } catch (err) {
      next(err);
    }
  }

  async getWalletHistory(req, res, next) {
    try {
      const customerId = req.user.MaNguoiDung;

      // Tương tự, nếu là nhân viên, đối soát trước khi lấy lịch sử giao dịch
      if (req.user.VaiTro === 2) {
        await checkAndExecutePayoutsForProvider(customerId);
      }

      const wallet = await ViTien.findOne({ where: { MaNguoiDung: customerId } });
      if (!wallet) {
        return error(res, 'Không tìm thấy ví của người dùng', 404);
      }

      const history = await LichSuViTien.findAll({
        where: {
          [Op.or]: [
            { MaViNguon: wallet.MaViTien },
            { MaViDich: wallet.MaViTien }
          ]
        },
        order: [['MaGiaoDich', 'DESC']]
      });

      return success(res, history, 'Lấy lịch sử giao dịch ví thành công');
    } catch (err) {
      next(err);
    }
  }

  async createReview(req, res, next) {
    try {
      const { error: valError } = createReviewSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const customerId = req.user.MaNguoiDung;
      const { MaCaLam, SoSao, NoiDungDanhGia } = req.body;

      const caLam = await CaLamViec.findByPk(MaCaLam);
      if (!caLam || caLam.MaKhachHang !== customerId) {
        return error(res, 'Ca làm việc không tồn tại hoặc không thuộc quyền sở hữu của bạn', 404);
      }

      // Chỉ cho phép đánh giá ca làm đã hoàn thành (TrangThaiDonHang = 2)
      if (caLam.TrangThaiDonHang !== 2) {
        return error(res, 'Chỉ có thể đánh giá ca làm việc đã hoàn thành', 400);
      }

      const existingReview = await DanhGia.findOne({ where: { MaCaLam } });
      if (existingReview) {
        return error(res, 'Mỗi ca làm việc chỉ được đánh giá một lần duy nhất', 400);
      }

      if (!caLam.MaNhanVien) {
        return error(res, 'Ca làm việc không có nhân viên để đánh giá', 400);
      }

      const review = await DanhGia.create({
        MaCaLam,
        MaKhachHang: customerId,
        MaNhanVien: caLam.MaNhanVien,
        SoSao,
        NoiDungDanhGia,
        NgayDanhGia: new Date()
      });

      // Cập nhật điểm đánh giá trung bình trong hồ sơ nhân viên
      const hoso = await HoSoNhanVien.findOne({ where: { MaNhanVien: caLam.MaNhanVien } });
      if (hoso) {
        const allReviews = await DanhGia.findAll({ where: { MaNhanVien: caLam.MaNhanVien } });
        const totalStars = allReviews.reduce((sum, r) => sum + r.SoSao, 0);
        const avgStars = totalStars / allReviews.length;

        await hoso.update({
          TongDanhGia: allReviews.length,
          SoSaoTrungBinh: avgStars
        });
      }

      return success(res, review, 'Đánh giá ca làm việc thành công', 201);
    } catch (err) {
      next(err);
    }
  }

  async createComplaint(req, res, next) {
    try {
      const { error: valError } = createComplaintSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const customerId = req.user.MaNguoiDung;
      const { MaCaLam, TieuDe, NoiDung } = req.body;

      const caLam = await CaLamViec.findByPk(MaCaLam);
      if (!caLam || caLam.MaKhachHang !== customerId) {
        return error(res, 'Ca làm việc không tồn tại', 404);
      }

      if (!caLam.MaNhanVien) {
        return error(res, 'Ca làm việc chưa được phân công nhân viên nên không thể khiếu nại', 400);
      }

      const complaint = await KhieuNai.create({
        MaNguoiGui: customerId,
        MaNguoiBiKhieuNai: caLam.MaNhanVien,
        MaCaLam,
        MaNguoiXuLy: null,
        MaHinhThucXuLy: null,
        TieuDe,
        NoiDung,
        NgayTao: new Date(),
        TrangThaiXuLy: 0 // 0: Chờ xử lý
      });

      // Gửi thông báo thời gian thực to admin
      oCamManager.guiThongBaoAdmin({
        tieuDe: 'Khiếu nại mới!',
        noiDung: `Khách hàng ${req.user.HoTenNguoiDung} vừa gửi khiếu nại #${complaint.MaKhieuNai} cho ca làm việc #${MaCaLam}`,
        data: complaint
      });

      return success(res, complaint, 'Gửi khiếu nại thành công. Admin đang xem xét.', 201);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new CustomerController();
