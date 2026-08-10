import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFF3F5F1);
  static const surface = Color(0xFFFBFCFA);
  static const ink = Color(0xFF17211C);
  static const mutedInk = Color(0xFF66716A);
  static const line = Color(0xFFD9DED9);
  static const accent = Color(0xFF386A53);
  static const accentSoft = Color(0xFFDDE9E1);
  static const amber = Color(0xFF8A662C);
  static const amberSoft = Color(0xFFF2E8D3);
  static const danger = Color(0xFFA64646);
  static const dangerSoft = Color(0xFFF3DFDF);

  static const darkCanvas = Color(0xFF111713);
  static const darkSurface = Color(0xFF18201B);
  static const darkInk = Color(0xFFE9EFEA);
  static const darkMutedInk = Color(0xFFA7B2AA);
  static const darkLine = Color(0xFF313B34);
  static const darkAccent = Color(0xFF8FC7A8);
  static const darkAccentSoft = Color(0xFF263E31);
  static const darkDanger = Color(0xFFF0A5A5);
  static const darkDangerSoft = Color(0xFF402525);
}

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        canvas: AppColors.canvas,
        surface: AppColors.surface,
        ink: AppColors.ink,
        mutedInk: AppColors.mutedInk,
        line: AppColors.line,
        accent: AppColors.accent,
        accentSoft: AppColors.accentSoft,
        danger: AppColors.danger,
        dangerSoft: AppColors.dangerSoft,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        canvas: AppColors.darkCanvas,
        surface: AppColors.darkSurface,
        ink: AppColors.darkInk,
        mutedInk: AppColors.darkMutedInk,
        line: AppColors.darkLine,
        accent: AppColors.darkAccent,
        accentSoft: AppColors.darkAccentSoft,
        danger: AppColors.darkDanger,
        dangerSoft: AppColors.darkDangerSoft,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color ink,
    required Color mutedInk,
    required Color line,
    required Color accent,
    required Color accentSoft,
    required Color danger,
    required Color dangerSoft,
  }) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: isLight ? Colors.white : AppColors.ink,
      primaryContainer: accentSoft,
      onPrimaryContainer: ink,
      secondary: mutedInk,
      onSecondary: surface,
      secondaryContainer:
          isLight ? const Color(0xFFE7EAE6) : const Color(0xFF29312C),
      onSecondaryContainer: ink,
      error: danger,
      onError: isLight ? Colors.white : AppColors.ink,
      errorContainer: dangerSoft,
      onErrorContainer: danger,
      surface: surface,
      onSurface: ink,
      outline: line,
      outlineVariant: line,
      shadow: Colors.black.withValues(alpha: 0.08),
      scrim: Colors.black.withValues(alpha: 0.42),
      inverseSurface: ink,
      onInverseSurface: surface,
      inversePrimary: accentSoft,
      surfaceTint: Colors.transparent,
    );

    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final textTheme = baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 36,
        height: 1.08,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.9,
        color: ink,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 28,
        height: 1.14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.55,
        color: ink,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 23,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: ink,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        color: ink,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
        color: mutedInk,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: mutedInk,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      textTheme: textTheme,
      dividerColor: line,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accentSoft,
        elevation: 0,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? ink : mutedInk,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? accent : mutedInk,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
    );
  }
}
