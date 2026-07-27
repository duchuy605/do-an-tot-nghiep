const express = require('express');
const customerController = require('../controllers/CustomerController');
const { authenticate, authorize } = require('../middlewares/xac_thuc');

const router = express.Router();

// Các API công khai services & provider lists (though users should be logged in to book)
router.get('/services', customerController.getServices);
router.get('/services/:id', customerController.getServiceDetail);
router.get('/providers', customerController.getProviders);
router.get('/providers/:id', customerController.getProviderDetail);
router.get('/providers/:id/busy-dates', customerController.getProviderBusyDates);
router.get('/packages', customerController.getPackages);

// Các API cần xác thực (Customer role only)
router.post('/bookings/preview', authenticate, authorize('CUSTOMER'), customerController.previewBookingPrice);
router.post('/bookings', authenticate, authorize('CUSTOMER'), customerController.createBooking);
router.get('/bookings', authenticate, authorize('CUSTOMER'), customerController.getBookings);
router.patch('/bookings/shifts/:id/reschedule', authenticate, authorize('CUSTOMER', 'PROVIDER'), customerController.rescheduleShift);
router.patch('/bookings/reschedule-requests/:id/respond', authenticate, authorize('CUSTOMER', 'PROVIDER'), customerController.respondRescheduleShift);
router.patch('/bookings/shifts/:id/change-provider', authenticate, authorize('CUSTOMER'), customerController.changeProvider);
router.get('/bookings/:id', authenticate, authorize('CUSTOMER', 'PROVIDER', 'ADMIN'), customerController.getBookingDetail);
router.delete('/bookings/:id', authenticate, authorize('CUSTOMER'), customerController.cancelBooking);

router.post('/payments', authenticate, authorize('CUSTOMER'), customerController.payBooking);
router.post('/wallet/topup', authenticate, authorize('CUSTOMER'), customerController.topupWallet);
router.get('/wallet', authenticate, authorize('CUSTOMER', 'PROVIDER', 'ADMIN'), customerController.getWallet);
router.get('/wallet/history', authenticate, authorize('CUSTOMER', 'PROVIDER', 'ADMIN'), customerController.getWalletHistory);

router.post('/reviews', authenticate, authorize('CUSTOMER'), customerController.createReview);
router.post('/complaints', authenticate, authorize('CUSTOMER'), customerController.createComplaint);

module.exports = router;
