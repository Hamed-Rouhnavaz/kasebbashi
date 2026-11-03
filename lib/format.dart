import 'package:intl/intl.dart';

final _fmt = NumberFormat('#,##0');

String toman(int value) => '${_fmt.format(value)} تومان';

/// عدد را از ورودی کاربر می‌خواند (اعداد فارسی و عربی هم قبول است)
int? parseNumber(String input) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var s = input.trim();
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
  }
  s = s.replaceAll(',', '').replaceAll('،', '');
  return int.tryParse(s);
}
