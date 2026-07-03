# 🏠 Hệ thống Backend Đặt Lịch Giúp Việc Theo Giờ (NodeJS + ExpressJS)

Dự án này là hệ thống Backend hoàn chỉnh cho ứng dụng đặt lịch giúp việc theo giờ, được thiết kế theo nguyên lý **Clean Architecture** sử dụng tên thư mục bằng **tiếng Anh** chuẩn. 

---

## 🛠️ Công nghệ sử dụng

*   **NodeJS + ExpressJS**: Môi trường chạy và Framework web chính.
*   **MySQL**: Cơ sở dữ liệu quan hệ lưu trữ thông tin nghiệp vụ.
*   **Sequelize ORM**: Tương tác cơ sở dữ liệu qua các Sequelize Models.
*   **JWT (JSON Web Token)**: Xác thực tài khoản người dùng bảo mật.
*   **bcrypt**: Mã hóa mật khẩu tài khoản.
*   **Socket.IO**: Gửi thông báo đẩy realtime (có đơn mới, nhận việc, hoàn thành,...).
*   **Multer**: Xử lý tải tập tin và ảnh đại diện lên server.
*   **Swagger API Docs**: Cung cấp giao diện tài liệu API trực quan tại `/api-docs`.
*   **RBAC (Role Based Access Control)**: Phân quyền tài khoản theo vai trò.

---

## 📁 Cấu trúc thư mục (Clean Architecture)

```text
src/
├── config/           # Cấu hình database, JWT, Swagger
├── models/           # Khai báo Sequelize Models và thiết lập Associations
├── migrations/       # Quản lý Migrations đồng bộ cấu trúc cơ sở dữ liệu
├── seeders/          # Seeders thêm dữ liệu mẫu ban đầu vào database
├── repositories/     # Repositories thực hiện truy vấn thô cơ sở dữ liệu
├── services/         # Lớp xử lý Logic nghiệp vụ cốt lõi - Business Logic
├── controllers/      # Tiếp nhận Request, điều phối Logic và trả về Response
├── middlewares/      # Các Middleware xác thực, phân quyền, tải file, bắt lỗi
├── routes/           # Khai báo các endpoints định tuyến API
├── validators/       # Khai báo schemas kiểm tra dữ liệu đầu vào sử dụng Joi
├── utils/            # Thư viện tiện ích - helper tính giá tiền, mã hóa JWT
├── sockets/          # Cấu hình Socket.io và xử lý thông báo đẩy realtime
└── app.js            # Điểm khởi động ứng dụng và kết nối máy chủ
```

---

## 🛡️ Hệ thống Phân quyền (RBAC)

Hệ thống hỗ trợ 3 vai trò chính được định nghĩa qua số ID tương ứng:
1.  **CUSTOMER (Khách hàng - ID: 1)**: Đặt lịch giúp việc, nạp tiền vào ví, thanh toán, đánh giá ca làm việc, gửi khiếu nại.
2.  **PROVIDER (Nhân viên - ID: 2)**: Nhận ca làm việc, từ chối ca làm việc, báo cáo hoàn thành công việc và nhận tiền chia sẻ hoa hồng.
3.  **ADMIN (Quản trị viên - ID: 3)**: Quản lý người dùng, duyệt hồ sơ nhân viên, quản lý danh mục dịch vụ, cấu hình quy định tính giá và xử lý khiếu nại hoàn tiền.

---

## 🚀 Hướng dẫn thiết lập và chạy dự án

### 1. Cài đặt các thư viện phụ thuộc
Mở terminal tại thư mục gốc của dự án và chạy:
```bash
npm install
```

### 2. Cấu hình biến môi trường
Tạo file `.env` tại thư mục gốc của dự án (hoặc sử dụng file `.env` có sẵn) và chỉnh sửa thông số kết nối MySQL của bạn:
```env
PORT=3000
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASS=your_password_here
DB_NAME=booking_giup_viec
JWT_SECRET=super_secret_jwt_key_helpservice_2026
JWT_EXPIRES_IN=7d
REVENUE_SPLIT_PROVIDER=80
REVENUE_SPLIT_SYSTEM=20
```

### 3. Tạo cơ sở dữ liệu và nạp dữ liệu mẫu (MySQL)
Hãy đảm bảo bạn đã tạo một schema/database trống trên MySQL có tên trùng với `DB_NAME` trong file `.env` (ví dụ: `booking_giup_viec`). Sau đó chạy các lệnh sau:

*   **Chạy Migration** (Tạo bảng):
    ```bash
    node src/migrations/migrations.js
    ```
*   **Chạy Seeder** (Thêm dữ liệu quy định giá, tài khoản mẫu):
    ```bash
    node src/seeders/seeders.js
    ```

### 4. Khởi chạy máy chủ
Chạy lệnh sau để khởi chạy Express và Socket.IO server:
```bash
node src/app.js
```
Máy chủ sẽ khởi chạy tại cổng mặc định `http://localhost:3000`.

---

## 📖 Tài liệu API Swagger

Dự án cung cấp tài liệu chi tiết cho tất cả các endpoint. Sau khi khởi chạy máy chủ, hãy truy cập:
👉 **[http://localhost:3000/api-docs](http://localhost:3000/api-docs)**

Tài liệu Swagger hỗ trợ chạy thử trực tiếp các API (nạp tiền, đăng ký, đăng nhập, lấy token đặt vào Bearer Authorize,...).

---

## 🧪 Kịch bản kiểm thử tích hợp tự động

Dự án đi kèm một script kiểm thử tích hợp tự động chạy trên **SQLite in-memory** (không cần cài đặt MySQL) để kiểm tra toàn bộ luồng nghiệp vụ. 
Để chạy thử nghiệm và kiểm tra thuật toán tính toán giá tiền tự động cùng cơ chế chia hoa hồng:
```bash
node scratch/test_api.js
```
*(Đường dẫn chính xác đến file test: xem trong thư mục `.gemini/antigravity/brain/.../scratch/test_api.js`)*

Luồng kiểm thử bao gồm:
1.  Đăng ký & đăng nhập tài khoản Khách hàng.
2.  Tự động tính tiền đơn đặt lịch dựa trên các hệ số: ngày thường/cuối tuần, khung giờ thường/cao điểm và ngày lễ đặc biệt.
3.  Tạo đơn đặt lịch và tự động chia nhỏ thành các ca làm việc.
4.  Khách hàng nạp tiền vào ví điện tử nội bộ và thực hiện thanh toán trực tiếp qua ví.
5.  Nhân viên nhận ca làm việc và báo cáo hoàn thành công việc.
6.  Hệ thống tự động thực hiện **phân chia tiền** (80% về ví nhân viên, 20% giữ lại tại ví hệ thống) và ghi lịch sử giao dịch.
7.  Khách hàng viết đánh giá nhân viên (cập nhật điểm đánh giá trung bình).
8.  Khách hàng gửi khiếu nại và Admin duyệt khiếu nại, tự động hoàn tiền đền bù vào ví khách hàng.
9.  Xem thống kê dashboard Admin.
