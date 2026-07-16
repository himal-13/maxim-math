import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxim_math/main.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for tests if needed (or it might be initialized already)
    try {
      Hive.init('.');
    } catch (_) {}
  });

  testWidgets('Dashboard loads and displays topics', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that dashboard header is displayed
    expect(find.text('MATH DUELS'), findsOneWidget);
    expect(find.text('Sharpen Your Mind'), findsOneWidget);

    // Verify that the Infinity Duel card is displayed
    expect(find.text('INFINITY DUEL'), findsOneWidget);
    expect(find.text('PLAY INFINITY DUEL'), findsOneWidget);

    // Verify that individual topic cards are listed
    expect(find.text('Fractions Duel'), findsOneWidget);
    expect(find.text('Percentages'), findsOneWidget);
    expect(find.text('Powers & Roots'), findsOneWidget);
    expect(find.text('Measurement'), findsOneWidget);
    expect(find.text('Decimals & Ops'), findsOneWidget);
  });
}
