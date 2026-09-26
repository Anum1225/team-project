import 'package:flutter/material.dart';

/// HarvestHub Award-Grade Typography & Theming System (SRS v1.0)
/// Grounded in Material Design 3 color science, Awwwards 2026 organic-neutral
/// palettes, and WCAG 2.2 AA accessibility contrast math.
@immutable
class HarvestPalette extends ThemeExtension<HarvestPalette> {
  const HarvestPalette({
    required this.forest,
    required this.green,
    required this.freshLeaf,
    required this.softSage,
    required this.paleLeaf,
    required this.cream,
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.honey,
    required this.tomato,
    required this.berry,
    required this.darkSoil,
    required this.border,
    required this.shadowColor,
    required this.surfaceElevated1,
    required this.surfaceElevated2,
    required this.surfaceElevated3,
    required this.surfaceElevated4,
    required this.categoryFruits,
    required this.categoryVegetables,
    required this.categoryGrains,
    required this.categoryDairy,
    required this.categoryHerbs,
    required this.categoryOrganic,
    required this.statusPending,
    required this.statusConfirmed,
    required this.statusReady,
    required this.statusCompleted,
    required this.statusCancelled,
  });

  final Color forest;
  final Color green;
  final Color freshLeaf;
  final Color softSage;
  final Color paleLeaf;
  final Color cream;
  final Color canvas;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color honey;
  final Color tomato;
  final Color berry;
  final Color darkSoil;
  final Color border;
  final Color shadowColor;

  // Material 3 Tonal Elevation Steps
  final Color surfaceElevated1;
  final Color surfaceElevated2;
  final Color surfaceElevated3;
  final Color surfaceElevated4;

  // Curated category accent tokens
  final Color categoryFruits;
  final Color categoryVegetables;
  final Color categoryGrains;
  final Color categoryDairy;
  final Color categoryHerbs;
  final Color categoryOrganic;

  // Order status semantic tokens
  final Color statusPending;
  final Color statusConfirmed;
  final Color statusReady;
  final Color statusCompleted;
  final Color statusCancelled;

  static const light = HarvestPalette(
    forest: Color(0xFF3D7A44), // Harvest Green (primary)
    green: Color(0xFF3D7A44),
    freshLeaf: Color(0xFF5C8A3A),
    softSage: Color(0xFFE8F5EE),
    paleLeaf: Color(0xFFF0EDE4), // Surface Variant
    cream: Color(0xFFFBFAF7), // Background (warm off-white)
    canvas: Color(0xFFFBFAF7), // Screen background
    surface: Color(0xFFFFFFFF), // Cards, sheets, tiles
    ink: Color(0xFF2B2620), // Soil Neutral body text
    muted: Color(0xFF6B6459), // Secondary text
    honey: Color(0xFFE8A93B), // Sunrise Amber (secondary/accent)
    tomato: Color(0xFFC1442D), // Tomato Red (alert/out-of-stock)
    berry: Color(0xFF8B5CF6),
    darkSoil: Color(0xFF2B2620),
    border: Color(0xFFE2DED3), // Divider / Outline
    shadowColor: Color(0x0F2B2620),
    surfaceElevated1: Color(0xFFFFFFFF),
    surfaceElevated2: Color(0xFFFFFFFF),
    surfaceElevated3: Color(0xFFF0EDE4),
    surfaceElevated4: Color(0xFFF0EDE4),
    categoryFruits: Color(0xFFD9714E), // terracotta
    categoryVegetables: Color(0xFF5C8A3A), // leaf green
    categoryGrains: Color(0xFFC79A4B), // wheat
    categoryDairy: Color(0xFF7A9BB0), // soft blue-grey
    categoryHerbs: Color(0xFF6E8B5E), // sage
    categoryOrganic: Color(0xFF3D7A44), // brand primary
    statusPending: Color(0xFFC79A4B),
    statusConfirmed: Color(0xFF5C8A3A),
    statusReady: Color(0xFF3D7A44),
    statusCompleted: Color(0xFF6B6459),
    statusCancelled: Color(0xFFC1442D),
  );

