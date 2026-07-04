const nodemailer = require('nodemailer');
console.log("EMAIL_USER =", process.env.EMAIL_USER);
console.log("EMAIL_PASS =", process.env.EMAIL_PASS ? "Có giá trị" : "Không có giá trị");

// Cấu hình gửi email qua Gmail
// Cần bật "Mật khẩu ứng dụng" trong tài khoản Google
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER || '',
    pass: process.env.EMAIL_PASS || ''
  }
});

// Gửi mã OTP đặt lại mật khẩu qua email
async function guiEmailOTP(email, otpCode) {
  const mailOptions = {
    from: `"Ứng dụng Giúp Việc" <${process.env.EMAIL_USER}>`, 
    to: email,
    subject: 'Mã OTP đặt lại mật khẩu',
    text: `Mã OTP của bạn là: ${otpCode}

Mã OTP có hiệu lực trong 5 phút.
Vui lòng không chia sẻ mã này cho bất kỳ ai.`
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`Đã gửi OTP đến ${email}`);
    return true;
  } catch (err) {
    console.error(`Lỗi gửi email đến ${email}:`, err);
    return false;
  }
}

module.exports = { guiEmailOTP };
