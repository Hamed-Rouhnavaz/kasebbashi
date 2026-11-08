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

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _search = TextEditingController();
  List<Product> _products = [];
  bool _loading = true;
  String _filter = ''; // خالی یعنی همه
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.getProducts();
    if (!mounted) return;
    cart.refresh(items);
    setState(() {
      _products = items;
      _loading = false;
    });
  }

  void _onAdd(Product p) {
    if (p.hasVariants) {
      _openVariants(p);
    } else {
      cart.add(p);
    }
  }

  Future<void> _continue() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CheckoutPage(cart: cart)),
    );
    if (!mounted) return;
    if (saved == true) {
      cart.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فروش ثبت شد')));
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خالی کردن سبد'),
        content: const Text('همه اقلام سبد خرید حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خالی کن'),
          ),
        ],
      ),
    );
    if (ok == true) cart.clear();
  }

  // ---------- پنجره گونه‌ها ----------
  Widget _variantControl(Product p, ProductVariant v) {
    if (v.stock <= 0) {
      return const Text(
        'تمام شد',
        style: TextStyle(color: AppColors.wine, fontSize: 12),
      );
    }
    final qty = cart.qtyOf(p, v);
    if (qty == 0) {
      return IconButton.filled(
        onPressed: () => cart.add(p, v),
        icon: const Icon(Icons.add),
      );
    }
    return _Stepper(
      qty: qty,
      onMinus: () => cart.decrement(p, v),
      onPlus: qty < v.stock ? () => cart.add(p, v) : null,
    );
  }

  void _openVariants(Product p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListenableBuilder(
          listenable: cart,
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
                          trailing: _variantControl(p, v),
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

  // ---------- ساخت صفحه ----------
  Widget _categoryChips(List<String> cats, bool showNoCat, String filter) {
    Widget chip(String key, String label, IconData? icon) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ChoiceChip(
            avatar: icon == null ? null : Icon(icon, size: 18),
            label: Text(label),
            selected: filter == key,
            onSelected: (_) => setState(() => _filter = key),
          ),
        );

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          chip('', 'همه محصولات', Icons.apps_rounded),
          for (final c in cats) chip(c, c, categoryIcon(c)),
          if (showNoCat)
            chip(_noCategory, _noCategory, Icons.inventory_2_outlined),
        ],
      ),
    );
  }

  Widget _cartBar() {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        if (cart.lines.isEmpty) return const SizedBox.shrink();
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
                    label: Text('${cart.count}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سبد خرید',
                          style:
                              TextStyle(fontSize: 11, color: scheme.outline),
                        ),
                        Text(
                          toman(cart.subtotal),
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
                    child: const Text('ثبت سفارش'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _products.where((p) => p.active).toList();
    final cats = <String>{
      for (final p in active)
        if (p.category.isNotEmpty) p.category,
    }.toList()
      ..sort();
    final showNoCat = cats.isNotEmpty && active.any((p) => p.category.isEmpty);
    final filter = (_filter.isEmpty ||
            _filter == _noCategory && showNoCat ||
            cats.contains(_filter))
        ? _filter
        : '';
    final q = normalizeText(_query);

    final visible = active.where((p) {
      if (filter == _noCategory) {
        if (p.category.isNotEmpty) return false;
      } else if (filter.isNotEmpty && p.category != filter) {
        return false;
      }
      if (q.isEmpty) return true;
      return normalizeText('${p.name} ${p.category}').contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('فروش'),
        actions: [
          ListenableBuilder(
            listenable: cart,
            builder: (context, _) => cart.lines.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'خالی کردن سبد',
                    onPressed: _confirmClear,
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : active.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'هنوز محصول فعالی ندارید.\nاز تب محصولات کالا اضافه کنید.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'جست‌وجوی محصول',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
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
                    if (cats.isNotEmpty) _categoryChips(cats, showNoCat, filter),
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('محصولی پیدا نشد'))
                          : ListenableBuilder(
                              listenable: cart,
                              builder: (context, _) => GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 24),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 140,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 0.68,
                                ),
                                itemCount: visible.length,
                                itemBuilder: (context, i) {
                                  final p = visible[i];
                                  return _ProductTile(
                                    product: p,
                                    qty: cart.qtyOfProduct(p),
                                    onAdd: () => _onAdd(p),
                                    onMinus: p.hasVariants
                                        ? null
                                        : () => cart.decrement(p),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: _cartBar(),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback? onMinus;

  const _ProductTile({
    required this.product,
    required this.qty,
    required this.onAdd,
    this.onMinus,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = product;
    final out = p.stock <= 0;
    final low = !out && p.stock < p.lowStock;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: out ? null : onAdd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LayoutBuilder(
                    builder: (context, c) =>
                        ProductThumb(p.image, size: c.maxWidth),
                  ),
                  if (out)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: const Text(
                          'تمام شد',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (p.hasVariants && !out)
                    PositionedDirectional(
                      end: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.layers_outlined,
                            size: 14, color: scheme.onSurface),
                      ),
                    ),
                  if (qty > 0)
                    PositionedDirectional(
                      start: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$qty',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (!out)
                    PositionedDirectional(
                      end: 6,
                      bottom: 6,
                      child: _RoundButton(
                        icon: Icons.add,
                        filled: true,
                        onTap: onAdd,
                      ),
                    ),
                  if (!out && qty > 0 && onMinus != null)
                    PositionedDirectional(
                      start: 6,
                      bottom: 6,
                      child: _RoundButton(
                        icon: Icons.remove,
                        filled: false,
                        onTap: onMinus!,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              toman(p.salePrice),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.outline,
                              ),
                            ),
                          ),
                        ),
                        if (low)
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.wine,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: filled ? scheme.secondary : scheme.surface,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 20,
            color: filled ? scheme.onSecondary : scheme.onSurface,
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
