import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'db.dart';
import 'format.dart';
import 'images.dart';
import 'product.dart';
import 'product_thumb.dart';

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
  late final TextEditingController _category;
  late final TextEditingController _lowStock;
  late final TextEditingController _note;

  String _image = '';
  String? _sessionImage; // عکسی که در همین باز شدن فرم گرفته شده
  bool _saved = false;
  bool _active = true;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _sale = TextEditingController(text: p?.salePrice.toString() ?? '');
    _cost = TextEditingController(text: p?.costPrice.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _lowStock = TextEditingController(text: (p?.lowStock ?? 3).toString());
    _active = p?.active ?? true;
    _note = TextEditingController(text: p?.note ?? '');
    _image = p?.image ?? '';
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final products = await AppDatabase.instance.getProducts();
    final set = <String>{};
    for (final p in products) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    if (!mounted) return;
    setState(() => _categories = set.toList()..sort());
  }

  @override
  void dispose() {
    // اگر عکس تازه گرفته شده ولی ذخیره نشده، پاکش کن
    if (!_saved) ImageStore.delete(_sessionImage);
    _name.dispose();
    _sale.dispose();
    _cost.dispose();
    _stock.dispose();
    _category.dispose();
    _lowStock.dispose();
    _note.dispose();
    super.dispose();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final name = await ImageStore.pick(source);
      if (name == null) return;
      final old = _sessionImage;
      if (old != null) await ImageStore.delete(old);
      if (!mounted) {
        await ImageStore.delete(name);
        return;
      }
      setState(() {
        _image = name;
        _sessionImage = name;
      });
    } catch (_) {
      if (mounted) _msg('گرفتن عکس انجام نشد');
    }
  }

  void _removeImage() {
    ImageStore.delete(_sessionImage);
    setState(() {
      _image = '';
      _sessionImage = null;
    });
  }

  String? _requiredNumber(String? v) =>
      parseNumber(v ?? '') == null ? 'یک عدد معتبر وارد کنید' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final original = widget.product?.image ?? '';
    final product = Product(
      id: widget.product?.id,
      name: _name.text.trim(),
      salePrice: parseNumber(_sale.text)!,
      costPrice: parseNumber(_cost.text)!,
      stock: parseNumber(_stock.text)!,
      note: _note.text.trim(),
      image: _image,
      category: _category.text.trim(),
      lowStock: parseNumber(_lowStock.text) ?? 3,
      active: _active,
    );
    await AppDatabase.instance.saveProduct(product);
    if (original.isNotEmpty && original != _image) {
      await ImageStore.delete(original);
    }
    _saved = true;
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
            Center(child: ProductThumb(_image, size: 140)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('گالری'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('دوربین'),
                ),
                if (_image.isNotEmpty)
                  IconButton(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'حذف عکس',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'نام محصول'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'نام را وارد کنید' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی (اختیاری)',
                hintText: 'مثلاً لباس، لوازم آشپزخانه',
              ),
            ),
            if (_categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final c in _categories)
                      ActionChip(
                        label: Text(c),
                        onPressed: () => setState(() => _category.text = c),
                      ),
                  ],
                ),
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
              controller: _lowStock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'هشدار کمبود',
                helperText:
                    'وقتی موجودی از این عدد کمتر شد «کم است» نشان داده شود (۰ = بدون هشدار)',
                helperMaxLines: 2,
              ),
              validator: _requiredNumber,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('محصول فعال (قابل فروش)'),
              subtitle: const Text(
                  'محصول غیرفعال در «فروش جدید» نشان داده نمی‌شود'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
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
