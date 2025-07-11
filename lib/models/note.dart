// lib/models/note.dart
// import 'package:sqflite/sqflite.dart'; // Bu satır kaldırıldı çünkü bu dosyada doğrudan kullanılmıyordu

final String tableNotes = 'notes';

class NoteFields {
  static final List<String> values = [
    id, isImportant, number, title, content, createdTime
  ];

  static final String id = '_id';
  static final String isImportant = 'isImportant';
  static final String number = 'number';
  static final String title = 'title';
  static final String content = 'content';
  static final String createdTime = 'createdTime';
}

class Note {
  final int? id;
  final bool isImportant;
  final int number;
  final String title;
  final String content;
  final DateTime createdTime;

  const Note({
    this.id,
    this.isImportant = false,
    this.number = 0,
    required this.title,
    required this.content,
    required this.createdTime,
  });

  Note copyWith({
    int? id,
    bool? isImportant,
    int? number,
    String? title,
    String? content,
    DateTime? createdTime,
  }) =>
      Note(
        id: id ?? this.id,
        isImportant: isImportant ?? this.isImportant,
        number: number ?? this.number,
        title: title ?? this.title,
        content: content ?? this.content,
        createdTime: createdTime ?? this.createdTime,
      );

  static Note fromJson(Map<String, Object?> json) => Note(
        id: json[NoteFields.id] as int?,
        isImportant: json[NoteFields.isImportant] == 1,
        number: json[NoteFields.number] as int,
        title: json[NoteFields.title] as String,
        content: json[NoteFields.content] as String,
        createdTime: DateTime.parse(json[NoteFields.createdTime] as String),
      );

  Map<String, Object?> toJson() => {
        NoteFields.id: id,
        NoteFields.isImportant: isImportant ? 1 : 0,
        NoteFields.number: number,
        NoteFields.title: title,
        NoteFields.content: content,
        NoteFields.createdTime: createdTime.toIso8601String(),
      };
}

