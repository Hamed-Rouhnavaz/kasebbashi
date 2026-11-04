import 'package:flutter/material.dart';

import 'sale.dart';

Color statusColor(String status) {
  switch (status) {
    case SaleStatus.preparing:
      return Colors.orange;
    case SaleStatus.shipped:
      return Colors.blue;
    case SaleStatus.delivered:
      return Colors.green;
    case SaleStatus.canceled:
      return Colors.grey;
    default:
      return Colors.grey;
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
