import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:team_mouse/data/cart_database.dart';
import 'package:team_mouse/data/product_repository.dart';
import 'package:team_mouse/models/category.dart';
import 'package:team_mouse/models/product.dart';
import 'package:team_mouse/utils/price_formatter.dart';
import 'package:team_mouse/viewmodel/cart_viewmodel.dart';
import 'package:team_mouse/viewmodel/catalog_viewmodel.dart';

// --- Фейковая БД корзины (без SQLite) ---
class FakeCartDatabase extends CartDatabase {
  final Map<String, CartRecord> _records = {};

  @override
  Future<List<CartRecord>> readAll() async => _records.values.toList();

  @override
  Future<void> upsert(String productId, String sizeId, int quantity) async {
    _records['$productId|$sizeId'] = CartRecord(
      productId: productId,
      sizeId: sizeId,
      quantity: quantity,
    );
  }

  @override
  Future<void> remove(String productId, String sizeId) async {
    _records.remove('$productId|$sizeId');
  }

  @override
  Future<void> clear() async => _records.clear();
}

// --- Фейковый репозиторий каталога (без сети и SQLite) ---
class FakeProductRepository extends ProductRepository {
  final CatalogData? _fakeCache;
  final CatalogData Function() _fetchFn;

  FakeProductRepository({
    CatalogData? cached,
    required CatalogData Function() fetch,
  })  : _fakeCache = cached,
        _fetchFn = fetch;

  @override
  Future<CatalogData?> loadFromCache() async => _fakeCache;

  @override
  Future<CatalogData> fetchFromApi() async => _fetchFn();
}

// --- Вспомогательная фабрика товара ---
Product makeProduct({
  String id = 'p1',
  String categoryId = 'cat1',
  List<String> tags = const [],
}) =>
    Product(
      id: id,
      name: 'Тестовый товар',
      shortDescription: 'Описание',
      longDescription: '',
      priceInKopecks: 100000,
      imageUrl: '',
      tags: tags,
      categoryId: categoryId,
      sizes: const [],
      material: '',
      weight: '',
      season: '',
      countryOfOrigin: '',
    );

