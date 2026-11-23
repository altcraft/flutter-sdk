import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:altcraft_sdk_example/main.dart';

void main() {
  testWidgets('App loads with Home tab', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AltcraftExampleApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('InApp'), findsOneWidget);
    expect(find.text('Config'), findsOneWidget);
  });
}
