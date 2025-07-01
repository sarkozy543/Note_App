// lib/pages/add_edit_note_page.dart
import 'package:flutter/material.dart';
import 'package:note_app/database/notes_database.dart';
import 'package:note_app/models/note.dart';

class AddEditNotePage extends StatefulWidget {
  final Note? note;

  const AddEditNotePage({
    super.key, // super.key kullanımı
    this.note,
  });

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  late bool isImportant;
  late int number;
  late String title;
  late String content;

  @override
  void initState() {
    super.initState();

    isImportant = widget.note?.isImportant ?? false;
    number = widget.note?.number ?? 0;
    title = widget.note?.title ?? '';
    content = widget.note?.content ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Yeni Not Ekle' : 'Notu Düzenle'),
        actions: [buildButton()],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildTitleField(),
              const SizedBox(height: 8),
              buildContentField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTitleField() => TextFormField(
        maxLines: 1,
        initialValue: title,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Başlık',
          hintStyle: TextStyle(color: Colors.white70),
        ),
        validator: (value) => value != null && value.isEmpty ? 'Başlık boş olamaz' : null, // 'title' yerine 'value'
        onChanged: (value) => setState(() => title = value), // 'this.title' yerine 'title'
      );

  Widget buildContentField() => TextFormField(
        maxLines: null, // Sınırsız satır
        initialValue: content,
        style: const TextStyle(color: Colors.white60, fontSize: 18),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Notunuzu yazın...',
          hintStyle: TextStyle(color: Colors.white60),
        ),
        validator: (value) => value != null && value.isEmpty ? 'İçerik boş olamaz' : null, // 'content' yerine 'value'
        onChanged: (value) => setState(() => content = value), // 'this.content' yerine 'content'
      );

  Widget buildButton() {
    final isFormValid = title.isNotEmpty && content.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isFormValid ? null : Colors.grey.shade700,
        ),
        onPressed: () async {
          final isValid = _formKey.currentState!.validate();
          debugPrint('Form Doğrulama Durumu: $isValid');

          if (isValid) {
            if (widget.note == null) {
              await addNote();
            } else {
              await updateNote();
            }
            if (mounted) { // mounted kontrolü
              Navigator.of(context).pop(); // Kaydedince geri dön
            }
          }
        },
        child: const Text('Kaydet'),
      ),
    );
  }

  Future<void> addNote() async { // Future<void> olarak tanımla
    final note = Note(
      title: title,
      content: content,
      createdTime: DateTime.now(),
    );

    await NotesDatabase.instance.create(note);
    debugPrint('addNote: Not başarıyla veritabanına eklendi.');
  }

  Future<void> updateNote() async { // Future<void> olarak tanımla
    final note = widget.note!.copyWith(
      title: title,
      content: content,
      createdTime: DateTime.now(),
    );

    await NotesDatabase.instance.update(note);
    debugPrint('updateNote: Not başarıyla veritabanında güncellendi.');
  }
}