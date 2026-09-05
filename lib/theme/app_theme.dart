import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand palette — calm, trustworthy sky blue with a subtle
  // turquoise accent. Used for every general-UI element: buttons, icons,
  // navigation, focus states, badges. This is the app's actual brand color.
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color turquoise = Color(0xFF14B8A6);

  // Reserved exclusively for emergency/urgent actions (the roadside-help
  // card). Never used for general branding, so red keeps a single, specific
  // meaning — "this needs attention now" — instead of being diluted across
  // the whole interface.
  static const Color emergency = Color(0xFFE53935);
  static const Color emergencyDark = Color(0xFFB71C1C);

  // Same reasoning as emergency above, extended to 2 of the homepage's 3
  // main service-category cards (see ServiceCategoryCard) — each color is
  // reserved for its one category, not general branding, so they stay a
  // clear visual index rather than diluting the turquoise-only accent
  // everywhere else. Araç Tamiri's own card deliberately has no separate
  // reserved color here — approved visual-identity direction retired its
  // near-black navy (which read as a different tier from these two vivid
  // colors) in favor of reusing [turquoise] directly, tying the app's
  // primary category to the actual secondary brand color instead of a
  // fourth one-off hex value.
  static const Color inspection = Color(0xFF2563EB);
  static const Color insurance = Color(0xFF16A34A);

  static const Color surface = Color(0xFFFFFFFF);
  // Refined neutral scale (approved visual-identity direction) — a
  // navy-tinted near-black and blue-gray instead of flat grays, so the
  // neutrals read as chosen rather than inherited. Kept under the existing
  // names (textPrimary/textSecondary/divider/background) rather than
  // renamed, so every existing call site across the app picks up the
  // refinement automatically with no per-file changes.
  static const Color background = Color(0xFFF6F9FC);
  static const Color textPrimary = Color(0xFF0F1B2B);
  static const Color textSecondary = Color(0xFF5B6B7C);
  static const Color divider = Color(0xFFE4EAF0);

  // Semantic state colors — deliberately distinct from every brand/category
  // color above (including [insurance]'s green and [emergency]'s red) so
  // "open/closed", "rating", and "verified" each carry exactly one meaning
  // and never collide. Never used for general branding.
  static const Color open = Color(0xFF15803D);
  static const Color openBackground = Color(0xFFE7F5EC);
  static const Color closed = Color(0xFF92400E);
  static const Color closedBackground = Color(0xFFFBEEE0);
  static const Color rating = Color(0xFFEAB308);
  static const Color ratingBackground = Color(0xFFFEF7DC);
  static const Color verified = Color(0xFF4338CA);
  static const Color verifiedBackground = Color(0xFFECECFB);

  // Schedule-status tags — the mechanic home screen's Bugün/Yarın/Gecikti
  // tags on pending requests. Kept separate from [emergency] (reserved
  // exclusively for the roadside-help card) and [open]/[closed] (business
  // hours), so this status vocabulary doesn't borrow either's one reserved
  // meaning. Never used for general branding.
  static const Color scheduleOverdue = Color(0xFFDC2626);
  static const Color scheduleOverdueBackground = Color(0xFFFDEBEA);
  static const Color scheduleToday = Color(0xFF0369A1);
  static const Color scheduleTodayBackground = Color(0xFFE3F2FB);
  static const Color scheduleTomorrow = Color(0xFF7C3AED);
  static const Color scheduleTomorrowBackground = Color(0xFFF1EAFE);
}

/// Named type scale (approved visual-identity direction) — four disciplined
/// roles on the app's single existing font family (see
/// [AppTheme.fontFamily]), rather than a second typeface. Every
/// new/redesigned widget should pull a role from here instead of writing
/// its own ad hoc TextStyle.
class AppTextStyles {
  AppTextStyles._();

  static const headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );
}

/// 4pt-based spacing scale — every new/redesigned widget should pull from
/// here instead of inventing its own numbers, so rhythm stays consistent
/// across sections.
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

/// Corner-radius scale, paired with [AppSpacing].
class AppRadius {
  AppRadius._();

  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 28.0;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
  ];

  static List<BoxShadow> primary = [
    BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 12)),
  ];

  /// Used only where red is intentionally the point — the emergency card.
  static List<BoxShadow> emergency = [
    BoxShadow(color: AppColors.emergency.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 12)),
  ];

  /// Two-layer "floating card" shadow — a tight, barely-there contact shadow
  /// plus a broad, very soft ambient one. Reads as considered elevation
  /// (Airbnb/Stripe-style) rather than a single flat Material drop shadow.
  static List<BoxShadow> card = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 32, offset: const Offset(0, 16)),
  ];

  /// Deeper version of [card] for a pressed/lifted state — the card grows
  /// slightly and the shadow spreads further, as if it rose off the page.
  static List<BoxShadow> cardLifted = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 32, offset: const Offset(0, 18)),
  ];

  /// Same two-layer shape as [card] but tinted with [color] instead of
  /// black — for [PremiumSurface]s that should cast colored light (the
  /// emergency card) rather than a neutral gray shadow.
  static List<BoxShadow> coloredCard(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 4, offset: const Offset(0, 2)),
    BoxShadow(color: color.withValues(alpha: 0.24), blurRadius: 32, offset: const Offset(0, 16)),
  ];

  /// Lifted counterpart to [coloredCard].
  static List<BoxShadow> coloredCardLifted(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 8, offset: const Offset(0, 4)),
    BoxShadow(color: color.withValues(alpha: 0.32), blurRadius: 36, offset: const Offset(0, 20)),
  ];
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Plus Jakarta Sans';

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 3,
        height: 68,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    );
  }
}
