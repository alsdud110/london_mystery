import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      onPrimary: AppColors.paperLight,
      secondary: AppColors.royalBlue,
      tertiary: AppColors.gold,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.tryAgain,
    );

    OutlineInputBorder border(Color color, [double width = AppLine.rule]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: AppText.body,
      splashFactory: InkRipple.splashFactory, // plain ink ripple, no sparkle
      textTheme: TextTheme(
        displayLarge: AppText.logo(),
        headlineMedium: AppText.title(),
        titleLarge: AppText.title(size: 22),
        titleMedium: AppText.subtitle(),
        bodyLarge: AppText.bodyText(),
        bodyMedium: AppText.bodyText(size: 16),
        labelLarge: AppText.button(),
        bodySmall: AppText.caption(),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        titleTextStyle: AppText.mark(color: AppColors.ink, size: 17),
      ),
      dividerTheme: DividerThemeData(color: AppLine.faint(), thickness: AppLine.hairline, space: AppSpace.xl),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: AppText.bodyText(size: 16, color: AppColors.paperLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.paperLight,
        showDragHandle: true,
        dragHandleColor: AppLine.faint(0.3),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paperLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          side: BorderSide(color: AppLine.faint(0.3), width: AppLine.hairline),
        ),
        contentTextStyle: AppText.bodyText(size: 16),
      ),
      // Dialog and sheet actions in the game's own ink, not Material purple.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.paperLight,
          minimumSize: const Size(64, 48),
          textStyle: AppText.style(AppText.body, size: 15, weight: FontWeight.w600, letterSpacing: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.inkBrown,
          minimumSize: const Size(48, 48),
          textStyle: AppText.button(size: 15, color: AppColors.inkBrown).copyWith(letterSpacing: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      // Operator tools (Game Master): ink outline, not Material seed colours.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: AppLine.faint(0.45)),
          textStyle: AppText.button(size: 15, color: AppColors.navy).copyWith(letterSpacing: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.goldLight : AppColors.paperLight),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.navy : AppColors.parchmentDark),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.ink, contentPadding: EdgeInsets.symmetric(horizontal: AppSpace.screen)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: border(AppLine.faint(0.3)),
        enabledBorder: border(AppLine.faint(0.3)),
        focusedBorder: border(AppColors.navy, AppLine.ink),
        errorBorder: border(AppColors.tryAgain),
        focusedErrorBorder: border(AppColors.tryAgain, AppLine.ink),
      ),
    );
  }
}
