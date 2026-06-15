import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:expenzo_frontend/core/theme/app_theme.dart';
import 'package:expenzo_frontend/features/auth/presentation/pages/auth_screen.dart';
import 'package:expenzo_frontend/features/auth/presentation/viewmodels/auth_viewmodel.dart';

void main() {
  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('AuthScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AuthScreen(),
        ),
      ),
    );

    expect(find.text('Expenzo'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    
    // Let animations finish to clear pending timers
    await tester.pumpAndSettle();
  });
}
