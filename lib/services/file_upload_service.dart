import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

class FileUploadService {
  static Future<String> extractTextFromDocx(String filePath) async {
    try {
      // DOCX dosyasını oku
      final bytes = await File(filePath).readAsBytes();
      // ZIP olarak aç
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // word/document.xml dosyasını bul
      final documentFile = archive.findFile('word/document.xml');
      if (documentFile == null) {
        return 'DOCX dosyası geçerli değil.';
      }

      // XML içeriğini çıkar
      final content = utf8.decode(documentFile.content);
      
      // XML etiketlerini temizle
      final text = content
          .replaceAll(RegExp(r'<[^>]*>'), '') // XML etiketlerini kaldır
          .replaceAll('&amp;', '&')  // HTML karakterlerini düzelt
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'")
          .replaceAll(RegExp(r'\s+'), ' ') // Fazla boşlukları temizle
          .trim();

      return text;
    } catch (e) {
      return 'Dosya okunurken bir hata oluştu: $e';
    }
  }

  static Future<String> extractTextFromPptx(String filePath) async {
    try {
      // PPTX dosyasını oku
      final bytes = await File(filePath).readAsBytes();
      // ZIP olarak aç
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final List<String> slideTexts = [];
      
      // Tüm slaytları bul ve işle
      for (final file in archive.files) {
        if (file.name.startsWith('ppt/slides/slide') && file.name.endsWith('.xml')) {
          // XML içeriğini çıkar
          final content = utf8.decode(file.content);
          
          // Metin içeren XML etiketlerini bul ve işle
          final text = content
              .replaceAll(RegExp(r'<[^>]*>'), '') // XML etiketlerini kaldır
              .replaceAll('&amp;', '&')  // HTML karakterlerini düzelt
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&apos;', "'")
              .replaceAll(RegExp(r'\s+'), ' ') // Fazla boşlukları temizle
              .trim();
          
          if (text.isNotEmpty) {
            slideTexts.add(text);
          }
        }
      }

      if (slideTexts.isEmpty) {
        return 'PPTX dosyasında metin bulunamadı.';
      }

      // Tüm slaytlardaki metinleri birleştir
      return slideTexts.join('\n\n--- Yeni Slayt ---\n\n');
    } catch (e) {
      return 'Dosya okunurken bir hata oluştu: $e';
    }
  }
}

