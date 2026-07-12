import 'user_model.dart';
import 'service_model.dart';

class BookingModel {
  final int maDatLich;
  final int maKhachHang;
  final int? maNhanVien;
  final int? maLoaiGoi;
  final String ngayBatDau;
  final String ngayKetThuc;
  final String? thuTrongTuan;
  final int loaiDatLich; // 1: Mot lan, 2: Dinh ky
  final double giaGoi;
  final int soBuoi;
  final String diaChiLamViec;
  final String gioBatDau;
  final String gioKetThuc;
  final String? moTaCongViec;
  final int trangThai; // 0: Huy, 1: Tao moi, 2: Da thanh toan/hoat dong, 3: Hoan thanh
  final List<DatDichVuModel>? datDichVus;
  final List<CaLamViecModel>? caLamViecs;
  final UserModel? khachHang;
  final UserModel? nhanVien;

  BookingModel({
    required this.maDatLich,
    required this.maKhachHang,
    this.maNhanVien,
    this.maLoaiGoi,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    this.thuTrongTuan,
    required this.loaiDatLich,
    required this.giaGoi,
    required this.soBuoi,
    required this.diaChiLamViec,
    required this.gioBatDau,
    required this.gioKetThuc,
    this.moTaCongViec,
    required this.trangThai,
    this.datDichVus,
    this.caLamViecs,
    this.khachHang,
    this.nhanVien,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    var dList = json['DatDichVus'] as List?;
    List<DatDichVuModel>? services = dList != null
        ? dList.map((e) => DatDichVuModel.fromJson(e)).toList()
        : null;

    var cList = json['CaLamViecs'] as List?;
    List<CaLamViecModel>? shifts = cList != null
        ? cList.map((e) => CaLamViecModel.fromJson(e)).toList()
        : null;

    return BookingModel(
      maDatLich: json['MaDatLich'] ?? 0,
      maKhachHang: json['MaKhachHang'] ?? 0,
      maNhanVien: json['MaNhanVien'],
      maLoaiGoi: json['MaLoaiGoi'],
      ngayBatDau: json['NgayBatDau'] ?? '',
      ngayKetThuc: json['NgayKetThuc'] ?? '',
      thuTrongTuan: json['ThuTrongTuan'],
      loaiDatLich: json['LoaiDatLich'] ?? 1,
      giaGoi: double.tryParse(json['GiaGoi']?.toString() ?? '0.0') ?? 0.0,
      soBuoi: json['SoBuoi'] ?? 1,
      diaChiLamViec: json['DiaChiLamViec'] ?? '',
      gioBatDau: json['GioBatDau'] ?? '',
      gioKetThuc: json['GioKetThuc'] ?? '',
      moTaCongViec: json['MoTaCongViec'],
      trangThai: json['TrangThai'] ?? 1,
      datDichVus: services,
      caLamViecs: shifts,
      khachHang: json['KhachHang'] != null ? UserModel.fromJson(json['KhachHang']) : null,
      nhanVien: json['NhanVien'] != null ? UserModel.fromJson(json['NhanVien']) : null,
    );
  }
}

class DatDichVuModel {
  final int maDatDichVu;
  final int maDatLich;
  final int maDichVu;
  final double donGia;
  final int soLuong;
  final double phuPhi;
  final double thanhTien;
  final ServiceModel? service;

  DatDichVuModel({
    required this.maDatDichVu,
    required this.maDatLich,
    required this.maDichVu,
    required this.donGia,
    required this.soLuong,
    required this.phuPhi,
    required this.thanhTien,
    this.service,
  });

  factory DatDichVuModel.fromJson(Map<String, dynamic> json) {
    return DatDichVuModel(
      maDatDichVu: json['MaDatDichVu'] ?? 0,
      maDatLich: json['MaDatLich'] ?? 0,
      maDichVu: json['MaDichVu'] ?? 0,
      donGia: double.tryParse(json['DonGia']?.toString() ?? '0.0') ?? 0.0,
      soLuong: json['SoLuong'] ?? 1,
      phuPhi: double.tryParse(json['PhuPhi']?.toString() ?? '0.0') ?? 0.0,
      thanhTien: double.tryParse(json['ThanhTien']?.toString() ?? '0.0') ?? 0.0,
      service: json['DichVu'] != null ? ServiceModel.fromJson(json['DichVu']) : null,
    );
  }
}

class CaLamViecModel {
  final int maCaLam;
  final int maKhachHang;
  final int maDatLich;
  final int? maNhanVien;
  final String gioBatDau;
  final String gioKetThuc;
  final String ngayLamViec;
  final double tongTien;
  final String diaChiLamViec;
  final String? moTaCongViec;
  final double tienNhanVienNhan;
  final double tienHeThongNhan;
  final String dichVu;
  final String? lyDoHuy;
  final int trangThaiDonHang; // 0: Cho thanh toan, 1: Cho nhan / Da nhan, 2: Hoan thanh, 3: Huy
  final UserModel? nhanVien;
  final bool daDanhGia;
  final bool daKhieuNai;
  final String? thoiGianBatDauThucTe;
  final List<LichSuDoiLichModel> lichSuDoiLichs;

