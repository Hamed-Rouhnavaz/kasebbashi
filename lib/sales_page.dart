import 'package:flutter/material.dart';

import 'dates.dart';
import 'db.dart';
import 'format.dart';
import 'sale.dart';
import 'sale_detail_page.dart';
import 'search_box.dart';
import 'status_style.dart';
import 'text_utils.dart';

const _all = 'all';
const _unpaid = 'unpaid';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Sale> _sales = [];
  bool _loading = true;
  String _filter = _all;
  String _query = '';

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

  Future<void> _openDetail(Sale sale) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SaleDetailPage(sale: sale)),
    );
    _load();
  }

  bool _matches(Sale s, String key) {
    if (key == _all) return true;
    if (key == _unpaid) {
      return s.status != SaleStatus.canceled && s.remaining > 0;
    }
    return s.status == key;
  }

  bool _matchesQuery(Sale s) {
    final q = normalizeText(_query);
    if (q.isEmpty) return true;
    final hay = normalizeText([
      s.customerName ?? '',
      s.customerInstagram ?? '',
      s.trackingCode,
      s.note,
      for (final i in s.items) i.productName,
    ].join(' '));
    return hay.contains(q);
  }

  Widget _chip(String key, String label, Color? color) {
    final count = _sales.where((s) => _matches(s, key)).length;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        avatar: color == null
            ? null
            : CircleAvatar(radius: 6, backgroundColor: color),
        label: Text('$label ($count)'),
        selected: _filter == key,
        onSelected: (_) => setState(() => _filter = key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _sales.where((s) => _matches(s, _filter) && _matchesQuery(s)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('تاریخچه فروش')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'هنوز فروشی ثبت نکرده‌اید.\nاز تب فروش، کالا را انتخاب و ثبت کنید.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    SearchBox(
                      hint: 'جست‌وجوی مشتری، محصول یا کد رهگیری',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        children: [
                          _chip(_all, 'همه', null),
                          for (final st in SaleStatus.all)
                            _chip(st, SaleStatus.label(st), statusColor(st)),
                          _chip(_unpaid, 'دارای مانده', Colors.red),
                        ],
                      ),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('فروشی پیدا نشد'))
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: visible.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final s = visible[i];
                                final color = statusColor(s.status);
                                final canceled =
                                    s.status == SaleStatus.canceled;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        color.withValues(alpha: 0.15),
                                    child: Icon(statusIcon(s.status),
                                        color: color),
                                  ),
                                  title: Text(
                                    '${s.customerName ?? 'بدون مشتری'}  —  '
                                    '${toman(s.total)}',
                                    style: TextStyle(
                                      decoration: canceled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                                text:
                                                    '${shamsiDate(s.createdAt)}  |  '),
                                            TextSpan(
                                              text: SaleStatus.label(s.status),
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!canceled && s.remaining > 0)
                                        Text(
                                          'مانده: ${toman(s.remaining)}',
                                          style: const TextStyle(
                                              color: Colors.red),
                                        ),
                                    ],
                                  ),
                                  onTap: () => _openDetail(s),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
