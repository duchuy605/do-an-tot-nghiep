const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class HoSoNhanVien extends Model {}

HoSoNhanVien.init({
  MaHoSo: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaNhanVien: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true
  },
  CCCD: {
    type: DataTypes.STRING(12),
    allowNull: false,
    unique: true
  },
  NgayDuyet: {
    type: DataTypes.DATE,
    allowNull: true
  },
  SoGioLamViec: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  TongDanhGia: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  SoSaoTrungBinh: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 5.0
  },
  TrangThaiDuyet: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0, // 0: Cho duyet, 1: Da duyet, 2: Tu choi
    comment: '0: Cho duyet, 1: Da duyet, 2: Tu choi'
  },
  TrangThaiHoatDong: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false // 0: Khong hoat dong, 1: Hoat dong
  }
}, {
  sequelize,
  modelName: 'HoSoNhanVien',
  tableName: 'HoSoNhanVien',
  timestamps: false
});

module.exports = HoSoNhanVien;
