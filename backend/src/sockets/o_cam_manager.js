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
      console.log(`User connected: ${socket.id}`);

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
          console.log(`Admin registered: ${MaNguoiDung} (Socket: ${socket.id})`);
        } else if (VaiTro === 2) {
          socket.join('providers');
          console.log(`Provider registered: ${MaNguoiDung} (Socket: ${socket.id})`);
        } else {
          socket.join('customers');
          console.log(`Customer registered: ${MaNguoiDung} (Socket: ${socket.id})`);
        }
      });

      socket.on('disconnect', () => {
        console.log(`[SOCKET] User disconnected: ${socket.id}`);
        
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
    console.log(`Emitting to User #${userId}: ${tieuDe} - ${noiDung}`);
    
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
        console.log(`[SOCKET] User #${userId} has no active socket connection. Notification saved to DB only.`);
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
      console.error('Failed to save/emit notification for user:', err);
    }
  }

  // Gửi thông báo to all admins
  async guiThongBaoAdmin({ tieuDe, noiDung, data = null }) {
    console.log(`[SOCKET] Emitting to all Admins: ${tieuDe} - ${noiDung}`);
    
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
      console.error('Failed to save/emit admin notification:', err);
    }
  }

  // Send to all providers only
  async guiThongBaoTatCaNhanVien({ tieuDe, noiDung, data = null }) {
    console.log(`Emitting to Providers only: ${tieuDe} - ${noiDung}`);
    
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
      console.error('Failed on system notification:', err);
    }
  }
}

module.exports = new OCamManager();
