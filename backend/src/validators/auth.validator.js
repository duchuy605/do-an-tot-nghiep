const Joi = require('joi');

const registerSchema = Joi.object({
  HoTenNguoiDung: Joi.string().max(50).required().messages({
    'string.empty': 'Họ tên không được để trống',
    'string.max': 'Họ tên tối đa 50 ký tự'
  }),
  VaiTro: Joi.number().valid(1, 2).required().messages({
    'any.only': 'Vai trò chỉ có thể là 1 (Khách hàng) hoặc 2 (Nhân viên)'
  }),
  MatKhau: Joi.string().min(6).max(30).required().messages({
    'string.min': 'Mật khẩu phải từ 6 ký tự',
    'string.max': 'Mật khẩu tối đa 30 ký tự'
  }),
  Email: Joi.string().email().required().messages({
    'string.email': 'Email không hợp lệ'
  }),
  DiaChi: Joi.string().allow(null, ''),
  SoDienThoai: Joi.string().pattern(/^[0-9]{9,11}$/).required().messages({
    'string.pattern.base': 'Số điện thoại phải từ 9 đến 11 số'
  }),
  GioiTinh: Joi.string().valid('Nam', 'Nu', 'Khac').allow(null, ''),
  NgaySinh: Joi.string().isoDate().allow(null, ''),
  AnhDaiDien: Joi.string().allow(null, ''),
  CCCD: Joi.string().pattern(/^[0-9]{9,12}$/).allow(null, '').messages({
    'string.pattern.base': 'Số CCCD phải từ 9 đến 12 số'
  })
});

const loginSchema = Joi.object({
  Email: Joi.string().email().required().messages({
    'string.email': 'Email không hợp lệ',
    'any.required': 'Email là bắt buộc'
  }),
  MatKhau: Joi.string().required().messages({
    'any.required': 'Mật khẩu là bắt buộc'
  })
});

const changePasswordSchema = Joi.object({
  MatKhauCu: Joi.string().required().messages({
    'any.required': 'Mật khẩu cũ là bắt buộc'
  }),
  MatKhauMoi: Joi.string().min(6).required().messages({
    'string.min': 'Mật khẩu mới phải từ 6 ký tự',
    'any.required': 'Mật khẩu mới là bắt buộc'
  })
});

const forgotPasswordSchema = Joi.object({
  Email: Joi.string().email().required().messages({
    'string.email': 'Email không hợp lệ'
  })
});

const resetPasswordSchema = Joi.object({
  Email: Joi.string().email().required().messages({
    'string.email': 'Email không hợp lệ'
  }),
  Code: Joi.string().required().messages({
    'any.required': 'Mã OTP/Xác nhận là bắt buộc'
  }),
  MatKhauMoi: Joi.string().min(6).required().messages({
    'string.min': 'Mật khẩu mới phải từ 6 ký tự'
  })
});

const updateProfileSchema = Joi.object({
  HoTenNguoiDung: Joi.string().max(50),
  DiaChi: Joi.string().allow(null, ''),
  SoDienThoai: Joi.string().pattern(/^[0-9]{9,11}$/),
  GioiTinh: Joi.string().valid('Nam', 'Nu', 'Khac').allow(null, ''),
  NgaySinh: Joi.string().isoDate().allow(null, '')
});

module.exports = {
  registerSchema,
  loginSchema,
  changePasswordSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  updateProfileSchema
};
