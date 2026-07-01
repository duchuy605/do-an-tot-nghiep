const { error } = require('../utils/phan_hoi');

function errorHandler(err, req, res, next) {
  console.error('Loi chua duoc bat (Uncaught Error):', err);
  
  if (err.name === 'SequelizeValidationError') {
    const details = err.errors.map(e => ({ field: e.path, message: e.message }));
    return error(res, 'Dữ liệu đầu vào không hợp lệ', 400, details);
  }

  if (err.name === 'SequelizeUniqueConstraintError') {
    const details = err.errors.map(e => ({ field: e.path, message: e.message }));
    return error(res, 'Dữ liệu đã tồn tại và trùng lặp khóa duy nhất', 400, details);
  }

  // Multer Error
  if (err instanceof require('multer').MulterError) {
    return error(res, `Lỗi tải tập tin: ${err.message}`, 400);
  }

  return error(res, err.message || 'Lỗi máy chủ nội bộ', err.status || 500);
}

module.exports = errorHandler;
