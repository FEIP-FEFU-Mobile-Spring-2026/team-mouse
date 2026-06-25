import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../viewmodel/catalog_viewmodel.dart';
import '../widgets/product_detail_sheet.dart';
import '../widgets/product_list_tile.dart';
import '../widgets/skeleton_tile.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (vm.isOffline) const _OfflineBanner(),
                  _buildTabBar(context, vm),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, vm)),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context, CatalogViewModel vm) {
    if (vm.status == CatalogStatus.loading) {
      return _SkeletonTabs();
    }
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: vm.tabs.length,
        itemBuilder: (_, i) {
          final tab = vm.tabs[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CategoryChip(
              category: tab,
              selected: tab.id == vm.selectedCategoryId,
              onTap: () => vm.selectCategory(tab.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CatalogViewModel vm) {
    switch (vm.status) {
      case CatalogStatus.loading:
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (_, _) => const SkeletonTile(),
        );

      case CatalogStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 72,
                  color: Color(0xFFBDBDBD),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Не удалось загрузить каталог',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  vm.errorMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBDBDBD),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: vm.loadCatalog,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );

      case CatalogStatus.success:
        final products = vm.filteredProducts;
        if (products.isEmpty) {
          return const Center(
            child: Text(
              'Нет товаров в этой категории',
              style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
            ),
          );
        }
        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => showProductDetailSheet(context, products[i]),
            behavior: HitTestBehavior.opaque,
            child: ProductListTile(product: products[i]),
          ),
        );
    }
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3E0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Text(
            'Нет сети — показаны сохранённые данные',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFE65100),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          border: Border.all(
            color: selected ? primary : const Color(0xFFD0D0D0),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }
}

class _SkeletonTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            width: const [78.0, 60.0, 72.0, 88.0][i],
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
