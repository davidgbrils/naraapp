# Crash + Analytics Setup (Sentry)

## 1) Create Sentry Project
- Create mobile project in Sentry.
- Copy DSN.

## 2) Build/Run With DSN
Use dart-define so DSN is not hardcoded:

```bash
flutter run --dart-define=SENTRY_DSN=YOUR_DSN_HERE
```

```bash
flutter build apk --release --dart-define=SENTRY_DSN=YOUR_DSN_HERE
```

## 3) Events Implemented
- `reminder_created`
- `reminder_snoozed`
- `debt_payment_saved`
- `voice_command_success`
- `voice_command_failed`

## 4) Notes
- If `SENTRY_DSN` is empty, telemetry is disabled automatically.
- Crash capture includes:
  - Flutter framework errors
  - Platform dispatcher uncaught errors
  - Critical provider catch blocks

