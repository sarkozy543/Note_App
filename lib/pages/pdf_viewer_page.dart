import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:note_app/pages/note_add_to_existing_page.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final String fileName;

  const PdfViewerPage({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  String _selectedText = '';
  bool _isTextSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            icon: Icon(
              _isTextSelectionMode ? Icons.text_fields : Icons.text_format,
              color: _isTextSelectionMode ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _isTextSelectionMode = !_isTextSelectionMode;
                if (!_isTextSelectionMode) {
                  _selectedText = '';
                }
              });
            },
            tooltip: 'Metin Seçme Modunu Aç/Kapat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SfPdfViewer.file(
              File(widget.filePath),
              key: _pdfViewerKey,
              enableTextSelection: _isTextSelectionMode,
              onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                setState(() {
                  _selectedText = details.selectedText ?? '';
                });
              },
            ),
          ),
          if (_selectedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seçilen Metin:',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // <-- Rengi siyah yaptık
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedText,
                    style: const TextStyle(color: Colors.black, fontSize: 16), // <-- Rengi siyah yaptık
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => NoteAddToExistingPage(
                            selectedText: _selectedText,
                            sourceUrl: 'file://${widget.fileName}',
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.black, // <-- Rengi siyah yaptık
                    ),
                    child: const Text('Seçili Metni Nota Ekle', style: TextStyle(color: Colors.black)), // <-- Rengi siyah yaptık
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}