  static const dark = HarvestPalette(
    forest: Color(0xFF8FC494), // Desaturated Harvest Green
    green: Color(0xFF8FC494),
    freshLeaf: Color(0xFF9AC47D),
    softSage: Color(0xFF2A2620),
    paleLeaf: Color(0xFF211E1A),
    cream: Color(0xFF1A1815), // Background base (0dp warm dark grey-brown)
    canvas: Color(0xFF1A1815), // Never pure black (#000000)
    surface: Color(0xFF211E1A), // Surface +1 (resting cards)
    ink: Color(0xFFF2EFE9), // Text Primary (15:1 contrast against 1A1815)
    muted: Color(0xFFB8B0A2), // Text Secondary
    honey: Color(0xFFF0C572), // Lightened Sunrise Amber
    tomato: Color(0xFFE8917E), // Lightened Tomato Red
    berry: Color(0xFFA78BFA),
    darkSoil: Color(0xFF123318), // On Primary ink
    border: Color(0xFF3A352C), // Divider / Outline
    shadowColor: Color(0x66000000),
    surfaceElevated1: Color(0xFF211E1A), // +3%
    surfaceElevated2: Color(0xFF2A2620), // +6% bottom sheets, nav
    surfaceElevated3: Color(0xFF332E26), // +8% search bar, floating bars
    surfaceElevated4: Color(0xFF3C362D), // +11% dropdowns, popovers
    categoryFruits: Color(0xFFE8917E),
    categoryVegetables: Color(0xFF9AC47D),
    categoryGrains: Color(0xFFDCB876),
    categoryDairy: Color(0xFFA8C4D4),
    categoryHerbs: Color(0xFFA3BF93),
    categoryOrganic: Color(0xFF8FC494),
    statusPending: Color(0xFFDCB876),
    statusConfirmed: Color(0xFF9AC47D),
    statusReady: Color(0xFF8FC494),
    statusCompleted: Color(0xFFB8B0A2),
    statusCancelled: Color(0xFFE8917E),
  );

  @override
  HarvestPalette copyWith({
    Color? forest,
    Color? green,
    Color? freshLeaf,
    Color? softSage,
    Color? paleLeaf,
    Color? cream,
    Color? canvas,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? honey,
    Color? tomato,
    Color? berry,
    Color? darkSoil,
    Color? border,
    Color? shadowColor,
    Color? surfaceElevated1,
    Color? surfaceElevated2,
    Color? surfaceElevated3,
    Color? surfaceElevated4,
    Color? categoryFruits,
    Color? categoryVegetables,
    Color? categoryGrains,
    Color? categoryDairy,
    Color? categoryHerbs,
    Color? categoryOrganic,
    Color? statusPending,
    Color? statusConfirmed,
    Color? statusReady,
    Color? statusCompleted,
    Color? statusCancelled,
  }) => HarvestPalette(
    forest: forest ?? this.forest,
    green: green ?? this.green,
    freshLeaf: freshLeaf ?? this.freshLeaf,
    softSage: softSage ?? this.softSage,
    paleLeaf: paleLeaf ?? this.paleLeaf,
    cream: cream ?? this.cream,
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    honey: honey ?? this.honey,
    tomato: tomato ?? this.tomato,
    berry: berry ?? this.berry,
    darkSoil: darkSoil ?? this.darkSoil,
    border: border ?? this.border,
    shadowColor: shadowColor ?? this.shadowColor,
    surfaceElevated1: surfaceElevated1 ?? this.surfaceElevated1,
    surfaceElevated2: surfaceElevated2 ?? this.surfaceElevated2,
    surfaceElevated3: surfaceElevated3 ?? this.surfaceElevated3,
    surfaceElevated4: surfaceElevated4 ?? this.surfaceElevated4,
    categoryFruits: categoryFruits ?? this.categoryFruits,
    categoryVegetables: categoryVegetables ?? this.categoryVegetables,
    categoryGrains: categoryGrains ?? this.categoryGrains,
    categoryDairy: categoryDairy ?? this.categoryDairy,
    categoryHerbs: categoryHerbs ?? this.categoryHerbs,
    categoryOrganic: categoryOrganic ?? this.categoryOrganic,
    statusPending: statusPending ?? this.statusPending,
    statusConfirmed: statusConfirmed ?? this.statusConfirmed,
    statusReady: statusReady ?? this.statusReady,
    statusCompleted: statusCompleted ?? this.statusCompleted,
    statusCancelled: statusCancelled ?? this.statusCancelled,
  );

