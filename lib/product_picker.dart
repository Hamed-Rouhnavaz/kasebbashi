import 'package:flutter/material.dart';

import 'format.dart';
import 'product.dart';
import 'product_thumb.dart';
import 'search_box.dart';
import 'text_utils.dart';

const _noCategory = 'بدون دسته‌بندی';

Future<Product?> pickProduct(BuildContext context, List<Product> products) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.8,
        child: _ProductPicker(products: products),
      ),
    ),
  );
}

class _ProductPicker extends StatefulWidget {
  final List<Product> products;
  const _ProductPicker({required this.products});

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  String? _category; // خالی یعنی لیست دسته‌ها نمایش داده شود
  String _query = '';

  String _catOf(Product p) => p.category.isEmpty ? _noCategory : p.category;

  Widget _productTile(Product p) => ListTile(
        leading: ProductThumb(p.image),
        title: Text(p.name),
        subtitle: Text('${toman(p.salePrice)}  |  موجودی: ${p.stock}'),
        onTap: () => Navigator.pop(context, p),
      );

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Product>>{};
    for (final p in widget.products) {
      groups.putIfAbsent(_catOf(p), () => []).add(p);
    }
    final names = groups.keys.toList()
      ..sort((a, b) {
        if (a == _noCategory) return 1;
        if (b == _noCategory) return -1;
        return a.compareTo(b);
      });
    final onlyUncategorized = names.length == 1 && names.first == _noCategory;
    final q = normalizeText(_query);

    var title = 'انتخاب محصول';
    final Widget body;
    if (q.isNotEmpty) {
      final results = widget.products
          .where((p) => normalizeText('${p.name} ${p.category}').contains(q))
          .toList();
      body = results.isEmpty
          ? const Center(child: Text('محصولی پیدا نشد'))
          : ListView(children: [for (final p in results) _productTile(p)]);
    } else if (_category != null || onlyUncategorized) {
      final cat = _category ?? _noCategory;
      if (!onlyUncategorized) title = cat;
      body = ListView(
        children: [for (final p in groups[cat] ?? <Product>[]) _productTile(p)],
      );
    } else {
      body = ListView(
        children: [
          for (final n in names)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(n),
              trailing: Text('${groups[n]!.length} محصول'),
              onTap: () => setState(() => _category = n),
            ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              if (_category != null && q.isEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => setState(() => _category = null),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
            ],
          ),
        ),
        SearchBox(
          hint: 'جست‌وجوی محصول',
          onChanged: (v) => setState(() => _query = v),
        ),
        Expanded(child: body),
      ],
    );
  }
}
