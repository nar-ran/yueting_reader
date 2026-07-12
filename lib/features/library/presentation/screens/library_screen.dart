import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/reading_entry.dart';
import '../../domain/services/library_service.dart';
import '../widgets/reading_entry_card.dart';
import '../widgets/rename_dialog.dart';
import 'package:yueting_reader/features/reader/presentation/screens/reading_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibraryService _libraryService = LibraryService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEntry(ReadingEntry entry) async {
    await _libraryService.touchEntry(entry.id);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingScreen(
          title: entry.displayTitle,
          text: entry.text,
          entryId: entry.id,
        ),
      ),
    );
  }

  Future<void> _renameEntry(ReadingEntry entry) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => RenameDialog(entry: entry),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      await _libraryService.renameEntry(entry.id, newTitle);
    }
  }

  Future<void> _confirmDelete(ReadingEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar texto', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${entry.displayTitle}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _libraryService.deleteEntry(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          'Biblioteca',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Buscar textos guardados...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Reactive list from Hive
          Expanded(
            child: ValueListenableBuilder<Box<ReadingEntry>>(
              valueListenable: _libraryService.listenable,
              builder: (context, box, _) {
                final entries = _searchQuery.trim().isEmpty
                    ? _libraryService.getAllEntries()
                    : _libraryService.search(_searchQuery);

                if (entries.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Dismissible(
                      key: Key(entry.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await _confirmDelete(entry);
                        return false; // We handle deletion manually
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                      ),
                      child: ReadingEntryCard(
                        entry: entry,
                        onTap: () => _openEntry(entry),
                        onRename: () => _renameEntry(entry),
                        onDelete: () => _confirmDelete(entry),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isEmpty = _searchQuery.trim().isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmpty ? Icons.menu_book_outlined : Icons.search_off_rounded,
              size: 72,
              color: Colors.deepPurple.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),
            Text(
              isEmpty ? 'Tu biblioteca está vacía' : 'Sin resultados',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEmpty
                  ? 'Los textos que leas se guardarán aquí automáticamente para que puedas retomar la lectura cuando quieras.'
                  : 'No se encontraron textos que coincidan con tu búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
