import 'package:flutter/foundation.dart';
import '../data/cart_database.dart';

/// Позиция корзины в «сыром» виде: только то, что хранится в БД.
@immutable
class CartLine {
  final String productId;
  final String sizeId;
  final int quantity;

  const CartLine({
    required this.productId,
    required this.sizeId,
    required this.quantity,
  });

  String get key => '$productId|$sizeId';

  CartLine copyWith({int? quantity}) => CartLine(
        productId: productId,
        sizeId: sizeId,
        quantity: quantity ?? this.quantity,
      );
}

class CartViewModel extends ChangeNotifier {
  final CartDatabase _database;

  CartViewModel({CartDatabase? database})
      : _database = database ?? CartDatabase();

  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => List.unmodifiable(_lines.values);

  bool get isEmpty => _lines.isEmpty;

  /// Суммарное количество всех позиций — для бейджа.
  int get totalItems =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);

  /// Количество конкретной позиции (товар + размер).
  int quantityOf(String productId, String sizeId) =>
      _lines['$productId|$sizeId']?.quantity ?? 0;

  /// Суммарное количество товара по всем размерам — для карточки каталога.
  int quantityOfProduct(String productId) => _lines.values
      .where((line) => line.productId == productId)
      .fold(0, (sum, line) => sum + line.quantity);

  Future<void> loadFromDb() async {
    final records = await _database.readAll();
    _lines.clear();
    for (final r in records) {
      if (r.quantity <= 0) continue;
      final line = CartLine(
        productId: r.productId,
        sizeId: r.sizeId,
        quantity: r.quantity,
      );
      _lines[line.key] = line;
    }
    notifyListeners();
  }

  /// Добавляет товар выбранного размера. Повторное добавление той же пары
  /// (товар + размер) увеличивает количество, а не создаёт дубликат.
  Future<void> add(String productId, String sizeId) async {
    await _setQuantity(productId, sizeId,
        quantityOf(productId, sizeId) + 1);
  }

  Future<void> increment(String productId, String sizeId) =>
      _setQuantity(productId, sizeId, quantityOf(productId, sizeId) + 1);

  Future<void> decrement(String productId, String sizeId) =>
      _setQuantity(productId, sizeId, quantityOf(productId, sizeId) - 1);

  Future<void> remove(String productId, String sizeId) async {
    final key = '$productId|$sizeId';
    if (_lines.remove(key) != null) {
      notifyListeners();
      await _database.remove(productId, sizeId);
    }
  }

  Future<void> clear() async {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
    await _database.clear();
  }

  Future<void> _setQuantity(
      String productId, String sizeId, int quantity) async {
    final key = '$productId|$sizeId';
    if (quantity <= 0) {
      if (_lines.remove(key) != null) {
        notifyListeners();
        await _database.remove(productId, sizeId);
      }
      return;
    }
    _lines[key] = CartLine(
      productId: productId,
      sizeId: sizeId,
      quantity: quantity,
    );
    notifyListeners();
    await _database.upsert(productId, sizeId, quantity);
  }
}
