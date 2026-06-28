import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:team_mouse/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders navigation bar with two tabs', (tester) async {
    await tester.pumpWidget(const MouseStoreApp());
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Меню'), findsOneWidget);
    expect(find.text('Корзина'), findsOneWidget);
  });

  testWidgets('Switching to cart tab shows app bar', (tester) async {
    await tester.pumpWidget(const MouseStoreApp());
    await tester.pump();

    await tester.tap(find.text('Корзина'));
    await tester.pump();

    expect(find.text('Корзина'), findsAtLeastNWidgets(1));
  });
}
