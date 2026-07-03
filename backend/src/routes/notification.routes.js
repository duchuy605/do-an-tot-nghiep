const express = require('express');
const notificationController = require('../controllers/NotificationController');
const { authenticate } = require('../middlewares/xac_thuc');

const router = express.Router();

router.get('/', authenticate, notificationController.getNotifications);
router.put('/:id/read', authenticate, notificationController.markAsRead);

module.exports = router;
