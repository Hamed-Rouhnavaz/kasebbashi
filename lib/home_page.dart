import 'package:flutter/material.dart';

import 'cart.dart';
import 'customers_page.dart';
import 'dashboard_page.dart';
import 'pos_page.dart';
import 'products_page.dart';
import 'reports_hub_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = [
    DashboardPage(),
    PosPage(),
    ProductsPage(),
    CustomersPage(),
    ReportsHubPage(),
  ];

  /// آیکون تب فروش با تعداد اقلام سبد
  Widget _salesIcon(IconData icon) => ListenableBuilder(
        listenable: cart,
        builder: (context, _) => Badge(
          isLabelVisible: cart.count > 0,
          label: Text('${cart.count}'),
          child: Icon(icon),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'داشبورد',
            ),
            NavigationDestination(
              icon: _salesIcon(Icons.storefront_outlined),
              selectedIcon: _salesIcon(Icons.storefront),
              label: 'فروش',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'محصولات',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'مشتری‌ها',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'گزارش',
            ),
          ],
        ),
      ),
    );
  }
}
