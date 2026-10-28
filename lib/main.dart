import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() => runApp(const SleepWellApp());

const bg = Color(0xFF0B1025);
const card = Color(0xFF151D3B);
const violet = Color(0xFF8B7CFF);
const lilac = Color(0xFFC6BCFF);
const mint = Color(0xFF7DE2D1);
final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
bool notificationsInitialized = false;

class SleepWellApp extends StatelessWidget {
  const SleepWellApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SleepWell',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: violet, brightness: Brightness.dark),
    ),
    home: const SleepShell(),
  );
}

class RoutineStep {
  RoutineStep(this.title, this.subtitle, this.icon, {this.done = false});
  final String title;
  final String subtitle;
  final IconData icon;
  bool done;
}

class SleepShell extends StatefulWidget {
  const SleepShell({super.key});
  @override
  State<SleepShell> createState() => _SleepShellState();
}

class _SleepShellState extends State<SleepShell> {
  bool started = false;
  bool onboardingQuestions = false;
  bool loadingSavedData = true;
  String wakeTime = '07:00';
  String preferredBedtime = '23:00';
  String sleepDifficulty = 'falling';
  String sleepGoal = 'routine';
  bool reminders = false;
  int breathingSessionMinutes = 1;
  Timer? breathingTimer;
  int breathingSecondsRemaining = 60;
  bool breathingActive = false;
  int tab = 0;
  int quality = 3;
  int mood = 1;
  String bedtime = '10:30 PM';
  final note = TextEditingController();
  final List<Map<String, dynamic>> diaryEntries = [];
  final Map<String, int> dailyCompletions = {};
  late List<RoutineStep> steps = <RoutineStep>[
    RoutineStep('Put your phone away', 'Give your mind a screen break', Icons.phone_iphone),
    RoutineStep('Breathe slowly', 'A few calm, gentle breaths', Icons.air),
    RoutineStep('Listen and unwind', 'Choose a calming sound', Icons.music_note),
    RoutineStep('Read a few pages', 'Ease into a quieter evening', Icons.menu_book),
    RoutineStep('Lights out', 'Let the day come to a close', Icons.nightlight_round),
  ];
  int get completed => steps.where((s) => s.done).length;
  int get currentStreak {
    var streak = 0;
    var day = DateTime.now();
    while (true) {
      final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final count = dailyCompletions[key] ?? (key == todayKey ? completed : 0);
      if (count <= 0) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
  String get todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  IconData _iconFromCode(int code) {
    const knownIcons = <int, IconData>{
      0xe8b8: Icons.settings_outlined,
    };
    if (code == Icons.phone_iphone.codePoint) return Icons.phone_iphone;
    if (code == Icons.air.codePoint) return Icons.air;
    if (code == Icons.music_note.codePoint) return Icons.music_note;
    if (code == Icons.menu_book.codePoint) return Icons.menu_book;
    if (code == Icons.nightlight_round.codePoint) return Icons.nightlight_round;
    if (code == Icons.check_circle_outline.codePoint) return Icons.check_circle_outline;
    return knownIcons[code] ?? Icons.check_circle_outline;
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedSteps = prefs.getString('routine_steps_v1');
    if (savedSteps != null) {
      try {
        final decoded = jsonDecode(savedSteps) as List<dynamic>;
        steps = decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          final title = map['title'] as String? ?? 'Routine step';
          final subtitle = map['subtitle'] as String? ?? 'Your custom routine step';
          final done = map['done'] as bool? ?? false;
          final code = map['icon'] as int? ?? Icons.check_circle_outline.codePoint;
          return RoutineStep(title, subtitle, _iconFromCode(code), done: done);
        }).toList();
      } catch (_) {
        // Ignore malformed local data and keep the safe default routine.
      }
    }
    final savedRoutineDate = prefs.getString('routine_completed_date_v1');
    if (savedRoutineDate != null && savedRoutineDate != todayKey) {
      for (final step in steps) { step.done = false; }
    }
    started = prefs.getBool('onboarding_done_v1') ?? false;
    onboardingQuestions = false;
    wakeTime = prefs.getString('sleep_wake_time_v1') ?? '07:00';
    preferredBedtime = prefs.getString('sleep_preferred_bedtime_v1') ?? '23:00';
    sleepDifficulty = prefs.getString('sleep_difficulty_v1') ?? 'falling';
    sleepGoal = prefs.getString('sleep_goal_v1') ?? 'routine';
    bedtime = prefs.getString('bedtime_v1') ?? _formatSavedTime(preferredBedtime);
    reminders = prefs.getBool('bedtime_reminders_v1') ?? false;
    final savedDiary = prefs.getString('sleep_diary_v1');
    if (savedDiary != null) {
      try {
        diaryEntries.addAll((jsonDecode(savedDiary) as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)));
        if (diaryEntries.isNotEmpty) {
          final latest = diaryEntries.last;
          quality = latest['quality'] as int? ?? quality;
          mood = latest['mood'] as int? ?? mood;
          note.text = latest['note'] as String? ?? '';
        }
      } catch (_) {}
    }
    final savedCompletions = prefs.getString('daily_completions_v1');
    if (savedCompletions != null) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(savedCompletions) as Map);
        decoded.forEach((key, value) { if (value is int) dailyCompletions[key] = value; });
      } catch (_) {}
    }
    if (mounted) setState(() => loadingSavedData = false);
    // Ask for notification permission contextually when the user enables reminders.
    // Avoid triggering platform permission UI before onboarding or in widget tests.
    // Restore the daily reminder after app restarts when the user has enabled it.
    if (reminders && mounted) await _setBedtimeReminder(true);
  }

  Future<void> _saveRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('routine_steps_v1', jsonEncode(steps.map((s) => {
      'title': s.title, 'subtitle': s.subtitle, 'icon': s.icon.codePoint, 'done': s.done,
    }).toList()));
    dailyCompletions[todayKey] = completed;
    await prefs.setString('routine_completed_date_v1', todayKey);
    await prefs.setString('daily_completions_v1', jsonEncode(dailyCompletions));
  }

  Future<void> _savePreference(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  @override
  void dispose() { breathingTimer?.cancel(); note.dispose(); super.dispose(); }


  Future<void> _startBreathingSession() async {
    if (breathingActive) {
      breathingTimer?.cancel();
      setState(() => breathingActive = false);
      return;
    }
    if (breathingSecondsRemaining <= 0) setState(() => breathingSecondsRemaining = breathingSessionMinutes * 60);
    setState(() => breathingActive = true);
    breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (breathingSecondsRemaining <= 1) {
        timer.cancel();
        setState(() { breathingSecondsRemaining = 0; breathingActive = false; });
        _snack('Breathing session complete. Well done for taking a quiet moment.');
      } else {
        setState(() => breathingSecondsRemaining--);
      }
    });
  }

  void _resetBreathingSession() {
    breathingTimer?.cancel();
    setState(() { breathingActive = false; breathingSecondsRemaining = breathingSessionMinutes * 60; });
  }

  Future<void> _initializeNotifications() async {
    if (notificationsInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await localNotifications.initialize(settings);
    tzdata.initializeTimeZones();
    final zoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zoneName));
    notificationsInitialized = true;
  }

  tz.TZDateTime _nextBedtime() {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false).matchAsPrefix(bedtime.trim());
    var hour = 22;
    var minute = 30;
    if (match != null) {
      hour = int.parse(match.group(1)!);
      minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();
      if (period == 'AM' && hour == 12) hour = 0;
      if (period == 'PM' && hour != 12) hour += 12;
    }
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  Future<void> _sendTestNotification() async {
    try {
      await _initializeNotifications();
      final androidPlugin = localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      const details = NotificationDetails(android: AndroidNotificationDetails(
        'sleepwell_test', 'SleepWell test notifications',
        channelDescription: 'Used to verify that notifications can appear on this device.',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ));
      await localNotifications.show(99, 'SleepWell test', 'Notifications are working on this device.', details);
      final pending = await localNotifications.pendingNotificationRequests();
      if (mounted) _snack('Test sent. Permission: ${granted ?? "already granted"}. Pending reminders: ${pending.length}.');
    } catch (e) {
      if (mounted) _snack('Notification test failed: $e');
    }
  }

  Future<void> _setBedtimeReminder(bool enabled) async {
    setState(() => reminders = enabled);
    await _savePreference('bedtime_reminders_v1', enabled);
    if (!enabled) {
      await localNotifications.cancel(1);
      if (mounted) _snack('Bedtime reminder turned off.');
      return;
    }
    try {
      await _initializeNotifications();
      final androidPlugin = localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      const details = NotificationDetails(android: AndroidNotificationDetails(
        'sleepwell_bedtime', 'Bedtime reminders',
        channelDescription: 'A gentle reminder when it is time to wind down.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ));
      await localNotifications.zonedSchedule(
        1,
        'Time to wind down',
        'Your bedtime routine is ready when you are.',
        _nextBedtime(),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      if (mounted) _snack('Daily bedtime reminder scheduled for ' + bedtime + '.');
    } catch (e) {
      if (mounted) {
        setState(() => reminders = false);
        await _savePreference('bedtime_reminders_v1', false);
        _snack('Could not schedule reminder: $e');
      }
    }
  }

@override
  Widget build(BuildContext context) {
    if (loadingSavedData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!started) return onboardingQuestions ? _personalization() : _welcome();
    final pages = [_home(), _routine(), _relax(), _diary(), _progress()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF111831),
        indicatorColor: violet.withValues(alpha: .24),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Routine'),
          NavigationDestination(icon: Icon(Icons.nightlight_outlined), selectedIcon: Icon(Icons.nightlight), label: 'Relax'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Diary'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'),
        ],
      ),
    );
  }

  Widget _welcome() => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF22265A), bg, Color(0xFF090D1C)])),
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          const Spacer(),
          Container(width: 112, height: 112, decoration: BoxDecoration(borderRadius: BorderRadius.circular(34), gradient: const LinearGradient(colors: [violet, Color(0xFF4542A5)])), child: const Icon(Icons.nightlight_round, size: 64, color: Colors.white)),
          const SizedBox(height: 26),
          const Text('SleepWell', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -.8)),
          const SizedBox(height: 8),
          const Text('Sleep & Wind-Down Coach', style: TextStyle(fontSize: 16, color: lilac)),
          const SizedBox(height: 18),
          const Text('Build a better bedtime routine,\none night at a time.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white70)),
          const Spacer(),
          _button('Get started', () { setState(() => onboardingQuestions = true); }),
          const SizedBox(height: 14),
          const Text('A calmer end to your day', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      )),
    ),
  );

  String _formatSavedTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return '11:00 PM';
    var hour = int.tryParse(parts[0]) ?? 23;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return hour.toString() + ':' + minute.toString().padLeft(2, '0') + ' ' + period;
  }

  Future<void> _completePersonalization({required bool skipped}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!skipped) {
      await prefs.setString('sleep_wake_time_v1', wakeTime);
      await prefs.setString('sleep_preferred_bedtime_v1', preferredBedtime);
      await prefs.setString('sleep_difficulty_v1', sleepDifficulty);
      await prefs.setString('sleep_goal_v1', sleepGoal);
      final savedBedtime = _formatSavedTime(preferredBedtime);
      await prefs.setString('bedtime_v1', savedBedtime);
      if (mounted) setState(() => bedtime = savedBedtime);
      final revised = <RoutineStep>[
        RoutineStep('Put your phone away', 'Give your mind a screen break', Icons.phone_iphone),
        RoutineStep(
          sleepDifficulty == 'anxiety' ? 'Quiet your thoughts' : 'Breathe slowly',
          sleepDifficulty == 'anxiety'
              ? 'Try a gentle breathing pause to unwind'
              : 'A few calm, gentle breaths',
          Icons.air,
        ),
        RoutineStep(
          sleepGoal == 'relax' ? 'Listen and unwind' : 'Prepare for tomorrow',
          sleepGoal == 'relax'
              ? 'Choose a calming sound when audio is available'
              : 'Make tomorrow feel a little easier',
          sleepGoal == 'relax' ? Icons.music_note : Icons.check_circle_outline,
        ),
        RoutineStep('Read a few pages', 'Ease into a quieter evening', Icons.menu_book),
        RoutineStep('Lights out', 'Aim for your chosen bedtime', Icons.nightlight_round),
      ];
      final hadSavedRoutine = prefs.getString('routine_steps_v1') != null;
      if (!hadSavedRoutine) steps = revised;
    }
    await prefs.setBool('onboarding_done_v1', true);
    if (!mounted) return;
    setState(() {
      started = true;
      onboardingQuestions = false;
      tab = 0;
    });
    if (!skipped) {
      await _saveRoutine();
      _snack('Your sleep preferences are saved. Your routine is personalized.');
    } else {
      _snack('You can personalize your sleep routine later.');
    }
  }

  Widget _personalization() => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF22265A), bg, Color(0xFF090D1C)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PERSONALIZATION', style: TextStyle(color: lilac, fontSize: 11, letterSpacing: 1.4)),
                        SizedBox(height: 4),
                        Text('Make it personal', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _completePersonalization(skipped: true),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A few quick answers help SleepWell shape a routine around you.', style: TextStyle(color: Colors.white70, height: 1.45)),
                    const SizedBox(height: 20),
                    _questionCard(
                      '1. What time do you usually wake up?',
                      [
                        _choice('6:00 AM', '06:00', wakeTime, (v) => setState(() => wakeTime = v)),
                        _choice('7:00 AM', '07:00', wakeTime, (v) => setState(() => wakeTime = v)),
                        _choice('8:00 AM', '08:00', wakeTime, (v) => setState(() => wakeTime = v)),
                        _choice('9:00 AM or later', '09:00', wakeTime, (v) => setState(() => wakeTime = v)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _questionCard(
                      '2. What time do you usually go to bed?',
                      [
                        _choice('9:00 PM', '21:00', preferredBedtime, (v) => setState(() => preferredBedtime = v)),
                        _choice('10:00 PM', '22:00', preferredBedtime, (v) => setState(() => preferredBedtime = v)),
                        _choice('11:00 PM', '23:00', preferredBedtime, (v) => setState(() => preferredBedtime = v)),
                        _choice('Midnight or later', '00:00', preferredBedtime, (v) => setState(() => preferredBedtime = v)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _questionCard(
                      '3. What makes sleep difficult?',
                      [
                        _choice('Falling asleep', 'falling', sleepDifficulty, (v) => setState(() => sleepDifficulty = v)),
                        _choice('Stress or racing thoughts', 'anxiety', sleepDifficulty, (v) => setState(() => sleepDifficulty = v)),
                        _choice('Waking during the night', 'waking', sleepDifficulty, (v) => setState(() => sleepDifficulty = v)),
                        _choice('Irregular sleep schedule', 'schedule', sleepDifficulty, (v) => setState(() => sleepDifficulty = v)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _questionCard(
                      '4. What is your main sleep goal?',
                      [
                        _choice('Build a consistent routine', 'routine', sleepGoal, (v) => setState(() => sleepGoal = v)),
                        _choice('Relax before bedtime', 'relax', sleepGoal, (v) => setState(() => sleepGoal = v)),
                        _choice('Wake up refreshed', 'energy', sleepGoal, (v) => setState(() => sleepGoal = v)),
                        _choice('Understand sleep patterns', 'track', sleepGoal, (v) => setState(() => sleepGoal = v)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _button('Save and build my routine', () => _completePersonalization(skipped: false)),
                    const SizedBox(height: 10),
                    const Text('Your answers stay on this device. You can skip now and personalize later.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _questionCard(String title, List<Widget> choices) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        ...choices,
      ],
    ),
  );

  Widget _choice(String label, String value, String selected, ValueChanged<String> onChanged) => RadioListTile<String>(
    value: value,
    groupValue: selected,
    onChanged: (v) { if (v != null) onChanged(v); },
    title: Text(label, style: const TextStyle(fontSize: 14)),
    dense: true,
    visualDensity: VisualDensity.compact,
    contentPadding: EdgeInsets.zero,
    activeColor: lilac,
  );

  Widget _home() => _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GOOD EVENING', style: TextStyle(color: lilac, fontSize: 12, letterSpacing: 1.5)),
        SizedBox(height: 5),
        Text('Let’s slow things down.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      ])),
      IconButton(onPressed: _settings, icon: const Icon(Icons.settings_outlined)),
    ]),
    const SizedBox(height: 22), _bedtimeCard(), const SizedBox(height: 24),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text("Tonight's routine", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(completed.toString() + '/' + steps.length.toString(), style: const TextStyle(color: lilac)),
    ]),
    const SizedBox(height: 12),
    ...steps.take(4).map(_stepTile),
    _outline('View full routine', () => setState(() => tab = 1)),
    const SizedBox(height: 22),
    const Text('A little moment for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    _action(Icons.air, 'Take a breathing break', 'One quiet minute', () => setState(() => tab = 2)),
  ]));

  Widget _bedtimeCard() => Container(width: double.infinity, padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5145B8), Color(0xFF25265F), Color(0xFF1A2349)])),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('YOUR BEDTIME', style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: Colors.white70)),
        const SizedBox(height: 8), Text(bedtime, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5), const Text('Make room for rest', style: TextStyle(color: Colors.white70)),
        TextButton.icon(onPressed: _editBedtime, icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit bedtime'), style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero)),
      ])),
      const Icon(Icons.nights_stay_rounded, size: 74, color: lilac),
    ]));

  Widget _routine() => _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Your routine', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8), const Text('Small steps can make evenings feel calmer.', style: TextStyle(color: Colors.white60)),
    const SizedBox(height: 22),
    Container(padding: const EdgeInsets.all(18), decoration: _decoration(), child: Row(children: [
      const Icon(Icons.auto_awesome, color: lilac, size: 28), const SizedBox(width: 12),
      Expanded(child: Text(completed.toString() + ' of ' + steps.length.toString() + ' steps complete', style: const TextStyle(fontWeight: FontWeight.w700))),
      Text((steps.isEmpty ? 0 : completed / steps.length * 100).round().toString() + '%', style: const TextStyle(color: mint, fontWeight: FontWeight.bold)),
    ])),
    const SizedBox(height: 16), ...steps.map((s) => _stepTile(s, large: true)),
    _button('Reset tonight’s checklist', () { setState(() { for (final s in steps) { s.done = false; } }); _saveRoutine(); }),
    const SizedBox(height: 10), _outline('Add a custom step', _addStep),
  ]));

  Widget _relax() => _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Relax & unwind', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    const Text('Take a gentle pause before bedtime.', style: TextStyle(color: Colors.white60)),
    const SizedBox(height: 24),
    Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [Color(0xFF2C326F), Color(0xFF18284A)])),
      child: Column(children: [
        const Text('SLOW BREATHING', style: TextStyle(color: lilac, letterSpacing: 1.6, fontSize: 11)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [1, 3, 5].map((minutes) => ChoiceChip(label: Text('$minutes min'), selected: breathingSessionMinutes == minutes, onSelected: breathingActive ? null : (_) => setState(() { breathingSessionMinutes = minutes; breathingSecondsRemaining = minutes * 60; }))).toList()),
        const SizedBox(height: 14),
        Container(width: 154, height: 154, decoration: BoxDecoration(shape: BoxShape.circle, color: violet.withValues(alpha: .15), border: Border.all(color: lilac.withValues(alpha: .6), width: 2)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.air, size: 42, color: lilac), const SizedBox(height: 8), Text('${(breathingSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(breathingSecondsRemaining % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold))]))),
        const SizedBox(height: 18),
        Text(breathingActive ? (breathingSecondsRemaining % 8 < 4 ? 'Breathe in gently' : 'Breathe out slowly') : 'A quiet $breathingSessionMinutes-minute pause', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        const Text('Follow a comfortable pace. Stop if you feel dizzy or uncomfortable.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 18),
        Row(children: [Expanded(child: _button(breathingActive ? 'Pause session' : (breathingSecondsRemaining == 0 ? 'Start again' : 'Start $breathingSessionMinutes-minute session'), _startBreathingSession)), const SizedBox(width: 10), IconButton(tooltip: 'Reset timer', onPressed: _resetBreathingSession, icon: const Icon(Icons.refresh), style: IconButton.styleFrom(foregroundColor: lilac, backgroundColor: violet.withValues(alpha: .15)))],),
      ])),
    const SizedBox(height: 24),
    const Text('Sound library', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    _action(Icons.water, 'Gentle ocean', 'Ambient audio is planned for the next audio milestone', () => _snack('Ocean audio needs a licensed audio track before playback can be enabled.')),
    _action(Icons.park_outlined, 'Quiet forest', 'Nature ambience', () => _snack('Forest audio needs a licensed audio track before playback can be enabled.')),
    _action(Icons.grain, 'Soft rain', 'Rain ambience', () => _snack('Rain audio needs a licensed audio track before playback can be enabled.')),
  ]));

  Widget _diary() => _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Sleep diary', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8), const Text('A quick check-in on how you feel.', style: TextStyle(color: Colors.white60)),
    const SizedBox(height: 24), const Text('How did you sleep?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(5, (i) {
      const faces = ['😴', '😕', '😐', '🙂', '😊'];
      return InkWell(onTap: () => setState(() => quality = i + 1), borderRadius: BorderRadius.circular(16),
        child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: quality == i + 1 ? violet.withValues(alpha: .3) : card, borderRadius: BorderRadius.circular(16), border: Border.all(color: quality == i + 1 ? lilac : Colors.white10)), child: Text(faces[i], style: const TextStyle(fontSize: 23))));
    })),
    const SizedBox(height: 24), const Text('How is your energy today?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    Wrap(spacing: 8, children: ['Tired', 'Okay', 'Energised'].asMap().entries.map((e) => ChoiceChip(label: Text(e.value), selected: mood == e.key, onSelected: (_) => setState(() => mood = e.key), selectedColor: violet.withValues(alpha: .35))).toList()),
    const SizedBox(height: 24), const Text('A note for yourself (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 10),
    TextField(controller: note, maxLines: 4, decoration: InputDecoration(hintText: 'What would you like to remember?', filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
    const SizedBox(height: 20), _button('Save check-in', _saveDiaryEntry),
    const SizedBox(height: 14), const Text('For personal reflection, not medical diagnosis.', style: TextStyle(fontSize: 12, color: Colors.white54)),
  ]));

  Widget _progress() => _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Your progress', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8), const Text('Celebrate the small steps you take.', style: TextStyle(color: Colors.white60)),
    const SizedBox(height: 24),
    Row(children: [
      Expanded(child: _metric('Routine steps', completed.toString() + '/' + steps.length.toString(), Icons.check_circle_outline, lilac)),
      const SizedBox(width: 12), Expanded(child: _metric('Current streak', currentStreak.toString() + (currentStreak == 1 ? ' day' : ' days'), Icons.local_fire_department_outlined, mint)),
    ]),
    const SizedBox(height: 16),
    Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: _decoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('This week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), const Text('Completed routine steps by day', style: TextStyle(color: Colors.white60, fontSize: 12)),
      const SizedBox(height: 22),
      SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
        final now = DateTime.now();
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
        final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final heights = (dailyCompletions[key] ?? (key == todayKey ? completed : 0)) * (steps.isEmpty ? 0.0 : 100.0 / steps.length) + 8;
        const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final label = weekdayLabels[day.weekday - 1];
        return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(width: 22, height: heights.clamp(8, 120).toDouble(), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF6558DA), lilac]))),
          const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ]);
      }))),
    ])),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(16), decoration: _decoration(), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, color: lilac), SizedBox(width: 12),
      Expanded(child: Text('Your routine history is saved on this device. Diary trends and sleep-time summaries can be expanded in a future update.', style: TextStyle(color: Colors.white70, height: 1.4))),
    ])),
    const SizedBox(height: 16),
    _action(Icons.workspace_premium_outlined, 'Explore Premium', 'More routines and an ad-free experience', _premium),
  ]));

  Widget _stepTile(RoutineStep s, {bool large = false}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(value: s.done, onChanged: (v) { setState(() => s.done = v ?? false); _saveRoutine(); },
        controlAffinity: ListTileControlAffinity.leading, activeColor: violet, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        secondary: Container(width: 42, height: 42, decoration: BoxDecoration(color: violet.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)), child: Icon(s.icon, color: lilac)),
        title: Text(s.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: s.done ? TextDecoration.lineThrough : null)),
        subtitle: Text(large ? s.subtitle + ' • 5 min' : s.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))),
    ),
  );

  Widget _action(IconData icon, String title, String subtitle, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ListTile(onTap: onTap, leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: violet.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: lilac)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)), trailing: const Icon(Icons.chevron_right, color: Colors.white54)),
    ),
  );

  Widget _metric(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16), decoration: _decoration(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 25), const SizedBox(height: 16),
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    ]),
  );

  Widget _shell(Widget child) => SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), child: child);
  BoxDecoration _decoration() => BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .045)));
  Widget _button(String label, VoidCallback action) => SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: action, style: FilledButton.styleFrom(backgroundColor: violet, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))));
  Widget _outline(String label, VoidCallback action) => SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: action, style: OutlinedButton.styleFrom(foregroundColor: lilac, side: const BorderSide(color: Color(0xFF49466F)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(label)));

  void _addStep() {
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: card, title: const Text('Add a routine step'),
      content: TextField(controller: controller, autofocus: true, maxLength: 50, decoration: const InputDecoration(hintText: 'e.g. Prepare for tomorrow')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final value = controller.text.trim();
          if (value.isNotEmpty) { setState(() => steps.insert(steps.length - 1, RoutineStep(value, 'Your custom routine step', Icons.check_circle_outline))); _saveRoutine(); }
          Navigator.pop(ctx);
        }, child: const Text('Add')),
      ]));
  }

  void _editBedtime() {
    showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 30))
       .then((t) { if (t != null && mounted) { final value = t.format(context); setState(() => bedtime = value); _savePreference('bedtime_v1', value); if (reminders) { _setBedtimeReminder(true); } else { _snack('Bedtime saved: ' + value); } } });
  }

  void _settings() {
    showModalBottomSheet(context: context, backgroundColor: card, showDragHandle: true, builder: (ctx) => StatefulBuilder(builder: (ctx, updateSheet) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Settings', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        SwitchListTile(title: const Text('Bedtime reminders'), subtitle: const Text('A daily notification at your saved bedtime'), value: reminders, onChanged: (v) async { await _setBedtimeReminder(v); updateSheet(() {}); }),
        ListTile(leading: const Icon(Icons.notifications_active_outlined), title: const Text('Send test notification'), subtitle: const Text('Show a notification immediately'), onTap: () async { await _sendTestNotification(); }),
        ListTile(leading: const Icon(Icons.workspace_premium_outlined), title: const Text('SleepWell Premium'), onTap: () { Navigator.pop(ctx); _premium(); }),
        const ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy'), subtitle: Text('Privacy policy will be linked before release')),
      ]),
    )));
  }

  void _premium() {
    showModalBottomSheet(context: context, backgroundColor: card, showDragHandle: true, isScrollControlled: true, builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.nights_stay_rounded, size: 52, color: lilac), const SizedBox(height: 12),
        const Text('SleepWell Premium', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8), const Text('More ways to make evenings your own.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 20),
        const ListTile(leading: Icon(Icons.check_circle_outline, color: mint), title: Text('Full relaxation library')),
        const ListTile(leading: Icon(Icons.check_circle_outline, color: mint), title: Text('Custom routine options')),
        const ListTile(leading: Icon(Icons.check_circle_outline, color: mint), title: Text('Ad-free experience')),
        const SizedBox(height: 12),
        _button('Preview premium state', () { Navigator.pop(ctx); _snack('Preview only. Real billing is not connected yet.'); }),
        const SizedBox(height: 10), const Text('Preview only — no payment is taken in this template.', style: TextStyle(fontSize: 11, color: Colors.white54)),
      ]),
    ));
  }

  Future<void> _saveDiaryEntry() async {
    final entry = <String, dynamic>{
      'date': todayKey,
      'quality': quality,
      'mood': mood,
      'note': note.text.trim(),
      'savedAt': DateTime.now().toIso8601String(),
    };
    final existingIndex = diaryEntries.indexWhere((e) => e['date'] == todayKey);
    setState(() {
      if (existingIndex >= 0) {
        diaryEntries[existingIndex] = entry;
      } else {
        diaryEntries.add(entry);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sleep_diary_v1', jsonEncode(diaryEntries));
    if (mounted) _snack('Sleep diary saved on this device.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}
