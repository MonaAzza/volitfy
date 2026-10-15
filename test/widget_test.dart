import 'package:flutter_test/flutter_test.dart';
import 'package:gaza_solar_guardian/main.dart';

void main() {
  testWidgets('App loads splash screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const GazaSolarGuardianApp());
    expect(find.byType(GazaSolarGuardianApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
