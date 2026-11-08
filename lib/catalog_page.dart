import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'cart.dart';
import 'category_style.dart';
import 'checkout_page.dart';
import 'db.dart';
import 'format.dart';
import 'product.dart';
import 'product_thumb.dart';
import 'text_utils.dart';

const _noCategory = 'بدون دسته‌بندی';
const _allKey = '*';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _cart = Cart();
  final _search = TextEditingController();
  List<Product> _products = [];
  bool _loading = true;
  String? _category; // خالی یعنی شبکه دسته‌ها
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _cart.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.getProducts();
    if (!mounted) return;
    setState(() {
      _products = items;
      _loading = false;
    });
  }

  Future<void> _onBack() async {
    if (_query.isNotEmpty) {
      _search.clear();
      setState(() => _query = '');
      return;
    }
    if (_category != null) {
      setState(() => _category = null);
      return;
    }
    if (_cart.lines.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('انصراف از فروش'),
          content: const Text('سبد خرید خالی شود و از این صفحه خارج شوید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ماندن'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('خروج'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _continue() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CheckoutPage(cart: _cart)),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  // ---------- کنترل افزودن (+ یا شمارنده) ----------
  Widget _control(Product p, ProductVariant? v) {
    final stock = v?.stock ?? p.stock;
    final qty = _cart.qtyOf(p, v);
    if (stock <= 0) {
      return const Text(
        'تمام شد',
        style: TextStyle(color: AppColors.wine, fontSize: 12),
      );
    }
    if (qty == 0) {
      return IconButton.filled(
        onPressed: () => _cart.add(p, v),
        icon: const Icon(Icons.add),
      );
    }
    return _Stepper(
      qty: qty,
      onMinus: () => _cart.decrement(p, v),
      onPlus: qty < stock ? () => _cart.add(p, v) : null,
    );
  }

  void _openVariants(Product p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListenableBuilder(
          listenable: _cart,
          builder: (context, _) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      ProductThumb(p.image, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final v in p.variants)
                        ListTile(
                          title: Text(v.label),
                          subtitle: Text(
                            v.stock <= 0 ? 'تمام شد' : 'موجودی: ${v.stock}',
                          ),
                          trailing: _control(p, v),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('تأیید'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- ردیف محصول ----------
  Widget _productRow(Product p) {
    final scheme = Theme.of(context).colorScheme;
    final out = p.stock <= 0;
    final low = !out && p.stock < p.lowStock;
    final inCart = _cart.qtyOfProduct(p);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProductThumb(p.image, size: 60),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    toman(p.salePrice),
                    style: TextStyle(color: scheme.outline, fontSize: 13),
                  ),
                  if (p.hasVariants)
                    Text(
                      '${p.variants.length} گونه',
                      style: TextStyle(color: scheme.outline, fontSize: 11),
                    ),
                  if (out || low)
                    Text(
                      out ? 'تمام شد' : 'موجودی کم: ${p.stock}',
                      style: const TextStyle(
                        color: AppColors.wine,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (p.hasVariants && !out)
              Badge(
                label: Text('$inCart'),
                isLabelVisible: inCart > 0,
                child: IconButton.filled(
                  onPressed: () => _openVariants(p),
                  icon: const Icon(Icons.add),
                ),
              )
            else
              _control(p, null),
          ],
        ),
      ),
    );
  }

  Widget _productList(List<Product> list) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: list.length,
      itemBuilder: (context, i) => _productRow(list[i]),
    );
  }

  Widget _categoryGrid(
    Map<String, List<Product>> groups,
    List<String> names,
    int total,
  ) {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.88,
      children: [
        _CategoryTile(
          name: 'همه محصولات',
          count: total,
          icon: Icons.apps_rounded,
          onTap: () => setState(() => _category = _allKey),
        ),
        for (final n in names)
          _CategoryTile(
            name: n,
            count: groups[n]!.length,
            icon: n == _noCategory
                ? Icons.inventory_2_outlined
                : categoryIcon(n),
            onTap: () => setState(() => _category = n),
          ),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final active = _products.where((p) => p.active).toList();
    if (active.isEmpty) {
      return const Center(child: Text('محصول فعالی وجود ندارد'));
    }

    final q = normalizeText(_query);
    if (q.isNotEmpty) {
      final results = active
          .where((p) => normalizeText('${p.name} ${p.category}').contains(q))
          .toList();
      return results.isEmpty
          ? const Center(child: Text('محصولی پیدا نشد'))
          : _productList(results);
    }

    final groups = <String, List<Product>>{};
    for (final p in active) {
      groups
          .putIfAbsent(p.category.isEmpty ? _noCategory : p.category, () => [])
          .add(p);
    }
    final names = groups.keys.toList()
      ..sort((a, b) {
        if (a == _noCategory) return 1;
        if (b == _noCategory) return -1;
        return a.compareTo(b);
      });

    // اگر فقط یک دسته (یا هیچ) باشد، مستقیم لیست محصولات را نشان بده
    final cat = _category ?? (names.length <= 1 ? _allKey : null);
    if (cat == null) return _categoryGrid(groups, names, active.length);
    final list = cat == _allKey ? active : (groups[cat] ?? <Product>[]);
    return _productList(list);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = _category == null
        ? 'انتخاب کالا'
        : (_category == _allKey ? 'همه محصولات' : _category!);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _onBack),
          title: Text(title),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'جست‌وجوی محصول',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _cart,
                builder: (context, _) => _body(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _cart,
          builder: (context, _) {
            if (_cart.lines.isEmpty) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      Badge(
                        label: Text('${_cart.count}'),
                        child: const Icon(Icons.shopping_bag_outlined),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سبد خرید',
                              style: TextStyle(
                                  fontSize: 11, color: scheme.outline),
                            ),
                            Text(
                              toman(_cart.subtotal),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: _continue,
                        child: const Text('ادامه'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.name,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '$count محصول',
                style: TextStyle(fontSize: 10, color: scheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback? onPlus;

  const _Stepper({required this.qty, required this.onMinus, this.onPlus});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onMinus,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPlus,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
