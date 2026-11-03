import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'product.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            sale_price INTEGER NOT NULL,
            cost_price INTEGER NOT NULL,
            stock INTEGER NOT NULL,
            note TEXT
          )
        ''');
      },
    );
  }

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
      await db.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    }
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
