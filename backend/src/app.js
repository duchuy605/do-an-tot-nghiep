const path = require("path");

const result = require("dotenv").config({
  path: path.join(__dirname, "../.env")
});

console.log(result);
console.log('DB_USER =', process.env.DB_USER);
console.log('DB_HOST =', process.env.DB_HOST);
console.log('DB_NAME =', process.env.DB_NAME);
console.log('EMAIL_USER =', process.env.EMAIL_USER);
const express = require('express');
const cors = require('cors');
const http = require('http');

const sequelize = require('./config/database');
const mainRouter = require('./routes');
const errorHandler = require('./middlewares/error_handler');
const oCamManager = require('./sockets/o_cam_manager');
const app = express();

// Các middleware xử lý trung gian
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Cấu hình thư mục chứa ảnh upload tĩnh
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Các tuyến định tuyến API
app.use('/api', mainRouter);

// Đường dẫn chào mừng đơn giản
app.get('/', (req, res) => {
  res.json({
    message: 'Chào mừng đến với Hệ thống API Đặt lịch Giúp việc theo giờ!',
    socketTest: 'Kết nối Socket.IO tại địa chỉ của máy chủ này.'
  });
});

// Middleware bắt và xử lý lỗi tập trung
app.use(errorHandler);

// Khởi tạo HTTP server
const server = http.createServer(app);

// Khởi tạo kết nối Socket.IO
oCamManager.initialize(server);

// Tự động kích hoạt giải ngân dựa trên sự kiện (không dùng node-cron chạy ngầm)

// Kết nối cơ sở dữ liệu & khởi động server
const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // Kiểm tra kết nối cơ sở dữ liệu
    await sequelize.authenticate();
    console.log('Kết nối cơ sở dữ liệu MySQL thành công qua Sequelize!');

    // Khởi động server
    server.listen(PORT, () => {
      console.log(` Server đang chạy tại địa chỉ: http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('SKhông thể kết nối cơ sở dữ liệu MySQL:', error);
    process.exit(1);
  }
}

// Xuất server phục vụ kiểm thử
if (require.main === module) {
  startServer();
}

module.exports = { app, server };
