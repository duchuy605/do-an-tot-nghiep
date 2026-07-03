const sequelize = require('../config/database');

// Import models
const NguoiDung = require('./NguoiDung');
const HoSoNhanVien = require('./HoSoNhanVien');
const DichVu = require('./DichVu');
const DonDatLich = require('./DonDatLich');
const CaLamViec = require('./CaLamViec');
const DatDichVu = require('./DatDichVu');
const DanhGia = require('./DanhGia');
const KhieuNai = require('./KhieuNai');
const HinhThucXuLy = require('./HinhThucXuLy');
const ViTien = require('./ViTien');
const LichSuViTien = require('./LichSuViTien');
const ThongBao = require('./ThongBao');
const NgayDacBiet = require('./NgayDacBiet');
const QuyDinhGia = require('./QuyDinhGia');
const QuyDinhKhungGio = require('./QuyDinhKhungGio');
const LoaiGoi = require('./LoaiGoi');
const LichSuDoiLich = require('./LichSuDoiLich');

// Setup associations

// NguoiDung & HoSoNhanVien
NguoiDung.hasOne(HoSoNhanVien, { foreignKey: 'MaNhanVien', as: 'HoSoNhanVien' });
HoSoNhanVien.belongsTo(NguoiDung, { foreignKey: 'MaNhanVien', as: 'NhanVien' });

// NguoiDung & ViTien
NguoiDung.hasOne(ViTien, { foreignKey: 'MaNguoiDung', as: 'ViTien' });
ViTien.belongsTo(NguoiDung, { foreignKey: 'MaNguoiDung', as: 'NguoiDung' });

// NguoiDung & ThongBao
NguoiDung.hasMany(ThongBao, { foreignKey: 'MaNguoiDung', as: 'ThongBaos' });
ThongBao.belongsTo(NguoiDung, { foreignKey: 'MaNguoiDung', as: 'NguoiDung' });

// NguoiDung & DonDatLich
NguoiDung.hasMany(DonDatLich, { foreignKey: 'MaKhachHang', as: 'DonDatLichsKhachHang' });
DonDatLich.belongsTo(NguoiDung, { foreignKey: 'MaKhachHang', as: 'KhachHang' });

NguoiDung.hasMany(DonDatLich, { foreignKey: 'MaNhanVien', as: 'DonDatLichsNhanVien' });
DonDatLich.belongsTo(NguoiDung, { foreignKey: 'MaNhanVien', as: 'NhanVien' });

// LoaiGoi & DonDatLich
LoaiGoi.hasMany(DonDatLich, { foreignKey: 'MaLoaiGoi', as: 'DonDatLichs' });
DonDatLich.belongsTo(LoaiGoi, { foreignKey: 'MaLoaiGoi', as: 'LoaiGoi' });

// DonDatLich & DatDichVu & DichVu
DonDatLich.hasMany(DatDichVu, { foreignKey: 'MaDatLich', as: 'DatDichVus' });
DatDichVu.belongsTo(DonDatLich, { foreignKey: 'MaDatLich', as: 'DonDatLich' });

DichVu.hasMany(DatDichVu, { foreignKey: 'MaDichVu', as: 'DatDichVus' });
DatDichVu.belongsTo(DichVu, { foreignKey: 'MaDichVu', as: 'DichVu' });

// DonDatLich & CaLamViec & NguoiDung
DonDatLich.hasMany(CaLamViec, { foreignKey: 'MaDatLich', as: 'CaLamViecs' });
CaLamViec.belongsTo(DonDatLich, { foreignKey: 'MaDatLich', as: 'DonDatLich' });

NguoiDung.hasMany(CaLamViec, { foreignKey: 'MaKhachHang', as: 'CaLamViecsKhachHang' });
CaLamViec.belongsTo(NguoiDung, { foreignKey: 'MaKhachHang', as: 'KhachHang' });

NguoiDung.hasMany(CaLamViec, { foreignKey: 'MaNhanVien', as: 'CaLamViecsNhanVien' });
CaLamViec.belongsTo(NguoiDung, { foreignKey: 'MaNhanVien', as: 'NhanVien' });

// CaLamViec & DanhGia
CaLamViec.hasOne(DanhGia, { foreignKey: 'MaCaLam', as: 'DanhGia' });
DanhGia.belongsTo(CaLamViec, { foreignKey: 'MaCaLam', as: 'CaLamViec' });

NguoiDung.hasMany(DanhGia, { foreignKey: 'MaKhachHang', as: 'DanhGiasKhachHang' });
DanhGia.belongsTo(NguoiDung, { foreignKey: 'MaKhachHang', as: 'KhachHang' });

NguoiDung.hasMany(DanhGia, { foreignKey: 'MaNhanVien', as: 'DanhGiasNhanVien' });
DanhGia.belongsTo(NguoiDung, { foreignKey: 'MaNhanVien', as: 'NhanVien' });

