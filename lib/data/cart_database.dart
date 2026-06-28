import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Минимальное представление позиции корзины в БД.
///
/// Хранится только то, что нельзя восстановить из каталога: идентификатор
/// товара, идентификатор размера и количество. Название, цена, картинка и
/// прочее собираются при отображении из данных каталога.
class CartRecord {
  final String productId;
  final String sizeId;
  final int quantity;

  const CartRecord({
    required this.productId,
    required this.sizeId,
    required this.quantity,
  });
}

/// Хранилище корзины на базе SQLite (sqflite).
class CartDatabase {
  static const _dbName = 'cart.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get _database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cart_items (
            product_id TEXT NOT NULL,
            size_id TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            PRIMARY KEY (product_id, size_id)
          )
        ''');
      },
    );
  }

  Future<List<CartRecord>> readAll() async {
    final db = await _database;
    final rows = await db.query('cart_items');
    return rows
        .map((row) => CartRecord(
              productId: row['product_id'] as String,
              sizeId: row['size_id'] as String,
              quantity: row['quantity'] as int,
            ))
        .toList();
  }

  /// Создаёт или обновляет позицию с заданным количеством.
  Future<void> upsert(String productId, String sizeId, int quantity) async {
    final db = await _database;
    await db.insert(
      'cart_items',
      {
        'product_id': productId,
        'size_id': sizeId,
        'quantity': quantity,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(String productId, String sizeId) async {
    final db = await _database;
    await db.delete(
      'cart_items',
      where: 'product_id = ? AND size_id = ?',
      whereArgs: [productId, sizeId],
    );
  }

  Future<void> clear() async {
    final db = await _database;
    await db.delete('cart_items');
  }
}
