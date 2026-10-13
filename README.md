# SleepWell

SleepWell is an Android-first Flutter starter for a sleep and wind-down routine app aimed at adults in the USA and UK.

## Current UI scaffold
- Calm dark navy, violet and lavender theme
- Welcome screen and five-tab navigation
- Home dashboard and bedtime card
- Interactive routine checklist and add-step dialog
- Breathing-session preview and sound library placeholders
- Sleep diary form UI and progress preview
- Settings and premium paywall preview

## Important implementation status
This is a first UI scaffold, not a production-ready health or monetization app:
- Data is held in memory and resets when the app restarts.
- Audio playback and actual notification scheduling are not connected.
- AdMob and Google Play Billing are not connected.
- The premium screen is a preview only; no payment is taken.
- Progress bars are illustrative until real diary history is stored.

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
1. Persist preferences, routine completion and diary entries locally.
2. Add real bedtime settings and local notifications.
3. Add licensed audio playback and a real breathing timer.
4. Build progress charts from saved data.
5. Add consent-aware AdMob integration.
6. Add Google Play subscriptions, entitlement verification and restore purchases.
7. Complete privacy, health-app declaration, testing and release checks.
