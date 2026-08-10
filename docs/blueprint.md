# DoseCheck product blueprint

DoseCheck is a local-first medication log whose primary job is to remove uncertainty about what has already been taken today.

It is not a dosage calculator, treatment recommender, glucose manager, or medical decision system.

## Product rule

The home screen must answer one question in a few seconds:

> What have I already logged today, and what is still unresolved?

Everything else is secondary.

## Safety boundaries

- A reminder is not proof that medication was taken.
- DoseCheck records user actions; it does not prescribe or change doses.
- The configured routine is user-entered information and must remain editable.
- If a dose is uncertain, DoseCheck records uncertainty instead of telling the user to take another dose.
- A second-pill reminder may be derived from the confirmed morning log and the configured minimum interval. That interval is configuration, not a recommendation from the app.
- Repeated logging of an already-confirmed dose is blocked on the main flow. Corrections belong in history rather than behind an easy "take again" action.
- Dose records are stored locally and are append-only at the repository boundary. Corrections create state changes rather than silently rewriting history.

## Experience principles

### Quiet hierarchy

No decorative uppercase headings, emoji, gradients, motivational filler, or duplicated status text. Typography, spacing, contrast, and position establish hierarchy.

### One purpose per surface

- Today: current state and logging.
- History: what was recorded on previous days and corrections.
- Settings: routine, reminders, language, and app information.

There is no separate dashboard, statistics page, onboarding carousel, account page, or API surface in v1.

### Friction where it protects the user

Routine logging should be one tap. Insulin units require a confirmation sheet because the amount is meaningful. An already-taken dose cannot be logged again from the normal action.

### Language is structural

English, French, and Arabic ship together. No user-visible string lives directly in feature widgets. Arabic is tested as a right-to-left layout from the start instead of being bolted on later.

## Visual language

DoseCheck should feel closer to a well-designed physical health journal than a generic wellness dashboard.

- Warm neutral canvas rather than pure white.
- Deep green-black primary text.
- Muted botanical green as the identity color.
- Amber and red are reserved for unresolved and destructive/error semantics.
- Thin dividers and a vertical regimen line replace repeated floating cards.
- Rounded corners are used selectively, mostly on actions and sheets.
- The brand mark is drawn in Flutter rather than depending on a decorative image asset.
- System typography is used for legibility in Latin and Arabic scripts.

## Navigation

Three destinations are enough:

1. Today
2. History
3. Settings

The bottom navigation stays visible. Detail and edit experiences use modal sheets so users do not lose their place.

## Project structure

```text
lib/
  app/
    app.dart
    bootstrap.dart
    app_dependencies.dart
  core/
    design/
    time/
    widgets/
  l10n/
    app_en.arb
    app_fr.arb
    app_ar.arb
  features/
    doses/
      domain/
      data/
      application/
    today/
      presentation/
    history/
      presentation/
    settings/
      presentation/
    reminders/
      application/
```

This is a vertical-slice structure. Shared medication concepts belong to the `doses` feature instead of being scattered into generic `models`, `services`, and `utils` folders.

## Data model

### RegimenPlan

Stores the configured routine:

- morning tablet quantity and target reminder time
- second tablet quantity and minimum interval after the morning log
- night insulin default units and target reminder time
- optional user-entered names for medications

The initial personal defaults are 2 morning tablets, 2 second tablets, a 6-hour minimum interval, and 8 insulin units. These values are configuration and can be changed.

### DoseEvent

Each event stores:

- stable id
- local calendar day
- slot (`morningPills`, `secondPills`, `nightInsulin`)
- event type (`taken`, `uncertain`, `missed`, `cleared`)
- UTC timestamp
- optional numeric amount

The current day state is derived from events rather than being stored as a second source of truth.

### AppPreferences

Stores:

- language preference (`system`, `en`, `fr`, `ar`)
- whether reminders are enabled

## Persistence

Hive CE is the local database.

Two boxes keep responsibilities separate:

- `dosecheck_events_v1`: append-only dose events
- `dosecheck_settings_v1`: regimen and app preferences

Domain objects serialize to primitive maps manually. This avoids generated adapters and keeps migrations explicit. Dose-event writes are awaited and flushed before the UI treats them as complete.

No backend is used in v1. `DoseCheck_API` remains intentionally empty.

## Reminder model

- Morning and night reminders are recurring local notifications at configured times.
- The second-pill reminder is not a fixed daily alarm. It is scheduled after a morning `taken` event at `morning time + configured minimum interval`.
- Changing the routine or language reschedules owned notifications.
- Web runs the app without notification scheduling; it remains useful for UI development and local history.
- Android uses inexact-while-idle scheduling initially. DoseCheck therefore avoids asking for exact-alarm privileges in v1.
- Android boot receivers are configured so the notification plugin can restore scheduled notifications after restart.

## Implementation slices

### Slice 1 — identity and application shell

1. Replace the counter template with a real bootstrap and app root.
2. Establish the design tokens and custom brand mark.
3. Add generated English, French, and Arabic localization.
4. Add the three-destination application shell.
5. Add strict analysis rules and remove demo code.

Review gate: reject abstractions that exist only to make the folder tree look architectural.

### Slice 2 — dose domain

1. Define regimen and dose-event models.
2. Define local-day and time helpers.
3. Build the day-state derivation engine.
4. Encode second-dose availability from the morning confirmation.
5. Add domain tests for timing, states, and serialization.

Review gate: derived state must have one source of truth and no medical decision logic.

### Slice 3 — durable local data

1. Initialize Hive CE at bootstrap.
2. Implement event storage.
3. Implement regimen storage.
4. Implement preferences storage.
5. Add repository interfaces plus in-memory fakes for tests.

Review gate: a successful UI check-in must never happen before the persistence write completes.

### Slice 4 — Today

1. Build the date/status header.
2. Build the regimen timeline.
3. Implement one-tap pill logging with duplicate protection.
4. Implement uncertain/missed states.
5. Implement the insulin amount confirmation sheet.

Review gate: remove any repeated labels, decorative cards, or actions whose purpose is not obvious.

### Slice 5 — History

1. Build recent-day grouping.
2. Show compact slot state without relying on color alone.
3. Add a day-detail sheet.
4. Add correction/clear flow.
5. Cover history derivation with tests.

Review gate: history should read like a record, not an analytics dashboard.

### Slice 6 — Settings

1. Add routine editing.
2. Add language selection including system locale.
3. Add reminder enable/disable controls.
4. Add concise safety and privacy information.
5. Add guarded local-data reset.

Review gate: settings should expose real behavior only; no placeholder toggles.

### Slice 7 — reminders

1. Initialize local notifications and device timezone.
2. Request notification permission only when reminders are enabled.
3. Schedule morning and night reminders.
4. Schedule/cancel the derived second-dose reminder after morning state changes.
5. Reschedule when routine or language changes and configure Android restart support.

Review gate: notifications are assistive, never authoritative; app state remains the source of truth.

### Slice 8 — quality pass

1. Add loading, empty, persistence-error, and notification-unavailable states.
2. Audit RTL, large text, semantics, and touch targets.
3. Add widget smoke tests for the three locales.
4. Rewrite README with setup, safety boundary, and validation commands.
5. Run formatting, localization generation, analysis, and tests before merging.

Review gate: remove anything that looks finished but has not actually been wired to behavior.

## Explicitly deferred

- accounts, login, sync, cloud backup, backend API
- glucose tracking
- AI features
- medication recommendations
- doctor/family sharing
- charts and adherence scores
- refill inventory
- watch integration
- custom launcher icon export

Those can be reconsidered only after the core logging flow proves reliable in daily use.
