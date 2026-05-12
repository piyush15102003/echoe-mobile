import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echoe_mobile/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EchoeApp(initialLocation: '/onboarding/language'),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
