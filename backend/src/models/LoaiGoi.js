const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class LoaiGoi extends Model {}

LoaiGoi.init({
  MaLoaiGoi: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  SoThang: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1
  },
  SoBuoi: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1
  },
  PhanTramGiamGia: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 0.0
  },
  TrangThai: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1, // 1: Dang ap dung, 2: Ngung ap dung
    comment: '1: Dang ap dung, 2: Ngung ap dung'
  }
}, {
  sequelize,
  modelName: 'LoaiGoi',
  tableName: 'LoaiGoi',
  timestamps: false
});

module.exports = LoaiGoi;
