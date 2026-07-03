const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class ViTien extends Model {}

ViTien.init({
  MaViTien: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaNguoiDung: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true
  },
  SoDu: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false,
    defaultValue: 0
  },
  LoaiVi: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: '1: khach hang, 2: nhan vien, 3: he thong'
  },
  TrangThai: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true // 0: khoa, 1: hoat dong
  }
}, {
  sequelize,
  modelName: 'ViTien',
  tableName: 'ViTien',
  timestamps: false
});

module.exports = ViTien;
