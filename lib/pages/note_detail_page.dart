// lib/pages/note_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_app/database/notes_database.dart';
import 'package:note_app/models/note.dart';
import 'package:note_app/pages/add_edit_note_page.dart';

class NoteDetailPage extends StatefulWidget {
  final int noteId;

  const NoteDetailPage({
    super.key, // super.key kullanımı
    required this.noteId,
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late Note note;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshNote();
  }

  Future<void> _refreshNote() async { // Future<void> olarak tanımla
    if (!mounted) return; // mounted kontrolü
    setState(() => isLoading = true);
    try {
      note = await NotesDatabase.instance.readNote(widget.noteId); // 'this.note' yerine 'note'
    } catch (e) {
      debugPrint('Not detayını yüklerken hata oluştu: $e');
      if (mounted) { // mounted kontrolü
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not detayını yüklerken hata oluştu: $e')),
        );
        // Hata durumunda sayfayı kapatmak isteyebilirsiniz
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) { // mounted kontrolü
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // note objesi henüz yüklenmemişse başlık boş olabilir veya bir yükleniyor göstergesi koyulabilir
        title: isLoading
            ? const Text('Yükleniyor...')
            : Text(
                note.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (isLoading) return; // Not yüklenirken düzenlemeyi engelle

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => AddEditNotePage(note: note),
                ),
              );
              // Sayfa geri döndüğünde, eğer widget hala mounted ise notu yenile
              if (mounted) { // mounted kontrolü
                _refreshNote(); // Notu düzenledikten sonra sayfayı yenile
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await NotesDatabase.instance.delete(widget.noteId);
              if (mounted) { // mounted kontrolü
                Navigator.of(context).pop(); // Geri dön
              }
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMMMd().format(note.createdTime),
                    style: const TextStyle(color: Colors.white38),
                  ),
                  const SizedBox(height: 8),
                  Expanded( // İçeriğin taşmasını önlemek için Expanded kullan
                    child: SingleChildScrollView( // İçerik uzunsa kaydırılabilir olsun
                      child: Text(
                        note.content,
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}