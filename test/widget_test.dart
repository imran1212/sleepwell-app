import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleepwell_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows welcome and opens the home dashboard', (tester) async {
    await tester.pumpWidget(const SleepWellApp());
    await tester.pumpAndSettle();

    expect(find.text('SleepWell'), findsOneWidget);
    expect(find.text('Build a better bedtime routine,\none night at a time.'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Let’s slow things down.'), findsOneWidget);
    expect(find.text("Tonight's routine"), findsOneWidget);
  });

  testWidgets('routine screen can be opened from bottom navigation', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done_v1': true});
    await tester.pumpWidget(const SleepWellApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Routine').last);
    await tester.pumpAndSettle();

    expect(find.text('Your routine'), findsOneWidget);
    expect(find.text('Add a custom step'), findsOneWidget);
  });
}
