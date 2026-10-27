# Architecture

DoseCheck is a small Flutter application with feature-oriented modules. Business rules, persistence, and device notifications are kept separate so they can be tested independently.

## Module layout

| Directory | Responsibility |
| --- | --- |
| `lib/app/` | Startup, controller, application shell |
| `lib/features/doses/domain/` | Dose events, routine configuration, derived day status |
| `lib/features/doses/data/` | Dose repository interface and Hive CE implementation |
| `lib/features/today/` | Current-day logging |
| `lib/features/history/` | Earlier records and corrections |
| `lib/features/settings/` | Preferences and regimen persistence |
| `lib/features/reminders/application/` | Reminder rules, coordination, platform service |
| `lib/core/` | Shared time, design, and layout helpers |
| `lib/l10n/` | English, French, and Arabic ARB catalogs |

## Event-based dose history

A `DoseEvent` contains a stable ID, local calendar-day key, dose slot, event type, UTC timestamp, and an amount for a confirmed taken entry.

Event types are `taken`, `missed`, `uncertain`, and `cleared`. The last type is used for corrections: rather than deleting an original event, the application appends a new event and derives the effective status using `DoseDayState`.

Recorded amounts belong to individual events. Editing the routine later does not retroactively alter them.

## Persistence and mutations

Hive CE stores events and settings in separate local boxes:

```text
dosecheck_events_v1
dosecheck_settings_v1
```

The stored data includes schema-version fields. Repositories isolate Hive operations from the domain model.

`DoseCheckController` coordinates state through Flutter's `ChangeNotifier`. A write is awaited before the controller publishes an updated successful state. If persistence fails, the UI must not present the operation as saved.

The two boxes do not form a shared transaction. Reset operations therefore clear settings first and recover from partial failure by reloading persisted state, rather than implying an atomic database reset.

## Routine timing

The current routine has three slots: morning tablets, a second tablet entry, and night insulin. Quantity and timing are configurable; the application does not derive a clinically appropriate regimen.

A second-entry action becomes available only after a confirmed morning `taken` event and its configured minimum interval. A missed or uncertain morning event does not unlock the second entry.

Each event retains both its UTC occurrence time and its local day key. This prevents a historical entry from moving between calendar days solely because the device timezone changes later.

## Reminder execution

A pure `ReminderSchedulePlan` decides which future reminders are applicable. The platform-specific `LocalReminderService` schedules the resulting notifications through Flutter's notification plugin.

- Morning and night reminders are recurring, aligned to configured local times.
- The second reminder is a one-time notification derived from a recorded morning event and configured interval.
- Notification operations are serialized, and failed synchronization is not cached as success.
- Android uses inexact-while-idle scheduling; no exact-alarm privilege is requested.
- Notification scheduling is not available on Web or desktop builds.

Reminder success is not evidence of taking medication. The user-entered event history is the application's record.

## Boundaries

DoseCheck runs without a backend service, account, cloud synchronization, analytics, or treatment logic. This simplifies data flow but means there is no automatic cross-device recovery of local records.

For application behavior and safety instructions, see [Safety and privacy](safety-and-privacy.md). For verification, see [Testing](testing.md).
