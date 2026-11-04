import 'package:flutter/material.dart';

import 'db.dart';
import 'format.dart';
import 'images.dart';
import 'product.dart';
import 'product_form_page.dart';
import 'product_thumb.dart';
import 'search_box.dart';
import 'text_utils.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const int lowStockLimit = 3;

  List<Product> _products = [];
  bool _loading = true;
  String _filter = ''; // خالی یعنی همه
  String _query = '';

  List<String> get _categories {
    final set = <String>{};
    for (final p in _products) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    return set.toList()..sort();
  }

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
      if (_filter.isNotEmpty && !_categories.contains(_filter)) _filter = '';
    });
  }

  Future<void> _openForm([Product? product]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف محصول'),
        content: Text('«${product.name}» حذف شود؟'),
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
      await AppDatabase.instance.deleteProduct(product.id!);
      await ImageStore.delete(product.image);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final q = normalizeText(_query);
    final visible = _products.where((p) {
      if (_filter.isNotEmpty && p.category != _filter) return false;
      if (q.isEmpty) return true;
      return normalizeText('${p.name} ${p.category}').contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('محصولات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('محصول جدید'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Text('هنوز محصولی ثبت نکرده‌اید.\nدکمه پایین را بزنید.',
                      textAlign: TextAlign.center),
                )
              : Column(
                  children: [
                    SearchBox(
                      hint: 'جست‌وجوی محصول',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    if (categories.isNotEmpty)
                      SizedBox(
                        height: 56,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: const Text('همه'),
                                selected: _filter.isEmpty,
                                onSelected: (_) =>
                                    setState(() => _filter = ''),
                              ),
                            ),
                            for (final c in categories)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: Text(c),
                                  selected: _filter == c,
                                  onSelected: (_) =>
                                      setState(() => _filter = c),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = visible[i];
                          final low = p.stock <= lowStockLimit;
                          return ListTile(
                            leading: ProductThumb(p.image),
                            title: Text(p.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p.category.isNotEmpty)
                                  Text(p.category,
                                      style: const TextStyle(fontSize: 12)),
                                Text(
                                  '${toman(p.salePrice)}  |  موجودی: ${p.stock}'
                                  '${low ? '  (کم است!)' : ''}',
                                  style: TextStyle(
                                      color: low ? Colors.red : null),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(p),
                            ),
                            onTap: () => _openForm(p),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
