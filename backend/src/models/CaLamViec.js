const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class CaLamViec extends Model {}

CaLamViec.init({
  MaCaLam: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaKhachHang: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaDatLich: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaNhanVien: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  GioBatDau: {
    type: DataTypes.TIME,
    allowNull: false
  },
  GioKetThuc: {
    type: DataTypes.TIME,
    allowNull: false
  },
  NgayLamViec: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  TongTien: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false
  },
  DiaChiLamViec: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  MoTaCongViec: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  NgayDat: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  TienNhanVienNhan: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false,
    defaultValue: 0
  },
  TienHeThongNhan: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false,
    defaultValue: 0
  },
  NgayCapNhat: {
    type: DataTypes.DATE,
    allowNull: true
  },
  DichVu: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'Luu danh sach ten dich vu'
  },
  LyDoHuy: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  TrangThaiDonHang: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0, // 0: Cho xac nhan, 1: Da nhan, 2: Hoan thanh, 3: Da huy
    comment: '0: Cho xac nhan, 1: Da nhan, 2: Hoan thanh, 3: Da huy'
  }
}, {
  sequelize,
  modelName: 'CaLamViec',
  tableName: 'CaLamViec',
  timestamps: false
});

module.exports = CaLamViec;
