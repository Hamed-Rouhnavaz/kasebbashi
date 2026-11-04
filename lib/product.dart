class Product {
  final int? id;
  final String name;
  final int salePrice;
  final int costPrice;
  final int stock;
  final String note;
  final String image;
  final String category;

  const Product({
    this.id,
    required this.name,
    required this.salePrice,
    required this.costPrice,
    required this.stock,
    this.note = '',
    this.image = '',
    this.category = '',
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'sale_price': salePrice,
        'cost_price': costPrice,
        'stock': stock,
        'note': note,
        'image': image,
        'category': category,
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
      );
}
