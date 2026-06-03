import 'package:flutter/material.dart';

void main() {
  runApp(const MouseStoreApp());
}

class Product {
  final String name;
  final double price;
  final String category;
  final IconData icon;

  const Product({
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
  });
}

const List<Product> kProducts = [
  Product(
    name: 'Классическая футболка',
    price: 1299,
    category: 'Футболки',
    icon: Icons.dry_cleaning,
  ),
  Product(
    name: 'Поло',
    price: 1799,
    category: 'Футболки',
    icon: Icons.checkroom,
  ),
  Product(
    name: 'Джинсы slim fit',
    price: 3499,
    category: 'Джинсы',
    icon: Icons.accessibility_new,
  ),
  Product(
    name: 'Джинсы mom',
    price: 3199,
    category: 'Джинсы',
    icon: Icons.accessibility,
  ),
  Product(
    name: 'Худи oversize',
    price: 2799,
    category: 'Худи',
    icon: Icons.sports,
  ),
  Product(
    name: 'Зип-худи',
    price: 2999,
    category: 'Худи',
    icon: Icons.sports_martial_arts,
  ),
  Product(
    name: 'Платье летнее',
    price: 2199,
    category: 'Платья',
    icon: Icons.woman,
  ),
  Product(
    name: 'Платье миди',
    price: 2999,
    category: 'Платья',
    icon: Icons.girl,
  ),
  Product(
    name: 'Куртка демисезонная',
    price: 5999,
    category: 'Верхняя одежда',
    icon: Icons.umbrella,
  ),
  Product(
    name: 'Пальто',
    price: 7499,
    category: 'Верхняя одежда',
    icon: Icons.wb_cloudy,
  ),
  Product(
    name: 'Брюки классические',
    price: 3199,
    category: 'Брюки',
    icon: Icons.man,
  ),
  Product(
    name: 'Рубашка оксфорд',
    price: 2999,
    category: 'Рубашки',
    icon: Icons.dry,
  ),
];

class MouseStoreApp extends StatelessWidget {
  const MouseStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mouse Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A2E)),
        useMaterial3: true,
      ),
      home: const CatalogPage(),
    );
  }
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final List<Product> _cart = [];
  String _selectedCategory = 'Все';

  List<String> get _categories {
    return ['Все', ...kProducts.map((p) => p.category).toSet()];
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'Все') return kProducts;
    return kProducts.where((p) => p.category == _selectedCategory).toList();
  }

  void _addToCart(Product product) {
    setState(() => _cart.add(product));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('«${product.name}» добавлен в корзину'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mouse Store'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartPage(cart: List.of(_cart)),
                  ),
                ),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: cat == _selectedCategory,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: _filteredProducts[index],
                  onAddToCart: () => _addToCart(_filteredProducts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[200],
              width: double.infinity,
              child: Icon(product.icon, size: 64, color: Colors.grey[500]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.price.toInt()} ₽',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: onAddToCart,
                      child: const Icon(Icons.add_shopping_cart, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  final List<Product> cart;

  const CartPage({super.key, required this.cart});

  double get _total => cart.fold(0, (sum, p) => sum + p.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина (${cart.length})'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: cart.isEmpty
          ? const Center(
              child: Text('Корзина пуста', style: TextStyle(fontSize: 16)),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = cart[index];
                      return ListTile(
                        leading: CircleAvatar(child: Icon(p.icon, size: 20)),
                        title: Text(p.name),
                        subtitle: Text(p.category),
                        trailing: Text(
                          '${p.price.toInt()} ₽',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Итого:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_total.toInt()} ₽',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Заказ успешно оформлен!'),
                            ),
                          ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Оформить заказ',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
