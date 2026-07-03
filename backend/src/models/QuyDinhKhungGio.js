const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class QuyDinhKhungGio extends Model {}

QuyDinhKhungGio.init({
  MaQuyDinhGio: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  GioBatDau: {
    type: DataTypes.TIME,
    allowNull: false
  },
  GioKetThuc: {
    type: DataTypes.TIME,
    allowNull: false
  },
  TenKhungGio: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  HeSoGia: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 1.0
  }
}, {
  sequelize,
  modelName: 'QuyDinhKhungGio',
  tableName: 'QuyDinhKhungGio',
  timestamps: false
});

module.exports = QuyDinhKhungGio;