void main() {
  // ═══════════════════════════════════════════════════
  // Корзина: CartViewModel
  // ═══════════════════════════════════════════════════
  group('CartViewModel', () {
    late FakeCartDatabase db;
    late CartViewModel vm;

    setUp(() {
      db = FakeCartDatabase();
      vm = CartViewModel(database: db);
    });

    test('add — создаёт позицию с quantity = 1', () async {
      await vm.add('p1', 's1');
      expect(vm.quantityOf('p1', 's1'), 1);
    });

    test('add дважды — инкрементирует quantity до 2', () async {
      await vm.add('p1', 's1');
      await vm.add('p1', 's1');
      expect(vm.quantityOf('p1', 's1'), 2);
    });

    test('decrement до 0 — удаляет позицию из корзины', () async {
      await vm.add('p1', 's1');
      await vm.decrement('p1', 's1');

      expect(vm.quantityOf('p1', 's1'), 0);
      expect(vm.lines, isEmpty);
    });

    test('totalItems — суммирует количество по всем позициям', () async {
      await vm.add('p1', 's1');
      await vm.add('p1', 's2');
      await vm.add('p2', 's1');

      expect(vm.totalItems, 3);
    });

    test('quantityOfProduct — суммирует разные размеры одного товара', () async {
      await vm.add('p1', 's1');
      await vm.add('p1', 's1'); // quantity p1/s1 = 2
      await vm.add('p1', 's2'); // quantity p1/s2 = 1

      expect(vm.quantityOfProduct('p1'), 3);
    });

    test('remove — удаляет конкретную позицию, не затрагивая другие', () async {
      await vm.add('p1', 's1');
      await vm.add('p1', 's2');
      await vm.remove('p1', 's1');

      expect(vm.quantityOf('p1', 's1'), 0);
      expect(vm.quantityOf('p1', 's2'), 1);
    });

    test('clear — полностью опустошает корзину', () async {
      await vm.add('p1', 's1');
      await vm.add('p2', 's1');
      await vm.clear();

      expect(vm.isEmpty, isTrue);
      expect(vm.totalItems, 0);
    });
  });

  // ═══════════════════════════════════════════════════
  // Маппинг: Product.fromJson / toJson
  // ═══════════════════════════════════════════════════
  group('Product.fromJson / toJson', () {
    const json = <String, dynamic>{
      'id': 'abc123',
      'name': 'Худи оверсайз',
      'shortDescription': 'Тёплое худи',
      'longDescription': 'Очень тёплое худи из хлопка',
      'priceInKopecks': 299900,
      'imageUrl': 'https://example.com/img.png',
      'tags': ['New', 'Sale'],
      'categoryId': 'hoodies',
      'sizes': [
        {'id': 's_m', 'name': 'M'},
        {'id': 's_l', 'name': 'L'},
      ],
      'material': 'Хлопок',
      'weight': '300г',
      'season': 'Зима',
      'countryOfOrigin': 'Россия',
    };

    test('fromJson — маппит все основные поля', () {
      final product = Product.fromJson(json);

      expect(product.id, 'abc123');
      expect(product.name, 'Худи оверсайз');
      expect(product.priceInKopecks, 299900);
      expect(product.tags, ['New', 'Sale']);
      expect(product.categoryId, 'hoodies');
    });

    test('fromJson — маппит список размеров', () {
      final product = Product.fromJson(json);

      expect(product.sizes.length, 2);
      expect(product.sizes[0].id, 's_m');
      expect(product.sizes[0].name, 'M');
      expect(product.sizes[1].name, 'L');
    });

    test('toJson — round-trip сохраняет id, tags и количество размеров', () {
      final product = Product.fromJson(json);
      final result = product.toJson();

      expect(result['id'], json['id']);
      expect(result['tags'], json['tags']);
      expect((result['sizes'] as List).length, 2);
    });

    test('fromJson — nullable поля принимают значение по умолчанию', () {
      final minimalJson = <String, dynamic>{
        'id': 'x',
        'name': 'T',
        'shortDescription': '',
        'priceInKopecks': 0,
        'imageUrl': '',
        'tags': <String>[],
        'categoryId': 'c',
      };
      final product = Product.fromJson(minimalJson);

      expect(product.longDescription, '');
      expect(product.material, '');
      expect(product.sizes, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════
  // Утилита: formatPrice
  // formatPrice использует неразрывный пробел (U+00A0) как разделитель тысяч.
  // В ожидаемых строках используем явный Dart-эскейп  .
  // ═══════════════════════════════════════════════════
  group('formatPrice', () {
    test('форматирует тысячи с разделителем и символом ₽', () {
      expect(formatPrice(299900), '2 999 ₽');
    });

    test('форматирует сумму до 1000 руб без разделителя', () {
      expect(formatPrice(50000), '500 ₽');
    });

    test('форматирует миллионные суммы с двумя разделителями', () {
      expect(formatPrice(100000000), '1 000 000 ₽');
    });
  });

  // ═══════════════════════════════════════════════════
  // Фильтрация: CatalogViewModel.filteredProducts
  // ═══════════════════════════════════════════════════
  group('CatalogViewModel.filteredProducts', () {
    const category = Category(id: 'cat_a', name: 'Категория А');

    final newProduct = makeProduct(id: 'new1', tags: ['New']);
    final catProduct = makeProduct(id: 'cat1', categoryId: 'cat_a');
    final bothProduct = makeProduct(id: 'both1', categoryId: 'cat_a', tags: ['New']);

    CatalogData makeCatalog() => (
          categories: [category],
          products: [newProduct, catProduct, bothProduct],
        );

    late CatalogViewModel vm;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      vm = CatalogViewModel(
        FakeProductRepository(cached: makeCatalog(), fetch: makeCatalog),
      );
    });

    test('по умолчанию показывает только товары с тегом New', () async {
      await vm.loadCatalog();
      final filtered = vm.filteredProducts;

      expect(filtered.map((p) => p.id), containsAll(['new1', 'both1']));
      expect(filtered.any((p) => p.id == 'cat1'), isFalse);
    });

    test('selectCategory — фильтрует по выбранной категории', () async {
      await vm.loadCatalog();
      await vm.selectCategory('cat_a');
      final filtered = vm.filteredProducts;

      expect(filtered.map((p) => p.id), containsAll(['cat1', 'both1']));
      expect(filtered.any((p) => p.id == 'new1'), isFalse);
    });
  });
}
