import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartViewModel extends ChangeNotifier {
  final Map<String, int> _quantities = {};

  int getQuantity(String productId) => _quantities[productId] ?? 0;

  bool hasItem(String productId) => (_quantities[productId] ?? 0) > 0;

  int get totalItems => _quantities.values.fold(0, (sum, q) => sum + q);

  Map<String, int> get quantities => Map.unmodifiable(_quantities);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('cart_ids') ?? [];
    for (final id in ids) {
      final qty = prefs.getInt('cart_qty_$id') ?? 0;
      if (qty > 0) _quantities[id] = qty;
    }
    notifyListeners();
  }

  void increment(String productId) {
    _quantities[productId] = (_quantities[productId] ?? 0) + 1;
    notifyListeners();
    _persist();
  }

  void decrement(String productId) {
    final current = _quantities[productId] ?? 0;
    if (current <= 1) {
      _quantities.remove(productId);
    } else {
      _quantities[productId] = current - 1;
    }
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _quantities.keys.toList();
    await prefs.setStringList('cart_ids', ids);
    for (final id in ids) {
      await prefs.setInt('cart_qty_$id', _quantities[id]!);
    }
    final staleKeys = prefs
        .getKeys()
        .where((k) => k.startsWith('cart_qty_') && !ids.contains(k.substring(9)));
    for (final key in staleKeys) {
      await prefs.remove(key);
    }
  }
}
