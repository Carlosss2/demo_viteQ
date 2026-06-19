import 'package:flutter_test/flutter_test.dart';
import 'package:secure_app_demo/main.dart';

void main() {
  testWidgets('App renders LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const SecureAppDemo());
    expect(find.text('Iniciar Sesion'), findsOneWidget);
  });
}
