import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'db.dart';
import 'format.dart';
import 'sale.dart';
import 'widgets.dart';

enum _Range { today, week, month, all }

const _rangeLabels = {
  _Range.today: 'امروز',
  _Range.week: '۷ روز اخیر',
  _Range.month: 'این ماه',
  _Range.all: 'همه',
};

class _ProductStat {
  final String name;
  int qty = 0;
  int revenue = 0;
  _ProductStat(this.name);
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Sale> _sales = [];
  bool _loading = true;
  _Range _range = _Range.month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.getSales();
    if (!mounted) return;
    setState(() {
      _sales = items;
      _loading = false;
    });
  }

  DateTime? _startOf(_Range range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (range == _Range.today) return today;
    if (range == _Range.week) return today.subtract(const Duration(days: 6));
    if (range == _Range.month) {
      final j = Jalali.fromDateTime(now);
      return Jalali(j.year, j.month, 1).toDateTime();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('گزارش‌ها')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // فروش‌های بازه انتخاب‌شده (بدون لغوشده‌ها)
    final start = _startOf(_range);
    final sales = _sales
        .where((s) =>
            s.status != SaleStatus.canceled &&
            (start == null || !s.createdAt.isBefore(start)))
        .toList();

    final revenue = sales.fold<int>(0, (a, s) => a + s.total);
    final paid = sales.fold<int>(0, (a, s) => a + s.paid);
    final remaining = revenue - paid;
    final profit = sales.fold<int>(0, (a, s) => a + s.profit);
    final average = sales.isEmpty ? 0 : (revenue / sales.length).round();

    // پرفروش‌ترین کالاها
    final stats = <String, _ProductStat>{};
    for (final s in sales) {
      for (final i in s.items) {
        final st = stats.putIfAbsent(i.productName, () => _ProductStat(i.productName));
        st.qty += i.quantity;
        st.revenue += i.total;
      }
    }
    final top = stats.values.toList()..sort((a, b) => b.qty.compareTo(a.qty));

    // طلب‌ها (کل زمان، بدون لغوشده‌ها)
    final debts = <String, int>{};
    for (final s in _sales) {
      if (s.status == SaleStatus.canceled || s.remaining <= 0) continue;
      final key = s.customerName ?? 'بدون مشتری';
      debts[key] = (debts[key] ?? 0) + s.remaining;
    }
    final debtList = debts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalDebt = debtList.fold<int>(0, (a, e) => a + e.value);

    return Scaffold(
      appBar: AppBar(title: const Text('گزارش‌ها')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final r in _Range.values)
                ChoiceChip(
                  label: Text(_rangeLabels[r]!),
                  selected: _range == r,
                  onSelected: (_) => setState(() => _range = r),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: sales.isEmpty
                  ? const Text('در این بازه فروشی ثبت نشده است.')
                  : Column(
                      children: [
                        AmountRow('تعداد فروش', '${sales.length}'),
                        AmountRow('جمع فروش', toman(revenue), bold: true),
                        AmountRow('دریافت‌شده', toman(paid)),
                        AmountRow('مانده از مشتری‌ها', toman(remaining),
                            color: remaining > 0 ? Colors.red : null),
                        const Divider(),
                        AmountRow('سود', toman(profit), bold: true),
                        AmountRow('میانگین هر فروش', toman(average)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text('پرفروش‌ترین کالاها', style: titleStyle),
          const SizedBox(height: 4),
          Card(
            child: top.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('اطلاعاتی برای نمایش نیست.'),
                  )
                : Column(
                    children: [
                      for (final p in top.take(5))
                        ListTile(
                          dense: true,
                          title: Text(p.name),
                          subtitle: Text('تعداد: ${p.qty}  |  '
                              'فروش: ${toman(p.revenue)}'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Text('طلب‌ها (کل زمان)', style: titleStyle),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: debtList.isEmpty
                  ? const Text('طلب باز ندارید. همه تسویه‌اند.')
                  : Column(
                      children: [
                        AmountRow('جمع کل طلب‌ها', toman(totalDebt),
                            bold: true, color: Colors.red),
                        const Divider(),
                        for (final e in debtList.take(10))
                          AmountRow(e.key, toman(e.value)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
