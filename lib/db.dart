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

  static const _variantsTable = '''
    CREATE TABLE product_variants (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      size TEXT,
      color TEXT,
      stock INTEGER NOT NULL DEFAULT 0
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
      variant_id INTEGER,
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
      version: 6,
      onCreate: (db, version) async {
        await db.execute(_productsTable);
        await db.execute(_variantsTable);
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
        if (oldVersion < 6) {
          await db.execute(_variantsTable);
          // اگر از نسخه ۳ به بالا ارتقا می‌دهیم، جدول اقلام فروش ستون جدید را می‌خواهد
          if (oldVersion >= 3) {
            await db.execute(
                'ALTER TABLE sale_items ADD COLUMN variant_id INTEGER');
          }
        }
      },
    );
  }

  // ---------- محصولات ----------
  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'id DESC');
    final varRows = await db.query('product_variants', orderBy: 'id ASC');
    final byProduct = <int, List<ProductVariant>>{};
    for (final r in varRows) {
      final v = ProductVariant.fromMap(r);
      byProduct.putIfAbsent(v.productId, () => []).add(v);
    }
    return rows
        .map((r) => Product.fromMap(r, byProduct[r['id'] as int] ?? const []))
        .toList();
  }

  /// محصول و گونه‌هایش را ذخیره می‌کند.
  /// اگر گونه دارد، موجودی کل از جمع موجودی گونه‌ها حساب می‌شود.
  Future<void> saveProduct(Product product) async {
    final db = await database;
    await db.transaction((txn) async {
      final total = product.variants.isEmpty
          ? product.stock
          : product.variants.fold<int>(0, (a, v) => a + v.stock);
      final map = product.toMap();
      map['stock'] = total;

      final int id;
      if (product.id == null) {
        id = await txn.insert('products', map);
      } else {
        id = product.id!;
        await txn.update('products', map, where: 'id = ?', whereArgs: [id]);
      }

      final keepIds = <int>[];
      for (final v in product.variants) {
        if (v.id != null) {
          keepIds.add(v.id!);
          await txn.update('product_variants', v.toMap(id),
              where: 'id = ?', whereArgs: [v.id]);
        } else {
          keepIds.add(await txn.insert('product_variants', v.toMap(id)));
        }
      }
      if (keepIds.isEmpty) {
        await txn.delete('product_variants',
            where: 'product_id = ?', whereArgs: [id]);
      } else {
        final marks = List.filled(keepIds.length, '?').join(',');
        await txn.delete(
          'product_variants',
          where: 'product_id = ? AND id NOT IN ($marks)',
          whereArgs: [id, ...keepIds],
        );
      }
    });
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('product_variants',
          where: 'product_id = ?', whereArgs: [id]);
      await txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
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

  /// موجودی را به اندازه delta تغییر می‌دهد.
  /// اگر کالا گونه دارد، موجودی همان گونه عوض می‌شود و موجودی کل از جمع گونه‌ها دوباره حساب می‌شود.
  Future<void> _adjustStock(
    Transaction txn, {
    required int? productId,
    required int? variantId,
    required int delta,
  }) async {
    if (productId == null) return;
    if (variantId != null) {
      await txn.rawUpdate(
        'UPDATE product_variants SET stock = stock + ? WHERE id = ?',
        [delta, variantId],
      );
      await txn.rawUpdate(
        'UPDATE products SET stock = '
        '(SELECT COALESCE(SUM(stock), 0) FROM product_variants WHERE product_id = ?) '
        'WHERE id = ? AND EXISTS '
        '(SELECT 1 FROM product_variants WHERE product_id = ?)',
        [productId, productId, productId],
      );
    } else {
      await txn.rawUpdate(
        'UPDATE products SET stock = stock + ? WHERE id = ?',
        [delta, productId],
      );
    }
  }

  /// فروش را ثبت می‌کند و موجودی کالاها (یا گونه‌ها) را کم می‌کند
  Future<void> createSale(Sale sale) async {
    final db = await database;
    await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());
      for (final item in sale.items) {
        await txn.insert('sale_items', item.toMap(saleId));
        await _adjustStock(
          txn,
          productId: item.productId,
          variantId: item.variantId,
          delta: -item.quantity,
        );
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
        final items = await txn
            .query('sale_items', where: 'sale_id = ?', whereArgs: [sale.id]);
        for (final r in items) {
          final q = r['quantity'] as int;
          await _adjustStock(
            txn,
            productId: r['product_id'] as int?,
            variantId: r['variant_id'] as int?,
            delta: nowCanceled ? q : -q,
          );
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
          await _adjustStock(
            txn,
            productId: r['product_id'] as int?,
            variantId: r['variant_id'] as int?,
            delta: r['quantity'] as int,
          );
        }
      }
      await txn.delete('sale_items',
          where: 'sale_id = ?', whereArgs: [sale.id]);
      await txn.delete('sales', where: 'id = ?', whereArgs: [sale.id]);
    });
  }
}
