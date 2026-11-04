class Customer {
  final int? id;
  final String name;
  final String phone;
  final String instagram;
  final String address;

  const Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.instagram = '',
    this.address = '',
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'instagram': instagram,
        'address': address,
      };

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as int,
        name: m['name'] as String,
        phone: (m['phone'] as String?) ?? '',
        instagram: (m['instagram'] as String?) ?? '',
        address: (m['address'] as String?) ?? '',
      );
}
