import 'package:flutter/material.dart';

import 'breakdown_report_page.dart';
import 'inventory_page.dart';
import 'reports_page.dart';
import 'sales_page.dart';

class ReportsHubPage extends StatelessWidget {
  const ReportsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('گزارش')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const _Section('فروش'),
          _ReportTile(
            icon: Icons.receipt_long_outlined,
            title: 'تاریخچه فروش',
            subtitle: 'همه فروش‌ها، وضعیت‌ها و جست‌وجو',
            onTap: () => open(const SalesPage()),
          ),
          _ReportTile(
            icon: Icons.insights_outlined,
            title: 'خلاصه فروش و سود',
            subtitle: 'جمع فروش، سود، پرفروش‌ها در یک بازه',
            onTap: () => open(const ReportsPage()),
          ),
          _ReportTile(
            icon: Icons.today_outlined,
            title: 'فروش روزانه',
            subtitle: 'فروش و سود هر روز',
            onTap: () =>
                open(const BreakdownReportPage(mode: BreakdownMode.day)),
          ),
          _ReportTile(
            icon: Icons.calendar_month_outlined,
            title: 'فروش ماهانه',
            subtitle: 'فروش و سود هر ماه شمسی',
            onTap: () =>
                open(const BreakdownReportPage(mode: BreakdownMode.month)),
          ),
          const _Section('تفکیک'),
          _ReportTile(
            icon: Icons.inventory_2_outlined,
            title: 'به تفکیک محصول',
            subtitle: 'کدام کالا بیشتر فروخته شده',
            onTap: () =>
                open(const BreakdownReportPage(mode: BreakdownMode.product)),
          ),
          _ReportTile(
            icon: Icons.category_outlined,
            title: 'به تفکیک دسته‌بندی',
            subtitle: 'کدام دسته بیشتر فروش داشته',
            onTap: () =>
                open(const BreakdownReportPage(mode: BreakdownMode.category)),
          ),
          _ReportTile(
            icon: Icons.people_outline,
            title: 'به تفکیک مشتری',
            subtitle: 'بهترین مشتری‌ها',
            onTap: () =>
                open(const BreakdownReportPage(mode: BreakdownMode.customer)),
          ),
          const _Section('حساب‌ها و انبار'),
          _ReportTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'طلب‌ها',
            subtitle: 'هر مشتری چقدر مانده دارد',
            onTap: () =>
                open(const BreakdownReportPage(mode: BreakdownMode.debt)),
          ),
          _ReportTile(
            icon: Icons.assessment_outlined,
            title: 'ارزش و موجودی انبار',
            subtitle: 'تعداد، ارزش و کالاهای کم‌موجود',
            onTap: () => open(const InventoryPage()),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
