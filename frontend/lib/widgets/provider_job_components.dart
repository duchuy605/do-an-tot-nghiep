import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobActionCallbacks {
  final Future<void> Function(List<dynamic> jobs) onRejectAllJobs;
  final Future<void> Function(List<dynamic> jobs) onAcceptAllJobs;
  final Future<void> Function(dynamic job) onRescheduleJob;
  final Future<void> Function(int caLamId) onAcceptJob;
  final Future<void> Function(int caLamId) onCancelJob;
  final Future<void> Function(int caLamId) onStartJob;
  final Future<void> Function(int caLamId) onCompleteJob;
  final Future<void> Function(int requestId, bool isAccept) onRespondReschedule;

  JobActionCallbacks({
    required this.onRejectAllJobs,
    required this.onAcceptAllJobs,
    required this.onRescheduleJob,
    required this.onAcceptJob,
    required this.onCancelJob,
    required this.onStartJob,
    required this.onCompleteJob,
    required this.onRespondReschedule,
  });
}

Widget detailRow(IconData icon, String label, String value, Color iconColor) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: iconColor),
      const SizedBox(width: 8),
      SizedBox(width: 80, child: Text('$label:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ],
  );
}

Widget earningsRow(String label, String value, Color valueColor, {bool bold = false, double fontSize = 14}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      Text(value, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: valueColor)),
    ],
  );
}

class ProviderRecurringJobCard extends StatelessWidget {
  final List<dynamic> jobs;
  final Color orangeColor;
  final Color darkColor;
  final JobActionCallbacks callbacks;

