import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/product.dart';

typedef CatalogData = ({List<Category> categories, List<Product> products});

/// Удалённый источник данных каталога.
class CatalogApi {
  static const String _baseUrl = 'https://fefu2026spring.deploy.feip.dev';
  static const String _token = 'Cmt7wdwFgDIi1_SRX8hlJIExs0jJKPr4axflLpExAxM';

  final http.Client _client;

  CatalogApi({http.Client? client}) : _client = client ?? http.Client();

  Future<CatalogData> fetchCatalog() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/catalog'),
      headers: const {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Сервер вернул код ${response.statusCode}');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;

    final categories = (json['categories'] as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();

    final products = (json['items'] as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();

    return (categories: categories, products: products);
  }
}
