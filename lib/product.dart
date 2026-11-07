class ProductVariant {
  final int? id;
  final int productId;
  final String size;
  final String color;
  final int stock;

  const ProductVariant({
    this.id,
    this.productId = 0,
    this.size = '',
    this.color = '',
    required this.stock,
  });

  /// مثلاً «سایز 30 | آبی»
  String get label => [
        if (size.isNotEmpty) 'سایز $size',
        if (color.isNotEmpty) color,
      ].join(' | ');

  Map<String, Object?> toMap(int productId) => {
        if (id != null) 'id': id,
        'product_id': productId,
        'size': size,
        'color': color,
        'stock': stock,
      };

  factory ProductVariant.fromMap(Map<String, Object?> m) => ProductVariant(
        id: m['id'] as int,
        productId: m['product_id'] as int,
        size: (m['size'] as String?) ?? '',
        color: (m['color'] as String?) ?? '',
        stock: m['stock'] as int,
      );
}

class Product {
  final int? id;
  final String name;
  final int salePrice;
  final int costPrice;
  final int stock;
  final String note;
  final String image;
  final String category;
  final int lowStock;
  final bool active;
  final List<ProductVariant> variants;

  const Product({
    this.id,
    required this.name,
    required this.salePrice,
    required this.costPrice,
    required this.stock,
    this.note = '',
    this.image = '',
    this.category = '',
    this.lowStock = 3,
    this.active = true,
    this.variants = const [],
  });

  bool get hasVariants => variants.isNotEmpty;

  Product copyWith({bool? active}) => Product(
        id: id,
        name: name,
        salePrice: salePrice,
        costPrice: costPrice,
        stock: stock,
        note: note,
        image: image,
        category: category,
        lowStock: lowStock,
        active: active ?? this.active,
        variants: variants,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'sale_price': salePrice,
        'cost_price': costPrice,
        'stock': stock,
        'note': note,
        'image': image,
        'category': category,
        'low_stock': lowStock,
        'active': active ? 1 : 0,
      };

  factory Product.fromMap(
    Map<String, Object?> m, [
    List<ProductVariant> variants = const [],
  ]) =>
      Product(
        id: m['id'] as int,
        name: m['name'] as String,
        salePrice: m['sale_price'] as int,
        costPrice: m['cost_price'] as int,
        stock: m['stock'] as int,
        note: (m['note'] as String?) ?? '',
        image: (m['image'] as String?) ?? '',
        category: (m['category'] as String?) ?? '',
        lowStock: (m['low_stock'] as int?) ?? 3,
        active: ((m['active'] as int?) ?? 1) == 1,
        variants: variants,
      );
}
