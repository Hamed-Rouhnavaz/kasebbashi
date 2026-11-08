import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'db.dart';
import 'format.dart';
import 'images.dart';
import 'number_input.dart';
import 'product.dart';
import 'product_thumb.dart';
import 'text_utils.dart';

/// یک ردیف از ویرایشگر گونه‌ها
class _Row {
  final int? id;
  final TextEditingController size;
  final TextEditingController color;
  final TextEditingController stock;

  _Row({this.id, String size = '', String color = '', String stock = ''})
      : size = TextEditingController(text: size),
        color = TextEditingController(text: color),
        stock = TextEditingController(text: stock);

  void dispose() {
    size.dispose();
    color.dispose();
    stock.dispose();
  }
}

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
  bool _hasVariants = false;
  final List<_Row> _rows = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _sale = TextEditingController(
        text: p == null ? '' : groupInt(p.salePrice));
    _cost = TextEditingController(
        text: p == null ? '' : groupInt(p.costPrice));
    _stock = TextEditingController(text: p?.stock.toString() ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _lowStock = TextEditingController(text: (p?.lowStock ?? 3).toString());
    _note = TextEditingController(text: p?.note ?? '');
    _image = p?.image ?? '';
    _active = p?.active ?? true;
    for (final v in p?.variants ?? const <ProductVariant>[]) {
      _rows.add(_Row(
        id: v.id,
        size: v.size,
        color: v.color,
        stock: v.stock.toString(),
      ));
    }
    _hasVariants = _rows.isNotEmpty;
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
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  int get _variantsTotal =>
      _rows.fold<int>(0, (a, r) => a + (parseNumber(r.stock.text) ?? 0));

  // ---------- عکس ----------
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

  // ---------- گونه‌ها ----------
  void _toggleVariants(bool on) {
    setState(() {
      _hasVariants = on;
      if (on && _rows.isEmpty) {
        _rows.add(_Row(stock: _stock.text));
      }
      if (!on) {
        _stock.text = '$_variantsTotal';
      }
    });
  }

  void _addRow() => setState(() => _rows.add(_Row(stock: '0')));

  void _removeRow(int index) {
    final row = _rows.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
  }

  List<String> _split(String text) => text
      .split(RegExp(r'[,\n،;؛]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _quickAdd() async {
    final sizes = TextEditingController();
    final colors = TextEditingController();
    final stock = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ساخت سریع گونه‌ها'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sizes,
                decoration: const InputDecoration(
                  labelText: 'سایزها (اختیاری)',
                  helperText: 'با ویرگول جدا کنید: 10, 20, 30, 40',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colors,
                decoration: const InputDecoration(
                  labelText: 'رنگ‌ها (اختیاری)',
                  helperText: 'مثلاً: آبی، صورتی، قرمز',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'موجودی هر گونه'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ساخت'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final sizeList = _split(sizes.text);
    final colorList = _split(colors.text);
    final count = parseNumber(stock.text) ?? 0;
    if (sizeList.isEmpty && colorList.isEmpty) {
      _msg('حداقل یک سایز یا رنگ وارد کنید');
      return;
    }
    final existing = {
      for (final r in _rows)
        '${normalizeText(r.size.text)}|${normalizeText(r.color.text)}',
    };
    setState(() {
      for (final s in sizeList.isEmpty ? [''] : sizeList) {
        for (final c in colorList.isEmpty ? [''] : colorList) {
          final key = '${normalizeText(s)}|${normalizeText(c)}';
          if (existing.add(key)) {
            _rows.add(_Row(size: s, color: c, stock: '$count'));
          }
        }
      }
    });
  }

  String? _requiredNumber(String? v) =>
      parseNumber(v ?? '') == null ? 'یک عدد معتبر وارد کنید' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final variants = <ProductVariant>[];
    if (_hasVariants) {
      if (_rows.isEmpty) {
        _msg('حداقل یک گونه اضافه کنید');
        return;
      }
      final seen = <String>{};
      for (final r in _rows) {
        final s = r.size.text.trim();
        final c = r.color.text.trim();
        if (s.isEmpty && c.isEmpty) {
          _msg('هر گونه باید سایز یا رنگ داشته باشد');
          return;
        }
        final stockText = r.stock.text.trim().isEmpty ? '0' : r.stock.text;
        final stock = parseNumber(stockText);
        if (stock == null || stock < 0) {
          _msg('موجودی گونه‌ها باید عدد معتبر باشد');
          return;
        }
        if (!seen.add('${normalizeText(s)}|${normalizeText(c)}')) {
          _msg('گونه تکراری وجود دارد');
          return;
        }
        variants.add(ProductVariant(id: r.id, size: s, color: c, stock: stock));
      }
    }

    final original = widget.product?.image ?? '';
    final product = Product(
      id: widget.product?.id,
      name: _name.text.trim(),
      salePrice: parseNumber(_sale.text)!,
      costPrice: parseNumber(_cost.text)!,
      stock: _hasVariants ? _variantsTotal : parseNumber(_stock.text)!,
      note: _note.text.trim(),
      image: _image,
      category: _category.text.trim(),
      lowStock: parseNumber(_lowStock.text) ?? 3,
      active: _active,
      variants: variants,
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
    final scheme = Theme.of(context).colorScheme;
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
              inputFormatters: [ThousandsInputFormatter()],
              decoration:
                  const InputDecoration(labelText: 'قیمت فروش (تومان)'),
              validator: _requiredNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              decoration:
                  const InputDecoration(labelText: 'قیمت خرید (تومان)'),
              validator: _requiredNumber,
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('این محصول سایز یا رنگ دارد'),
              subtitle: const Text('هر سایز یا رنگ، موجودی جداگانه دارد'),
              value: _hasVariants,
              onChanged: _toggleVariants,
            ),
            if (!_hasVariants) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'موجودی'),
                validator: _requiredNumber,
              ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'گونه‌ها',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            'جمع موجودی: $_variantsTotal',
                            style: TextStyle(color: scheme.secondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _rows.length; i++)
                        Padding(
                          key: ObjectKey(_rows[i]),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _rows[i].size,
                                  decoration: const InputDecoration(
                                      labelText: 'سایز'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _rows[i].color,
                                  decoration: const InputDecoration(
                                      labelText: 'رنگ'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _rows[i].stock,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'موجودی'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _removeRow(i),
                              ),
                            ],
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _addRow,
                            icon: const Icon(Icons.add),
                            label: const Text('افزودن گونه'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _quickAdd,
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('ساخت سریع'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lowStock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'هشدار کمبود',
                helperText:
                    'وقتی موجودی کل از این عدد کمتر شد «کم است» نشان داده شود (۰ = بدون هشدار)',
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
