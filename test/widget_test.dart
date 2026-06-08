import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app_demo/views/login_view.dart';
import 'package:app_demo/viewmodels/login_viewmodel.dart';
import 'package:app_demo/viewmodels/session_viewmodel.dart';

void main() {
  testWidgets('LoginView renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LoginViewModel()),
          ChangeNotifierProvider(create: (_) => SessionViewModel()),
        ],
        child: const MaterialApp(home: LoginView()),
      ),
    );

    expect(find.text('ViteQ'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
