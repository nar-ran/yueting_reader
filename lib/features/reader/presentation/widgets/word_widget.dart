import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/entities/word_token.dart';

// Widget que representa una palabra individual con su Hanzi y Pinyin
class WordWidget extends StatelessWidget {
  final WordToken token;
  final bool isSelected;
  final bool isPlaying;
  final double fontSizeMultiplier;
  final VoidCallback onTap;

  const WordWidget({
    super.key,
    required this.token,
    required this.isSelected,
    required this.isPlaying,
    this.fontSizeMultiplier = 1.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ThemeColors>() ?? ThemeColors.defaultColors;

    // Si es un salto de linea, fuerza el salto en el Wrap usando ancho completo
    if (token.text == '\n' || token.text == '\r') {
      return const SizedBox(width: double.infinity, height: 12);
    }

    // Si es un espacio, muestra un pequeño espacio horizontal
    if (token.text == ' ' || token.text == '\t') {
      return const SizedBox(width: 8);
    }

    if (token.isPunctuation) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Text(
          token.text,
          style: TextStyle(
            fontSize: 22 * fontSizeMultiplier,
            fontWeight: FontWeight.w400,
            color: colors.text.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : isPlaying
                  ? colors.accent.withValues(alpha: 0.3)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.4)
                : isPlaying
                    ? colors.accent.withValues(alpha: 0.7)
                    : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pinyin
            Text(
              token.pinyin,
              style: TextStyle(
                fontSize: 12 * fontSizeMultiplier,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? colors.primary
                    : isPlaying
                        ? colors.text
                        : colors.text.withValues(alpha: 0.5),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2.0),
            // Hanzi
            Text(
              token.text,
              style: TextStyle(
                fontSize: 22 * fontSizeMultiplier,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? colors.primary
                    : isPlaying
                        ? colors.text
                        : colors.text,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
