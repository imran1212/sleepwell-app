# SleepWell MVP Specification

## Product
**Name:** SleepWell (provisional)  
**Positioning:** Sleep & Wind-Down Coach  
**Audience:** Adults in the USA and UK  
**Platform:** Android first, Flutter  
**Goal:** Help users build a bedtime routine and reflect on sleep habits. The app does not diagnose or treat sleep disorders.

## Screens
1. Welcome/onboarding: explain app value, choose bedtime/wake-up preferences, request notification permission contextually.
2. Home: bedtime card, routine checklist, progress and quick actions.
3. Routine builder: add/edit/remove/reorder steps and set durations.
4. Relax: breathing timer and licensed sound library.
5. Sleep diary: bedtime, wake time, perceived sleep quality, morning energy and optional note.
6. Progress: weekly summaries, routine completion, streaks and trends from actual saved data.
7. Settings: reminders, time format, privacy and delete-data actions.
8. Premium: localized monthly/yearly prices, benefits, subscribe, restore purchases and manage subscription.

## MVP features
- Welcome screen and onboarding
- Home dashboard and bedtime routine
- Custom routine builder
- Relaxation sounds and breathing timer
- Sleep diary and mood check-in
- Weekly progress charts and streaks
- Local bedtime notifications
- AdMob integration with appropriate consent and test ads
- Google Play monthly/yearly subscription

## UX and safety rules
- Useful core features remain available free.
- No ads during active breathing sessions or diary entry.
- Premium removes third-party ads.
- Avoid medical diagnosis claims.
- Missing diary data is not zero sleep.
- Respect local time, daylight saving and notification permissions.
- Provide clear subscription terms and restore purchases.

## Data
Preferences, routine definitions and ordered steps, dated routine completion, diary entries, relaxation session history, settings and consent state. Health diary content should not be sent to analytics. Document retention, deletion and backup behavior in the privacy policy.

## Initial scaffold limitations
The first commit is UI-focused. Persistence, actual audio, scheduled notifications, AdMob and billing are follow-on tasks.
