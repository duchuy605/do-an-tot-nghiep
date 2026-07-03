function success(res, data = null, message = 'Thành công', code = 200) {
  return res.status(code).json({
    success: true,
    message,
    data
  });
}

function error(res, message = 'Đã xảy ra lỗi', code = 500, details = null) {
  return res.status(code).json({
    success: false,
    message,
    details
  });
}

module.exports = {
  success,
  error
};
