const { verifyToken } = require('../utils/ma_hoa');
const { error } = require('../utils/phan_hoi');
const { NguoiDung } = require('../models');

const ROLE_MAP = {
  'CUSTOMER': 1,
  'PROVIDER': 2,
  'ADMIN': 3,
  1: 1,
  2: 2,
  3: 3
};

async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return error(res, 'Không tìm thấy Token xác thực hoặc Token không hợp lệ', 401);
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);
    if (!decoded) {
      return error(res, 'Token đã hết hạn hoặc không hợp lệ', 401);
    }

    // Check user in database to ensure they are active and exist
    const user = await NguoiDung.findByPk(decoded.MaNguoiDung);
    if (!user) {
      return error(res, 'Người dùng không tồn tại', 401);
    }

    if (user.TrangThaiTaiKhoan === 2) {
      return error(res, 'Tài khoản của bạn đã bị khóa', 403);
    }

    req.user = user; // Store Sequelize model instance directly
    next();
  } catch (err) {
    console.error('Loi middleware authenticate:', err);
    return error(res, 'Lỗi xác thực hệ thống', 500);
  }
}

function authorize(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return error(res, 'Yêu cầu xác thực tài khoản trước', 401);
    }

    const mappedAllowedRoles = allowedRoles.map(r => ROLE_MAP[r.toString().toUpperCase()] || r);
    
    if (!mappedAllowedRoles.includes(req.user.VaiTro)) {
      return error(res, 'Bạn không có quyền truy cập chức năng này', 403);
    }

    next();
  };
}

module.exports = {
  authenticate,
  authorize
};
