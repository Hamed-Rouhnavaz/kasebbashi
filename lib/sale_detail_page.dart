import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dates.dart';
import 'db.dart';
import 'format.dart';
import 'sale.dart';
import 'widgets.dart';

class SaleDetailPage extends StatefulWidget {
  final Sale sale;
  const SaleDetailPage({super.key, required this.sale});

  @override
  State<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends State<SaleDetailPage> {
  late Sale _sale;
  late final TextEditingController _tracking;

  @override
  void initState() {
    super.initState();
    _sale = widget.sale;
    _tracking = TextEditingController(text: _sale.trackingCode);
  }

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _reload() async {
    final fresh = await AppDatabase.instance.getSale(_sale.id!);
    if (!mounted) return;
    if (fresh != null) setState(() => _sale = fresh);
  }

  Future<void> _changeStatus(String status) async {
    await AppDatabase.instance.updateSaleStatus(_sale, status);
    await _reload();
  }

  Future<void> _saveTracking() async {
    await AppDatabase.instance
        .updateSaleFields(_sale.id!, {'tracking_code': _tracking.text.trim()});
    await _reload();
    if (!mounted) return;
    _msg('کد رهگیری ذخیره شد');
  }

  Future<void> _addPayment() async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ثبت پرداخت جدید'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'مبلغ (تومان)',
            helperText: 'مانده: ${toman(_sale.remaining)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, parseNumber(controller.text)),
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (amount == null || amount <= 0) return;
    if (amount > _sale.remaining) {
      _msg('مبلغ از مانده بیشتر است');
      return;
    }
    await AppDatabase.instance
        .updateSaleFields(_sale.id!, {'paid': _sale.paid + amount});
    await _reload();
  }

  String _invoiceText() {
    final b = StringBuffer();
    b.writeln('فاکتور کاسب‌باشی');
    if (_sale.customerName != null) b.writeln('مشتری: ${_sale.customerName}');
    b.writeln('تاریخ: ${shamsiDate(_sale.createdAt)}');
    b.writeln('------------------');
    var n = 1;
    for (final i in _sale.items) {
      b.writeln('$n) ${i.productName}  ${i.quantity} × ${toman(i.unitPrice)}'
          ' = ${toman(i.total)}');
      n++;
    }
    b.writeln('------------------');
    b.writeln('جمع: ${toman(_sale.subtotal)}');
    if (_sale.discount > 0) b.writeln('تخفیف: ${toman(_sale.discount)}');
    b.writeln('مبلغ نهایی: ${toman(_sale.total)}');
    b.writeln('دریافتی: ${toman(_sale.paid)}');
    if (_sale.remaining > 0) b.writeln('مانده: ${toman(_sale.remaining)}');
    if (_sale.trackingCode.isNotEmpty) {
      b.writeln('کد رهگیری: ${_sale.trackingCode}');
    }
    return b.toString().trim();
  }

  Future<void> _copyInvoice() async {
    await Clipboard.setData(ClipboardData(text: _invoiceText()));
    if (!mounted) return;
    _msg('متن فاکتور کپی شد');
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف فروش'),
        content: const Text('این فروش حذف شود؟ موجودی کالاها به انبار برمی‌گردد.'),
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
    if (ok != true) return;
    await AppDatabase.instance.deleteSale(_sale);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = _sale;
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات فروش'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(s.customerName ?? 'بدون مشتری'),
              subtitle: Text([
                shamsiDateTime(s.createdAt),
                if ((s.customerInstagram ?? '').isNotEmpty)
                  '@${s.customerInstagram}',
              ].join('  |  ')),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final i in s.items)
                    AmountRow(
                      '${i.productName}  (${i.quantity} × ${toman(i.unitPrice)})',
                      toman(i.total),
                    ),
                  const Divider(),
                  AmountRow('جمع کل', toman(s.subtotal)),
                  if (s.discount > 0) AmountRow('تخفیف', toman(s.discount)),
                  AmountRow('مبلغ نهایی', toman(s.total), bold: true),
                  AmountRow('دریافتی', toman(s.paid)),
                  AmountRow('مانده', toman(s.remaining),
                      color: s.remaining > 0 ? Colors.red : null),
                  AmountRow('سود این فروش', toman(s.profit)),
                ],
              ),
            ),
          ),
          if (s.remaining > 0 && s.status != SaleStatus.canceled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _addPayment,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('ثبت پرداخت جدید'),
              ),
            ),
          const SizedBox(height: 16),
          Text('وضعیت سفارش',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final st in SaleStatus.all)
                ChoiceChip(
                  label: Text(SaleStatus.label(st)),
                  selected: s.status == st,
                  onSelected: (_) => _changeStatus(st),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'با لغو سفارش، موجودی کالاها به انبار برمی‌گردد.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tracking,
                  decoration:
                      const InputDecoration(labelText: 'کد رهگیری پست'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _saveTracking,
                child: const Text('ذخیره'),
              ),
            ],
          ),
          if (s.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('توضیحات: ${s.note}'),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _copyInvoice,
            icon: const Icon(Icons.copy),
            label: const Text('کپی متن فاکتور'),
          ),
        ],
      ),
    );
  }
}