  @override
  HarvestPalette lerp(ThemeExtension<HarvestPalette>? other, double t) {
    if (other is! HarvestPalette) return this;
    return HarvestPalette(
      forest: Color.lerp(forest, other.forest, t)!,
      green: Color.lerp(green, other.green, t)!,
      freshLeaf: Color.lerp(freshLeaf, other.freshLeaf, t)!,
      softSage: Color.lerp(softSage, other.softSage, t)!,
      paleLeaf: Color.lerp(paleLeaf, other.paleLeaf, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      honey: Color.lerp(honey, other.honey, t)!,
      tomato: Color.lerp(tomato, other.tomato, t)!,
      berry: Color.lerp(berry, other.berry, t)!,
      darkSoil: Color.lerp(darkSoil, other.darkSoil, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      surfaceElevated1: Color.lerp(
        surfaceElevated1,
        other.surfaceElevated1,
        t,
      )!,
      surfaceElevated2: Color.lerp(
        surfaceElevated2,
        other.surfaceElevated2,
        t,
      )!,
      surfaceElevated3: Color.lerp(
        surfaceElevated3,
        other.surfaceElevated3,
        t,
      )!,
      surfaceElevated4: Color.lerp(
        surfaceElevated4,
        other.surfaceElevated4,
        t,
      )!,
      categoryFruits: Color.lerp(categoryFruits, other.categoryFruits, t)!,
      categoryVegetables: Color.lerp(
        categoryVegetables,
        other.categoryVegetables,
        t,
      )!,
      categoryGrains: Color.lerp(categoryGrains, other.categoryGrains, t)!,
      categoryDairy: Color.lerp(categoryDairy, other.categoryDairy, t)!,
      categoryHerbs: Color.lerp(categoryHerbs, other.categoryHerbs, t)!,
      categoryOrganic: Color.lerp(categoryOrganic, other.categoryOrganic, t)!,
      statusPending: Color.lerp(statusPending, other.statusPending, t)!,
      statusConfirmed: Color.lerp(statusConfirmed, other.statusConfirmed, t)!,
      statusReady: Color.lerp(statusReady, other.statusReady, t)!,
      statusCompleted: Color.lerp(statusCompleted, other.statusCompleted, t)!,
      statusCancelled: Color.lerp(statusCancelled, other.statusCancelled, t)!,
    );
  }
}

abstract final class Harvest {
  static HarvestPalette colors(BuildContext context) =>
      Theme.of(context).extension<HarvestPalette>() ?? HarvestPalette.light;

  // Primary brand palette — Research Brief Seed Colors
  static const forest = Color(0xFF3D7A44); // Harvest Green (primary)
  static const deepForest = Color(0xFF1E4624);
  static const green = Color(0xFF3D7A44);
  static const freshLeaf = Color(0xFF5C8A3A);
  static const mint = Color(0xFF5C8A3A);
  static const softSage = Color(0xFFE8F5EE);
  static const sage = Color(0xFFF0EDE4);
  static const paleLeaf = Color(0xFFF0EDE4);
  static const cream = Color(0xFFFBFAF7);
  static const canvas = Color(0xFFFBFAF7);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2B2620); // Soil Neutral
  static const muted = Color(0xFF6B6459);
  static const honey = Color(0xFFE8A93B); // Sunrise Amber
  static const honeyLight = Color(0xFFFDF3DF);
  static const tomato = Color(0xFFC1442D); // Tomato Red alert
  static const clay = Color(0xFFD9714E);
  static const berry = Color(0xFF8B5CF6);
  static const darkSoil = Color(0xFF2B2620);
  static const border = Color(0xFFE2DED3);
  static const success = Color(0xFF3D7A44);
  static const warning = Color(0xFFE8A93B);
  static const danger = Color(0xFFC1442D);
  static const error = Color(0xFFC1442D);

  // Rich Gradients
  static const forestGradient = LinearGradient(
    colors: [Color(0xFF25522B), Color(0xFF3D7A44), Color(0xFF4C9354)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF25522B), Color(0xFF3D7A44)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const chartGradient = LinearGradient(
    colors: [Color(0x553D7A44), Color(0x053D7A44)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const honeyGradient = LinearGradient(
    colors: [Color(0xFFE8A93B), Color(0xFFC79A4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const freshGradient = LinearGradient(
    colors: [Color(0xFFF0EDE4), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Spacing & padding (8pt Baseline Grid Alignment)
  static const page = EdgeInsets.symmetric(horizontal: 20);
  static const pageDense = EdgeInsets.symmetric(horizontal: 16);

  // Radius system
  static const radiusSm = BorderRadius.all(Radius.circular(10));
  static const radiusMd = BorderRadius.all(Radius.circular(16));
  static const radius = BorderRadius.all(Radius.circular(16));
  static const radiusLg = BorderRadius.all(Radius.circular(22));
  static const radiusXl = BorderRadius.all(Radius.circular(28));
  static const radiusPill = BorderRadius.all(Radius.circular(999));

  // Ambient subtle shadows
  static const ambientShadow = [
    BoxShadow(
      color: Color(0x0D2B2620),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static const cardShadow = [
    BoxShadow(color: Color(0x0A2B2620), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const floatingShadow = [
    BoxShadow(
      color: Color(0x182B2620),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
  ];

  // Motion timing
  static const microMotion = Duration(milliseconds: 140);
  static const motion = Duration(milliseconds: 220);
  static const cardMotion = Duration(milliseconds: 280);
  static const routeMotion = Duration(milliseconds: 320);

  // Editorial display typography
  static TextStyle editorial(
    double size, {
    Color? color,
    double height = 1.15,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = -0.5,
  }) => TextStyle(
    fontFamily: 'Fraunces',
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color,
  );

  // Sans grotesque UI typography
  static TextStyle sans(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w500,
    double height = 1.45,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color,
  );

  /// Full Light Mode Theme Definition per SRS v1.0
  static ThemeData get theme {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: forest,
      onPrimary: Colors.white,
      secondary: freshLeaf,
      onSecondary: Colors.white,
      tertiary: honey,
      onTertiary: ink,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: paleLeaf,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: Color(0xFFECE7DB),
      error: tomato,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      extensions: const [HarvestPalette.light],
      textTheme: const TextTheme(
        // Mobile 8pt baseline type scale
        displayLarge: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 32,
          height: 1.18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 26,
          height: 1.23,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 22,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 26,
          height: 1.23,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.30,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.35,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.40,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.40,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          height: 1.46,
          color: ink,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          height: 1.46,
          color: ink,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          height: 1.38,
          color: muted,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          height: 1.33,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          height: 1.38,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          height: 1.27,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: const RoundedRectangleBorder(borderRadius: radiusMd),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forest,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: const BorderSide(color: border, width: 1.2),
          shape: const RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: forest,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: ink,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: TextStyle(color: muted, fontSize: 14),
        hintStyle: TextStyle(color: muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: forest, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: tomato, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: paleLeaf,
        side: const BorderSide(color: border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: forest,
        contentTextStyle: const TextStyle(
          fontFamily: 'Manrope',
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: forest),
    );
  }

  /// Full Dark Mode Theme Definition per Material 3 Tonal Elevation Spec
  static ThemeData get darkTheme {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8FC494), // Desaturated Harvest Green
      onPrimary: Color(0xFF123318), // On Primary dark ink
      secondary: Color(0xFF9AC47D),
      onSecondary: Color(0xFF123318),
      tertiary: Color(0xFFF0C572), // Lightened Sunrise Amber
      onTertiary: Color(0xFF2B1D00),
      surface: Color(0xFF211E1A), // Surface +1
      onSurface: Color(0xFFF2EFE9), // Text Primary (15:1 contrast)
      surfaceContainerHighest: Color(0xFF2A2620), // Surface +2
      onSurfaceVariant: Color(0xFFB8B0A2), // Text Secondary
      outline: Color(0xFF3A352C), // Divider / Outline
      outlineVariant: Color(0x2EFFFFFF),
      error: Color(0xFFE8917E), // Lightened Tomato Red
      onError: Color(0xFF3D0E07),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF1A1815), // Base 0dp dark surface
      extensions: const [HarvestPalette.dark],
      textButtonTheme: TextButtonThemeData(
        style: theme.textButtonTheme.style!.copyWith(
          foregroundColor: const WidgetStatePropertyAll(Color(0xFF8FC494)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: theme.outlinedButtonTheme.style!.copyWith(
          foregroundColor: const WidgetStatePropertyAll(Color(0xFF8FC494)),
          side: const WidgetStatePropertyAll(
            BorderSide(color: Color(0xFF3A352C), width: 1.2),
          ),
        ),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF211E1A),
        labelStyle: const TextStyle(color: Color(0xFFB8B0A2), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFFB8B0A2), fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: Color(0xFF3A352C), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: Color(0xFF8FC494), width: 1.8),
        ),
      ),
      chipTheme: theme.chipTheme.copyWith(
        backgroundColor: const Color(0xFF211E1A),
        selectedColor: const Color(0xFF2A2620),
        side: const BorderSide(color: Color(0xFF3A352C), width: 1),
        labelStyle: const TextStyle(
          fontFamily: 'Manrope',
          color: Color(0xFFF2EFE9),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 32,
          height: 1.18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Color(0xFFF2EFE9),
        ),
        displayMedium: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 26,
          height: 1.23,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: Color(0xFFF2EFE9),
        ),
        displaySmall: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 22,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: Color(0xFFF2EFE9),
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 26,
          height: 1.23,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF2EFE9),
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: Color(0xFFF2EFE9),
          height: 1.30,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: Color(0xFFF2EFE9),
          height: 1.35,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF2EFE9),
          height: 1.40,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF2EFE9),
          height: 1.40,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          height: 1.46,
          color: Color(0xFFF2EFE9),
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          height: 1.46,
          color: Color(0xFFF2EFE9),
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          height: 1.38,
          color: Color(0xFFB8B0A2),
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          height: 1.33,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          height: 1.38,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          height: 1.27,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1815),
        foregroundColor: Color(0xFFF2EFE9),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF2EFE9),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A352C),
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: theme.filledButtonTheme.style!.textStyle!.resolve({}),
          backgroundColor: const Color(0xFF8FC494),
          foregroundColor: const Color(0xFF123318),
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: const RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF211E1A),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0xFFB8B0A2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF8FC494),
        contentTextStyle: const TextStyle(
          fontFamily: 'Manrope',
          color: Color(0xFF123318),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF8FC494),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF211E1A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF211E1A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: const Color(0xFFF2EFE9),
        ),
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
