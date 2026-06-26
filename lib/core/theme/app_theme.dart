import 'package:flutter/material.dart';

class AppTheme {
  // Brand palette (kept from the original design).
  static const Color deepRed = Color(0xFFE53935);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color lightBackground = Color(0xFFFAFAFA);

  /// Subtle red wash fading into the background, used at the top of every screen
  /// so they share the player's immersive look behind the transparent app bar.
  static BoxDecoration topFade(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.colorScheme.primary.withValues(alpha: 0.18),
          theme.scaffoldBackgroundColor,
        ],
        stops: const [0.0, 0.28],
      ),
    );
  }

  static final ThemeData darkTheme = _build(
    brightness: Brightness.dark,
    scaffold: darkBackground,
    surface: darkSurface,
    navBackground: const Color(0xFF181818),
    onSurface: Colors.white,
    subtitle: Colors.white70,
    scheme: const ColorScheme.dark(
      primary: deepRed,
      onPrimary: Colors.white,
      secondary: deepRed,
      onSecondary: Colors.white,
      surface: darkSurface,
      onSurface: Colors.white,
    ),
  );

  static final ThemeData lightTheme = _build(
    brightness: Brightness.light,
    scaffold: lightBackground,
    surface: Colors.white,
    navBackground: Colors.white,
    onSurface: const Color(0xFF1A1A1A),
    subtitle: Colors.black54,
    scheme: const ColorScheme.light(
      primary: deepRed,
      onPrimary: Colors.white,
      secondary: deepRed,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1A1A1A),
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color navBackground,
    required Color onSurface,
    required Color subtitle,
    required ColorScheme scheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: scheme,
      primaryColor: deepRed,

      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: onSurface.withValues(alpha: 0.85),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: deepRed,
        inactiveTrackColor: deepRed.withValues(alpha: 0.18),
        thumbColor: deepRed,
        trackHeight: 4,
        overlayColor: deepRed.withValues(alpha: 0.16),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackground,
        indicatorColor: deepRed.withValues(alpha: 0.20),
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? deepRed
                : onSurface.withValues(alpha: 0.55),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? deepRed
                : onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: deepRed,
        foregroundColor: Colors.white,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: deepRed),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      iconTheme: IconThemeData(color: onSurface.withValues(alpha: 0.9)),

      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: subtitle),
        bodySmall: TextStyle(color: subtitle),
      ),
    );
  }
}
