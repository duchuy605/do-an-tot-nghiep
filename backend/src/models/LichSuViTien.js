const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class LichSuViTien extends Model {}

LichSuViTien.init({
  MaGiaoDich: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaViNguon: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  MaViDich: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  MaDatLich: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  MaCaLam: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  MaKhieuNai: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  LoaiGiaoDich: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: '1: nap tien, 2: thanh toan, 3: hoan tien, 4: rut tien'
  },
  SoTien: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false
  },
  SoDuSau: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false
  },
  NgayTao: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  }
}, {
  sequelize,
  modelName: 'LichSuViTien',
  tableName: 'LichSuViTien',
  timestamps: false
});

module.exports = LichSuViTien;
