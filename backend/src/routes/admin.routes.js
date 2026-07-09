const express = require('express');
const adminController = require('../controllers/AdminController');
const { authenticate, authorize } = require('../middlewares/xac_thuc');

const router = express.Router();

// Áp dụng bộ lọc xác thực to all admin routes
router.use(authenticate, authorize('ADMIN'));

// Quản lý Người dùng
router.get('/users', adminController.getUsers);
router.get('/users/:id', adminController.getUserDetail);
router.put('/users/:id', adminController.updateUser);
router.put('/users/:id/lock', adminController.lockUser);
router.put('/users/:id/unlock', adminController.unlockUser);

// Quản lý Nhân viên
router.get('/providers', adminController.getProviders);
router.put('/providers/:id/approve', adminController.approveProvider);
router.put('/providers/:id/reject', adminController.rejectProvider);

// Quản lý Dịch vụ
router.post('/services', adminController.createService);
router.put('/services/:id', adminController.updateService);
router.delete('/services/:id', adminController.deleteService);
router.get('/services', adminController.getServices);

// Quản lý Lịch đặt
router.get('/bookings', adminController.getBookings);
router.get('/bookings/:id', adminController.getBookingDetail);
router.put('/bookings/:id/status', adminController.updateBookingStatus);

// Quản lý Ngày đặc biệt
router.get('/special-days', adminController.getSpecialDays);
router.post('/special-days', adminController.createSpecialDay);
router.put('/special-days/:id', adminController.updateSpecialDay);
router.delete('/special-days/:id', adminController.deleteSpecialDay);

// Quản lý Khung giờ
router.get('/time-slots', adminController.getTimeSlots);
router.post('/time-slots', adminController.createTimeSlot);
router.put('/time-slots/:id', adminController.updateTimeSlot);
router.delete('/time-slots/:id', adminController.deleteTimeSlot);

// Quản lý Gói định kỳ
router.get('/packages', adminController.getPackages);
router.post('/packages', adminController.createPackage);
router.put('/packages/:id', adminController.updatePackage);
router.delete('/packages/:id', adminController.deletePackage);

// Quản lý Khiếu nại
router.get('/complaints', adminController.getComplaints);
router.put('/complaints/:id/process', adminController.processComplaint);
router.put('/complaints/:id/resolve', adminController.resolveComplaint);

// Hình thức xử lý khiếu nại
router.get('/resolution-types', adminController.getResolutionTypes);

// Báo cáo thống kê Dashboard Dashboard
router.get('/dashboard', adminController.getDashboard);

// [DEV] Kích hoạt thanh toán tự động thủ công (để test)
router.post('/payout/trigger', async (req, res, next) => {
  try {
    const result = await adminController.executeAutomaticPayouts();
    return res.json({ success: result.success, data: result.data, message: result.message });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
