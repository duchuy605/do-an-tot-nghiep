const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class HinhThucXuLy extends Model {}

HinhThucXuLy.init({
  MaHinhThucXuLy: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  TenHinhThuc: {
    type: DataTypes.STRING(255),
    allowNull: false
  }
}, {
  sequelize,
  modelName: 'HinhThucXuLy',
  tableName: 'HinhThucXuLy',
  timestamps: false
});

module.exports = HinhThucXuLy;
