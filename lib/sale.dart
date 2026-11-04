class SaleStatus {
  static const preparing = 'preparing';
  static const shipped = 'shipped';
  static const delivered = 'delivered';
  static const canceled = 'canceled';

  static const all = [preparing, shipped, delivered, canceled];

  static const _labels = {
    preparing: 'در حال آماده‌سازی',
    shipped: 'ارسال‌شده',
    delivered: 'تحویل‌شده',
    canceled: 'لغو شده',
  };

  static String label(String status) => _labels[status] ?? status;
}

class SaleItem {
  final int? productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int unitCost;

  const SaleItem({
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
  });

  int get total => quantity * unitPrice;

  Map<String, Object?> toMap(int saleId) => {
        'sale_id': saleId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'unit_cost': unitCost,
      };

  factory SaleItem.fromMap(Map<String, Object?> m) => SaleItem(
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String,
        quantity: m['quantity'] as int,
        unitPrice: m['unit_price'] as int,
        unitCost: m['unit_cost'] as int,
      );
}

class Sale {
  final int? id;
  final int? customerId;
  final String? customerName;
  final String? customerInstagram;
  final DateTime createdAt;
  final String status;
  final int discount;
  final int paid;
  final String trackingCode;
  final String note;
  final List<SaleItem> items;

  const Sale({
    this.id,
    this.customerId,
    this.customerName,
    this.customerInstagram,
    required this.createdAt,
    required this.status,
    this.discount = 0,
    this.paid = 0,
    this.trackingCode = '',
    this.note = '',
    required this.items,
  });

  int get subtotal => items.fold<int>(0, (sum, i) => sum + i.total);
  int get total => subtotal - discount;
  int get remaining => total - paid;
  int get profit =>
      total - items.fold<int>(0, (sum, i) => sum + i.unitCost * i.quantity);

  Map<String, Object?> toMap() => {
        'customer_id': customerId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'status': status,
        'discount': discount,
        'paid': paid,
        'tracking_code': trackingCode,
        'note': note,
      };

  factory Sale.fromMap(Map<String, Object?> m, List<SaleItem> items) => Sale(
        id: m['id'] as int,
        customerId: m['customer_id'] as int?,
        customerName: m['customer_name'] as String?,
        customerInstagram: m['customer_instagram'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        status: m['status'] as String,
        discount: m['discount'] as int,
        paid: m['paid'] as int,
        trackingCode: (m['tracking_code'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
        items: items,
      );
}
