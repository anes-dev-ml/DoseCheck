# Design rationale

DoseCheck is intentionally limited to user-entered medication history, local reminders, and a configurable routine. The narrow scope avoids conflating a reminder with evidence of taking medication or a log entry with medical advice.

## Why an event history?

A mutable status field would show only the latest value for a dose slot. DoseCheck instead records an event (`taken`, `missed`, `uncertain`, or `cleared`) and derives the current status. A correction appends an event rather than erasing the original action.

This preserves the sequence of user decisions and keeps the originally recorded quantity even after routine settings change. The trade-off is that the application must derive effective state from ordered events instead of reading one status field.

## Why persistence precedes UI confirmation

Recording a dose is a user-visible, consequential action. The controller awaits the Hive repository write before presenting the action as saved. A failed local write should not appear as a successful check-in.

The two local Hive boxes do not provide an atomic cross-box transaction, so reset operations prioritize preserving medication history and reload persisted state after partial failure.

## Why separate reminder rules from notifications?

The timing plan is calculated independently of the Flutter notification plugin. It can be exercised in pure tests for today's and tomorrow's reminder times, whether a conditional reminder should exist, and what happens after an uncertain or missed entry.

The platform service then applies that plan. Failed device notification synchronization is not recorded as success. Delivery remains dependent on operating-system permissions and behavior.

## Why local-first?

The current design does not require accounts, network connectivity, a backend, or analytics SDKs. This keeps the storage and execution path small, but removes automatic cloud backup or multi-device recovery. Local storage alone should not be described as encrypted or immune to data loss.

## Why a configurable routine?

The prototype provides a morning tablet entry, a conditional second tablet entry, and a night insulin entry. It does not calculate amounts or determine medically appropriate intervals. Starting quantities and times are configuration examples only; users must confirm their actual routine with their existing instructions.

## Implementation references

- [Architecture](architecture.md) — module layout, time model, event data, persistence, and notifications
- [Safety and privacy](safety-and-privacy.md) — medication and storage limitations
- [Testing](testing.md) — reproducible verification commands

This document explains the design decisions rather than repeating the implementation reference.
