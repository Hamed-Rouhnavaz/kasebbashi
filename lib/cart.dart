import 'package:flutter/foundation.dart';

import 'product.dart';

/// کلید یکتا برای یک ردیف سبد (محصول + گونه)
String lineKey(int? productId, int? variantId) =>
    '${productId ?? 0}:${variantId ?? 0}';

class CartLine {
  final Product product;
  final ProductVariant? variant;
  int qty;

  CartLine(this.product, this.variant, this.qty);

  int get stock => variant?.stock ?? product.stock;
  String get name =>
      variant == null ? product.name : '${product.name} (${variant!.label})';
  String get key => lineKey(product.id, variant?.id);
  int get total => qty * product.salePrice;
}

class Cart extends ChangeNotifier {
  final List<CartLine> lines = [];

  int get count => lines.fold<int>(0, (a, l) => a + l.qty);
  int get subtotal => lines.fold<int>(0, (a, l) => a + l.total);

  CartLine? _find(Product p, ProductVariant? v) {
    final key = lineKey(p.id, v?.id);
    for (final l in lines) {
      if (l.key == key) return l;
    }
    return null;
  }

  int qtyOf(Product p, [ProductVariant? v]) => _find(p, v)?.qty ?? 0;

  /// جمع تعداد همه گونه‌های یک محصول در سبد
  int qtyOfProduct(Product p) =>
      lines.where((l) => l.product.id == p.id).fold<int>(0, (a, l) => a + l.qty);

  void add(Product p, [ProductVariant? v]) {
    final line = _find(p, v);
    if (line == null) {
      lines.add(CartLine(p, v, 1));
    } else if (line.qty < line.stock) {
      line.qty++;
    }
    notifyListeners();
  }

  void decrement(Product p, [ProductVariant? v]) {
    final line = _find(p, v);
    if (line == null) return;
    if (line.qty <= 1) {
      lines.remove(line);
    } else {
      line.qty--;
    }
    notifyListeners();
  }

  void remove(CartLine line) {
    lines.remove(line);
    notifyListeners();
  }
}
