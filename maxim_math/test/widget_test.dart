import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maxim_math/main.dart';
import 'package:maxim_math/core/health_service.dart';
import 'package:maxim_math/core/score_provider.dart';
import 'package:maxim_math/core/reward_provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('maxim_math_test');
    Hive.init(tempDir.path);
  });

  testWidgets('Dashboard loads and displays topics', (WidgetTester tester) async {
    late HealthService healthService;
    late ScoreProvider scoreProvider;
    late RewardProvider rewardProvider;

    // Run real I/O operations (Hive openBox) inside runAsync to bypass fake clock
    await tester.runAsync(() async {
      healthService = HealthService();
      await healthService.init();

      scoreProvider = ScoreProvider();
      await scoreProvider.init();

      rewardProvider = RewardProvider();
      await rewardProvider.init();
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: healthService),
          ChangeNotifierProvider.value(value: scoreProvider),
          ChangeNotifierProvider.value(value: rewardProvider),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that dashboard header is displayed
    expect(find.text('Sharpen Your Mind'), findsOneWidget);

    // Verify that individual topic cards are listed
    expect(find.text('Basic Ops'), findsOneWidget);
    expect(find.text('Fractions'), findsOneWidget);
    expect(find.text('Decimals'), findsOneWidget);
    expect(find.text('Percent'), findsOneWidget);
    expect(find.text('Powers'), findsOneWidget);
    expect(find.text('Infinity'), findsOneWidget);
  });
}
