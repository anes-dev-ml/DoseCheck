# Testing

The repository includes focused Flutter tests for the dose history, controller, reminder plan, localization, and packaged application assets.

## Local verification

From the repository root:

```sh
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Build checks used in the GitHub Actions configuration:

```sh
flutter build apk --debug
flutter build web --release
```

The workflow uses Flutter 3.44.9. These build commands verify that the intended targets compile; they do not prove notification delivery on a physical Android or iOS device.

## Test areas

| Area | Coverage |
| --- | --- |
| Dose events and daily state | State derivation, effective events, locking and amounts |
| Serialization | Stored regimen and event validation |
| Controller | Persistence-before-success, write failures, reset behavior |
| Reminder plan | Recurring/conditional schedules and local-day boundaries |
| Localization | English, French, Arabic and right-to-left behavior |
| Assets and UI | Packaged image references and widget smoke tests |

## Additional device verification

Before using reminders for a real routine, manually verify permission handling, scheduling, restart behavior, timezone/day transitions, disabled reminders, and delayed notification behavior on the target phone.

The workflow configuration alone is not evidence of a passing run. Review the actual [GitHub Actions results](https://github.com/anes-dev-ml/DoseCheck/actions) and report verified outcomes separately.

See [Architecture](architecture.md) for the implementation boundaries and [Safety and privacy](safety-and-privacy.md) for user-facing limitations.
