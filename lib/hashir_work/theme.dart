import 'package:flutter/material.dart';

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

  static const light = HarvestPalette(
    forest: Color(0xFF0E4D34),
    green: Color(0xFF166534),
    freshLeaf: Color(0xFF10B981),
    softSage: Color(0xFFD1FAE5),
    paleLeaf: Color(0xFFE8F5EE),
    cream: Color(0xFFFFFFFF),
    canvas: Color(0xFFF4F6F4),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF111827),
    muted: Color(0xFF6B7280),
    honey: Color(0xFFF59E0B),
    tomato: Color(0xFFEF4444),
    berry: Color(0xFF8B5CF6),
    darkSoil: Color(0xFF1F2937),
    border: Color(0xFFE5E7EB),
    shadowColor: Color(0x0A000000),
  );

  static const dark = HarvestPalette(
    forest: Color(0xFF223C2D),
    green: Color(0xFF77B47A),
    freshLeaf: Color(0xFFA7C6A6),
    softSage: Color(0xFF2A3E31),
    paleLeaf: Color(0xFF1D2821),
    cream: Color(0xFF0E1511),
    canvas: Color(0xFF151E18),
    surface: Color(0xFF1B241E),
    ink: Color(0xFFF4F5F0),
    muted: Color(0xFFA8B0A9),
    honey: Color(0xFFF2BA57),
    tomato: Color(0xFFEB7655),
    berry: Color(0xFFD4616A),
    darkSoil: Color(0xFF0A0F0C),
    border: Color(0x1AFFFFFF),
    shadowColor: Color(0x26000000),
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
    );
  }
}

abstract final class Harvest {
  // Primary brand palette (HARVEST BOTANICAL EDITORIAL — REFERENCE MATCH)
  static const forest = Color(0xFF0E4D34);
  static const deepForest = Color(0xFF0A3A27);
  static const green = Color(0xFF166534);
  static const freshLeaf = Color(0xFF10B981);
  static const mint = Color(0xFF10B981);
  static const softSage = Color(0xFFD1FAE5);
  static const sage = Color(0xFFE8F5EE);
  static const paleLeaf = Color(0xFFE8F5EE);
  static const cream = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF4F6F4);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const honey = Color(0xFFF59E0B);
  static const honeyLight = Color(0xFFFEF3C7);
  static const tomato = Color(0xFFEF4444);
  static const clay = Color(0xFFC2410C);
  static const berry = Color(0xFF8B5CF6);
  static const darkSoil = Color(0xFF1F2937);
  static const border = Color(0xFFE5E7EB);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const error = Color(0xFFDC2626);

  // Rich Gradients
  static const forestGradient = LinearGradient(
    colors: [Color(0xFF0A3A27), Color(0xFF0E4D34), Color(0xFF156345)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0A3A27), Color(0xFF0E4D34)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const chartGradient = LinearGradient(
    colors: [Color(0x5510B981), Color(0x0510B981)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const honeyGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const freshGradient = LinearGradient(
    colors: [Color(0xFFE8F5EE), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Spacing & padding
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
      color: Color(0x0C0C2D1F),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static const cardShadow = [
    BoxShadow(color: Color(0x0A14281C), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const floatingShadow = [
    BoxShadow(
      color: Color(0x1A14281C),
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

  // Typography helpers
  static TextStyle editorial(
    double size, {
    Color color = ink,
    double height = 1.15,
  }) => TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: size,
    height: height,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.6,
    color: color,
  );

  static TextStyle sans(
    double size, {
    Color color = ink,
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

  static ThemeData get theme {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: forest,
      onPrimary: Colors.white,
      secondary: green,
      onSecondary: Colors.white,
      tertiary: honey,
      onTertiary: darkSoil,
      surface: cream,
      onSurface: ink,
      surfaceContainerHighest: sage,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: Color(0xFFECEFE8),
      error: danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      visualDensity: VisualDensity.standard,
      extensions: const [HarvestPalette.light],
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 38,
          height: 1.12,
          color: ink,
        ),
        displayMedium: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 30,
          height: 1.18,
          color: ink,
        ),
        displaySmall: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 24,
          height: 1.22,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.35,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: ink,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: ink,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.45,
          color: muted,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
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
            fontWeight: FontWeight.w700,
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
            fontWeight: FontWeight.w700,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: muted, fontSize: 14),
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: forest, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: sage,
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

  static ThemeData get darkTheme {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF77B47A),
      onPrimary: Color(0xFF0E1511),
      secondary: Color(0xFFA7C6A6),
      onSecondary: Color(0xFF0E1511),
      tertiary: Color(0xFFF2BA57),
      onTertiary: Color(0xFF0E1511),
      surface: Color(0xFF151E18),
      onSurface: Color(0xFFF4F5F0),
      surfaceContainerHighest: Color(0xFF1D2821),
      onSurfaceVariant: Color(0xFFA8B0A9),
      outline: Color(0x26FFFFFF),
      outlineVariant: Color(0x14FFFFFF),
      error: Color(0xFFEB7655),
      onError: Color(0xFF0E1511),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0E1511),
      extensions: const [HarvestPalette.dark],
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 38,
          height: 1.12,
          color: Color(0xFFF4F5F0),
        ),
        displayMedium: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 30,
          height: 1.18,
          color: Color(0xFFF4F5F0),
        ),
        displaySmall: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 24,
          height: 1.22,
          color: Color(0xFFF4F5F0),
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF4F5F0),
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF4F5F0),
          height: 1.35,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF4F5F0),
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF4F5F0),
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Color(0xFFF4F5F0),
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0xFFF4F5F0),
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.45,
          color: Color(0xFFA8B0A9),
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0E1511),
        foregroundColor: Color(0xFFF4F5F0),
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF),
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF77B47A),
          foregroundColor: const Color(0xFF0E1511),
          minimumSize: const Size(48, 52),
          shape: const RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
    );
  }
}
