import 'package:flutter_test/flutter_test.dart';
import 'package:altcraft_sdk_example/main.dart';

void main() {
  testWidgets('App loads with Home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const AltcraftExampleApp());
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Config'), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);
  });
}
