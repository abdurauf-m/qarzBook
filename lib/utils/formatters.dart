import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Faqat raqamlarni qoldiramiz
    String newValueText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (newValueText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final format = NumberFormat("#,###", "en_US");
    String newString = format.format(int.parse(newValueText));
    
    // Kursor pozitsiyasini hisoblash
    int selectionEnd = newValue.selection.end;
    if (selectionEnd < 0) selectionEnd = 0;
    
    int digitsBeforeCursor = newValue.text.substring(0, selectionEnd).replaceAll(RegExp(r'[^0-9]'), '').length;
    int newCursorPos = 0;
    int digitCount = 0;
    
    for (int i = 0; i < newString.length; i++) {
      if (newString[i] != ',') {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor) {
        newCursorPos = i + 1;
        break;
      }
    }
    
    if (digitsBeforeCursor == newValueText.length) {
      newCursorPos = newString.length;
    }

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}