  CaLamViecModel({
    required this.maCaLam,
    required this.maKhachHang,
    required this.maDatLich,
    this.maNhanVien,
    required this.gioBatDau,
    required this.gioKetThuc,
    required this.ngayLamViec,
    required this.tongTien,
    required this.diaChiLamViec,
    this.moTaCongViec,
    required this.tienNhanVienNhan,
    required this.tienHeThongNhan,
    required this.dichVu,
    this.lyDoHuy,
    required this.trangThaiDonHang,
    this.nhanVien,
    this.daDanhGia = false,
    this.daKhieuNai = false,
    this.thoiGianBatDauThucTe,
    this.lichSuDoiLichs = const [],
  });

  factory CaLamViecModel.fromJson(Map<String, dynamic> json) {
    final requestList = json['LichSuDoiLichs'] as List?;
    return CaLamViecModel(
      maCaLam: json['MaCaLam'] ?? 0,
      maKhachHang: json['MaKhachHang'] ?? 0,
      maDatLich: json['MaDatLich'] ?? 0,
      maNhanVien: json['MaNhanVien'],
      gioBatDau: json['GioBatDau'] ?? '',
      gioKetThuc: json['GioKetThuc'] ?? '',
      ngayLamViec: json['NgayLamViec'] ?? '',
      tongTien: double.tryParse(json['TongTien']?.toString() ?? '0.0') ?? 0.0,
      diaChiLamViec: json['DiaChiLamViec'] ?? '',
      moTaCongViec: json['MoTaCongViec'],
      tienNhanVienNhan: double.tryParse(json['TienNhanVienNhan']?.toString() ?? '0.0') ?? 0.0,
      tienHeThongNhan: double.tryParse(json['TienHeThongNhan']?.toString() ?? '0.0') ?? 0.0,
      dichVu: json['DichVu'] ?? '',
      lyDoHuy: json['LyDoHuy'],
      trangThaiDonHang: json['TrangThaiDonHang'] ?? 0,
      nhanVien: json['NhanVien'] != null ? UserModel.fromJson(json['NhanVien']) : null,
      daDanhGia: json['DanhGia'] != null,
      daKhieuNai: json['KhieuNais'] != null && (json['KhieuNais'] as List).isNotEmpty,
      thoiGianBatDauThucTe: json['ThoiGianBatDauThucTe'],
      lichSuDoiLichs: requestList != null
          ? requestList.map((e) => LichSuDoiLichModel.fromJson(e)).toList()
          : const [],
    );
  }
}

class LichSuDoiLichModel {
  final int maLichSu;
  final int maCaLam;
  final int maNguoiXuLy;
  final int maNguoiYeuCau;
  final String? ngayMoi;
  final String? gioBatDauMoi;
  final String? gioKetThucMoi;
  final int ketQua;
  final UserModel? nguoiYeuCau;
  final UserModel? nguoiXuLy;

  LichSuDoiLichModel({
    required this.maLichSu,
    required this.maCaLam,
    required this.maNguoiXuLy,
    required this.maNguoiYeuCau,
    this.ngayMoi,
    this.gioBatDauMoi,
    this.gioKetThucMoi,
    required this.ketQua,
    this.nguoiYeuCau,
    this.nguoiXuLy,
  });

  factory LichSuDoiLichModel.fromJson(Map<String, dynamic> json) {
    return LichSuDoiLichModel(
      maLichSu: json['MaLichSu'] ?? 0,
      maCaLam: json['MaCaLam'] ?? 0,
      maNguoiXuLy: json['MaNguoiXuLy'] ?? 0,
      maNguoiYeuCau: json['MaNguoiYeuCau'] ?? 0,
      ngayMoi: json['NgayMoi'],
      gioBatDauMoi: json['GioBatDauMoi'],
      gioKetThucMoi: json['GioKetThucMoi'],
      ketQua: json['KetQua'] ?? 0,
      nguoiYeuCau: json['NguoiYeuCau'] != null ? UserModel.fromJson(json['NguoiYeuCau']) : null,
      nguoiXuLy: json['NguoiXuLy'] != null ? UserModel.fromJson(json['NguoiXuLy']) : null,
    );
  }
}
