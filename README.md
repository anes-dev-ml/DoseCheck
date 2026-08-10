# DoseCheck

DoseCheck is a local-first medication log built to answer one question clearly:

> What have I already logged today?

The current routine supports morning tablets, a second tablet entry after a configured minimum interval, and night insulin with an explicitly confirmed unit amount.

## Safety boundary

DoseCheck records actions. It does not prescribe treatment.

- A reminder is not proof that medication was taken.
- DoseCheck does not calculate insulin doses.
- An uncertain entry stays uncertain; the app does not tell the user to repeat it.
- The second-entry interval is user configuration from the prescribed routine, not a recommendation from the app.
- Duplicate logging is blocked in the normal flow. Corrections are made from History and remain traceable as appended events.
- Medication history is stored locally. There is no account, backend, cloud sync, or analytics in this version.

If a prescribed plan changes, update the routine in Settings before relying on the displayed schedule.

## Product surfaces

DoseCheck intentionally has only three primary destinations:

- **Today** — current medication state and check-in actions.
- **History** — past records, recorded amounts, and corrections.
- **Settings** — routine, local reminders, language, safety/privacy information, and local-data reset.

The interface ships in English, French, and Arabic. Arabic uses RTL layout from the same feature surfaces rather than a separate UI.

## Architecture

```text
lib/
  app/                         # bootstrap, runtime dependencies, app shell
  core/
    design/                    # visual tokens and DoseCheck mark
    time/                      # local calendar helpers
    widgets/                   # shared layout primitives
  features/
    doses/
      domain/                  # regimen, events, derived day state
      data/                    # repository boundary + Hive implementation
    today/presentation/
    history/presentation/
    settings/
      domain/
      data/
      presentation/
    reminders/application/     # local-notification boundary and coordinator
  l10n/                        # en/fr/ar ARB source files
```

The app uses a small `DoseCheckController` instead of a state-management framework. It coordinates the two local repositories and exposes persistence-first mutations to the UI.

### Local data

Hive CE stores two independent boxes:

- `dosecheck_events_v1` — append-only dose events.
- `dosecheck_settings_v1` — regimen and app preferences.

Each taken event snapshots the recorded amount so changing the routine later does not rewrite historical meaning.

The current state for a day is derived from the event stream. A correction appends a `cleared` event instead of deleting the prior event.

### Reminders

Local notifications are supported on Android and iOS in this version.

- Morning and night reminders recur at configured local times.
- The second reminder is scheduled only after a confirmed morning `taken` event and only for the configured minimum interval.
- Android uses inexact-while-idle scheduling; DoseCheck does not request exact-alarm privileges.
- Scheduled Android notifications are restored after device restart.
- Web and desktop builds remain useful for UI development and local records but do not schedule medication notifications.

Notifications are assistive. The record inside DoseCheck remains the source of truth.

## Run locally

From the repository root:

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run
```

For a connected Android device:

```bash
flutter devices
flutter run -d <device-id>
```

For UI work in Chrome:

```bash
flutter run -d chrome
```

Reminder scheduling is intentionally unavailable in the web preview.

## Validation before using it for the real routine

Do not treat a successful build as enough validation for a medication log.

Before depending on DoseCheck day-to-day:

1. Confirm English/French/Arabic layouts on the target phone.
2. Log and correct test entries across several days.
3. Force-close and reopen the app; verify history remains intact.
4. Reboot the phone; verify scheduled reminders still exist.
5. Test notification permission denied, granted, and later disabled in system settings.
6. Test a morning entry and confirm the second reminder is not scheduled before the configured interval.
7. Change the routine and verify old History amounts do not change.
8. Confirm device time-zone and daylight-saving changes behave as expected.

## Current scope

This foundation deliberately does not include:

- accounts or authentication
- backend/API calls
- cloud backup or multi-device sync
- glucose tracking
- dosage recommendations or AI
- adherence scores or charts
- doctor/family sharing
- refill inventory

The detailed product and implementation reasoning lives in [`docs/blueprint.md`](docs/blueprint.md).
