import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'charts.dart';
import 'db.dart';
import 'format.dart';
import 'inventory_page.dart';
import 'jalali_utils.dart';
import 'product.dart';
import 'reports_page.dart';
import 'sale.dart';
import 'status_style.dart';

class _ProductStat {
  final String name;
  int qty = 0;
  _ProductStat(this.name);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _weekLetters = ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'];

  List<Sale> _sales = [];
  List<Product> _products = [];
  bool _loading = true;
  bool _monthly = false; // false = ۷ روز اخیر، true = ۶ ماه اخیر

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
      _products = products;
      _loading = false;
    });
  }

  int _sumTotal(Iterable<Sale> sales) =>
      sales.fold<int>(0, (a, s) => a + s.total);

  List<BarItem> _weekBars(List<Sale> active, DateTime today) {
    final items = <BarItem>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day - i);
      final value = _sumTotal(active.where((s) =>
          s.createdAt.year == day.year &&
          s.createdAt.month == day.month &&
          s.createdAt.day == day.day));
      items.add(BarItem(
        _weekLetters[day.weekday - 1],
        '${Jalali.fromDateTime(day).day}',
        value,
      ));
    }
    return items;
  }

  List<BarItem> _monthBars(List<Sale> active, Jalali now) {
    final buckets = <(int, int)>[];
    var y = now.year;
    var m = now.month;
    for (var i = 0; i < 6; i++) {
      buckets.add((y, m));
      m--;
      if (m == 0) {
        m = 12;
        y--;
      }
    }
    final items = <BarItem>[];
    for (final (by, bm) in buckets.reversed) {
      final start = jalaliStart(by, bm, 1);
      final end = nextJalaliMonthStart(by, bm);
      final value = _sumTotal(active.where(
          (s) => !s.createdAt.isBefore(start) && s.createdAt.isBefore(end)));
      items.add(BarItem(jalaliMonthNames[bm - 1], '', value));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final primary = Theme.of(context).colorScheme.primary;

    final appBar = AppBar(
      title: const Text('داشبورد'),
      actions: [
        IconButton(
          icon: const Icon(Icons.insights),
          tooltip: 'گزارش‌ها',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ReportsPage())),
        ),
      ],
    );

    if (_loading) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final jNow = Jalali.fromDateTime(now);
    final monthStart = jalaliStart(jNow.year, jNow.month, 1);

    final active =
        _sales.where((s) => s.status != SaleStatus.canceled).toList();
    final todaySales =
        active.where((s) => !s.createdAt.isBefore(today)).toList();
    final monthActive =
        active.where((s) => !s.createdAt.isBefore(monthStart)).toList();
    final monthAll =
        _sales.where((s) => !s.createdAt.isBefore(monthStart)).toList();

    final todayRevenue = _sumTotal(todaySales);
    final monthRevenue = _sumTotal(monthActive);
    final monthProfit = monthActive.fold<int>(0, (a, s) => a + s.profit);
    final totalDebt = active.fold<int>(
        0, (a, s) => a + (s.remaining > 0 ? s.remaining : 0));

    final attention = _products
        .where((p) => p.active && (p.stock <= 0 || p.stock < p.lowStock))
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    // پرفروش‌ترین کالاهای این ماه
    final stats = <String, _ProductStat>{};
    for (final s in monthActive) {
      for (final i in s.items) {
        stats.putIfAbsent(i.productName, () => _ProductStat(i.productName))
            .qty += i.quantity;
      }
    }
    final top = (stats.values.toList()..sort((a, b) => b.qty.compareTo(a.qty)))
        .take(5)
        .toList();
    final maxQty = top.isEmpty ? 1 : top.first.qty;

    // وضعیت فروش‌های این ماه
    final statusCounts = [
      for (final st in SaleStatus.all)
        monthAll.where((s) => s.status == st).length,
    ];

    return Scaffold(
      appBar: appBar,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.today,
                  color: Colors.teal,
                  title: 'فروش امروز',
                  value: toman(todayRevenue),
                  caption: '${todaySales.length} فروش',
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_month,
                  color: Colors.indigo,
                  title: 'فروش این ماه',
                  value: toman(monthRevenue),
                  caption: '${monthActive.length} فروش',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.trending_up,
                  color: Colors.green,
                  title: 'سود این ماه',
                  value: toman(monthProfit),
                  caption: 'بر اساس قیمت خرید',
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.red,
                  title: 'طلب‌ها',
                  value: toman(totalDebt),
                  caption: 'از مشتری‌ها',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نمودار فروش', style: titleStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('۷ روز اخیر'),
                        selected: !_monthly,
                        onSelected: (_) => setState(() => _monthly = false),
                      ),
                      ChoiceChip(
                        label: const Text('۶ ماه اخیر'),
                        selected: _monthly,
                        onSelected: (_) => setState(() => _monthly = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BarChartView(
                    items: _monthly
                        ? _monthBars(active, jNow)
                        : _weekBars(active, today),
                    color: primary,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'م = میلیون تومان  |  ه = هزار تومان',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('وضعیت فروش‌های این ماه', style: titleStyle),
                  const SizedBox(height: 12),
                  if (monthAll.isEmpty)
                    const Text('این ماه هنوز فروشی ثبت نشده است.')
                  else
                    Row(
                      children: [
                        DonutChart(
                          values: [for (final c in statusCounts) c.toDouble()],
                          colors: [
                            for (final st in SaleStatus.all) statusColor(st),
                          ],
                          center: Text(
                            '${monthAll.length}\nفروش',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              for (var i = 0; i < SaleStatus.all.length; i++)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: statusColor(SaleStatus.all[i]),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                            SaleStatus.label(SaleStatus.all[i])),
                                      ),
                                      Text('${statusCounts[i]}'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('پرفروش‌ترین کالاهای این ماه', style: titleStyle),
                  const SizedBox(height: 12),
                  if (top.isEmpty)
                    const Text('اطلاعاتی برای نمایش نیست.')
                  else
                    for (final p in top)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(p.name)),
                                Text('${p.qty} عدد'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: p.qty / maxQty,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('کم‌موجودی', style: titleStyle),
                  const SizedBox(height: 8),
                  if (attention.isEmpty)
                    const Text('همه کالاها موجودی کافی دارند.')
                  else
                    for (final p in attention.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text(p.name)),
                            Text(
                              p.stock <= 0 ? 'تمام شد' : 'موجودی: ${p.stock}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  if (attention.length > 5)
                    Text('و ${attention.length - 5} مورد دیگر',
                        style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const InventoryPage()),
                    ),
                    icon: const Icon(Icons.assessment_outlined),
                    label: const Text('ارزش و موجودی انبار'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReportsPage())),
            icon: const Icon(Icons.insights),
            label: const Text('گزارش کامل و بازه زمانی'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String caption;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(caption,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
