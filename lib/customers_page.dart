import 'package:flutter/material.dart';

import 'customer.dart';
import 'customer_form_page.dart';
import 'customer_stats.dart';
import 'db.dart';
import 'format.dart';
import 'search_box.dart';
import 'text_utils.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Customer> _customers = [];
  Map<int, CustomerStat> _stats = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.getCustomers();
    final stats = await AppDatabase.instance.customerStats();
    if (!mounted) return;
    setState(() {
      _customers = items;
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _openForm([Customer? customer]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomerFormPage(customer: customer)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Customer customer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مشتری'),
        content: Text('«${customer.name}» حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AppDatabase.instance.deleteCustomer(customer.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = normalizeText(_query);
    final visible = _customers.where((c) {
      if (q.isEmpty) return true;
      return normalizeText('${c.name} ${c.instagram} ${c.phone}').contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('مشتری‌ها')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('مشتری جدید'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? const Center(
                  child: Text('هنوز مشتری‌ای ثبت نکرده‌اید.\nدکمه پایین را بزنید.',
                      textAlign: TextAlign.center),
                )
              : Column(
                  children: [
                    SearchBox(
                      hint: 'جست‌وجوی نام، آیدی یا شماره',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('مشتری‌ای پیدا نشد'))
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 90),
                              itemCount: visible.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final c = visible[i];
                                final stat = _stats[c.id];
                                final details = [
                                  if (c.instagram.isNotEmpty) '@${c.instagram}',
                                  if (c.phone.isNotEmpty) c.phone,
                                ].join('  |  ');
                                return ListTile(
                                  leading: const CircleAvatar(
                                      child: Icon(Icons.person)),
                                  title: Text(c.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (details.isNotEmpty) Text(details),
                                      Text(
                                        stat == null
                                            ? 'هنوز خریدی نداشته'
                                            : '${stat.count} خرید  |  '
                                                'جمع: ${toman(stat.total)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: stat == null
                                              ? null
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(c),
                                  ),
                                  onTap: () => _openForm(c),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
