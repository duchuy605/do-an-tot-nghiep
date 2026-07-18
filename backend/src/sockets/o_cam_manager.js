const socketIo = require('socket.io');
const { NguoiDung, ThongBao } = require('../models');

class OCamManager {
  constructor() {
    this.io = null;
    this.userSockets = new Map(); // Map: MaNguoiDung -> Set of Socket IDs
    this.adminSockets = new Set(); // Set of Admin Socket IDs
  }

  initialize(server) {
    this.io = socketIo(server, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST']
      }
    });

    this.io.on('connection', (socket) => {

      // Đăng ký định danh Socket.IO cho Client
      socket.on('register', (data) => {
        const { MaNguoiDung, VaiTro } = data;
        if (!MaNguoiDung) return;

        socket.userId = MaNguoiDung;
        socket.role = VaiTro;

        // Lưu trữ Socket ID tương ứng
        if (!this.userSockets.has(MaNguoiDung)) {
          this.userSockets.set(MaNguoiDung, new Set());
        }
        this.userSockets.get(MaNguoiDung).add(socket.id);

        // Đăng ký tham gia vào phòng (Room) tương ứng
        socket.join(`user_${MaNguoiDung}`);

        if (VaiTro === 3) {
          this.adminSockets.add(socket.id);
          socket.join('admins');
       
        } else if (VaiTro === 2) {
          socket.join('providers');
        } else {
          socket.join('customers');
        }
      });

      socket.on('disconnect', () => {
        if (socket.userId) {
          const sockets = this.userSockets.get(socket.userId);
          if (sockets) {
            sockets.delete(socket.id);
            if (sockets.size === 0) {
              this.userSockets.delete(socket.userId);
            }
          }
        }
        
        this.adminSockets.delete(socket.id);
      });
    });
  }

  // Gửi thông báo cho một người dùng cụ thể và lưu vào DB
  async guiThongBaoNguoiDung(userId, { tieuDe, noiDung, data = null }) {
    
    try {
      // Lưu thông tin thông báo vào cơ sở dữ liệu
      const notif = await ThongBao.create({
        MaNguoiDung: userId,
        TieuDe: tieuDe,
        NoiDung: noiDung,
        NgayTao: new Date().toISOString().split('T')[0],
        TrangThaiThongBao: false
      });

      const connectedSockets = this.userSockets.get(userId);
      const hasConnectedSocket = connectedSockets && connectedSockets.size > 0;

      if (!hasConnectedSocket) {
        return;
      }
      
      if (this.io) {
        this.io.to(`user_${userId}`).emit('thong_bao', {
          MaThongBao: notif.MaThongBao,
          tieuDe,
          noiDung,
          data,
          NgayTao: notif.NgayTao,
          TrangThaiThongBao: false
        });
      }
    } catch (err) {
    }
  }

  // Gửi thông báo to all admins
  async guiThongBaoAdmin({ tieuDe, noiDung, data = null }) {
    
    try {
      // Tìm tất cả quản trị viên in DB
      const admins = await NguoiDung.findAll({ where: { VaiTro: 3 } });
      for (const adm of admins) {
        await ThongBao.create({
          MaNguoiDung: adm.MaNguoiDung,
          TieuDe: tieuDe,
          NoiDung: noiDung,
          NgayTao: new Date().toISOString().split('T')[0],
          TrangThaiThongBao: false
        });
      }

      if (this.io) {
        this.io.to('admins').emit('thong_bao_admin', {
          tieuDe,
          noiDung,
          data
        });
      }
    } catch (err) {
    }
  }

  // Send to all providers only
  async guiThongBaoTatCaNhanVien({ tieuDe, noiDung, data = null }) {
    
    try {
      // Tìm tất cả providers in DB
      const { Op } = require('sequelize');
      const recipients = await NguoiDung.findAll({
        where: {
          VaiTro: 2
        }
      });

      for (const user of recipients) {
        await ThongBao.create({
          MaNguoiDung: user.MaNguoiDung,
          TieuDe: tieuDe,
          NoiDung: noiDung,
          NgayTao: new Date().toISOString().split('T')[0],
          TrangThaiThongBao: false
        });
      }

      if (this.io) {
        this.io.to('providers').emit('thong_bao_he_thong', {
          tieuDe,
          noiDung,
          data
        });
      }
    } catch (err) {
    }
  }
}

module.exports = new OCamManager();
