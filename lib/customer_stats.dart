import 'db.dart';
import 'sale.dart';

class CustomerStat {
  final int count;
  final int total;
  final int debt;
  const CustomerStat(this.count, this.total, this.debt);
}

extension CustomerStats on AppDatabase {
  /// تعداد خرید، جمع خرید و مانده هر مشتری (فروش‌های لغوشده حساب نمی‌شوند)
  Future<Map<int, CustomerStat>> customerStats() async {
    final sales = await getSales();
    final map = <int, CustomerStat>{};
    for (final s in sales) {
      final id = s.customerId;
      if (id == null || s.status == SaleStatus.canceled) continue;
      final old = map[id];
      map[id] = CustomerStat(
        (old?.count ?? 0) + 1,
        (old?.total ?? 0) + s.total,
        (old?.debt ?? 0) + (s.remaining > 0 ? s.remaining : 0),
      );
    }
    return map;
  }
}
