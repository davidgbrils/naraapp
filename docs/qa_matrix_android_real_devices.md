# QA Matrix Android Real Devices

## Scope
- Target build: `v1.0.1+2` (or latest RC)
- Focus: reminder reliability, voice flow, and transaction/debt correctness
- Minimum test set must be executed on real hardware (not emulator only)

## Device Matrix
| Tier | Device Example | RAM | Android | OEM |
|---|---|---:|---:|---|
| Low-end | Samsung A04 / Redmi 12C | 3-4 GB | 13 | Samsung/Xiaomi |
| Mid-range | Samsung A34 / Redmi Note series | 6-8 GB | 14 | Samsung/Xiaomi |
| New OS | Pixel 8 / equivalent | 8 GB+ | 15 | Google |

## Core Test Scenarios
| ID | Scenario | Expected |
|---|---|---|
| R1 | Create reminder mode `Notification` | System notification appears on schedule |
| R2 | Create reminder mode `Loud Alarm` | Full alert shown once, no duplicate popup |
| R3 | Create reminder mode `Fake Call` | Fake call UI shown once, no duplicate popup |
| R4 | App foreground then due reminder | Correct mode behavior in-app/system |
| R5 | App background then due reminder | Alert still delivered |
| R6 | Device reboot before due time | Reminder re-scheduled and still delivered |
| R7 | Snooze from alert (5 min) | New schedule saved and fires again |
| D1 | Debt partial payment | Remaining amount and status update correctly |
| D2 | H-1/H-0 debt reminder | Schedule marker + actual notification delivered |
| V1 | Voice command success (expense/debt/reminder) | Action preview and apply works |
| V2 | Voice command invalid/fail | Friendly fail message, no wrong data write |
| N1 | Delete notification/reminder item | No framework dismiss assertion/crash |
| I1 | Switch language ID/EN | Labels and tabs update consistently |

## Battery/Background Stress
- Enable battery optimization ON, verify R5/R6.
- Whitelist app from battery optimization, verify R5/R6 again.
- Lock screen for 30+ minutes and validate due reminder.

## Pass Criteria
- 0 crash on all mandatory scenarios.
- 0 duplicate popup on Loud Alarm/Fake Call.
- Voice fail never creates transaction/reminder/debt unintentionally.
- Debt payment math always consistent (paid + remaining = total).

## Execution Log Template
| Date | Device | OS | Tester | Scenario IDs | Result | Notes |
|---|---|---|---|---|---|---|
| 2026-05-26 |  |  |  |  |  |  |