// NguoiDung & KhieuNai
NguoiDung.hasMany(KhieuNai, { foreignKey: 'MaNguoiGui', as: 'KhieuNaisGui' });
KhieuNai.belongsTo(NguoiDung, { foreignKey: 'MaNguoiGui', as: 'NguoiGui' });

NguoiDung.hasMany(KhieuNai, { foreignKey: 'MaNguoiBiKhieuNai', as: 'KhieuNaisBiKhieuNai' });
KhieuNai.belongsTo(NguoiDung, { foreignKey: 'MaNguoiBiKhieuNai', as: 'NguoiBiKhieuNai' });

NguoiDung.hasMany(KhieuNai, { foreignKey: 'MaNguoiXuLy', as: 'KhieuNaisXuLy' });
KhieuNai.belongsTo(NguoiDung, { foreignKey: 'MaNguoiXuLy', as: 'NguoiXuLy' });

// CaLamViec & KhieuNai
CaLamViec.hasMany(KhieuNai, { foreignKey: 'MaCaLam', as: 'KhieuNais' });
KhieuNai.belongsTo(CaLamViec, { foreignKey: 'MaCaLam', as: 'CaLamViec' });

// HinhThucXuLy & KhieuNai
HinhThucXuLy.hasMany(KhieuNai, { foreignKey: 'MaHinhThucXuLy', as: 'KhieuNais' });
KhieuNai.belongsTo(HinhThucXuLy, { foreignKey: 'MaHinhThucXuLy', as: 'HinhThucXuLy' });

// ViTien & LichSuViTien
ViTien.hasMany(LichSuViTien, { foreignKey: 'MaViNguon', as: 'GiaoDichsDi' });
LichSuViTien.belongsTo(ViTien, { foreignKey: 'MaViNguon', as: 'ViNguon' });

ViTien.hasMany(LichSuViTien, { foreignKey: 'MaViDich', as: 'GiaoDichsDen' });
LichSuViTien.belongsTo(ViTien, { foreignKey: 'MaViDich', as: 'ViDich' });

// DonDatLich / CaLamViec / KhieuNai & LichSuViTien
DonDatLich.hasMany(LichSuViTien, { foreignKey: 'MaDatLich', as: 'GiaoDichs' });
LichSuViTien.belongsTo(DonDatLich, { foreignKey: 'MaDatLich', as: 'DonDatLich' });

CaLamViec.hasMany(LichSuViTien, { foreignKey: 'MaCaLam', as: 'GiaoDichs' });
LichSuViTien.belongsTo(CaLamViec, { foreignKey: 'MaCaLam', as: 'CaLamViec' });

KhieuNai.hasMany(LichSuViTien, { foreignKey: 'MaKhieuNai', as: 'GiaoDichs' });
LichSuViTien.belongsTo(KhieuNai, { foreignKey: 'MaKhieuNai', as: 'KhieuNai' });

// CaLamViec & LichSuDoiLich
CaLamViec.hasMany(LichSuDoiLich, { foreignKey: 'MaCaLam', as: 'LichSuDoiLichs' });
LichSuDoiLich.belongsTo(CaLamViec, { foreignKey: 'MaCaLam', as: 'CaLamViec' });

// NguoiDung & LichSuDoiLich
NguoiDung.hasMany(LichSuDoiLich, { foreignKey: 'MaNguoiXuLy', as: 'DoiLichsXuLy' });
LichSuDoiLich.belongsTo(NguoiDung, { foreignKey: 'MaNguoiXuLy', as: 'NguoiXuLy' });

NguoiDung.hasMany(LichSuDoiLich, { foreignKey: 'MaNguoiYeuCau', as: 'DoiLichsYeuCau' });
LichSuDoiLich.belongsTo(NguoiDung, { foreignKey: 'MaNguoiYeuCau', as: 'NguoiYeuCau' });

NguoiDung.hasMany(LichSuDoiLich, { foreignKey: 'MaNhanVienMoi', as: 'DoiLichsNhanVienMoi' });
LichSuDoiLich.belongsTo(NguoiDung, { foreignKey: 'MaNhanVienMoi', as: 'NhanVienMoi' });

NguoiDung.hasMany(LichSuDoiLich, { foreignKey: 'MaNhanVienCu', as: 'DoiLichsNhanVienCu' });
LichSuDoiLich.belongsTo(NguoiDung, { foreignKey: 'MaNhanVienCu', as: 'NhanVienCu' });

module.exports = {
  sequelize,
  NguoiDung,
  HoSoNhanVien,
  DichVu,
  DonDatLich,
  CaLamViec,
  DatDichVu,
  DanhGia,
  KhieuNai,
  HinhThucXuLy,
  ViTien,
  LichSuViTien,
  ThongBao,
  NgayDacBiet,
  QuyDinhGia,
  QuyDinhKhungGio,
  LoaiGoi,
  LichSuDoiLich
};
