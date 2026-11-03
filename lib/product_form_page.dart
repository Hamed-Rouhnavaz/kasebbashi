import 'package:flutter/material.dart';

import 'db.dart';
import 'format.dart';
import 'product.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sale;
  late final TextEditingController _cost;
  late final TextEditingController _stock;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _sale = TextEditingController(text: p?.salePrice.toString() ?? '');
    _cost = TextEditingController(text: p?.costPrice.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '');
    _note = TextEditingController(text: p?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _sale.dispose();
    _cost.dispose();
    _stock.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _requiredNumber(String? v) =>
      parseNumber(v ?? '') == null ? 'یک عدد معتبر وارد کنید' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final product = Product(
      id: widget.product?.id,
      name: _name.text.trim(),
      salePrice: parseNumber(_sale.text)!,
      costPrice: parseNumber(_cost.text)!,
      stock: parseNumber(_stock.text)!,
      note: _note.text.trim(),
    );
    await AppDatabase.instance.saveProduct(product);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'ویرایش محصول' : 'محصول جدید')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'نام محصول'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'نام را وارد کنید' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sale,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'قیمت فروش (تومان)'),
              validator: _requiredNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'قیمت خرید (تومان)'),
              validator: _requiredNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'موجودی'),
              validator: _requiredNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration:
                  const InputDecoration(labelText: 'توضیحات (اختیاری)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('ذخیره')),
          ],
        ),
      ),
    );
  }
}
