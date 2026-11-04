/// متن را برای جست‌وجو یکسان می‌کند:
/// ی/ي، ک/ك، فاصله مجازی، اعداد فارسی/عربی و حروف بزرگ و کوچک انگلیسی
String normalizeText(String input) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var s = input.trim().toLowerCase();
  s = s
      .replaceAll('\u064a', '\u06cc')
      .replaceAll('\u0643', '\u06a9')
      .replaceAll('\u200c', ' ');
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
  }
  return s;
}
