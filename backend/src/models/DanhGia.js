const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class DanhGia extends Model {}

DanhGia.init({
  MaDanhGia: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaCaLam: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true
  },
  MaKhachHang: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaNhanVien: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  SoSao: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 1,
      max: 5
    }
  },
  NoiDungDanhGia: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  NgayDanhGia: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  }
}, {
  sequelize,
  modelName: 'DanhGia',
  tableName: 'DanhGia',
  timestamps: false
});

module.exports = DanhGia;
