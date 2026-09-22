import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkzap/app/router.dart';

void main() {
  testWidgets('MainNavigationScaffold renders Home tab properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationScaffold(),
        ),
      ),
    );

    expect(find.text('Paste. Zap. Share.'), findsOneWidget);
    expect(find.text('⚡ ZAP QR'), findsOneWidget);
  });
}
