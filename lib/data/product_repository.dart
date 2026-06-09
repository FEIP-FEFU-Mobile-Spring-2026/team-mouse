import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/product.dart';

typedef CatalogData = ({List<Category> categories, List<Product> products});

class ProductRepository {
  Future<CatalogData> loadCatalog() async {
    final jsonString = await rootBundle.loadString('products.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    final categories = (json['categories'] as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();

    final products = (json['items'] as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();

    return (categories: categories, products: products);
  }
}
