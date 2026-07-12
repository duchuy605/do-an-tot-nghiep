const { ThongBao } = require('../models');
const { success, error } = require('../utils/phan_hoi');

class NotificationController {
  async getNotifications(req, res, next) {
    try {
      const { Op } = require('sequelize');
      const userId = req.user.MaNguoiDung;
      const vaiTro = req.user.VaiTro;
      
      const whereCondition = { MaNguoiDung: userId };
      
      // Nếu là Admin (VaiTro === 3), chỉ hiển thị thông báo khiếu nại và đi trễ
      if (vaiTro === 3) {
        whereCondition[Op.or] = [
          { TieuDe: { [Op.like]: '%Khiếu nại%' } },
          { TieuDe: { [Op.like]: '%đi trễ%' } }
        ];
      }

      const notifications = await ThongBao.findAll({
        where: whereCondition,
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
