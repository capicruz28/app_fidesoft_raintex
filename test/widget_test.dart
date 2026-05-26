// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_fidesoft/main.dart';
import 'package:app_fidesoft/core/theme/theme_provider.dart';
import 'package:app_fidesoft/core/providers/user_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      // Evita que SplashScreen redirija sin config durante tests.
      'base_url_cliente': 'http://test.local/api/v1',
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => UserProvider()),
        ],
        child: const FidesoftApp(),
      ),
    );

    // Nota: este proyecto no usa Counter demo; verificamos que el app renderice.
    // Evitamos pumpAndSettle porque hay loaders/animaciones continuas en Splash.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
