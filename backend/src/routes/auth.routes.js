const express = require('express');
const authController = require('../controllers/AuthController');
const { authenticate } = require('../middlewares/xac_thuc');
const upload = require('../middlewares/upload');

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/logout', authController.logout);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);

// Các API cần xác thực
router.put('/change-password', authenticate, authController.changePassword);
router.get('/profile', authenticate, authController.getProfile);
router.put('/profile', authenticate, upload.single('AnhDaiDien'), authController.updateProfile);

module.exports = router;
