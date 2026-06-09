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

  CatalogViewModel(this._repository);

  List<Product> get products => _products;
  CatalogStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get selectedCategoryId => _selectedCategoryId;

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

  Future<void> loadCatalog() async {
    _status = CatalogStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await _repository.loadCatalog();
      _products = data.products;
      _categories = data.categories;
      if (!tabs.any((t) => t.id == _selectedCategoryId)) {
        _selectedCategoryId = _kNewId;
      }
      _status = CatalogStatus.success;
    } catch (e) {
      _errorMessage = 'Не удалось загрузить каталог';
      _status = CatalogStatus.error;
    }

    notifyListeners();
  }

  Future<void> selectCategory(String categoryId) async {
    _selectedCategoryId = categoryId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_category_id', categoryId);
  }
}
