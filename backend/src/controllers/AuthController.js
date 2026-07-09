const bcrypt = require('bcrypt');
const { NguoiDung, HoSoNhanVien, ViTien } = require('../models');
const { generateToken } = require('../utils/ma_hoa');
const { success, error } = require('../utils/phan_hoi');
const {
  registerSchema,
  loginSchema,
  changePasswordSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  updateProfileSchema
} = require('../validators/auth.validator');
const { guiEmailOTP } = require('../utils/email');

// Bộ nhớ tạm lưu OTP đặt lại mật khẩu (email -> { code, expiresAt })
const otpStore = new Map();

class AuthController {
  async register(req, res, next) {
    try {
      const { error: valError } = registerSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const data = req.body;

      // Kiểm tra xem email đã được sử dụng chưa
      const existingEmail = await NguoiDung.findOne({ where: { Email: data.Email } });
      if (existingEmail) {
        return error(res, 'Email đã được sử dụng bởi tài khoản khác', 400);
      }

      // Kiểm tra xem số điện thoại đã được sử dụng chưa
      const existingPhone = await NguoiDung.findOne({ where: { SoDienThoai: data.SoDienThoai } });
      if (existingPhone) {
        return error(res, 'Số điện thoại đã được sử dụng bởi tài khoản khác', 400);
      }

      // Mã hóa (băm) mật khẩu người dùng
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(data.MatKhau, saltRounds);

      // Tạo mới người dùng với trạng thái hoạt động mặc định
      const user = await NguoiDung.create({
        ...data,
        MatKhau: hashedPassword,
        TrangThaiTaiKhoan: 1 // Mặc định là đang hoạt động
      });

      // Khởi tạo ví tiền nội bộ cho người dùng để phục vụ thanh toán
      await ViTien.create({
        MaNguoiDung: user.MaNguoiDung,
        SoDu: 0,
        LoaiVi: user.VaiTro, // 1: Khách hàng, 2: Nhân viên
        TrangThai: true
      });

      // Nếu người dùng đăng ký với vai trò là Nhân viên (VaiTro = 2), tự động khởi tạo Hồ sơ nhân viên.
      // Trạng thái phê duyệt ban đầu sẽ là chờ duyệt (0). Admin cần kiểm tra hồ sơ và phê duyệt trước khi nhân viên có thể bắt đầu nhận việc.
      if (user.VaiTro === 2) {
        await HoSoNhanVien.create({
          MaNhanVien: user.MaNguoiDung,
          CCCD: data.CCCD || `CCCD_${Date.now()}`,
          SoGioLamViec: 0,
          TongDanhGia: 0,
          SoSaoTrungBinh: 5.0,
          TrangThaiDuyet: 0, // Chờ Admin phê duyệt
          TrangThaiHoatDong: false
        });
      }

      const userJson = user.toJSON();
      delete userJson.MatKhau;

      return success(res, userJson, 'Đăng ký tài khoản thành công', 201);
    } catch (err) {
      next(err);
    }
  }

  async login(req, res, next) {
    try {
      const { error: valError } = loginSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const { Email, MatKhau } = req.body;
      const user = await NguoiDung.findOne({ where: { Email } });
      if (!user) {
        return error(res, 'Email hoặc mật khẩu không chính xác', 400);
      }

      if (user.TrangThaiTaiKhoan === 2) {
        return error(res, 'Tài khoản đã bị khóa', 403);
      }

      const isMatch = await bcrypt.compare(MatKhau, user.MatKhau);
      if (!isMatch) {
        return error(res, 'Email hoặc mật khẩu không chính xác', 400);
      }

      // Khởi tạo mã Token JWT (JSON Web Token) để xác thực các yêu cầu sau này của người dùng.
      // Token chứa thông tin cơ bản: MaNguoiDung, VaiTro, Email, giúp định danh người dùng trên các API yêu cầu đăng nhập.
      const token = generateToken({
        MaNguoiDung: user.MaNguoiDung,
        VaiTro: user.VaiTro,
        Email: user.Email
      });

      // Loại bỏ trường mật khẩu trước khi gửi phản hồi
      const userJson = user.toJSON();
      delete userJson.MatKhau;

      return success(res, { token, user: userJson }, 'Đăng nhập thành công');
    } catch (err) {
      next(err);
    }
  }

  async logout(req, res, next) {
    try {
      return success(res, null, 'Đăng xuất thành công');
    } catch (err) {
      next(err);
    }
  }

  async changePassword(req, res, next) {
    try {
      const { error: valError } = changePasswordSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const userId = req.user.MaNguoiDung;
      const { MatKhauCu, MatKhauMoi } = req.body;

      const user = await NguoiDung.findByPk(userId);
      if (!user) {
        return error(res, 'Người dùng không tồn tại', 404);
      }

      const isMatch = await bcrypt.compare(MatKhauCu, user.MatKhau);
      if (!isMatch) {
        return error(res, 'Mật khẩu cũ không chính xác', 400);
      }

      const saltRounds = 10;
      const hashedNewPassword = await bcrypt.hash(MatKhauMoi, saltRounds);

      await user.update({ MatKhau: hashedNewPassword });
      return success(res, null, 'Thay đổi mật khẩu thành công');
    } catch (err) {
      next(err);
    }
  }

