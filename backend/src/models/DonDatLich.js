const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class DonDatLich extends Model {}

DonDatLich.init({
  MaDatLich: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false
  },
  MaKhachHang: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  MaNhanVien: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  MaLoaiGoi: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  NgayBatDau: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  NgayKetThuc: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  ThuTrongTuan: {
    type: DataTypes.STRING(20),
    allowNull: true,
    comment: 'Cac thu trong tuan lam viec, vi du: "2,4,6"'
  },
  LoaiDatLich: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1, // 1: Standard, 2: Plus
    comment: '1: Standard, 2: Plus'
  },
  GiaGoi: {
    type: DataTypes.DECIMAL(18, 0),
    allowNull: false,
    defaultValue: 0
  },
  SoBuoi: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1
  },
  DiaChiLamViec: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  GioBatDau: {
    type: DataTypes.TIME,
    allowNull: false
  },
  GioKetThuc: {
    type: DataTypes.TIME,
    allowNull: false
  },
  MoTaCongViec: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  TrangThai: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1, // 0: huy, 1: co hieu luc, 2: ket thuc
    comment: '0: huy, 1: co hieu luc, 2: ket thuc'
  }
}, {
  sequelize,
  modelName: 'DonDatLich',
  tableName: 'DonDatLich',
  timestamps: false
});

module.exports = DonDatLich;
