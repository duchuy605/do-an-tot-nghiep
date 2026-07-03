const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class KhieuNai extends Model {}

KhieuNai.init({
  MaKhieuNai: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaNguoiGui: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaNguoiBiKhieuNai: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaCaLam: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaNguoiXuLy: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  MaHinhThucXuLy: {
    type: DataTypes.INTEGER,
    allowNull: true
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
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  NgayXuLy: {
    type: DataTypes.DATE,
    allowNull: true
  },
  TrangThaiXuLy: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0, // 0: cho xu ly, 1: dang xu ly, 2: da xu ly
    comment: '0: cho xu ly, 1: dang xu ly, 2: da xu ly'
  }
}, {
  sequelize,
  modelName: 'KhieuNai',
  tableName: 'KhieuNai',
  timestamps: false
});

module.exports = KhieuNai;
