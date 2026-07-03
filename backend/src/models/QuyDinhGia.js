const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class QuyDinhGia extends Model {}

QuyDinhGia.init({
  MaQuyDinhGia: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  SoGio: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  HeSoGiamGia: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 1.0
  },
  HeSoT7CN: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 1.0
  }
}, {
  sequelize,
  modelName: 'QuyDinhGia',
  tableName: 'QuyDinhGia',
  timestamps: false
});

module.exports = QuyDinhGia;
