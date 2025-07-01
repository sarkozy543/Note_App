import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:note_app/pages/note_add_to_existing_page.dart';
import 'package:note_app/pages/pdf_viewer_page.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:archive/archive.dart';
import 'package:note_app/services/file_upload_service.dart';
import 'dart:io';
import 'dart:convert';

class FileTextExtractorPage extends StatefulWidget {
  const FileTextExtractorPage({super.key});

  @override
  State<FileTextExtractorPage> createState() => _FileTextExtractorPageState();
}

class _FileTextExtractorPageState extends State<FileTextExtractorPage> {
  String _extractedText = '';
  String _selectedText = '';
  String _fileName = 'Dosya Seçilmedi';
  bool _isLoading = false;
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickAndExtractFile() async {
    setState(() {
      _isLoading = true;
      _extractedText = '';
      _selectedText = '';
      _fileName = 'Dosya Seçiliyor...';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'pptx', 'pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        PlatformFile file = result.files.single;
        String? filePath = file.path;
        
        if (filePath != null) {
          final extension = file.extension?.toLowerCase();
          _fileName = file.name;
          
          print('Seçilen dosya bilgileri:');
          print('Ad: ${file.name}');
          print('Yol: $filePath');
          print('Uzantı: $extension');
          
          // PDF dosyaları için özel görüntüleyici
          if (extension == 'pdf') {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PdfViewerPage(
                    filePath: filePath,
                    fileName: file.name,
                  ),
                ),
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
          }
          
          // Diğer dosya türleri için metin çıkarma
          String extractedContent;
          if (extension == 'docx') {
            extractedContent = await FileUploadService.extractTextFromDocx(filePath);
          } else if (extension == 'pptx') {
            extractedContent = await FileUploadService.extractTextFromPptx(filePath);
          } else if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
            extractedContent = await _extractTextFromFile(filePath, file.extension!);
          } else {
            extractedContent = 'Desteklenmeyen dosya türü';
          }
          setState(() {
            _extractedText = extractedContent;
          });
        }
      } else {
        setState(() {
          _fileName = 'Dosya Seçilmedi';
          _extractedText = 'Dosya seçimi iptal edildi.';
        });
      }
    } catch (e) {
      debugPrint('Dosya seçme veya metin çıkarma hatası: $e');
      setState(() {
        _extractedText = 'Bir hata oluştu: $e';
        _fileName = 'Hata!';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _extractTextFromDocx(String filePath) async {
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
      
      // Basit bir şekilde XML etiketlerini temizle
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
      debugPrint('DOCX metin çıkarırken hata: $e');
      return 'DOCX metin çıkarılırken bir hata oluştu: ${e.toString()}';
    }
  }

  Future<String> _extractTextFromPptx(String filePath) async {
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
      debugPrint('PPTX metin çıkarırken hata: $e');
      return 'PPTX metin çıkarılırken bir hata oluştu: ${e.toString()}';
    }
  }

  Future<String> _extractTextFromFile(String filePath, String fileExtension) async {
    try {
      final inputImage = InputImage.fromFile(File(filePath));
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('${fileExtension.toUpperCase()} metin çıkarırken hata: $e');
      return '${fileExtension.toUpperCase()} metin çıkarılırken bir hata oluştu: ${e.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosyadan Not Al'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            // Üst bilgi kartı
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Desteklenen Dosya Türleri:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFileTypeChip('PDF', Icons.picture_as_pdf),
                        _buildFileTypeChip('DOCX', Icons.description),
                        _buildFileTypeChip('PPTX', Icons.slideshow),
                        _buildFileTypeChip('JPG', Icons.image),
                        _buildFileTypeChip('PNG', Icons.image),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Dosya seçme butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _pickAndExtractFile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.file_upload,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLoading ? 'İşleniyor...' : 'Dosya Seç',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Seçilen dosya adı
            if (_fileName != 'Dosya Seçilmedi')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.file_present),
                    title: Text(
                      'Seçilen Dosya:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(_fileName),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Çıkarılan metin
            if (_extractedText.isNotEmpty)
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.text_fields,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Metinden İstediğiniz Kısmı Seçin:',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _extractedText,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.5,
                              ),
                              onSelectionChanged: (selection, cause) {
                                if (selection != null) {
                                  setState(() {
                                    _selectedText = selection.textInside(_extractedText);
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Seçilen metin ve not ekleme butonu
            if (_selectedText.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Seçilen Metin:',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedText,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => NoteAddToExistingPage(
                                selectedText: _selectedText,
                                sourceUrl: 'file://$_fileName',
                              ),
                            ),
                          ).then((_) {
                            if (mounted) {
                              setState(() {
                                _selectedText = '';
                              });
                            }
                          });
                        },
                        icon: const Icon(Icons.note_add),
                        label: const Text('Seçili Metni Nota Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypeChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
    );
  }
} 