import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleepwell_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('welcome screen opens the SleepWell dashboard', (tester) async {
    await tester.pumpWidget(const SleepWellApp());
    await tester.pumpAndSettle();
    expect(find.text('SleepWell'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Make it personal'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text("Tonight's routine"), findsOneWidget);
    expect(find.text('Routine'), findsWidgets);
  });

  testWidgets('routine completion is saved locally', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done_v1', true);
    await tester.pumpWidget(const SleepWellApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Put your phone away'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    final stored = await SharedPreferences.getInstance();
    expect(stored.getString('routine_steps_v1'), contains('Put your phone away'));
  });
}