  async forgotPassword(req, res, next) {
    try {
      const { error: valError } = forgotPasswordSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const user = await NguoiDung.findOne({ where: { Email: req.body.Email } });
      if (!user) {
        return error(res, 'Không tìm thấy tài khoản với email này', 404);
      }

      // Tạo mã OTP 6 chữ số và lưu vào bộ nhớ tạm với thời hạn 5 phút
      const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = Date.now() + 5 * 60 * 1000; // 5 phút

      otpStore.set(req.body.Email, { code: resetCode, expiresAt });

      // Gửi mã OTP qua email cho người dùng để xác nhận việc đặt lại mật khẩu
      const emailSent = await guiEmailOTP(req.body.Email, resetCode);
      if (!emailSent) {
        console.log(`[SAO LƯU OTP] Mã OTP cho ${req.body.Email}: ${resetCode}`);
      }

      return success(
        res,
        { message: 'Mã đặt lại mật khẩu đã được gửi đến email của bạn' },
        'Yêu cầu đặt lại mật khẩu đã được xử lý'
      );
    } catch (err) {
      next(err);
    }
  }

  async resetPassword(req, res, next) {
    try {
      const { error: valError } = resetPasswordSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const { Email, Code, MatKhauMoi } = req.body;
      const user = await NguoiDung.findOne({ where: { Email } });
      if (!user) {
        return error(res, 'Tài khoản không tồn tại', 404);
      }

      // Xác thực mã OTP từ bộ nhớ tạm
      const storedOtp = otpStore.get(Email);
      if (!storedOtp) {
        return error(res, 'Chưa yêu cầu đặt lại mật khẩu hoặc mã OTP đã hết hạn. Vui lòng yêu cầu lại.', 400);
      }

      if (Date.now() > storedOtp.expiresAt) {
        otpStore.delete(Email);
        return error(res, 'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.', 400);
      }

      if (storedOtp.code !== Code) {
        return error(res, 'Mã OTP không chính xác', 400);
      }

      // OTP hợp lệ → Xóa khỏi bộ nhớ sau khi sử dụng
      otpStore.delete(Email);

      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(MatKhauMoi, saltRounds);

      await user.update({ MatKhau: hashedPassword });
      return success(res, null, 'Đặt lại mật khẩu thành công');
    } catch (err) {
      next(err);
    }
  }

  async getProfile(req, res, next) {
    try {
      const userId = req.user.MaNguoiDung;
      const user = await NguoiDung.findByPk(userId, {
        include: [{ model: HoSoNhanVien, as: 'HoSoNhanVien' }]
      });

      if (!user) {
        return error(res, 'Người dùng không tồn tại', 404);
      }

      const userJson = user.toJSON();
      delete userJson.MatKhau;
      return success(res, userJson, 'Lấy thông tin hồ sơ thành công');
    } catch (err) {
      next(err);
    }
  }

  async updateProfile(req, res, next) {
    try {
      const { error: valError } = updateProfileSchema.validate(req.body);
      if (valError) {
        return error(res, valError.details[0].message, 400);
      }

      const userId = req.user.MaNguoiDung;
      const updateData = { ...req.body };

      // Xử lý tệp tin tải lên nếu có
      if (req.file) {
        updateData.AnhDaiDien = `/uploads/${req.file.filename}`;
      }

      const user = await NguoiDung.findByPk(userId);
      if (!user) {
        return error(res, 'Người dùng không tồn tại', 404);
      }

      // Kiểm tra tính duy nhất của Email/Số điện thoại nếu có thay đổi
      if (updateData.Email && updateData.Email !== user.Email) {
        const emailDup = await NguoiDung.findOne({ where: { Email: updateData.Email } });
        if (emailDup) return error(res, 'Email đã được sử dụng', 400);
      }
      if (updateData.SoDienThoai && updateData.SoDienThoai !== user.SoDienThoai) {
        const phoneDup = await NguoiDung.findOne({ where: { SoDienThoai: updateData.SoDienThoai } });
        if (phoneDup) return error(res, 'Số điện thoại đã được sử dụng', 400);
      }

      await user.update(updateData);
      const updatedUser = await NguoiDung.findByPk(userId, {
        include: [{ model: HoSoNhanVien, as: 'HoSoNhanVien' }]
      });

      const updatedUserJson = updatedUser.toJSON();
      delete updatedUserJson.MatKhau;
      return success(res, updatedUserJson, 'Cập nhật thông tin hồ sơ thành công');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AuthController();
