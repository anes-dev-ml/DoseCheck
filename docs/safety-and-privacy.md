# Safety and privacy

DoseCheck helps record a medication routine. Its reminders and interface do not replace prescription instructions, clinical judgment, or device-supported safety alarms.

## Medication-safety boundaries

- The application does not choose or recommend a medication or dose.
- The configured routine reflects user input. Fresh-install values are examples, **not treatment recommendations**.
- A logged `taken` event is a user report, not confirmation that medication was administered.
- A reminder notification is not proof of taking medication, and notification delivery is not guaranteed.
- If the user is uncertain whether a dose was taken, DoseCheck records the uncertainty; it does not recommend repeating the dose.
- Changes to a medication plan should come from the prescribing clinician or pharmacist, not from this software.

Before use, confirm the displayed medication quantities, timing, and interval against the instructions currently provided by a qualified healthcare professional.

## Data handling

Dose events and preferences are stored locally through Hive CE. The current implementation does not use a DoseCheck account, transmit records to an application backend, or synchronize medication history through a cloud API.

Local storage does not itself guarantee encryption, device security, or recovery after uninstalling the application, replacing a device, or losing local storage. Do not assume an automatic backup exists.

The application allows local-data reset. Review stored records and any needed backups before resetting or removing the app.

## Notifications and platforms

Medication notifications are implemented on Android and iOS when the required permissions and platform services are available. Web and desktop builds can show logging screens but do not schedule these notifications.

Operating-system settings, permission denial, power-saving behavior, time changes, and device availability can affect delivery.

## Intended scope

DoseCheck is a personal logging prototype. It is not a glucose monitor, medical device substitute, dose calculator, or emergency alert service. For medical questions about a missed, duplicated, or uncertain dose, follow the treatment instructions supplied by the care team or contact an appropriate healthcare professional.
