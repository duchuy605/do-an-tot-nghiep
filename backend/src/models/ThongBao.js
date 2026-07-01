const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class ThongBao extends Model {}

ThongBao.init({
  MaThongBao: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaNguoiDung: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  TieuDe: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  NoiDung: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  NgayTao: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  TrangThaiThongBao: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false // false: chua doc, true: da doc
  }
}, {
  sequelize,
  modelName: 'ThongBao',
  tableName: 'ThongBao',
  timestamps: false
});

module.exports = ThongBao;
