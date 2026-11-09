import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'cart.dart';
import 'customer.dart';
import 'db.dart';
import 'format.dart';
import 'number_input.dart';
import 'quick_customer_sheet.dart';
import 'sale.dart';
import 'widgets.dart';

enum _PayMode { full, partial, none }

class CheckoutPage extends StatefulWidget {
  final Cart cart;
  const CheckoutPage({super.key, required this.cart});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _discount = TextEditingController();
  final _paid = TextEditingController();
  final _note = TextEditingController();

  List<Customer> _customers = [];
  int? _customerId;
  _PayMode _mode = _PayMode.full;
  bool _saving = false;

  Cart get _cart => widget.cart;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await AppDatabase.instance.getCustomers();
    if (!mounted) return;
    setState(() => _customers = customers);
  }

  @override
  void dispose() {
    _discount.dispose();
    _paid.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _subtotal => _cart.subtotal;
  int get _discountValue => parseNumber(_discount.text) ?? 0;
  int get _total => _subtotal - _discountValue;
  int get _paidValue {
    switch (_mode) {
      case _PayMode.full:
        return _total;
      case _PayMode.none:
        return 0;
      case _PayMode.partial:
        return parseNumber(_paid.text) ?? 0;
    }
  }

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

  Future<void> _save() async {
    if (_saving) return;
    if (_cart.lines.isEmpty) {
      _msg('سبد خرید خالی است');
      return;
    }
    if (_discountValue < 0 || _discountValue > _subtotal) {
      _msg('مبلغ تخفیف درست نیست');
      return;
    }
    final paid = _paidValue;
    if (paid < 0 || paid > _total) {
      _msg('مبلغ دریافتی نمی‌تواند از مبلغ نهایی بیشتر باشد');
      return;
    }
    setState(() => _saving = true);
    final sale = Sale(
      customerId: _customerId,
      createdAt: DateTime.now(),
      status: SaleStatus.preparing,
      discount: _discountValue,
      paid: paid,
      note: _note.text.trim(),
      items: [
        for (final l in _cart.lines)
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
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.w700);

    return Scaffold(
      appBar: AppBar(title: const Text('تسویه و ثبت فروش')),
      body: ListenableBuilder(
        listenable: _cart,
        builder: (context, _) {
          if (_cart.lines.isEmpty) {
            return const Center(child: Text('سبد خرید خالی است'));
          }
          final remaining = _total - _paidValue;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('سبد خرید', style: titleStyle),
              const SizedBox(height: 8),
              for (final l in _cart.lines)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${toman(l.product.salePrice)} × ${l.qty} = '
                                '${toman(l.total)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _cart.decrement(l.product, l.variant),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('${l.qty}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: l.qty < l.stock
                              ? () => _cart.add(l.product, l.variant)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _cart.remove(l),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('افزودن کالای بیشتر'),
                ),
              ),
              const SizedBox(height: 8),
              Text('مشتری', style: titleStyle),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(_customerLabel),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _pickCustomer,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _discount,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'تخفیف (تومان، اختیاری)',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Text('پرداخت', style: titleStyle),
              const SizedBox(height: 8),
              SegmentedButton<_PayMode>(
                segments: const [
                  ButtonSegment(
                    value: _PayMode.full,
                    label: Text('تسویه کامل'),
                  ),
                  ButtonSegment(
                    value: _PayMode.partial,
                    label: Text('بیعانه'),
                  ),
                  ButtonSegment(
                    value: _PayMode.none,
                    label: Text('بدون پرداخت'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 12),
              if (_mode == _PayMode.partial)
                TextField(
                  controller: _paid,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'مبلغ دریافتی (تومان)',
                  ),
                  onChanged: (_) => setState(() {}),
                )
              else if (_mode == _PayMode.full)
                Text(
                  'کل مبلغ (${toman(_total)}) دریافت شده است.',
                  style: TextStyle(fontSize: 12, color: scheme.outline),
                )
              else
                Text(
                  'مبلغی دریافت نشده و کل مبلغ به‌عنوان مانده ثبت می‌شود.',
                  style: TextStyle(fontSize: 12, color: scheme.outline),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'توضیحات (اختیاری)'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      AmountRow('جمع کل', toman(_subtotal)),
                      AmountRow('تخفیف', toman(_discountValue)),
                      AmountRow('مبلغ نهایی', toman(_total), bold: true),
                      AmountRow('دریافتی', toman(_paidValue)),
                      AmountRow(
                        'مانده',
                        toman(remaining),
                        color: remaining > 0 ? AppColors.wine : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('ثبت فروش'),
              ),
            ],
          );
        },
      ),
    );
  }
}
