import 'package:flutter/material.dart';

void main() => runApp(const SleepWellApp());

const bg = Color(0xFF0B1025);
const card = Color(0xFF151D3B);
const violet = Color(0xFF8B7CFF);
const lilac = Color(0xFFC6BCFF);
const mint = Color(0xFF7DE2D1);

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
  RoutineStep(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
  bool done = false;
}

class SleepShell extends StatefulWidget {
  const SleepShell({super.key});
  @override
  State<SleepShell> createState() => _SleepShellState();
}

class _SleepShellState extends State<SleepShell> {
  bool started = false;
  int tab = 0;
  int quality = 3;
  int mood = 1;
  bool reminders = true;
  final note = TextEditingController();
  final steps = <RoutineStep>[
    RoutineStep('Put your phone away', 'Give your mind a screen break', Icons.phone_iphone),
    RoutineStep('Breathe slowly', 'A few calm, gentle breaths', Icons.air),
    RoutineStep('Listen and unwind', 'Choose a calming sound', Icons.music_note),
    RoutineStep('Read a few pages', 'Ease into a quieter evening', Icons.menu_book),
    RoutineStep('Lights out', 'Let the day come to a close', Icons.nightlight_round),
  ];
  int get completed => steps.where((s) => s.done).length;
  @override
  void dispose() { note.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!started) return _welcome();
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
          _button('Get started', () => setState(() => started = true)),
          const SizedBox(height: 14),
          const Text('A calmer end to your day', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      )),
    ),
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
        const SizedBox(height: 8), const Text('10:30 PM', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
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
      Text((completed / steps.length * 100).round().toString() + '%', style: const TextStyle(color: mint, fontWeight: FontWeight.bold)),
    ])),
    const SizedBox(height: 16), ...steps.map((s) => _stepTile(s, large: true)),
    _button('Reset tonight’s checklist', () => setState(() { for (final s in steps) { s.done = false; } })),
    const SizedBox(height: 10), _outline('Add a custom step', _addStep),
  ]));

  Widget _relax() => _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Relax & unwind', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8), const Text('Take a gentle pause before bedtime.', style: TextStyle(color: Colors.white60)),
    const SizedBox(height: 24),
    Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [Color(0xFF2C326F), Color(0xFF18284A)])),
      child: Column(children: [
        const Text('SLOW BREATHING', style: TextStyle(color: lilac, letterSpacing: 1.6, fontSize: 11)),
        const SizedBox(height: 22),
        Container(width: 154, height: 154, decoration: BoxDecoration(shape: BoxShape.circle, color: violet.withValues(alpha: .15), border: Border.all(color: lilac.withValues(alpha: .6), width: 2)), child: const Center(child: Icon(Icons.air, size: 60, color: lilac))),
        const SizedBox(height: 18),
        const Text('One mindful minute', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), const Text('Breathe in gently, then breathe out.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 18),
        _button('Preview breathing session', () => _snack('A timed breathing exercise will be connected next.')),
      ])),
    const SizedBox(height: 24), const Text('Sound library', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    _action(Icons.water, 'Gentle ocean', 'Sound playback will be connected next', () => _snack('Audio playback is not connected in this starter.')),
    _action(Icons.park_outlined, 'Quiet forest', 'Nature ambience', () => _snack('Audio playback is not connected in this starter.')),
    _action(Icons.grain, 'Soft rain', 'Rain ambience', () => _snack('Audio playback is not connected in this starter.')),
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
    const SizedBox(height: 20), _button('Save check-in', () => _snack('Diary UI ready. Local data saving is a next step.')),
    const SizedBox(height: 14), const Text('For personal reflection, not medical diagnosis.', style: TextStyle(fontSize: 12, color: Colors.white54)),
  ]));

  Widget _progress() => _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Your progress', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8), const Text('Celebrate the small steps you take.', style: TextStyle(color: Colors.white60)),
    const SizedBox(height: 24),
    Row(children: [
      Expanded(child: _metric('Routine steps', completed.toString() + '/' + steps.length.toString(), Icons.check_circle_outline, lilac)),
      const SizedBox(width: 12), Expanded(child: _metric('Current streak', 'Preview', Icons.local_fire_department_outlined, mint)),
    ]),
    const SizedBox(height: 16),
    Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: _decoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('This week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), const Text('Illustrative routine completion preview', style: TextStyle(color: Colors.white60, fontSize: 12)),
      const SizedBox(height: 22),
      SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
        final heights = [42.0, 70.0, 56.0, 90.0, 62.0, 104.0, completed * 18.0 + 12];
        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(width: 22, height: heights[i].clamp(12, 120).toDouble(), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF6558DA), lilac]))),
          const SizedBox(height: 8), Text(labels[i], style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]);
      }))),
    ])),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(16), decoration: _decoration(), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, color: lilac), SizedBox(width: 12),
      Expanded(child: Text('Progress will use saved diary and routine history once local storage is connected.', style: TextStyle(color: Colors.white70, height: 1.4))),
    ])),
    const SizedBox(height: 16),
    _action(Icons.workspace_premium_outlined, 'Explore Premium', 'More routines and an ad-free experience', _premium),
  ]));

  Widget _stepTile(RoutineStep s, {bool large = false}) => Container(
    margin: const EdgeInsets.only(bottom: 10), decoration: _decoration(),
    child: CheckboxListTile(value: s.done, onChanged: (v) => setState(() => s.done = v ?? false),
      controlAffinity: ListTileControlAffinity.leading, activeColor: violet, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      secondary: Container(width: 42, height: 42, decoration: BoxDecoration(color: violet.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)), child: Icon(s.icon, color: lilac)),
      title: Text(s.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: s.done ? TextDecoration.lineThrough : null)),
      subtitle: Text(large ? s.subtitle + ' • 5 min' : s.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))),
  );

  Widget _action(IconData icon, String title, String subtitle, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(bottom: 10), decoration: _decoration(),
    child: ListTile(onTap: onTap, leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: violet.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: lilac)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)), trailing: const Icon(Icons.chevron_right, color: Colors.white54)),
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
          if (value.isNotEmpty) setState(() => steps.insert(steps.length - 1, RoutineStep(value, 'Your custom routine step', Icons.check_circle_outline)));
          Navigator.pop(ctx);
        }, child: const Text('Add')),
      ]));
  }

  void _editBedtime() {
    showTimePicker(context: context, initialTime: const TimeOfDay(hour: 22, minute: 30))
      .then((t) { if (t != null && mounted) _snack('Bedtime selected: ' + t.format(context) + '. Saving comes next.'); });
  }

  void _settings() {
    showModalBottomSheet(context: context, backgroundColor: card, showDragHandle: true, builder: (ctx) => StatefulBuilder(builder: (ctx, updateSheet) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Settings', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        SwitchListTile(title: const Text('Bedtime reminders'), subtitle: const Text('Scheduling will be connected next'), value: reminders, onChanged: (v) { setState(() => reminders = v); updateSheet(() {}); }),
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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}
