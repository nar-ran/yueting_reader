import 'package:flutter/material.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/entities/reading_entry.dart';

// Dialogo modal para cambiar el titulo de un texto de la biblioteca
class RenameDialog extends StatefulWidget {
  final ReadingEntry entry;

  const RenameDialog({super.key, required this.entry});

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry.title);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final newTitle = _controller.text.trim();
    if (newTitle.isNotEmpty) {
      Navigator.of(context).pop(newTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<ThemeColors>() ?? ThemeColors.defaultColors;

    return AlertDialog(
      backgroundColor: colors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.library_rename_title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.text),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
        style: TextStyle(color: colors.text),
        decoration: InputDecoration(
          hintText: l10n.library_rename_hint,
          hintStyle: TextStyle(color: colors.text.withValues(alpha: 0.4)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.common_cancel, style: TextStyle(color: colors.text.withValues(alpha: 0.6))),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.background,
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l10n.common_save, style: TextStyle(color: colors.background == const Color(0xFFFFFFFF) ? Colors.white : colors.text, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
