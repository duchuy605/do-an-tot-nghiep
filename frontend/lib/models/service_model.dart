class ServiceModel {
  final int maDichVu;
  final String tenDichVu;
  final String motaDichVu;
  final int soGioQuyDinh;
  final double donGia;
  final bool trangThai;

  ServiceModel({
    required this.maDichVu,
    required this.tenDichVu,
    required this.motaDichVu,
    required this.soGioQuyDinh,
    required this.donGia,
    required this.trangThai,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      maDichVu: json['MaDichVu'] ?? 0,
      tenDichVu: json['TenDichVu'] ?? '',
      motaDichVu: json['MotaDichVu'] ?? '',
      soGioQuyDinh: json['SoGioQuyDinh'] ?? 1,
      donGia: double.tryParse(json['DonGia']?.toString() ?? '0.0') ?? 0.0,
      trangThai: json['TrangThai'] == true || json['TrangThai'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaDichVu': maDichVu,
      'TenDichVu': tenDichVu,
      'MotaDichVu': motaDichVu,
      'SoGioQuyDinh': soGioQuyDinh,
      'DonGia': donGia,
      'TrangThai': trangThai,
    };
  }
}
