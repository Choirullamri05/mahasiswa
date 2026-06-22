import 'package:database_mahasiswa/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shows the login page content', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Login Admin'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
