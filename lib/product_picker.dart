import 'package:flutter/material.dart';

import 'format.dart';
import 'product.dart';
import 'product_thumb.dart';
import 'search_box.dart';
import 'text_utils.dart';

const _noCategory = 'بدون دسته‌بندی';

/// نتیجه انتخاب: محصول و (اگر داشت) گونه آن
class PickedItem {
  final Product product;
  final ProductVariant? variant;
  const PickedItem(this.product, [this.variant]);
}

/// کلید یکتا برای یک ردیف فاکتور (محصول + گونه)
String lineKey(int? productId, int? variantId) =>
    '${productId ?? 0}:${variantId ?? 0}';

Future<PickedItem?> pickProduct(
  BuildContext context,
  List<Product> products,
  Set<String> usedKeys,
) {
  return showModalBottomSheet<PickedItem>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.8,
        child: _ProductPicker(products: products, usedKeys: usedKeys),
      ),
    ),
  );
}

class _ProductPicker extends StatefulWidget {
  final List<Product> products;
  final Set<String> usedKeys;
  const _ProductPicker({required this.products, required this.usedKeys});

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  String? _category; // خالی یعنی لیست دسته‌ها
  Product? _product; // اگر پر باشد، لیست گونه‌های این محصول نمایش داده می‌شود
  String _query = '';

  String _catOf(Product p) => p.category.isEmpty ? _noCategory : p.category;

  bool _selectable(Product p) {
    if (!p.hasVariants) {
      return !widget.usedKeys.contains(lineKey(p.id, null));
    }
    return p.variants.any((v) =>
        v.stock > 0 && !widget.usedKeys.contains(lineKey(p.id, v.id)));
  }

  void _onProductTap(Product p) {
    if (p.hasVariants) {
      setState(() => _product = p);
    } else {
      Navigator.pop(context, PickedItem(p));
    }
  }

  Widget _productTile(Product p) => ListTile(
        leading: ProductThumb(p.image),
        title: Text(p.name),
        subtitle: Text(
          '${toman(p.salePrice)}  |  موجودی: ${p.stock}'
          '${p.hasVariants ? '  (${p.variants.length} گونه)' : ''}',
        ),
        trailing: p.hasVariants ? const Icon(Icons.chevron_left) : null,
        onTap: () => _onProductTap(p),
      );

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    // مرحله انتخاب گونه
    final selected = _product;
    if (selected != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => setState(() => _product = null),
                ),
                Expanded(child: Text(selected.name, style: titleStyle)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final v in selected.variants)
                  Builder(builder: (context) {
                    final used =
                        widget.usedKeys.contains(lineKey(selected.id, v.id));
                    final out = v.stock <= 0;
                    final enabled = !out && !used;
                    return ListTile(
                      enabled: enabled,
                      title: Text(v.label),
                      subtitle: Text(
                        out
                            ? 'تمام شد'
                            : used
                                ? 'در این فاکتور هست'
                                : 'موجودی: ${v.stock}',
                      ),
                      onTap: enabled
                          ? () => Navigator.pop(
                              context, PickedItem(selected, v))
                          : null,
                    );
                  }),
              ],
            ),
          ),
        ],
      );
    }

    final available = widget.products.where(_selectable).toList();
    final groups = <String, List<Product>>{};
    for (final p in available) {
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
      final results = available
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
                  child: Text(title, style: titleStyle),
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
