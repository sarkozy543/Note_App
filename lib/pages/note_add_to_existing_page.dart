// lib/pages/note_add_to_existing_page.dart
import 'package:flutter/material.dart';
import 'package:note_app/database/notes_database.dart';
import 'package:note_app/models/note.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';

class NoteAddToExistingPage extends StatefulWidget {
  final String selectedText;
  final String sourceUrl; // Yeni: Kaynak URL

  const NoteAddToExistingPage({
    super.key,
    required this.selectedText,
    required this.sourceUrl, // Yeni: sourceUrl parametresi zorunlu yapıldı
  });

  @override
  State<NoteAddToExistingPage> createState() => _NoteAddToExistingPageState();
}

class _NoteAddToExistingPageState extends State<NoteAddToExistingPage> {
  List<Note> notes = [];
  bool isLoading = false;

  final List<Color> _lightColors = [
    const Color(0xFFFFF9C4), // Yellow
    const Color(0xFFE1BEE7), // Purple
    const Color(0xFFC8E6C9), // Green
    const Color(0xFFBBDEFB), // Blue
    const Color(0xFFFFCCBC), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _readAllNotes();
  }

  Future<void> _readAllNotes() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      notes = await NotesDatabase.instance.readAllNotes();
      debugPrint('Notlar "Nota Ekle" sayfası için yüklendi. Toplam not: ${notes.length}');
      if (notes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Henüz kaydedilmiş notunuz yok. Lütfen önce bir not oluşturun.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Notları "Nota Ekle" sayfası için yüklerken hata oluştu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notları yüklerken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Seçilen metni ve URL'yi nota ekleyen metot
  Future<void> _addSelectedTextToNote(int noteId) async {
    try {
      final existingNote = await NotesDatabase.instance.readNote(noteId);

      // Kaynak URL'den sadece host (site adı) kısmını alalım
      Uri uri = Uri.parse(widget.sourceUrl);
      String siteName = uri.host.isNotEmpty ? uri.host : widget.sourceUrl; // Host yoksa tam URL'yi kullan

      // "Kaynak: [site adı/url]" şeklinde bir başlık ekle
      // Eğer site adı "www." ile başlıyorsa, "www." kısmını kaldıralım daha temiz görünsün.
      if (siteName.startsWith('www.')) {
        siteName = siteName.substring(4);
      }

      final sourceLine = "Kaynak: $siteName";

      // Metni mevcut içeriğin sonuna, kaynak bilgisi ve boşlukla ekle
      final updatedContent = existingNote.content.isNotEmpty
          ? "${existingNote.content}\n\n$sourceLine\n\n${widget.selectedText}"
          : "$sourceLine\n\n${widget.selectedText}";


      final updatedNote = existingNote.copyWith(
        content: updatedContent,
        createdTime: DateTime.now(), // Güncelleme zamanını da değiştiriyoruz
      );

      await NotesDatabase.instance.update(updatedNote);
      debugPrint('Metin ve kaynak başarıyla nota eklendi. Not ID: $noteId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metin ve kaynak nota başarıyla eklendi!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Metni nota eklerken hata oluştu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Metni nota eklerken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metni Hangi Nota Eklemek İstersiniz?'),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : notes.isEmpty
                ? const Text(
                    'Not bulunamadı. Lütfen önce bir not oluşturun.',
                    style: TextStyle(color: Colors.black, fontSize: 18), // <-- Rengi siyah yaptık
                    textAlign: TextAlign.center,
                  )
                : buildNotesGrid(),
      ),
    );
  }

  Widget buildNotesGrid() => MasonryGridView.builder(
        itemCount: notes.length,
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) {
          final note = notes[index];
          final color = _lightColors[index % _lightColors.length];

          return GestureDetector(
            onTap: () async {
              await _addSelectedTextToNote(note.id!);
            },
            child: Card(
              color: color,
              margin: const EdgeInsets.all(4),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(note.createdTime),
                      style: TextStyle(color: Colors.black, fontSize: 12), // <-- Rengi siyah yaptık
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.content,
                      style: const TextStyle(color: Colors.black, fontSize: 14), // <-- Rengi siyah yaptık
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}