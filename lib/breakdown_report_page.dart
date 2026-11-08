import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'dates.dart';
import 'db.dart';
import 'format.dart';
import 'jalali_utils.dart';
import 'product.dart';
import 'range_bar.dart';
import 'sale.dart';
import 'widgets.dart';

enum BreakdownMode { product, category, customer, day, month, debt }

const _noCategory = 'بدون دسته‌بندی';

class _Row {
  final String label;
  final String sortKey;
  int count = 0;
  int revenue = 0;
  int profit = 0;
  _Row(this.label, this.sortKey);
}

class BreakdownReportPage extends StatefulWidget {
  final BreakdownMode mode;
  const BreakdownReportPage({super.key, required this.mode});

  @override
  State<BreakdownReportPage> createState() => _BreakdownReportPageState();
}

class _BreakdownReportPageState extends State<BreakdownReportPage> {
  List<Sale> _sales = [];
  Map<int?, Product> _products = {};
  bool _loading = true;
  RangeSelection _sel = const RangeSelection(RangeKind.month);

  BreakdownMode get _mode => widget.mode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sales = await AppDatabase.instance.getSales();
    final products = await AppDatabase.instance.getProducts();
    if (!mounted) return;
    setState(() {
      _sales = sales;
      _products = {for (final p in products) p.id: p};
      _loading = false;
    });
  }

  String get _title => switch (_mode) {
        BreakdownMode.product => 'فروش به تفکیک محصول',
        BreakdownMode.category => 'فروش به تفکیک دسته‌بندی',
        BreakdownMode.customer => 'فروش به تفکیک مشتری',
        BreakdownMode.day => 'فروش روزانه',
        BreakdownMode.month => 'فروش ماهانه',
        BreakdownMode.debt => 'طلب‌ها',
      };

  List<_Row> _buildRows(List<Sale> sales) {
    final map = <String, _Row>{};
    _Row row(String key, String label) =>
        map.putIfAbsent(key, () => _Row(label, key));

    for (final s in sales) {
      switch (_mode) {
        case BreakdownMode.product:
          for (final i in s.items) {
            final key = i.productId != null ? 'p:${i.productId}' : 'n:${i.productName}';
            final label = _products[i.productId]?.name ?? i.productName;
            final r = row(key, label);
            r.count += i.quantity;
            r.revenue += i.total;
            r.profit += i.quantity * (i.unitPrice - i.unitCost);
          }
        case BreakdownMode.category:
          for (final i in s.items) {
            final cat = _products[i.productId]?.category ?? '';
            final name = cat.isEmpty ? _noCategory : cat;
            final r = row(name, name);
            r.count += i.quantity;
            r.revenue += i.total;
            r.profit += i.quantity * (i.unitPrice - i.unitCost);
          }
        case BreakdownMode.customer:
          final r = row('c:${s.customerId}', s.customerName ?? 'بدون مشتری');
          r.count += 1;
          r.revenue += s.total;
          r.profit += s.profit;
        case BreakdownMode.day:
          final d = shamsiDate(s.createdAt);
          final r = row(d, d);
          r.count += 1;
          r.revenue += s.total;
          r.profit += s.profit;
        case BreakdownMode.month:
          final j = Jalali.fromDateTime(s.createdAt);
          final key = '${j.year}-${j.month.toString().padLeft(2, '0')}';
          final r = row(key, '${jalaliMonthNames[j.month - 1]} ${j.year}');
          r.count += 1;
          r.revenue += s.total;
          r.profit += s.profit;
        case BreakdownMode.debt:
          final r = row('c:${s.customerId}', s.customerName ?? 'بدون مشتری');
          r.count += 1;
          r.revenue += s.remaining;
      }
    }

    final rows = map.values.toList();
    if (_mode == BreakdownMode.day || _mode == BreakdownMode.month) {
      rows.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    } else {
      rows.sort((a, b) => b.revenue.compareTo(a.revenue));
    }
    return rows;
  }

  String _sub(_Row r) {
    switch (_mode) {
      case BreakdownMode.product:
      case BreakdownMode.category:
        return 'تعداد: ${r.count}  |  سود: ${toman(r.profit)}';
      case BreakdownMode.debt:
        return '${r.count} فروش تسویه‌نشده';
      case BreakdownMode.customer:
      case BreakdownMode.day:
      case BreakdownMode.month:
        return '${r.count} فروش  |  سود: ${toman(r.profit)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDebt = _mode == BreakdownMode.debt;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final active = _sales.where((s) => s.status != SaleStatus.canceled);
    final sales = isDebt
        ? active.where((s) => s.remaining > 0).toList()
        : active.where((s) => _sel.contains(s.createdAt)).toList();

    final rows = _buildRows(sales);
    final totalCount = rows.fold<int>(0, (a, r) => a + r.count);
    final totalRevenue = rows.fold<int>(0, (a, r) => a + r.revenue);
    final totalProfit = rows.fold<int>(0, (a, r) => a + r.profit);
    final maxRevenue =
        rows.fold<int>(0, (m, r) => r.revenue > m ? r.revenue : m);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isDebt) ...[
            RangeChips(
              value: _sel,
              onChanged: (v) => setState(() => _sel = v),
            ),
            const SizedBox(height: 8),
            Text(_sel.describe(), style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  AmountRow(
                    (_mode == BreakdownMode.product ||
                            _mode == BreakdownMode.category)
                        ? 'تعداد کالای فروخته‌شده'
                        : isDebt
                            ? 'تعداد فروش تسویه‌نشده'
                            : 'تعداد فروش',
                    '$totalCount',
                  ),
                  AmountRow(
                    isDebt ? 'جمع طلب‌ها' : 'جمع فروش',
                    toman(totalRevenue),
                    bold: true,
                    color: isDebt && totalRevenue > 0
                        ? const Color(0xFFB5485A)
                        : null,
                  ),
                  if (!isDebt) AmountRow('سود', toman(totalProfit)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('اطلاعاتی برای نمایش نیست')),
            ),
          for (final r in rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          toman(r.revenue),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: maxRevenue == 0 ? 0 : r.revenue / maxRevenue,
                      minHeight: 6,
                      color: scheme.secondary,
                      backgroundColor: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sub(r),
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                  ],
                ),
              ),
            ),
          if (_mode == BreakdownMode.product ||
              _mode == BreakdownMode.category)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'مبلغ‌های این گزارش قبل از اعمال تخفیف فاکتورها هستند.',
                style: TextStyle(fontSize: 11, color: scheme.outline),
              ),
            ),
        ],
      ),
    );
  }
}
