import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/price_formatter.dart';
import '../viewmodel/cart_viewmodel.dart';
import '../viewmodel/catalog_viewmodel.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _commentController = TextEditingController();
  bool _nameValid = false;
  bool _emailValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validate);
    _emailController.addListener(_validate);
  }

  void _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    setState(() {
      _nameValid = name.isNotEmpty;
      _emailValid = emailRe.hasMatch(email);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final catalog = context.watch<CatalogViewModel>();

    if (cart.isEmpty) {
      return _EmptyState();
    }

    final lines = cart.lines;
    final productsById = {for (final p in catalog.products) p.id: p};

    int totalKopecks = 0;
    for (final line in lines) {
      final product = productsById[line.productId];
      if (product != null) {
        totalKopecks += product.priceInKopecks * line.quantity;
      }
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              _ClearButton(
                onClear: () => _confirmClear(context, cart),
              ),
              const Divider(height: 1),
              ...lines.map((line) {
                final product = productsById[line.productId];
                if (product == null) return const SizedBox.shrink();

                final sizeName = line.sizeId.isEmpty
                    ? null
                    : product.sizes
                        .where((s) => s.id == line.sizeId)
                        .map((s) => s.name)
                        .firstOrNull;

                return Column(
                  children: [
                    _CartLineItem(
                      imageUrl: product.imageUrl,
                      name: product.name,
                      sizeName: sizeName,
                      priceKopecks: product.priceInKopecks * line.quantity,
                      quantity: line.quantity,
                      onRemove: () =>
                          cart.remove(line.productId, line.sizeId),
                      onDecrement: () =>
                          cart.decrement(line.productId, line.sizeId),
                      onIncrement: () =>
                          cart.increment(line.productId, line.sizeId),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }),
              const SizedBox(height: 16),
              _OrderForm(
                nameController: _nameController,
                emailController: _emailController,
                commentController: _commentController,
              ),
            ],
          ),
        ),
        _CartFooter(
          totalKopecks: totalKopecks,
          canOrder: _nameValid && _emailValid,
          primary: primary,
          onOrder: () => _placeOrder(context, cart),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context, CartViewModel cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить корзину?'),
        content:
            const Text('Все товары будут удалены из корзины.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cart.clear();
            },
            child: const Text(
              'Очистить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _placeOrder(BuildContext context, CartViewModel cart) {
    cart.clear();
    _nameController.clear();
    _emailController.clear();
    _commentController.clear();
    _showSuccessSheet(context);
  }

  void _showSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        onBack: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Корзина пуста',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте товары из каталога',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback onClear;

  const _ClearButton({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        icon: const Icon(Icons.delete_outline),
        color: Colors.grey[500],
        tooltip: 'Очистить корзину',
        onPressed: onClear,
      ),
    );
  }
}

class _CartLineItem extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String? sizeName;
  final int priceKopecks;
  final int quantity;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartLineItem({
    required this.imageUrl,
    required this.name,
    required this.sizeName,
    required this.priceKopecks,
    required this.quantity,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFFF2F2F2),
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: Color(0xFFBDBDBD), size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(Icons.close,
                          size: 18, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
                if (sizeName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sizeName!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      formatPrice(priceKopecks),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: primary,
                      ),
                    ),
                    const Spacer(),
                    _QuantityControl(
                      quantity: quantity,
                      color: primary,
                      onDecrement: onDecrement,
                      onIncrement: onIncrement,
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

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final Color color;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControl({
    required this.quantity,
    required this.color,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove, color: color, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
          _QtyBtn(icon: Icons.add, color: color, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _OrderForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController commentController;

  const _OrderForm({
    required this.nameController,
    required this.emailController,
    required this.commentController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _Field(
            controller: nameController,
            label: 'Имя',
            hint: 'Имя*',
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: emailController,
            label: 'Почта',
            hint: 'Почта*',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: commentController,
            label: 'Комментарий',
            hint: 'Комментарий к заказу',
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int minLines;
  final int? maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  final int totalKopecks;
  final bool canOrder;
  final Color primary;
  final VoidCallback onOrder;

  const _CartFooter({
    required this.totalKopecks,
    required this.canOrder,
    required this.primary,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Итого',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                formatPrice(totalKopecks),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: canOrder ? onOrder : null,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                disabledBackgroundColor:
                    primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Оформить',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final VoidCallback onBack;

  const _SuccessSheet({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 32, 24, 32 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'Заказ успешно оформлен',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Подтверждение и чек отправили на\nвашу почту',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Вернуться на главную',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
