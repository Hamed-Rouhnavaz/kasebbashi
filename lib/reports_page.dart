import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'dates.dart';
import 'db.dart';
import 'format.dart';
import 'jalali_utils.dart';
import 'sale.dart';
import 'widgets.dart';

enum _Range { today, week, month, lastMonth, all, custom }

const _rangeLabels = {
  _Range.today: 'امروز',
  _Range.week: '۷ روز اخیر',
  _Range.month: 'این ماه',
  _Range.lastMonth: 'ماه قبل',
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
  DateTime? _from;
  DateTime? _to;

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

  /// (شروع، پایان) بازه انتخاب‌شده. پایان باز نیست (exclusive).
  (DateTime?, DateTime?) _bounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case _Range.today:
        return (today, null);
      case _Range.week:
        return (DateTime(today.year, today.month, today.day - 6), null);
      case _Range.month:
        {
          final j = Jalali.fromDateTime(now);
          return (jalaliStart(j.year, j.month, 1), null);
        }
      case _Range.lastMonth:
        {
          final j = Jalali.fromDateTime(now);
          var y = j.year;
          var m = j.month - 1;
          if (m == 0) {
            m = 12;
            y--;
          }
          return (jalaliStart(y, m, 1), jalaliStart(j.year, j.month, 1));
        }
      case _Range.all:
        return (null, null);
      case _Range.custom:
        {
          final f = _from;
          final t = _to;
          if (f == null || t == null) return (null, null);
          return (f, DateTime(t.year, t.month, t.day + 1));
        }
    }
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = await pickJalaliDate(
      context,
      initial: _from ?? DateTime(today.year, today.month, today.day - 6),
      title: 'از تاریخ',
    );
    if (from == null || !mounted) return;
    final to = await pickJalaliDate(
      context,
      initial: _to ?? today,
      title: 'تا تاریخ',
    );
    if (to == null || !mounted) return;
    setState(() {
      _range = _Range.custom;
      if (to.isBefore(from)) {
        _from = to;
        _to = from;
      } else {
        _from = from;
        _to = to;
      }
    });
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

    final (start, end) = _bounds();
    final sales = _sales
        .where((s) =>
            s.status != SaleStatus.canceled &&
            (start == null || !s.createdAt.isBefore(start)) &&
            (end == null || s.createdAt.isBefore(end)))
        .toList();

    final rangeText = start == null
        ? 'کل زمان'
        : 'از ${shamsiDate(start)} تا '
            '${shamsiDate(end == null ? DateTime.now() : end.subtract(const Duration(days: 1)))}';

    final revenue = sales.fold<int>(0, (a, s) => a + s.total);
    final paid = sales.fold<int>(0, (a, s) => a + s.paid);
    final remaining = revenue - paid;
    final profit = sales.fold<int>(0, (a, s) => a + s.profit);
    final average = sales.isEmpty ? 0 : (revenue / sales.length).round();

    // پرفروش‌ترین کالاها
    final stats = <String, _ProductStat>{};
    for (final s in sales) {
      for (final i in s.items) {
        final st =
            stats.putIfAbsent(i.productName, () => _ProductStat(i.productName));
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

    final customLabel = (_range == _Range.custom && _from != null && _to != null)
        ? '${shamsiDate(_from!)} تا ${shamsiDate(_to!)}'
        : 'بازه دلخواه';

    return Scaffold(
      appBar: AppBar(title: const Text('گزارش‌ها')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final r in _rangeLabels.keys)
                ChoiceChip(
                  label: Text(_rangeLabels[r]!),
                  selected: _range == r,
                  onSelected: (_) => setState(() => _range = r),
                ),
              ChoiceChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(customLabel),
                selected: _range == _Range.custom,
                onSelected: (_) => _pickCustom(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(rangeText, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
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
