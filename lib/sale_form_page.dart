import 'package:flutter/material.dart';

import 'customer.dart';
import 'db.dart';
import 'format.dart';
import 'product.dart';
import 'product_picker.dart';
import 'quick_customer_sheet.dart';
import 'sale.dart';
import 'widgets.dart';

class _Line {
  final Product product;
  final ProductVariant? variant;
  int qty;
  _Line(this.product, this.variant, this.qty);

  int get stock => variant?.stock ?? product.stock;
  String get name =>
      variant == null ? product.name : '${product.name} (${variant!.label})';
  String get key => lineKey(product.id, variant?.id);
}

class SaleFormPage extends StatefulWidget {
  const SaleFormPage({super.key});

  @override
  State<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends State<SaleFormPage> {
  final _discount = TextEditingController();
  final _paid = TextEditingController();
  final _note = TextEditingController();

  List<Customer> _customers = [];
  List<Product> _products = [];
  final List<_Line> _lines = [];
  int? _customerId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customers = await AppDatabase.instance.getCustomers();
    final products = await AppDatabase.instance.getProducts();
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _products = products;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _discount.dispose();
    _paid.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _subtotal =>
      _lines.fold<int>(0, (s, l) => s + l.qty * l.product.salePrice);
  int get _discountValue => parseNumber(_discount.text) ?? 0;
  int get _paidValue => parseNumber(_paid.text) ?? 0;
  int get _total => _subtotal - _discountValue;

  String get _customerLabel {
    for (final c in _customers) {
      if (c.id == _customerId) return c.name;
    }
    return 'بدون مشتری';
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickCustomer() async {
    final primary = Theme.of(context).colorScheme.primary;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.person_add, color: primary),
              title: Text(
                'مشتری جدید',
                style: TextStyle(color: primary, fontWeight: FontWeight.bold),
              ),
              onTap: () => Navigator.pop(ctx, -2),
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: const Text('بدون مشتری'),
              onTap: () => Navigator.pop(ctx, -1),
            ),
            for (final c in _customers)
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(c.name),
                subtitle: c.instagram.isEmpty ? null : Text('@${c.instagram}'),
                onTap: () => Navigator.pop(ctx, c.id!),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;

    if (picked == -2) {
      final newId = await showQuickCustomerSheet(context);
      if (newId == null) return;
      final customers = await AppDatabase.instance.getCustomers();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _customerId = newId;
      });
      return;
    }
    setState(() => _customerId = picked == -1 ? null : picked);
  }

  Future<void> _addProduct() async {
    final usedKeys = _lines.map((l) => l.key).toSet();
    final available = _products.where((p) => p.active && p.stock > 0).toList();
    if (available.isEmpty) {
      _msg('محصولی با موجودی برای افزودن وجود ندارد');
      return;
    }
    final picked = await pickProduct(context, available, usedKeys);
    if (picked != null) {
      setState(() => _lines.add(_Line(picked.product, picked.variant, 1)));
    }
  }

  Future<void> _save() async {
    if (_lines.isEmpty) {
      _msg('حداقل یک محصول اضافه کنید');
      return;
    }
    if (_discountValue < 0 || _discountValue > _subtotal) {
      _msg('مبلغ تخفیف درست نیست');
      return;
    }
    if (_paidValue < 0 || _paidValue > _total) {
      _msg('مبلغ دریافتی نمی‌تواند از مبلغ نهایی بیشتر باشد');
      return;
    }
    final sale = Sale(
      customerId: _customerId,
      createdAt: DateTime.now(),
      status: SaleStatus.preparing,
      discount: _discountValue,
      paid: _paidValue,
      note: _note.text.trim(),
      items: [
        for (final l in _lines)
          SaleItem(
            productId: l.product.id,
            variantId: l.variant?.id,
            productName: l.name,
            quantity: l.qty,
            unitPrice: l.product.salePrice,
            unitCost: l.product.costPrice,
          ),
      ],
    );
    await AppDatabase.instance.createSale(sale);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فروش جدید')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text('مشتری: $_customerLabel'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: _pickCustomer,
                  ),
                ),
                const SizedBox(height: 8),
                for (final l in _lines)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.name,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('${toman(l.product.salePrice)}  |  '
                              'موجودی: ${l.stock}'),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: l.qty > 1
                                    ? () => setState(() => l.qty--)
                                    : null,
                              ),
                              Text('${l.qty}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: l.qty < l.stock
                                    ? () => setState(() => l.qty++)
                                    : null,
                              ),
                              const Spacer(),
                              Text(toman(l.product.salePrice * l.qty)),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => _lines.remove(l)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('افزودن محصول'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'تخفیف (تومان، اختیاری)'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _paid,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'مبلغ دریافتی / بیعانه (تومان، اختیاری)'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  decoration:
                      const InputDecoration(labelText: 'توضیحات (اختیاری)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        AmountRow('جمع کل', toman(_subtotal)),
                        AmountRow('تخفیف', toman(_discountValue)),
                        AmountRow('مبلغ نهایی', toman(_total), bold: true),
                        AmountRow('دریافتی', toman(_paidValue)),
                        AmountRow('مانده', toman(_total - _paidValue),
                            color: _total - _paidValue > 0 ? Colors.red : null),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: const Text('ثبت فروش')),
              ],
            ),
    );
  }
}
