import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/product_repository.dart';
import 'screens/cart_screen.dart';
import 'screens/catalog_screen.dart';
import 'viewmodel/cart_viewmodel.dart';
import 'viewmodel/catalog_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MouseStoreApp());
}

class MouseStoreApp extends StatelessWidget {
  const MouseStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CatalogViewModel(ProductRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => CartViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Mouse Store',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3E2723),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogViewModel>().init();
      context.read<CartViewModel>().loadFromPrefs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartViewModel>().totalItems;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _tab == 1
          ? AppBar(
              title: const Text(
                'Корзина',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 1,
            )
          : null,
      body: IndexedStack(
        index: _tab,
        children: const [
          CatalogScreen(),
          CartScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Меню',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Корзина',
          ),
        ],
      ),
    );
  }
}
