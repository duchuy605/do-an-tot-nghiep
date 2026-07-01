const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class NguoiDung extends Model {}

NguoiDung.init({
  MaNguoiDung: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  HoTenNguoiDung: {
    type: DataTypes.STRING(50),
    allowNull: false
  },
  VaiTro: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: '1: Khach hang, 2: Nhan vien, 3: Admin'
  },
  MatKhau: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  Email: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true
  },
  DiaChi: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  SoDienThoai: {
    type: DataTypes.STRING(15),
    allowNull: false,
    unique: true
  },
  GioiTinh: {
    type: DataTypes.STRING(5),
    allowNull: true
  },
  NgaySinh: {
    type: DataTypes.DATEONLY,
    allowNull: true
  },
  TrangThaiTaiKhoan: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1, // 0: Cho xac minh, 1: Hoat dong, 2: Bi khoa
    comment: '0: Cho xac minh, 1: Hoat dong, 2: Bi khoa'
  },
  AnhDaiDien: {
    type: DataTypes.STRING(255),
    allowNull: true
  }
}, {
  sequelize,
  modelName: 'NguoiDung',
  tableName: 'NguoiDung',
  timestamps: false
});

module.exports = NguoiDung;
