import 'package:flutter_test/flutter_test.dart';
import 'package:sleepwell_app/main.dart';

void main() {
  testWidgets('welcome screen opens the SleepWell dashboard', (tester) async {
    await tester.pumpWidget(const SleepWellApp());
    expect(find.text('SleepWell'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text("Tonight's routine"), findsOneWidget);
    expect(find.text('Routine'), findsWidgets);
  });
}
