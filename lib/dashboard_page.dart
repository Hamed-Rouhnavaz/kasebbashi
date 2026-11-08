import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'app_theme.dart';
import 'charts.dart';
import 'db.dart';
import 'format.dart';
import 'inventory_page.dart';
import 'jalali_utils.dart';
import 'product.dart';
import 'reports_page.dart';
import 'settings_page.dart';
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

  void _openReports() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.w700);

    final appBar = AppBar(
      title: const Text('کاسب‌باشی'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'تنظیمات',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
        const SizedBox(width: 4),
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
        stats
            .putIfAbsent(i.productName, () => _ProductStat(i.productName))
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          _HeroCard(
            title: 'فروش این ماه',
            amount: toman(monthRevenue),
            stats: [
              ('سود این ماه', toman(monthProfit)),
              ('فروش امروز', toman(todayRevenue)),
              ('تعداد فروش ماه', '${monthActive.length}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.wine,
                  title: 'طلب‌ها',
                  value: toman(totalDebt),
                  caption: 'از مشتری‌ها',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.gold,
                  title: 'کم‌موجودی',
                  value: '${attention.length} کالا',
                  caption: 'نیاز به تأمین',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نمودار فروش', style: titleStyle),
                  const SizedBox(height: 10),
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
                    color: scheme.secondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'م = میلیون تومان  |  ه = هزار تومان',
                    style: TextStyle(fontSize: 10, color: scheme.outline),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('وضعیت فروش‌های این ماه', style: titleStyle),
                  const SizedBox(height: 14),
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
                                        child: Text(SaleStatus.label(
                                            SaleStatus.all[i])),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('پرفروش‌ترین کالاهای این ماه', style: titleStyle),
                  const SizedBox(height: 14),
                  if (top.isEmpty)
                    const Text('اطلاعاتی برای نمایش نیست.')
                  else
                    for (final p in top)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(p.name)),
                                Text('${p.qty} عدد'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: p.qty / maxQty,
                              minHeight: 8,
                              color: scheme.secondary,
                              backgroundColor: scheme.outlineVariant,
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
              padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(child: Text(p.name)),
                            Text(
                              p.stock <= 0 ? 'تمام شد' : 'موجودی: ${p.stock}',
                              style: const TextStyle(color: AppColors.wine),
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
            onPressed: _openReports,
            icon: const Icon(Icons.insights_outlined),
            label: const Text('گزارش کامل و بازه زمانی'),
          ),
        ],
      ),
    );
  }
}

/// کارت اصلی تیره با اعداد طلایی
class _HeroCard extends StatelessWidget {
  final String title;
  final String amount;
  final List<(String, String)> stats;

  const _HeroCard({
    required this.title,
    required this.amount,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final hero = Theme.of(context).extension<AppHero>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [hero.top, hero.bottom],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hero.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              amount,
              style: TextStyle(
                color: hero.accent,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final s in stats)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.$1,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          s.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(caption, style: TextStyle(fontSize: 10, color: scheme.outline)),
          ],
        ),
      ),
    );
  }
}
