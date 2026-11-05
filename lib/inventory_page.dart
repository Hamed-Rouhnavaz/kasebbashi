import 'package:flutter/material.dart';

import 'db.dart';
import 'format.dart';
import 'product.dart';
import 'product_thumb.dart';
import 'widgets.dart';

const _noCategory = 'بدون دسته‌بندی';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _Group {
  final String name;
  final List<Product> products = [];
  _Group(this.name);

  int get units => products.fold<int>(0, (a, p) => a + p.stock);
  int get costValue =>
      products.fold<int>(0, (a, p) => a + p.stock * p.costPrice);
}

class _InventoryPageState extends State<InventoryPage> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.getProducts();
    if (!mounted) return;
    setState(() {
      _products = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ارزش موجودی انبار')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final units = _products.fold<int>(0, (a, p) => a + p.stock);
    final costValue =
        _products.fold<int>(0, (a, p) => a + p.stock * p.costPrice);
    final saleValue =
        _products.fold<int>(0, (a, p) => a + p.stock * p.salePrice);

    final attention = _products
        .where((p) =>
            p.active && (p.stock <= 0 || (p.stock < p.lowStock)))
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    final groupMap = <String, _Group>{};
    for (final p in _products) {
      final name = p.category.isEmpty ? _noCategory : p.category;
      groupMap.putIfAbsent(name, () => _Group(name)).products.add(p);
    }
    final groups = groupMap.values.toList()
      ..sort((a, b) => b.costValue.compareTo(a.costValue));
    for (final g in groups) {
      g.products.sort((a, b) =>
          (b.stock * b.costPrice).compareTo(a.stock * a.costPrice));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ارزش موجودی انبار')),
      body: _products.isEmpty
          ? const Center(child: Text('هنوز محصولی ثبت نشده است.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        AmountRow('تعداد انواع کالا', '${_products.length}'),
                        AmountRow('کل تعداد موجودی', '$units عدد'),
                        const Divider(),
                        AmountRow('ارزش موجودی (قیمت خرید)', toman(costValue),
                            bold: true),
                        AmountRow(
                            'ارزش موجودی (قیمت فروش)', toman(saleValue)),
                        AmountRow('سود بالقوه', toman(saleValue - costValue)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('نیاز به تأمین', style: titleStyle),
                const SizedBox(height: 4),
                Card(
                  child: attention.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('همه کالاها موجودی کافی دارند.'),
                        )
                      : Column(
                          children: [
                            for (final p in attention)
                              ListTile(
                                dense: true,
                                leading: ProductThumb(p.image, size: 40),
                                title: Text(p.name),
                                trailing: Text(
                                  p.stock <= 0
                                      ? 'تمام شد'
                                      : 'موجودی: ${p.stock}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Text('به تفکیک دسته‌بندی', style: titleStyle),
                const SizedBox(height: 4),
                for (final g in groups)
                  Card(
                    child: ExpansionTile(
                      title: Text(g.name),
                      subtitle: Text(
                          '${g.units} عدد  |  ارزش: ${toman(g.costValue)}'),
                      children: [
                        for (final p in g.products)
                          ListTile(
                            dense: true,
                            leading: ProductThumb(p.image, size: 40),
                            title: Text(p.name),
                            subtitle: Text(
                              '${p.stock} × ${toman(p.costPrice)} = '
                              '${toman(p.stock * p.costPrice)}',
                            ),
                            trailing: p.active ? null : const Text('غیرفعال'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
