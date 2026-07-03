const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class NgayDacBiet extends Model {}

NgayDacBiet.init({
  MaNgay: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  Ngay: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  LoaiNgay: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  HeSoGia: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 1.0
  },
  TenNgay: {
    type: DataTypes.STRING(255),
    allowNull: false
  }
}, {
  sequelize,
  modelName: 'NgayDacBiet',
  tableName: 'NgayDacBiet',
  timestamps: false
});

module.exports = NgayDacBiet;
