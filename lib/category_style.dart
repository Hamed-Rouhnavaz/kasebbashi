import 'package:flutter/material.dart';

import 'text_utils.dart';

const _rules = <(List<String>, IconData)>[
  (
    ['کفش', 'کتانی', 'صندل', 'نعلین', 'بوت'],
    Icons.directions_walk,
  ),
  (
    ['کیف', 'کوله', 'ساک'],
    Icons.backpack_outlined,
  ),
  (
    ['لباس', 'پیراهن', 'تیشرت', 'شلوار', 'مانتو', 'پوشاک', 'بلوز', 'دامن', 'هودی', 'سارافون', 'شال', 'روسری', 'جوراب'],
    Icons.checkroom,
  ),
  (
    ['عطر', 'ادکلن', 'اسپری'],
    Icons.water_drop_outlined,
  ),
  (
    ['آرایش', 'آرایشی', 'کرم', 'رژ', 'لاک', 'مراقبت', 'پوست', 'مو'],
    Icons.face_retouching_natural,
  ),
  (
    ['زیور', 'جواهر', 'گردنبند', 'انگشتر', 'دستبند', 'گوشواره', 'طلا', 'نقره', 'بدلیجات'],
    Icons.diamond_outlined,
  ),
  (
    ['ساعت'],
    Icons.watch_outlined,
  ),
  (
    ['عینک'],
    Icons.visibility_outlined,
  ),
  (
    ['خوراک', 'شیرینی', 'کیک', 'قهوه', 'چای', 'میوه', 'غذا', 'آجیل', 'نوشیدنی', 'عسل'],
    Icons.restaurant_outlined,
  ),
  (
    ['آشپزخانه', 'ظرف', 'قابلمه', 'لیوان'],
    Icons.kitchen_outlined,
  ),
  (
    ['خانه', 'دکور', 'دکوراسیون', 'مبل', 'فرش', 'پرده', 'منزل'],
    Icons.chair_outlined,
  ),
  (
    ['هدفون', 'هندزفری', 'اسپیکر'],
    Icons.headphones_outlined,
  ),
  (
    ['برقی', 'الکترونیک', 'موبایل', 'گوشی', 'لپ‌تاپ', 'لپتاپ', 'کابل', 'شارژر', 'دیجیتال'],
    Icons.devices_other_outlined,
  ),
  (
    ['کودک', 'بچه', 'اسباب', 'نوزاد', 'عروسک'],
    Icons.child_care_outlined,
  ),
  (
    ['ورزش', 'ورزشی', 'بدنسازی'],
    Icons.fitness_center_outlined,
  ),
  (
    ['تحریر', 'کتاب', 'دفتر', 'خودکار'],
    Icons.menu_book_outlined,
  ),
  (
    ['گل', 'گیاه', 'گلدان'],
    Icons.local_florist_outlined,
  ),
];

/// آیکون دسته را از روی اسمش حدس می‌زند
IconData categoryIcon(String name) {
  final n = normalizeText(name);
  for (final (words, icon) in _rules) {
    for (final w in words) {
      if (n.contains(normalizeText(w))) return icon;
    }
  }
  return Icons.category_outlined;
}
