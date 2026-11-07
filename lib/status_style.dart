import 'package:flutter/material.dart';

import 'sale.dart';

Color statusColor(String status) {
  switch (status) {
    case SaleStatus.preparing:
      return const Color(0xFFD08A1E); // کهربایی
    case SaleStatus.shipped:
      return const Color(0xFF3F74B8); // آبی
    case SaleStatus.delivered:
      return const Color(0xFF2E8B67); // زمرد
    case SaleStatus.canceled:
      return const Color(0xFF8C928F); // خاکستری
    default:
      return const Color(0xFF8C928F);
  }
}

IconData statusIcon(String status) {
  switch (status) {
    case SaleStatus.preparing:
      return Icons.hourglass_top;
    case SaleStatus.shipped:
      return Icons.local_shipping_outlined;
    case SaleStatus.delivered:
      return Icons.check_circle_outline;
    case SaleStatus.canceled:
      return Icons.cancel_outlined;
    default:
      return Icons.help_outline;
  }
}
