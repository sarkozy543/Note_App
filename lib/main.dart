// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // StaggeredGrid için import
import 'package:note_app/database/notes_database.dart'; // NotesDatabase için import
import 'package:note_app/models/note.dart'; // Note modeli için import
import 'package:note_app/pages/add_edit_note_page.dart'; // AddEditNotePage için import
import 'package:note_app/pages/note_detail_page.dart'; // NoteDetailPage için import
import 'package:note_app/pages/web_scraper_page.dart'; // WebScraperPage için import
import 'package:intl/intl.dart'; // DateFormat için import
import 'package:note_app/pages/file_text_extractor_page.dart'; // Yeni import: FileTextExtractorPage için
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Not Uygulaması',
      theme: AppTheme.lightTheme,
      home: const MainNotesPage(), // Ana sayfa widget'ımız
    );
  }
}

class MainNotesPage extends StatefulWidget {
  const MainNotesPage({super.key});

  @override
  State<MainNotesPage> createState() => _MainNotesPageState();
}

class _MainNotesPageState extends State<MainNotesPage> {
  List<Note> notes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _readAllNotes();
  }

  @override
  void dispose() {
    NotesDatabase.instance.close();
    super.dispose();
  }

  Future<void> _readAllNotes() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      notes = await NotesDatabase.instance.readAllNotes();
      debugPrint('Notlar başarıyla yüklendi. Toplam not: ${notes.length}');
    } catch (e) {
      debugPrint('Notları yüklerken hata oluştu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notlar yüklenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notlar',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Arama işlevi buraya gelecek
              // Notları filtrelemek için yeni bir arama çubuğu açabiliriz.
            },
          ),
          IconButton(
            icon: const Icon(Icons.web), // Web scraper iconu
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const WebScraperPage()),
              );
              // WebScraperPage'den geri dönüldüğünde notları yenile
              if (!mounted) return;
              _readAllNotes();
            },
          ),
          // Yeni Dosya Çıkarıcı Butonu
          IconButton(
            icon: const Icon(Icons.insert_drive_file), // Dosya ikonu
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const FileTextExtractorPage()),
              );
              // FileTextExtractorPage'den geri dönüldüğünde notları yenile
              if (!mounted) return;
              _readAllNotes();
            },
          ),
          const SizedBox(width: 8), // İkonlar arasında biraz boşluk
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : notes.isEmpty
                ? const Text(
                    'Henüz Not Yok',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )
                : buildNotes(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const AddEditNotePage()),
          );
          // Yeni not eklendikten sonra listeyi güncelle
          if (!mounted) return;
          _readAllNotes();
        },
      ),
    );
  }

  Widget buildNotes() => MasonryGridView.builder(
        itemCount: notes.length,
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) {
          final note = notes[index];
          return GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => NoteDetailPage(noteId: note.id!),
              ));
              if (!mounted) return;
              _readAllNotes();
            },
            child: NoteCardWidget(note: note, index: index),
          );
        },
      );
}

// Renk paleti (MainNotesPage sınıfının dışında tanımlanmalı, genel erişim için)
const _lightColors = [
  Color(0xFFFFF9C4), // Yellow
  Color(0xFFE1BEE7), // Purple
  Color(0xFFC8E6C9), // Green
  Color(0xFFBBDEFB), // Blue
  Color(0xFFFFCCBC), // Orange
];

// NoteCardWidget
class NoteCardWidget extends StatelessWidget {
  const NoteCardWidget({
    super.key,
    required this.note,
    required this.index,
  });

  final Note note;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = _lightColors[index % _lightColors.length];
    final minHeight = getMinHeight(index);
    final time = DateFormat.yMMMd().format(note.createdTime);

    return Card(
      color: color,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              note.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getMinHeight(int index) {
    switch (index % 4) {
      case 0:
        return 100;
      case 1:
        return 150;
      case 2:
        return 150;
      case 3:
        return 100;
      default:
        return 100;
    }
  }
}