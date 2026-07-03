class UserModel {
  final int maNguoiDung;
  final String hoTenNguoiDung;
  final int vaiTro;
  final String email;
  final String soDienThoai;
  final String diaChi;
  final String gioiTinh;
  final String ngaySinh;
  final int trangThaiTaiKhoan;
  final String? anhDaiDien;

  UserModel({
    required this.maNguoiDung,
    required this.hoTenNguoiDung,
    required this.vaiTro,
    required this.email,
    required this.soDienThoai,
    required this.diaChi,
    required this.gioiTinh,
    required this.ngaySinh,
    required this.trangThaiTaiKhoan,
    this.anhDaiDien,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      maNguoiDung: json['MaNguoiDung'] ?? 0,
      hoTenNguoiDung: json['HoTenNguoiDung'] ?? '',
      vaiTro: json['VaiTro'] ?? 1,
      email: json['Email'] ?? '',
      soDienThoai: json['SoDienThoai'] ?? '',
      diaChi: json['DiaChi'] ?? '',
      gioiTinh: json['GioiTinh'] ?? '',
      ngaySinh: json['NgaySinh'] ?? '',
      trangThaiTaiKhoan: json['TrangThaiTaiKhoan'] ?? 1,
      anhDaiDien: json['AnhDaiDien'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaNguoiDung': maNguoiDung,
      'HoTenNguoiDung': hoTenNguoiDung,
      'VaiTro': vaiTro,
      'Email': email,
      'SoDienThoai': soDienThoai,
      'DiaChi': diaChi,
      'GioiTinh': gioiTinh,
      'NgaySinh': ngaySinh,
      'TrangThaiTaiKhoan': trangThaiTaiKhoan,
      'AnhDaiDien': anhDaiDien,
    };
  }
}

class HoSoNhanVienModel {
  final int maNhanVien;
  final String cccd;
  final int soGioLamViec;
  final int tongDanhGia;
  final double soSaoTrungBinh;
  final int trangThaiDuyet;
  final bool trangThaiHoatDong;

  HoSoNhanVienModel({
    required this.maNhanVien,
    required this.cccd,
    required this.soGioLamViec,
    required this.tongDanhGia,
    required this.soSaoTrungBinh,
    required this.trangThaiDuyet,
    required this.trangThaiHoatDong,
  });

  factory HoSoNhanVienModel.fromJson(Map<String, dynamic> json) {
    return HoSoNhanVienModel(
      maNhanVien: json['MaNhanVien'] ?? 0,
      cccd: json['CCCD'] ?? '',
      soGioLamViec: json['SoGioLamViec'] ?? 0,
      tongDanhGia: json['TongDanhGia'] ?? 0,
      soSaoTrungBinh: double.tryParse(json['SoSaoTrungBinh']?.toString() ?? '5.0') ?? 5.0,
      trangThaiDuyet: json['TrangThaiDuyet'] ?? 0,
      trangThaiHoatDong: json['TrangThaiHoatDong'] == true || json['TrangThaiHoatDong'] == 1,
    );
  }
}
