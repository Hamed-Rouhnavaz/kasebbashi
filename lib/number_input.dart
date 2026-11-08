import 'package:flutter/services.dart';

/// 1234567 را به «1,234,567» تبدیل می‌کند
String groupInt(int v) {
  final s = v.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return (v < 0 ? '-' : '') + buf.toString();
}

String _latinDigit(String ch) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final i = fa.indexOf(ch);
  if (i >= 0) return '$i';
  final j = ar.indexOf(ch);
  if (j >= 0) return '$j';
  return ch;
}

final _digitRe = RegExp(r'^[0-9]$');

/// هنگام تایپ، عدد را سه‌رقمی‌سه‌رقمی جدا می‌کند و مکان مکان‌نما را حفظ می‌کند
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final cursor = newValue.selection.baseOffset < 0
        ? raw.length
        : newValue.selection.baseOffset.clamp(0, raw.length).toInt();

    final digits = StringBuffer();
    var digitsBeforeCursor = 0;
    for (var i = 0; i < raw.length; i++) {
      final d = _latinDigit(raw[i]);
      if (_digitRe.hasMatch(d)) {
        digits.write(d);
        if (i < cursor) digitsBeforeCursor++;
      }
    }

    final plain = digits.toString();
    if (plain.isEmpty) return const TextEditingValue(text: '');

    final formatted = groupInt(int.tryParse(plain) ?? 0);
    // اگر عدد با صفر شروع شده بود، همان را بدون حذف صفرها نگه دار
    final shown = plain.startsWith('0') && plain.length > 1
        ? plain
        : formatted;

    var pos = shown.length;
    if (digitsBeforeCursor == 0) {
      pos = 0;
    } else {
      var seen = 0;
      for (var i = 0; i < shown.length; i++) {
        if (shown[i] != ',') {
          seen++;
          if (seen == digitsBeforeCursor) {
            pos = i + 1;
            break;
          }
        }
      }
    }
    return TextEditingValue(
      text: shown,
      selection: TextSelection.collapsed(offset: pos),
    );
  }
}
