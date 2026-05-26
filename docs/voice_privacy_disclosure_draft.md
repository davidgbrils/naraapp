# Privacy & Voice Disclosure (Final Wording)

## Short In-App Disclosure
NARA uses microphone access only when you actively use voice features.  
Voice recognition is handled by your device speech service/provider, and may be processed on-device or by that provider's cloud depending on device settings.  
NARA stores your confirmed financial data locally on your device and uses notification/background permissions to deliver reminders on time.

## Store Privacy Policy Wording
NARA is a personal finance and reminder app that supports optional voice input.

1. Data collected by the app
- Financial records you create (expenses, income, debt/receivable, reminders).
- App settings (language, theme, notification preferences, voice preferences).
- Diagnostic telemetry for app stability and feature quality (crash/error reports and event-level analytics).

2. Microphone and voice processing
- Microphone is used only when you trigger voice interaction in the app.
- Speech-to-text conversion is provided by the device/platform speech service.
- Depending on your device/OS/provider, voice processing can occur locally or via provider network services.
- NARA does not continuously listen in background by default.

3. Reminder and background behavior
- NARA uses notification/alarm/background capabilities to trigger reminders.
- Exact alarm and full-screen reminder behavior depends on OS permissions and device policies (battery optimization, OEM restrictions).

4. Data storage and sharing
- Core app data is stored locally on device storage.
- Voice transcripts are used for command parsing in-app flow.
- NARA does not sell personal data.

5. User control
- You can disable Voice Beta and voice confirmation from Settings.
- You can disable reminder categories/notification behavior from Settings.
- You can clear local app data at any time.

6. Third-party services
- Crash and telemetry events are sent to Sentry for stability monitoring and product quality analytics.
- Voice recognition depends on platform speech providers available on the device.

7. Contact
- Provide a support email/contact URL before production release.
