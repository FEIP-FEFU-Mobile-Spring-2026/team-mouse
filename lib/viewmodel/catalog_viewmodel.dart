import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/product_repository.dart';
import '../models/category.dart';
import '../models/product.dart';

const _kNewId = '__new__';
const _kNewName = 'Новинки';

enum CatalogStatus { loading, success, error }

class CatalogViewModel extends ChangeNotifier {
  final ProductRepository _repository;

  List<Product> _products = [];
  List<Category> _categories = [];
  String _selectedCategoryId = _kNewId;
  CatalogStatus _status = CatalogStatus.loading;
  String _errorMessage = '';
  bool _isOffline = false;

  CatalogViewModel(this._repository);

  List<Product> get products => _products;
  CatalogStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get selectedCategoryId => _selectedCategoryId;

  /// true, когда показываются закэшированные данные из-за отсутствия сети.
  bool get isOffline => _isOffline;

  List<Category> get tabs {
    return [
      const Category(id: _kNewId, name: _kNewName),
      ..._categories,
    ];
  }

  List<Product> get filteredProducts {
    if (_selectedCategoryId == _kNewId) {
      return _products.where((p) => p.tags.contains('New')).toList();
    }
    return _products.where((p) => p.categoryId == _selectedCategoryId).toList();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selected_category_id');
    if (saved != null) _selectedCategoryId = saved;
    await loadCatalog();
  }

  /// Стратегия cache-first: сначала отдаём кэш, параллельно идём в сеть.
  Future<void> loadCatalog() async {
    _isOffline = false;

    // 1. Показываем кэш, если он есть.
    final cached = await _repository.loadFromCache();
    final hasCache = cached != null &&
        (cached.products.isNotEmpty || cached.categories.isNotEmpty);
    if (hasCache) {
      debugPrint('[Каталог] показан КЭШ: ${cached.products.length} товаров');
      _applyData(cached);
      _status = CatalogStatus.success;
    } else {
      debugPrint('[Каталог] кэш пуст, ждём API');
      _status = CatalogStatus.loading;
    }
    _errorMessage = '';
    notifyListeners();

    // 2. Запрашиваем свежие данные из API.
    try {
      final fresh = await _repository.fetchFromApi();
      debugPrint('[Каталог] получено с API: ${fresh.products.length} товаров');
      _applyData(fresh);
      _status = CatalogStatus.success;
      _isOffline = false;
    } catch (e) {
      debugPrint('[Каталог] ошибка сети: $e (есть кэш: $hasCache)');
      if (hasCache) {
        // Сеть недоступна, но есть кэш — показываем его без ошибки.
        _isOffline = true;
      } else {
        // Кэш пуст и сети нет — состояние ошибки с возможностью повторить.
        _errorMessage = 'Проверьте подключение к интернету и попробуйте снова';
        _status = CatalogStatus.error;
      }
    }

    notifyListeners();
  }

  void _applyData(CatalogData data) {
    _products = data.products;
    _categories = data.categories;
    if (!tabs.any((t) => t.id == _selectedCategoryId)) {
      _selectedCategoryId = _kNewId;
    }
  }

  Future<void> selectCategory(String categoryId) async {
    _selectedCategoryId = categoryId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_category_id', categoryId);
  }
}
