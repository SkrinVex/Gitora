import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitora/main.dart';

void main() {
  testWidgets('GitoraApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GitoraApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Welcome to Gitora or main app UI appears
    expect(find.byType(GitoraApp), findsOneWidget);
  });
}
