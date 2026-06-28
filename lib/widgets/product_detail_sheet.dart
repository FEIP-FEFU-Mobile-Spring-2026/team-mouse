import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../utils/price_formatter.dart';
import '../viewmodel/cart_viewmodel.dart';

void showProductDetailSheet(BuildContext context, Product product) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProductDetailSheet(product: product),
  );
}

class _ProductDetailSheet extends StatefulWidget {
  final Product product;

  const _ProductDetailSheet({required this.product});

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  String? _selectedSizeId;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final primary = Theme.of(context).colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _DragHandle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    _ImageSection(product: product),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _InfoButton(product: product),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.longDescription,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            formatPrice(product.priceInKopecks),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                          if (product.sizes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Размер',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _SizeSelector(
                              sizes: product.sizes,
                              selectedId: _selectedSizeId,
                              onSelect: (id) =>
                                  setState(() => _selectedSizeId = id),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _AddToCartButton(
                product: product,
                selectedSizeId: _selectedSizeId,
                primary: primary,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD0D0D0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final Product product;

  const _ImageSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            product.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _ImageLoading(),
            errorBuilder: (_, _, _) => _ImageError(),
          ),
        ),
        if (product.tags.isNotEmpty)
          Positioned(
            left: 12,
            bottom: 12,
            child: Wrap(
              spacing: 6,
              children: product.tags
                  .map((tag) => _TagChip(label: tag))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _ImageLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFFBDBDBD),
          size: 48,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  final Product product;

  const _InfoButton({required this.product});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      color: const Color(0xFF9E9E9E),
      tooltip: 'Характеристики',
      onPressed: () => _showInfoDialog(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final product = this.product;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Характеристики'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.material.isNotEmpty)
              _InfoRow(label: 'Материал', value: product.material),
            if (product.weight.isNotEmpty)
              _InfoRow(label: 'Вес', value: product.weight),
            if (product.season.isNotEmpty)
              _InfoRow(label: 'Сезон', value: product.season),
            if (product.countryOfOrigin.isNotEmpty)
              _InfoRow(
                label: 'Страна производства',
                value: product.countryOfOrigin,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeSelector extends StatelessWidget {
  final List<ProductSize> sizes;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _SizeSelector({
    required this.sizes,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((size) {
        final isSelected = size.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(size.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? primary : const Color(0xFFD0D0D0),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              size.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final Product product;
  final String? selectedSizeId;
  final Color primary;

  const _AddToCartButton({
    required this.product,
    required this.selectedSizeId,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    // Если у товара есть размеры — кнопка активна только после выбора размера.
    final needsSize = product.sizes.isNotEmpty;
    final canAdd = !needsSize || selectedSizeId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: canAdd ? () => _addToCart(context) : null,
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            disabledBackgroundColor: primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            needsSize && selectedSizeId == null
                ? 'Выберите размер'
                : 'В корзину · ${formatPrice(product.priceInKopecks)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    // Для товара без размеров используем пустой идентификатор размера.
    final sizeId = selectedSizeId ?? '';
    context.read<CartViewModel>().add(product.id, sizeId);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('«${product.name}» добавлен в корзину'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
