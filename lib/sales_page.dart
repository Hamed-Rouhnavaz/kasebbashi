import 'package:flutter/material.dart';

import 'dates.dart';
import 'db.dart';
import 'format.dart';
import 'sale.dart';
import 'sale_detail_page.dart';
import 'sale_form_page.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Sale> _sales = [];
  bool _loading = true;

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

  Future<void> _openForm() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SaleFormPage()),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(Sale sale) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SaleDetailPage(sale: sale)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فروش‌ها')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('فروش جدید'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? const Center(
                  child: Text('هنوز فروشی ثبت نکرده‌اید.\nدکمه پایین را بزنید.',
                      textAlign: TextAlign.center),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: _sales.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = _sales[i];
                    final canceled = s.status == SaleStatus.canceled;
                    return ListTile(
                      title: Text(
                        '${s.customerName ?? 'بدون مشتری'}  —  ${toman(s.total)}',
                        style: TextStyle(
                          decoration:
                              canceled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${shamsiDate(s.createdAt)}  |  '
                              '${SaleStatus.label(s.status)}'),
                          if (!canceled && s.remaining > 0)
                            Text(
                              'مانده: ${toman(s.remaining)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                      onTap: () => _openDetail(s),
                    );
                  },
                ),
    );
  }
}