  const ProviderRecurringJobCard({
    super.key,
    required this.jobs,
    required this.orangeColor,
    required this.darkColor,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return const SizedBox.shrink();
    final firstJob = jobs.first;
    final String services = firstJob['DichVu'] ?? '';
    final String address = firstJob['DiaChiLamViec'] ?? '';
    final String customerName = firstJob['KhachHang']?['HoTenNguoiDung'] ?? 'Khách hàng';
    final String customerPhone = firstJob['KhachHang']?['SoDienThoai'] ?? '';
    final int totalShifts = jobs.length;
    final int completedShifts = jobs.where((j) => j['TrangThaiDonHang'] == 2).length;
    final int pendingConfirmShifts = jobs.where((j) => j['TrangThaiDonHang'] == 0).length;
    final bool allPending = pendingConfirmShifts == totalShifts;

    double totalEarnings = 0;
    for (final job in jobs) {
      final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
      totalEarnings += money * 0.8;
    }
    final String earningsStr = '${NumberFormat('#,###', 'vi_VN').format(totalEarnings.toInt())} đ';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showRecurringDetailSheet(context, jobs, orangeColor, darkColor, callbacks),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: orangeColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      services,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: orangeColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: orangeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Định kỳ - $totalShifts ca',
                      style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Khách: $customerName ($customerPhone)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '$completedShifts/$totalShifts ca hoàn thành',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng lương (80%):', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(earningsStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ],
                  ),
                  if (allPending)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => callbacks.onRejectAllJobs(jobs),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('TỪ CHỐI', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => callbacks.onAcceptAllJobs(jobs),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('NHẬN VIỆC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  if (!allPending && pendingConfirmShifts > 0)
                    Text(
                      '$pendingConfirmShifts ca chờ xác nhận',
                      style: TextStyle(fontSize: 12, color: orangeColor, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProviderJobCard extends StatelessWidget {
  final dynamic job;
  final Color orangeColor;
  final Color darkColor;
  final JobActionCallbacks callbacks;

  const ProviderJobCard({
    super.key,
    required this.job,
    required this.orangeColor,
    required this.darkColor,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    final int id = job['MaCaLam'] ?? 0;
    final int status = job['TrangThaiDonHang'] ?? 1;
    final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
    final double providerEarnings = money * 0.8;
    final String earningsStr = '${NumberFormat('#,###', 'vi_VN').format(providerEarnings.toInt())} đ';

    final String date = job['NgayLamViec'] ?? '';
    final String start = job['GioBatDau']?.substring(0, 5) ?? '';
    final String end = job['GioKetThuc']?.substring(0, 5) ?? '';
    final String services = job['DichVu'] ?? '';
    final String address = job['DiaChiLamViec'] ?? '';
    final String customerName = job['KhachHang']?['HoTenNguoiDung'] ?? 'Khách hàng';
    final String customerPhone = job['KhachHang']?['SoDienThoai'] ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showJobDetailSheet(context, job, orangeColor, darkColor, callbacks),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade50),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      services,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: orangeColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (status == 2 ? Colors.green : (status == 3 ? Colors.red : (status == 0 ? Colors.orange : Colors.blue))).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 0 ? 'Chờ xác nhận' : (status == 2 ? 'Đã hoàn thành' : (status == 3 ? 'Đã hủy' : 'Đã nhận việc')),
                      style: TextStyle(
                        color: status == 2 ? Colors.green : (status == 3 ? Colors.red : Colors.blue),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày làm: $date ($start - $end)',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Khách: $customerName ($customerPhone)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lương thực nhận (80%):', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(earningsStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ],
                  ),
                  if (status == 0)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => callbacks.onCancelJob(id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Từ Chối'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => callbacks.onAcceptJob(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('NHẬN VIỆC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  if (status == 1)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => callbacks.onRescheduleJob(job),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: orangeColor,
                            side: BorderSide(color: orangeColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Đổi Lịch'),
                        ),
                        const SizedBox(width: 8),
                        if (job['ThoiGianBatDauThucTe'] == null)
                          ElevatedButton(
                            onPressed: () => callbacks.onStartJob(id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('BẮT ĐẦU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => callbacks.onCompleteJob(id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('HOÀN THÀNH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showJobDetailSheet(BuildContext context, dynamic job, Color orangeColor, Color darkColor, JobActionCallbacks callbacks) {
  final int id = job['MaCaLam'] ?? 0;
  final int status = job['TrangThaiDonHang'] ?? 1;
  final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
  final double providerEarnings = money * 0.8;
  final double systemFee = money * 0.2;
  final String moneyStr = '${NumberFormat('#,###', 'vi_VN').format(money.toInt())} đ';
  final String earningsStr = '${NumberFormat('#,###', 'vi_VN').format(providerEarnings.toInt())} đ';
  final String feeStr = '${NumberFormat('#,###', 'vi_VN').format(systemFee.toInt())} đ';

  final String date = job['NgayLamViec'] ?? '';
  final String start = job['GioBatDau']?.substring(0, 5) ?? '';
  final String end = job['GioKetThuc']?.substring(0, 5) ?? '';
  final String services = job['DichVu'] ?? '';
  final String address = job['DiaChiLamViec'] ?? '';
  final String note = job['MoTaCongViec'] ?? '';
  final String customerName = job['KhachHang']?['HoTenNguoiDung'] ?? 'Khách hàng';
  final String customerPhone = job['KhachHang']?['SoDienThoai'] ?? '';
  final String customerEmail = job['KhachHang']?['Email'] ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Icon(Icons.assignment_rounded, color: orangeColor, size: 24),
                const SizedBox(width: 8),
                Text('Chi Tiết Ca Làm ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkColor)),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: (status == 2 ? Colors.green : (status == 3 ? Colors.red : (status == 0 ? Colors.orange : Colors.blue))).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 0 ? '🟠 Chờ xác nhận' : (status == 2 ? ' Đã hoàn thành' : (status == 3 ? ' Đã hủy' : ' Đã nhận việc')),
                  style: TextStyle(
                    color: status == 2 ? Colors.green : (status == 3 ? Colors.red : Colors.blue),
                    fontWeight: FontWeight.bold, fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            detailRow(Icons.cleaning_services_rounded, 'Dịch vụ', services, orangeColor),
            const SizedBox(height: 12),
            detailRow(Icons.calendar_today_rounded, 'Ngày làm', date, orangeColor),
            const SizedBox(height: 12),
            detailRow(Icons.access_time_rounded, 'Giờ làm', '$start → $end', orangeColor),
            const SizedBox(height: 12),
            detailRow(Icons.location_on_rounded, 'Địa chỉ', address, orangeColor),
            const SizedBox(height: 12),
            if (note.isNotEmpty) ...[
              detailRow(Icons.notes_rounded, 'Ghi chú', note, orangeColor),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 12),
            const Text('Thông tin khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            detailRow(Icons.person_rounded, 'Họ tên', customerName, Colors.blue),
            const SizedBox(height: 8),
            detailRow(Icons.phone_rounded, 'SĐT', customerPhone, Colors.blue),
            const SizedBox(height: 8),
            if (customerEmail.isNotEmpty) ...[
              detailRow(Icons.email_rounded, 'Email', customerEmail, Colors.blue),
              const SizedBox(height: 8),
            ],
            const Divider(),
            const SizedBox(height: 12),
            const Text('Chi tiết thu nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            earningsRow('Tổng tiền ca làm', moneyStr, darkColor),
            const SizedBox(height: 6),
            earningsRow('Phí hệ thống (20%)', '- $feeStr', Colors.red),
            const SizedBox(height: 6),
            const Divider(),
            const SizedBox(height: 6),
            earningsRow('Lương thực nhận', earningsStr, Colors.green, bold: true, fontSize: 17),
            const SizedBox(height: 20),
            if (status == 0 || status == 1) ...[
              Builder(builder: (_) {
                final List pendingRequests = (job['LichSuDoiLichs'] as List?) ?? [];
                final hasPending = pendingRequests.isNotEmpty;

                if (hasPending) {
                  final req = pendingRequests.first;
                  final requesterName = req['NguoiYeuCau']?['HoTenNguoiDung'] ?? 'Người dùng';
                  final requesterRole = req['NguoiYeuCau']?['VaiTro'] ?? 0;
                  final requestId = req['MaLichSu'] ?? 0;
                  final ngayMoiRaw = req['NgayMoi'] ?? '';
                  final gioBatDauMoiRaw = req['GioBatDauMoi'] ?? '';
                  final gioKetThucMoiRaw = req['GioKetThucMoi'] ?? '';
                  final ngayMoi = ngayMoiRaw.length >= 10 ? ngayMoiRaw.substring(0, 10) : ngayMoiRaw;
                  final gioBatDauMoi = gioBatDauMoiRaw.length >= 16 ? gioBatDauMoiRaw.substring(11, 16) : gioBatDauMoiRaw;
                  final gioKetThucMoi = gioKetThucMoiRaw.length >= 16 ? gioKetThucMoiRaw.substring(11, 16) : gioKetThucMoiRaw;
                  final isResponder = requesterRole == 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded, color: orangeColor, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Yêu cầu đổi lịch (đang chờ)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        detailRow(Icons.person_outline, 'Người gửi', requesterName, Colors.blueGrey),
                        const SizedBox(height: 6),
                        detailRow(Icons.calendar_today_outlined, 'Ngày mới', ngayMoi, Colors.blueGrey),
                        const SizedBox(height: 6),
                        detailRow(Icons.schedule_outlined, 'Giờ mới', '$gioBatDauMoi - $gioKetThucMoi', Colors.blueGrey),
                        if (isResponder) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    callbacks.onRespondReschedule(requestId, false);
                                  },
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  label: const Text('Từ Chối'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    callbacks.onRespondReschedule(requestId, true);
                                  },
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text('Đồng Ý'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              ' Đang chờ bên kia phản hồi...',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 12),
            ],
            if (status == 0) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { Navigator.pop(context); callbacks.onCancelJob(id); },
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Từ Chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () { Navigator.pop(context); callbacks.onAcceptJob(id); },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('NHẬN VIỆC'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 1) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { Navigator.pop(context); callbacks.onRescheduleJob(job); },
                      icon: const Icon(Icons.event_repeat_rounded, size: 18),
                      label: const Text('Đổi Lịch'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: orangeColor,
                        side: BorderSide(color: orangeColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (job['ThoiGianBatDauThucTe'] == null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () { Navigator.pop(context); callbacks.onStartJob(id); },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('BẮT ĐẦU'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () { Navigator.pop(context); callbacks.onCompleteJob(id); },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('HOÀN THÀNH'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

void showRecurringDetailSheet(BuildContext context, List<dynamic> jobs, Color orangeColor, Color darkColor, JobActionCallbacks callbacks) {
  final int maDatLich = jobs.first['MaDatLich'] ?? 0;
  final int totalShifts = jobs.length;
  final int completedShifts = jobs.where((j) => j['TrangThaiDonHang'] == 2).length;

  final sortedJobs = List<dynamic>.from(jobs)
    ..sort((a, b) => (a['NgayLamViec'] ?? '').compareTo(b['NgayLamViec'] ?? ''));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Icon(Icons.repeat_rounded, color: orangeColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chi Tiết Đơn Định Kỳ - Đơn #$maDatLich',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: orangeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📋 $completedShifts/$totalShifts ca hoàn thành',
                  style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...sortedJobs.map((job) {
              final int caLamId = job['MaCaLam'] ?? 0;
              final int status = job['TrangThaiDonHang'] ?? 1;
              final String date = job['NgayLamViec'] ?? '';
              final String start = job['GioBatDau']?.substring(0, 5) ?? '';
              final String end = job['GioKetThuc']?.substring(0, 5) ?? '';
              final double money = double.tryParse(job['TongTien']?.toString() ?? '0') ?? 0;
              final double providerEarnings = money * 0.8;
              final String earningsStr = '${NumberFormat('#,###', 'vi_VN').format(providerEarnings.toInt())} đ';

              Color statusColor;
              String statusText;
              switch (status) {
                case 0:
                  statusColor = Colors.orange;
                  statusText = 'Chờ xác nhận';
                  break;
                case 2:
                  statusColor = Colors.green;
                  statusText = 'Hoàn thành';
                  break;
                case 3:
                  statusColor = Colors.red;
                  statusText = 'Đã hủy';
                  break;
                default:
                  statusColor = Colors.blue;
                  statusText = 'Đã nhận';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('$start - $end', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        Text(earningsStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                      ],
                    ),
                    if (status == 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () { Navigator.pop(context); callbacks.onRescheduleJob(job); },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: orangeColor,
                              side: BorderSide(color: orangeColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Đổi Lịch', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () { Navigator.pop(context); callbacks.onAcceptJob(caLamId); },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('NHẬN VIỆC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                    if (status == 1) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () { Navigator.pop(context); callbacks.onRescheduleJob(job); },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: orangeColor,
                              side: BorderSide(color: orangeColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Đổi Lịch', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          if (job['ThoiGianBatDauThucTe'] == null)
                            ElevatedButton(
                              onPressed: () { Navigator.pop(context); callbacks.onStartJob(caLamId); },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('BẮT ĐẦU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            )
                          else
                            ElevatedButton(
                              onPressed: () { Navigator.pop(context); callbacks.onCompleteJob(caLamId); },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('HOÀN THÀNH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}
