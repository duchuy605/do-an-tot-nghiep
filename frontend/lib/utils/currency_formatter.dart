import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(text: '');
    }

    String cleanValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Nếu người dùng nhấn backspace và xóa trúng dấu chấm (.), cleanValue sẽ không đổi
    // Nên ta chủ động xóa luôn 1 số cuối cùng để backspace mượt mà.
    if (oldValue.text.length > newValue.text.length && 
        oldValue.text.replaceAll(RegExp(r'[^0-9]'), '') == cleanValue) {
      if (cleanValue.isNotEmpty) {
        cleanValue = cleanValue.substring(0, cleanValue.length - 1);
      }
    }

    if (cleanValue.isEmpty) {
      return const TextEditingValue(text: '');
    }

    int value = int.parse(cleanValue);
    String newText = NumberFormat('#,###', 'vi_VN').format(value);

    // Đơn giản nhất: luôn đẩy con trỏ về cuối cùng để tránh lỗi kẹt cursor
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
