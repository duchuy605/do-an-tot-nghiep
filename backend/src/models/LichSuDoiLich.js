const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class LichSuDoiLich extends Model {}

LichSuDoiLich.init({
  MaLichSu: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaCaLam: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaNguoiXuLy: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaNguoiYeuCau: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaNhanVienMoi: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  MaNhanVienCu: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  NgayMoi: {
    type: DataTypes.DATE,
    allowNull: true
  },
  GioBatDauMoi: {
    type: DataTypes.DATE,
    allowNull: true
  },
  GioKetThucMoi: {
    type: DataTypes.DATE,
    allowNull: true
  },
  KetQua: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: '1: dong y, 2: tu choi, 3: chuyen nhan vien, 4: huy ca'
  },
  NgayDoi: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  }
}, {
  sequelize,
  modelName: 'LichSuDoiLich',
  tableName: 'LichSuDoiLich',
  timestamps: false
});

module.exports = LichSuDoiLich;
