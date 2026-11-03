import 'package:flutter/material.dart';

import 'db.dart';
import 'format.dart';
import 'product.dart';
import 'product_form_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const int lowStockLimit = 3;

  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.getProducts();
    if (!mounted) return;
    setState(() {
      _products = items;
      _loading = false;
    });
  }

  Future<void> _openForm([Product? product]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف محصول'),
        content: Text('«${product.name}» حذف شود؟'),
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
    if (ok == true) {
      await AppDatabase.instance.deleteProduct(product.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محصولات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('محصول جدید'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Text('هنوز محصولی ثبت نکرده‌اید.\nدکمه پایین را بزنید.',
                      textAlign: TextAlign.center),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: _products.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = _products[i];
                    final low = p.stock <= lowStockLimit;
                    return ListTile(
                      title: Text(p.name),
                      subtitle: Text(
                        '${toman(p.salePrice)}  |  موجودی: ${p.stock}'
                        '${low ? '  (کم است!)' : ''}',
                        style: TextStyle(color: low ? Colors.red : null),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(p),
                      ),
                      onTap: () => _openForm(p),
                    );
                  },
                ),
    );
  }
}
