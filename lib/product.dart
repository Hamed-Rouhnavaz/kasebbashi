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
  });

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

  factory Product.fromMap(Map<String, Object?> m) => Product(
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
      );
}
