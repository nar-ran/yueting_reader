import 'package:flutter/material.dart';

// Extension de tema personalizada para soportar multiples paletas de colores coherentes
class ThemeColors extends ThemeExtension<ThemeColors> {
  final Color primary;
  final Color background;
  final Color cardBackground;
  final Color accent;
  final Color text;
  final Color divider;

  const ThemeColors({
    required this.primary,
    required this.background,
    required this.cardBackground,
    required this.accent,
    required this.text,
    required this.divider,
  });

  static const defaultColors = ThemeColors(
    primary: Color(0xFF673AB7), // Violeta clasico
    background: Color(0xFFF9F9FB), // Gris claro premium
    cardBackground: Color(0xFFFFFFFF), // Blanco puro
    accent: Color(0xFFFFA000), // Resaltado de shadowing naranja/ambar
    text: Color(0xFF212121), // Texto oscuro suave
    divider: Color(0xFFE0E0E0), // Gris de division
  );

  @override
  ThemeColors copyWith({
    Color? primary,
    Color? background,
    Color? cardBackground,
    Color? accent,
    Color? text,
    Color? divider,
  }) {
    return ThemeColors(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      accent: accent ?? this.accent,
      text: text ?? this.text,
      divider: divider ?? this.divider,
    );
  }

  @override
  ThemeColors lerp(ThemeExtension<ThemeColors>? other, double t) {
    if (other is! ThemeColors) {
      return this;
    }
    return ThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      background: Color.lerp(background, other.background, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      text: Color.lerp(text, other.text, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }

  // Genera el objeto ThemeData completo basado en el nombre de la paleta seleccionada
  static ThemeData getThemeData(String themeName) {
    final colors = getColors(themeName);
    
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      dividerColor: colors.divider,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        primary: colors.primary,
        surface: colors.cardBackground,
        onSurface: colors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.cardBackground,
        foregroundColor: colors.text,
        elevation: 0.5,
        iconTheme: IconThemeData(color: colors.text),
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      extensions: [colors],
    );
  }

  // Mapea el nombre a los colores de las 9 paletas de la imagen Cloud
  static ThemeColors getColors(String themeName) {
    switch (themeName) {
      case 'earthy':
      case 'cloud_1': // Nube de Atardecer
        return const ThemeColors(
          primary: Color(0xFFE8A990),
          background: Color(0xFFF8F4EB),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFF98A8D2),
          text: Color(0xFF4A3C31),
          divider: Color(0xFFE7D3AA),
        );
      case 'cloud_2': // Nube de Ensueño
        return const ThemeColors(
          primary: Color(0xFFB2ABC0),
          background: Color(0xFFFAF9F4),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFBDC2CF),
          text: Color(0xFF3E3C42),
          divider: Color(0xFFECEAD9),
        );
      case 'lavender':
      case 'cloud_3': // Nube de Lavanda
        return const ThemeColors(
          primary: Color(0xFF9FAAD2),
          background: Color(0xFFFAF7F9),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFE4D3DD),
          text: Color(0xFF3F435C),
          divider: Color(0xFFEEEAF3),
        );
      case 'sage':
      case 'cloud_4': // Nube de Menta
        return const ThemeColors(
          primary: Color(0xFFB9D9C5),
          background: Color(0xFFFAFBF8),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFDBDDDB),
          text: Color(0xFF3B463F),
          divider: Color(0xFFE5EADF),
        );
      case 'cloud_5': // Nube de Vainilla
        return const ThemeColors(
          primary: Color(0xFFECDCA8),
          background: Color(0xFFFBF9F0),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFD2CFDC),
          text: Color(0xFF4C4957),
          divider: Color(0xFFE5ECD4),
        );
      case 'cloud_6': // Nube de Tarde
        return const ThemeColors(
          primary: Color(0xFF9384B6),
          background: Color(0xFFF9F5F7),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFF596CAD),
          text: Color(0xFF2F2A3D),
          divider: Color(0xFFDCB0C3),
        );
      case 'cloud_7': // Nube de Coral
        return const ThemeColors(
          primary: Color(0xFFF0BFB4),
          background: Color(0xFFFBF8F5),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFDDDABF),
          text: Color(0xFF55453E),
          divider: Color(0xFFF3D8C1),
        );
      case 'cloud_8': // Nube de Rosas
        return const ThemeColors(
          primary: Color(0xFFE8B2C3),
          background: Color(0xFFF8F3F5),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFB8C0BE),
          text: Color(0xFF4E3B42),
          divider: Color(0xFFE3CFD8),
        );
      case 'cloud_9': // Nube del Alba
        return const ThemeColors(
          primary: Color(0xFFD4DFE0),
          background: Color(0xFFFDF9F7),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFE3E1DC),
          text: Color(0xFF3A4546),
          divider: Color(0xFFF9E3DA),
        );
      case 'classic':
      default:
        return const ThemeColors(
          primary: Color(0xFF673AB7),
          background: Color(0xFFF9F9FB),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFFFA000),
          text: Color(0xFF212121),
          divider: Color(0xFFE0E0E0),
        );
    }
  }
}
