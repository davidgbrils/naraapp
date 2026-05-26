# Publish Readiness Checklist

## 1) Release Hardening
- [x] Integrate crash reporting (`Sentry`, via `SENTRY_DSN` dart-define)
- [x] Integrate analytics events:
  - `reminder_created`
  - `reminder_snoozed`
  - `debt_payment_saved`
  - `voice_command_success`
  - `voice_command_failed`
- [ ] Add release build smoke run (`flutter build apk --release`)
- [ ] Verify startup without internet/offline mode

## 2) QA Matrix
- [ ] Execute matrix in `docs/qa_matrix_android_real_devices.md`
- [ ] Test OEM battery-kill variants (Xiaomi/Oppo/Vivo/Samsung)
- [ ] Validate reminder behavior:
  - app foreground
  - app background
  - after reboot

## 3) Notification + Reminder Reliability
- [ ] Verify exact alarm permission flow
- [ ] Verify full-screen intent permission flow for loud/fake-call modes
- [ ] Verify fallback watcher behavior for non-notification reminder modes
- [ ] Verify no double-popup for Fake Call/Loud Alarm/Fullscreen modes

## 4) Voice Feature Readiness
- [ ] Validate all command families in ID + EN
- [ ] Verify `debt_payment` voice flow (partial payment)
- [ ] Verify graceful failure message when voice service unavailable
- [ ] Confirm Voice Beta and Voice Confirmation toggles persist

## 5) Security & Privacy
- [ ] Publish Privacy Policy URL
- [ ] Add in-app disclosure for microphone/notification/background behavior
- [ ] Clarify voice data processing path (local/device service vs remote)
- [ ] Ensure user can disable voice and background reminder behavior

## 6) Store Submission Prep
- [ ] Final app name/icon/splash
- [ ] Final screenshots + feature graphics
- [ ] Target SDK + required permissions reviewed
- [ ] Internal test track rollout before production
