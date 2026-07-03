const { ThongBao } = require('../models');
const { success, error } = require('../utils/phan_hoi');

class NotificationController {
  async getNotifications(req, res, next) {
    try {
      const userId = req.user.MaNguoiDung;
      const notifications = await ThongBao.findAll({
        where: { MaNguoiDung: userId },
        order: [['MaThongBao', 'DESC']]
      });
      return success(res, notifications, 'Lấy danh sách thông báo thành công');
    } catch (err) {
      next(err);
    }
  }

  async markAsRead(req, res, next) {
    try {
      const userId = req.user.MaNguoiDung;
      const notificationId = req.params.id;

      const notification = await ThongBao.findByPk(notificationId);
      if (!notification || notification.MaNguoiDung !== userId) {
        return error(res, 'Thông báo không tồn tại', 404);
      }

      await notification.update({ TrangThaiThongBao: true });
      return success(res, null, 'Đánh dấu đã đọc thông báo thành công');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new NotificationController();
