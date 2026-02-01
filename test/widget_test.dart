// Basic Flutter widget test for Amorae app

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amorae/app/app.dart';

void main() {
  testWidgets('Amorae app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AmoraeApp(),
      ),
    );

    // Wait for async initialization
    await tester.pump();
    
    // Verify app renders
    expect(find.byType(AmoraeApp), findsOneWidget);
  });
}
