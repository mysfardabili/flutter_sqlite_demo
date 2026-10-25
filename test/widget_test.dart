import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sqlite_demo/main.dart';

void main() {
  testWidgets('App renders without crashing smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('CatatanKu'), findsOneWidget);
  });
}
