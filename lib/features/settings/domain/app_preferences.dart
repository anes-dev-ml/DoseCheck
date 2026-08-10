class AppPreferences {
  const AppPreferences({
    required this.languageCode,
    required this.remindersEnabled,
  });

  const AppPreferences.initial()
      : languageCode = null,
        remindersEnabled = false;

  static const int schemaVersion = 1;
  static const supportedLanguageCodes = {'en', 'fr', 'ar'};

  final String? languageCode;
  final bool remindersEnabled;

  AppPreferences copyWith({
    String? languageCode,
    bool clearLanguageCode = false,
    bool? remindersEnabled,
  }) {
    final nextLanguageCode = clearLanguageCode ? null : languageCode ?? this.languageCode;
    _validateLanguage(nextLanguageCode);

    return AppPreferences(
      languageCode: nextLanguageCode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'schema_version': schemaVersion,
      'language_code': languageCode,
      'reminders_enabled': remindersEnabled,
    };
  }

  factory AppPreferences.fromMap(Map<String, dynamic> map) {
    final rawVersion = map['schema_version'] ?? 1;
    if (rawVersion is! int || rawVersion != schemaVersion) {
      throw FormatException(
        'Unsupported preferences schema version: $rawVersion',
      );
    }

    final languageCode = map['language_code'];
    final remindersEnabled = map['reminders_enabled'];
    if (languageCode != null && languageCode is! String) {
      throw const FormatException('Invalid language preference');
    }
    if (remindersEnabled is! bool) {
      throw const FormatException('Invalid reminder preference');
    }

    try {
      _validateLanguage(languageCode as String?);
    } on ArgumentError catch (error) {
      throw FormatException('Invalid language preference: ${error.message}');
    }

    return AppPreferences(
      languageCode: languageCode,
      remindersEnabled: remindersEnabled,
    );
  }

  static void _validateLanguage(String? value) {
    if (value != null && !supportedLanguageCodes.contains(value)) {
      throw ArgumentError.value(value, 'languageCode', 'Unsupported language.');
    }
  }

  @override
  bool operator ==(Object other) {
    return other is AppPreferences &&
        other.languageCode == languageCode &&
        other.remindersEnabled == remindersEnabled;
  }

  @override
  int get hashCode => Object.hash(languageCode, remindersEnabled);
}
