import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/entities/reading_entry.dart';

// Tarjeta que representa un texto guardado en la biblioteca
class ReadingEntryCard extends StatelessWidget {
  final ReadingEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const ReadingEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  // Formatea la fecha de ultima apertura de forma localizada
  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final l10n = AppLocalizations.of(context)!;
    
    if (diff.inDays == 0) return l10n.library_date_today;
    if (diff.inDays == 1) return l10n.library_date_yesterday;
    if (diff.inDays < 7) return l10n.library_date_days_ago(diff.inDays.toString());
    
    return DateFormat('dd MMM yyyy', l10n.localeName).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<ThemeColors>() ?? ThemeColors.defaultColors;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.text.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Izquierda: icono o indicador del tema
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('阅', style: TextStyle(fontSize: 22, color: colors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 14),

            // Centro: titulo, vista previa y fecha
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.text.withValues(alpha: 0.6),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(context, entry.dateLastOpened),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Derecha: menu de opciones
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colors.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'rename') onRename();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: colors.text.withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
                      Text(l10n.common_rename, style: TextStyle(color: colors.text)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Text(l10n.common_delete, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
