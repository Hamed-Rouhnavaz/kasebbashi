class Product {
  final int? id;
  final String name;
  final int salePrice;
  final int costPrice;
  final int stock;
  final String note;

  const Product({
    this.id,
    required this.name,
    required this.salePrice,
    required this.costPrice,
    required this.stock,
    this.note = '',
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'sale_price': salePrice,
        'cost_price': costPrice,
        'stock': stock,
        'note': note,
      };

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int,
        name: m['name'] as String,
        salePrice: m['sale_price'] as int,
        costPrice: m['cost_price'] as int,
        stock: m['stock'] as int,
        note: (m['note'] as String?) ?? '',
      );
}
