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

    // Tính toán lại vị trí con trỏ (selection)
    int selectionIndex = newValue.selection.end;
    if (selectionIndex < 0) {
      selectionIndex = newValue.text.length;
    } else if (selectionIndex > newValue.text.length) {
      selectionIndex = newValue.text.length;
    }
    
    // Đếm số lượng ký tự không phải số ở bên trái con trỏ trong chuỗi cũ
    int nonDigitCountBeforeCursor = 0;
    for (int i = 0; i < selectionIndex; i++) {
      if (!RegExp(r'[0-9]').hasMatch(newValue.text[i])) {
        nonDigitCountBeforeCursor++;
      }
    }
    
    // Số lượng chữ số thực sự ở bên trái con trỏ
    int digitCountBeforeCursor = selectionIndex - nonDigitCountBeforeCursor;
    
    // Tìm vị trí con trỏ mới trong chuỗi newText
    int newSelectionIndex = 0;
    int currentDigitCount = 0;
    for (int i = 0; i < newText.length; i++) {
      if (currentDigitCount == digitCountBeforeCursor) {
        break;
      }
      if (RegExp(r'[0-9]').hasMatch(newText[i])) {
        currentDigitCount++;
      }
      newSelectionIndex++;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }
}
