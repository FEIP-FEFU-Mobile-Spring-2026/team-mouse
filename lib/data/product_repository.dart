import 'catalog_api.dart';
import 'catalog_database.dart';

export 'catalog_api.dart' show CatalogData;

/// Координирует удалённый API и локальный кэш каталога.
class ProductRepository {
  final CatalogApi _api;
  final CatalogDatabase _database;

  ProductRepository({CatalogApi? api, CatalogDatabase? database})
      : _api = api ?? CatalogApi(),
        _database = database ?? CatalogDatabase();

  /// Возвращает закэшированный каталог или null, если кэш пуст.
  Future<CatalogData?> loadFromCache() => _database.readCatalog();

  /// Загружает каталог из API и обновляет кэш.
  Future<CatalogData> fetchFromApi() async {
    final data = await _api.fetchCatalog();
    await _database.saveCatalog(data);
    return data;
  }
}
