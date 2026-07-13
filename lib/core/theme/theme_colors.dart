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
    primary: Color(0xFF828854), 
    background: Color(0xFFF9F8F5),
    cardBackground: Color(0xFFFFFFFF),
    accent: Color(0xFFEAA093), 
    text: Color(0xFF433E3A), 
    divider: Color(0xFFBFC08E),
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

  // Mapea el nombre a los colores de las paletas
  static ThemeColors getColors(String themeName) {
    switch (themeName) {
      case 'violet': // Clasico Violeta
        return const ThemeColors(
          primary: Color(0xFF673AB7),
          background: Color(0xFFF9F9FB),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFFFA000),
          text: Color(0xFF212121),
          divider: Color(0xFFE0E0E0),
        );
      case 'earthy': // Nube de Atardecer
        return const ThemeColors(
          primary: Color(0xFFCC6B4F),
          background: Color(0xFFFAF7F2),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFF6C83B8),
          text: Color(0xFF4A3C31),
          divider: Color(0xFFE7D3AA),
        );
      case 'cloud_2': // Nube de Ensueño
        return const ThemeColors(
          primary: Color(0xFF7C738D),
          background: Color(0xFFFAF9F6),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFF8A94A6),
          text: Color(0xFF2C2A30),
          divider: Color(0xFFECEAD9),
        );
      case 'lavender':
      case 'cloud_3': // Nube de Lavanda
        return const ThemeColors(
          primary: Color(0xFF6172A8),
          background: Color(0xFFF9F7FA),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFC29FBA),
          text: Color(0xFF282D46),
          divider: Color(0xFFEEEAF3),
        );
      case 'sage':
      case 'cloud_4': // Nube de Menta
        return const ThemeColors(
          primary: Color(0xFF4E8761),
          background: Color(0xFFFAFBF9),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFF8E958E),
          text: Color(0xFF26312A),
          divider: Color(0xFFE5EADF),
        );
      case 'cloud_5': // Nube de Vainilla
        return const ThemeColors(
          primary: Color(0xFFB08522),
          background: Color(0xFFFAF9F2),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFF9C98B0),
          text: Color(0xFF2F2C3A),
          divider: Color(0xFFECDCA8),
        );
      case 'cloud_6': // Nube de Tarde
        return const ThemeColors(
          primary: Color(0xFF68598C),
          background: Color(0xFFFAF7F9),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFF42528A),
          text: Color(0xFF1F1A28),
          divider: Color(0xFFDCB0C3),
        );
      case 'cloud_7': // Nube de Coral
        return const ThemeColors(
          primary: Color(0xFFD48070),
          background: Color(0xFFFAF6F4),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFF9A9673),
          text: Color(0xFF3A2A23),
          divider: Color(0xFFF3D8C1),
        );
      case 'cloud_8': // Nube de Rosas
        return const ThemeColors(
          primary: Color(0xFFB55673),
          background: Color(0xFFFAF5F7),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFF7D8D8A),
          text: Color(0xFF37252C),
          divider: Color(0xFFE3CFD8),
        );
      case 'cloud_9': // Nube del Alba
        return const ThemeColors(
          primary: Color(0xFF4E7C80),
          background: Color(0xFFFAFDFD),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFC4ADA3),
          text: Color(0xFF263132),
          divider: Color(0xFFF9E3DA),
        );
      case 'classic':
      default:
        // Por defecto: Clásico Salvia
        return const ThemeColors(
          primary: Color(0xFFBFBB8D),
          background: Color(0xFFF9F8F5),
          cardBackground: Color(0xFFFFFFFF),
          accent: Color(0xFFEAA093),
          text: Color(0xFF433E3A),
          divider: Color(0xFF828854),
        );
    }
  }
}
