const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class DichVu extends Model {}

DichVu.init({
  MaDichVu: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  TenDichVu: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  MotaDichVu: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  SoGioQuyDinh: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 2
  },
  DonGia: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false
  },
  TrangThai: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true // 0: Ngung cung cap, 1: Cung cap
  },
  NgayTao: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  }
}, {
  sequelize,
  modelName: 'DichVu',
  tableName: 'DichVu',
  timestamps: false
});

module.exports = DichVu;
