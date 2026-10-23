# SleepWell

SleepWell is an Android-first Flutter starter for a sleep and wind-down routine app aimed at adults in the USA and UK.

## Current UI scaffold
- Calm dark navy, violet and lavender theme
- Welcome screen and five-tab navigation
- Home dashboard and bedtime card
- Interactive routine checklist and add-step dialog
- Interactive 60-second breathing timer with pause/reset controls
- Relaxation sound library placeholders
- Locally saved sleep diary and routine progress chart
- Settings and premium paywall preview

## Important implementation status
The app is an early MVP, not yet production-ready for health or monetization:
- Routine definitions, routine completion, bedtime, reminder preference and diary entries are stored locally with SharedPreferences.
- Audio playback and actual notification scheduling are not connected.
- AdMob and Google Play Billing are not connected.
- The premium screen is a preview only; no payment is taken.
- Routine completion history powers the weekly bars and current streak; detailed diary trend summaries remain a follow-on.

## Build
The Codemagic workflow creates Android platform scaffolding, then runs package resolution, analysis, tests and a debug APK build.

For a full Flutter development environment:
```bash
flutter create --platforms=android --project-name sleepwell_app .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

See [docs/MVP_SPEC.md](docs/MVP_SPEC.md) for the agreed feature scope.

## Next implementation steps
1. Add real local bedtime notification scheduling and permission handling.
2. Add licensed audio playback with pause/stop controls.
3. Expand progress charts with saved diary trends and sleep-time summaries.
4. Add consent-aware AdMob integration using test ads during development.
5. Add Google Play subscriptions, entitlement verification and restore purchases.
6. Complete privacy, health-app declaration, accessibility, testing and release checks.


## Automated build
GitHub Actions workflow: `.github/workflows/android-ci.yml`. Pushes to `main` run Flutter analysis, widget tests, and attempt a debug APK build; the APK is uploaded as a workflow artifact when successful.
