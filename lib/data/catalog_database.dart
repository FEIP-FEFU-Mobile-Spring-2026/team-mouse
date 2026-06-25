import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'catalog_api.dart';

/// Локальный кэш каталога на базе SQLite (sqflite).
///
/// Категории и товары хранятся в реляционных таблицах; вложенные списки
/// (размеры, теги) сериализуются в JSON-колонки.
class CatalogDatabase {
  static const _dbName = 'catalog.db';
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
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            sort_order INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            sort_order INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Полностью перезаписывает кэш свежими данными из API.
  Future<void> saveCatalog(CatalogData data) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('categories');
      await txn.delete('products');

      final batch = txn.batch();
      for (var i = 0; i < data.categories.length; i++) {
        final c = data.categories[i];
        batch.insert('categories', {
          'id': c.id,
          'name': c.name,
          'sort_order': i,
        });
      }
      for (var i = 0; i < data.products.length; i++) {
        final product = data.products[i];
        batch.insert('products', {
          'id': product.id,
          'data': jsonEncode(product.toJson()),
          'sort_order': i,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  /// Читает закэшированный каталог. Возвращает null, если кэш пуст.
  Future<CatalogData?> readCatalog() async {
    final db = await _database;
    final categoryRows = await db.query('categories', orderBy: 'sort_order');
    final productRows = await db.query('products', orderBy: 'sort_order');

    if (categoryRows.isEmpty && productRows.isEmpty) return null;

    final categories = categoryRows
        .map((row) => Category(
              id: row['id'] as String,
              name: row['name'] as String,
            ))
        .toList();

    final products = productRows
        .map((row) => Product.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>,
            ))
        .toList();

    return (categories: categories, products: products);
  }
}
