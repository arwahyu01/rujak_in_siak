import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/theme/app_theme.dart';
import 'package:rujak_pos/features/splash/splash_screen.dart';

void main() {
  testWidgets('splash screen renders the app brand', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.build(), home: const SplashScreen()),
    );

    expect(find.text('RUJAK.IN.SIAK'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
