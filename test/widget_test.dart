import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkzap/app/app.dart';

void main() {
  testWidgets('LinkZap app renders splash screen properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LinkZapApp(),
      ),
    );

    expect(find.text('Link'), findsOneWidget);
    expect(find.text('Zap'), findsOneWidget);
  });
}
