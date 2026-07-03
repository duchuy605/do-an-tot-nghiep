const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class DatDichVu extends Model {}

DatDichVu.init({
  MaDatDichVu: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaDatLich: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaDichVu: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  DonGia: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false
  },
  SoLuong: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1
  },
  PhuPhi: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false,
    defaultValue: 0
  },
  ThanhTien: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false
  }
}, {
  sequelize,
  modelName: 'DatDichVu',
  tableName: 'DatDichVu',
  timestamps: false
});

module.exports = DatDichVu;
