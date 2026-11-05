import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'customer.dart';
import 'product.dart';
import 'sale.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _productsTable = '''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      sale_price INTEGER NOT NULL,
      cost_price INTEGER NOT NULL,
      stock INTEGER NOT NULL,
      note TEXT,
      image TEXT,
      category TEXT,
      low_stock INTEGER NOT NULL DEFAULT 3,
      active INTEGER NOT NULL DEFAULT 1
    )
  ''';

  static const _customersTable = '''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      instagram TEXT,
      address TEXT
    )
  ''';

  static const _salesTable = '''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER,
      created_at INTEGER NOT NULL,
      status TEXT NOT NULL,
      discount INTEGER NOT NULL DEFAULT 0,
      paid INTEGER NOT NULL DEFAULT 0,
      tracking_code TEXT,
      note TEXT
    )
  ''';

  static const _saleItemsTable = '''
    CREATE TABLE sale_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      product_id INTEGER,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit_price INTEGER NOT NULL,
      unit_cost INTEGER NOT NULL
    )
  ''';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'kasebbashi.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute(_productsTable);
        await db.execute(_customersTable);
        await db.execute(_salesTable);
        await db.execute(_saleItemsTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(_customersTable);
        }
        if (oldVersion < 3) {
          await db.execute(_salesTable);
          await db.execute(_saleItemsTable);
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE products ADD COLUMN image TEXT');
          await db.execute('ALTER TABLE products ADD COLUMN category TEXT');
        }
        if (oldVersion < 5) {
          await db.execute(
              'ALTER TABLE products ADD COLUMN low_stock INTEGER NOT NULL DEFAULT 3');
          await db.execute(
              'ALTER TABLE products ADD COLUMN active INTEGER NOT NULL DEFAULT 1');
        }
      },
    );
  }

  // ---------- محصولات ----------
  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'id DESC');
    return rows.map(Product.fromMap).toList();
  }

  Future<void> saveProduct(Product product) async {
    final db = await database;
    if (product.id == null) {
      await db.insert('products', product.toMap());
    } else {
      await db.update('products', product.toMap(),
          where: 'id = ?', whereArgs: [product.id]);
    }
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- مشتری‌ها ----------
  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final rows = await db.query('customers', orderBy: 'id DESC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<void> saveCustomer(Customer customer) async {
    final db = await database;
    if (customer.id == null) {
      await db.insert('customers', customer.toMap());
    } else {
      await db.update('customers', customer.toMap(),
          where: 'id = ?', whereArgs: [customer.id]);
    }
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- فروش ----------
  Future<List<Sale>> getSales() async {
    final db = await database;
    final saleRows = await db.rawQuery('''
      SELECT s.*, c.name AS customer_name, c.instagram AS customer_instagram
      FROM sales s
      LEFT JOIN customers c ON c.id = s.customer_id
      ORDER BY s.id DESC
    ''');
    final itemRows = await db.query('sale_items');
    final itemsBySale = <int, List<SaleItem>>{};
    for (final r in itemRows) {
      itemsBySale
          .putIfAbsent(r['sale_id'] as int, () => [])
          .add(SaleItem.fromMap(r));
    }
    return saleRows
        .map((r) => Sale.fromMap(r, itemsBySale[r['id'] as int] ?? []))
        .toList();
  }

  Future<Sale?> getSale(int id) async {
    final all = await getSales();
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// فروش را ثبت می‌کند و موجودی کالاها را کم می‌کند
  Future<void> createSale(Sale sale) async {
    final db = await database;
    await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());
      for (final item in sale.items) {
        await txn.insert('sale_items', item.toMap(saleId));
        if (item.productId != null) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ?',
            [item.quantity, item.productId],
          );
        }
      }
    });
  }

  /// وضعیت را عوض می‌کند. وضعیت قبلی و اقلام از خود دیتابیس خوانده می‌شود.
  /// با لغو، موجودی برمی‌گردد؛ با برگرداندن از لغو، دوباره کم می‌شود.
  Future<void> updateSaleStatus(Sale sale, String newStatus) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query('sales',
          columns: ['status'], where: 'id = ?', whereArgs: [sale.id]);
      if (rows.isEmpty) return;
      final oldStatus = rows.first['status'] as String;
      if (oldStatus == newStatus) return;

      await txn.update('sales', {'status': newStatus},
          where: 'id = ?', whereArgs: [sale.id]);

      final wasCanceled = oldStatus == SaleStatus.canceled;
      final nowCanceled = newStatus == SaleStatus.canceled;
      if (wasCanceled != nowCanceled) {
        final sign = nowCanceled ? '+' : '-';
        final items = await txn
            .query('sale_items', where: 'sale_id = ?', whereArgs: [sale.id]);
        for (final r in items) {
          final productId = r['product_id'] as int?;
          if (productId != null) {
            await txn.rawUpdate(
              'UPDATE products SET stock = stock $sign ? WHERE id = ?',
              [r['quantity'] as int, productId],
            );
          }
        }
      }
    });
  }

  Future<void> updateSaleFields(int id, Map<String, Object?> values) async {
    final db = await database;
    await db.update('sales', values, where: 'id = ?', whereArgs: [id]);
  }

  /// فروش را حذف می‌کند (اگر لغو نشده بود، موجودی برمی‌گردد)
  Future<void> deleteSale(Sale sale) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query('sales',
          columns: ['status'], where: 'id = ?', whereArgs: [sale.id]);
      if (rows.isEmpty) return;
      final status = rows.first['status'] as String;
      final items = await txn
          .query('sale_items', where: 'sale_id = ?', whereArgs: [sale.id]);
      if (status != SaleStatus.canceled) {
        for (final r in items) {
          final productId = r['product_id'] as int?;
          if (productId != null) {
            await txn.rawUpdate(
              'UPDATE products SET stock = stock + ? WHERE id = ?',
              [r['quantity'] as int, productId],
            );
          }
        }
      }
      await txn.delete('sale_items',
          where: 'sale_id = ?', whereArgs: [sale.id]);
      await txn.delete('sales', where: 'id = ?', whereArgs: [sale.id]);
    });
  }
}
