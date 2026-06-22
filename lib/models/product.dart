class ProductSize {
  final String id;
  final String name;

  const ProductSize({required this.id, required this.name});

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String shortDescription;
  final String longDescription;
  final int priceInKopecks;
  final String imageUrl;
  final List<String> tags;
  final String categoryId;
  final List<ProductSize> sizes;
  final String material;
  final String weight;
  final String season;
  final String countryOfOrigin;

  const Product({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.priceInKopecks,
    required this.imageUrl,
    required this.tags,
    required this.categoryId,
    required this.sizes,
    required this.material,
    required this.weight,
    required this.season,
    required this.countryOfOrigin,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      shortDescription: json['shortDescription'] as String,
      longDescription: (json['longDescription'] as String?) ?? '',
      priceInKopecks: json['priceInKopecks'] as int,
      imageUrl: json['imageUrl'] as String,
      tags: List<String>.from(json['tags'] as List),
      categoryId: json['categoryId'] as String,
      sizes: ((json['sizes'] as List?) ?? [])
          .map((e) => ProductSize.fromJson(e as Map<String, dynamic>))
          .toList(),
      material: (json['material'] as String?) ?? '',
      weight: (json['weight'] as String?) ?? '',
      season: (json['season'] as String?) ?? '',
      countryOfOrigin: (json['countryOfOrigin'] as String?) ?? '',
    );
  }
}
