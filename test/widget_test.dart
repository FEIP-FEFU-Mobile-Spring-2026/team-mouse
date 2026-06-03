import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:team_mouse/main.dart';

void main() {
  testWidgets('Catalog page shows products and cart icon', (WidgetTester tester) async {
    await tester.pumpWidget(const MouseStoreApp());

    expect(find.text('Mouse Store'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('Adding product to cart updates badge', (WidgetTester tester) async {
    await tester.pumpWidget(const MouseStoreApp());

    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Category filter shows correct products', (WidgetTester tester) async {
    await tester.pumpWidget(const MouseStoreApp());

    await tester.tap(find.text('Футболки'));
    await tester.pump();

    final cards = tester.widgetList<ProductCard>(find.byType(ProductCard));
    expect(cards.every((c) => c.product.category == 'Футболки'), isTrue);
  });
}
