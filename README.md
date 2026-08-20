# DoseCheck

[![Flutter checks](https://github.com/anes-dev-ml/DoseCheck/actions/workflows/flutter.yml/badge.svg)](https://github.com/anes-dev-ml/DoseCheck/actions/workflows/flutter.yml)

**A local-first medication log designed to make daily dose history clear, traceable, and hard to double-log by accident.**

DoseCheck focuses on one practical question:

> What have I already logged today, and what is still unresolved?

The app keeps that answer local to the device, preserves corrections as history instead of silently rewriting records, and uses reminder timing without turning reminders into proof that medication was taken.

Built with Flutter. English, French, and Arabic are supported from the same UI, including right-to-left layout for Arabic.

## What DoseCheck does

### Today

The Today view presents three routine entries in a simple timeline:

- morning tablets;
- a second tablet entry after a configured minimum interval;
- night insulin with explicit unit confirmation.

Each entry can be recorded as taken, missed, or uncertain. Once an entry is resolved, the normal flow blocks a duplicate log and directs corrections to History.

The second entry is intentionally dependent on the morning record: its availability is derived from a confirmed morning `taken` event plus the configured interval. An uncertain or missed morning entry does not unlock or schedule the second entry.

### History

History is a record, not an adherence dashboard.

- Previous days show the state of each routine entry.
- Taken entries retain the amount that was recorded at the time.
- Corrections append a `cleared` event instead of deleting the original event.
- Days with corrections expose the underlying audit sequence.

Changing the current routine therefore does not rewrite historical amounts.

### Settings

Settings contains only behavior that is actually implemented:

- routine quantities and times;
- second-entry minimum interval;
- local notification reminders;
- English, French, Arabic, or device language;
- concise safety and privacy information;
- guarded local-data reset.

Fresh installations start with deliberately neutral placeholder values. They are **not recommendations**. Every routine value should be reviewed in Settings against the user's current prescribed plan before the app is relied on.

## Engineering highlights

### Event-based records without framework overhead

DoseCheck stores medication actions as `DoseEvent` objects rather than maintaining a second mutable status table.

```text
DoseEvent
├── id
├── local day key
├── slot
├── type: taken | missed | uncertain | cleared
├── UTC timestamp
└── recorded amount
```

`DoseDayState` derives the effective state for a day from that event stream. A correction changes the effective state while preserving the earlier event for traceability.

This gives the project the useful properties of an audit log without introducing a general event-sourcing framework.

### Persistence before UI success

Hive CE is isolated behind repository interfaces.

A controller mutation follows this order:

```text
validate action
      ↓
await local persistence
      ↓
update in-memory state
      ↓
notify the UI
```

A failed write is never presented as a successful check-in.

DoseCheck uses two local boxes:

```text
dosecheck_events_v1
dosecheck_settings_v1
```

Stored models include explicit schema versions so future migrations can be handled deliberately.

### Reminder rules are testable without a device

The notification plugin is not responsible for deciding *whether* a reminder should exist.

A pure `ReminderSchedulePlan` determines:

- whether morning/night scheduling begins today or tomorrow;
- whether a future second reminder is valid;
- when that second reminder should occur.

The Android/iOS service then applies that plan to local notifications.

Notification mutations are serialized because the app owns a fixed set of notification IDs. Identical successful plans are skipped, while failed synchronization is never cached as successful.

### Local-first by design

This version has:

- no account;
- no backend/API calls;
- no cloud synchronization;
- no analytics SDK;
- no advertising SDK.

Medication records remain in the local Hive store for this installation.

### Small dependency surface

The application intentionally avoids adding architecture packages when Flutter's built-in tools are enough.

Core runtime dependencies are limited to local notifications, timezone handling, Hive CE, localization, and Flutter itself. State is coordinated by a focused `ChangeNotifier` controller rather than a third-party state-management framework.

## Safety boundary

DoseCheck is a logging and reminder tool. It is **not** a treatment or dosage system.

- It records user actions; it does not prescribe treatment.
- It does not calculate insulin doses.
- A reminder is not evidence that medication was taken.
- An uncertain entry remains uncertain; DoseCheck does not tell the user to repeat it.
- The second-entry interval is user configuration from an existing routine, not a recommendation generated by the app.
- Fresh-install placeholder values are configuration starting points, not suggested doses or timings.

If the configured routine does not match the prescribed plan, it should be updated before relying on the displayed schedule.

## Architecture

```text
lib/
  app/                         # bootstrap, runtime, controller, app shell
  core/
    design/                    # theme, visual tokens, asset paths
    time/                      # local calendar helpers
    widgets/                   # shared layout primitives
  features/
    doses/
      domain/                  # events, regimen, derived day state
      data/                    # repository boundary + Hive implementation
    today/presentation/        # current-day logging flow
    history/presentation/      # records and corrections
    settings/
      domain/
      data/
      presentation/
    reminders/application/     # schedule rules + device notification service
  l10n/                        # English, French, Arabic ARB sources
```

The structure follows feature boundaries and keeps shared abstractions limited to code with a real cross-feature responsibility.

More detail is available in [`docs/blueprint.md`](docs/blueprint.md).

## Reminder behavior

Local medication reminders are supported on Android and iOS.

- Morning and night reminders recur at configured local times.
- The second reminder is a one-shot notification derived from a confirmed morning entry and the configured interval.
- Resolved morning/night entries start their next recurring reminder on the following day.
- Android uses inexact-while-idle scheduling; the app does not request exact-alarm privileges.
- Android restart receivers are configured for the notification plugin.
- Web and desktop builds keep the logging UI and local history but do not schedule medication notifications.

Notifications are assistive. The record inside DoseCheck remains the source of truth.

## Localization

DoseCheck ships with:

- English;
- French;
- Arabic with right-to-left layout.

Feature copy lives in ARB localization files and is generated with Flutter's localization tooling. The Arabic version uses the same feature surfaces rather than a separate UI implementation.

## Quality checks

The test suite covers the highest-value behavior, including:

- day-state derivation;
- second-entry timing and locking;
- serialization validation;
- persistence-first controller mutations;
- failed persistence behavior;
- reset failure behavior;
- reminder scheduling decisions;
- localization direction for English, French, and Arabic;
- packaged runtime assets;
- application widget smoke behavior.

GitHub Actions validates changes with:

```text
dart format check
flutter analyze
flutter test
flutter build apk --debug
flutter build web --release
```

## Run locally

Flutter is pinned to **3.44.9** in CI.

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run
```

For an Android device:

```bash
flutter devices
flutter run -d <device-id>
```

For browser UI development:

```bash
flutter run -d chrome
```

Web builds intentionally do not schedule medication reminders.

## Asset pipeline

Runtime asset paths are centralized in `lib/core/design/app_assets.dart`.

Source artwork lives under `assets/source/`; normalized runtime and platform assets can be regenerated from the repository root with:

```bash
python -m pip install pillow==11.3.0
python tool/prepare_assets.py
```

The runtime asset test verifies that every image referenced by the Flutter UI is packaged and non-empty.

## Source availability

This repository is published to demonstrate the project and its implementation for portfolio and code-review purposes.

No open-source license is granted. The source may be read and evaluated, but permission to copy, modify, redistribute, or incorporate it into another project is not granted by this repository.

## Current scope

DoseCheck deliberately does not include features that are outside its current job:

- authentication or accounts;
- cloud backup or multi-device sync;
- glucose tracking;
- dosage recommendations or AI;
- adherence scoring or charts;
- doctor/family sharing;
- refill inventory;
- watch integration.

Those are product choices for a different scope, not placeholder screens in this one.
