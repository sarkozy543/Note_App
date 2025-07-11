// lib/pages/web_scraper_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:note_app/pages/note_add_to_existing_page.dart';

class WebScraperPage extends StatefulWidget {
  const WebScraperPage({super.key});

  @override
  State<WebScraperPage> createState() => _WebScraperPageState();
}

class _WebScraperPageState extends State<WebScraperPage> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  String _selectedText = ''; // Seçilen metni tutacak değişken
  String _currentUrl = ''; // Mevcut URL'yi tutacak değişken

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress: $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            _urlController.text = url;
            if (mounted) {
              setState(() {
                _selectedText = '';
                _currentUrl = url; // Sayfa başladığında URL'yi kaydet
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            _injectSelectionHandler();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
            Page resource error:
              Code: ${error.errorCode}
              Description: ${error.description}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'SelectionChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (mounted) {
            setState(() {
              _selectedText = message.message;
              debugPrint('Selected Text: $_selectedText');
            });
          }
        },
      )
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  Future<void> _injectSelectionHandler() async {
    await _controller.runJavaScript('''
      (function() {
        document.addEventListener('selectionchange', function() {
          var selection = window.getSelection();
          if (selection && selection.toString().length > 0) {
            SelectionChannel.postMessage(selection.toString());
          }
        });
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web\'den Not Al'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'URL girin...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onSubmitted: (url) {
                      if (url.startsWith('http://') || url.startsWith('https://')) {
                        _controller.loadRequest(Uri.parse(url));
                      } else {
                        _controller.loadRequest(Uri.parse('https://$url'));
                      }
                      if (mounted) {
                        setState(() {
                          _selectedText = '';
                          _currentUrl = url; // Yeni URL submit edildiğinde de kaydet
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _controller.reload(),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      _controller.goBack();
                      if (mounted) {
                        setState(() {
                          _selectedText = '';
                          // Geri gidildiğinde URL'nin güncellenmesi gerektiği için
                          // WebViewController'dan current URL'i tekrar çekebiliriz.
                          // Ancak bu, sayfa yüklendikten sonra 'onPageStarted' ile zaten yapılıyor.
                          // Bu nedenle burada ek bir işlem yapmaya gerek yok.
                        });
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () async {
                    if (await _controller.canGoForward()) {
                      _controller.goForward();
                      if (mounted) {
                        setState(() {
                          _selectedText = '';
                          // Geri gidildiğinde URL'nin güncellenmesi gerektiği için
                          // WebViewController'dan current URL'i tekrar çekabiliriz.
                          // Ancak bu, sayfa yüklendikten sonra 'onPageStarted' ile zaten yapılıyor.
                          // Bu nedenle burada ek bir işlem yapmaya gerek yok.
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          if (_selectedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seçilen Metin: "${_selectedText.length > 50 ? _selectedText.substring(0, 50) + '...' : _selectedText}"',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.note_add, color: Colors.black),
                    label: const Text('Nota Ekle', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      if (_selectedText.isNotEmpty && mounted) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => NoteAddToExistingPage(
                              selectedText: _selectedText,
                              sourceUrl: _currentUrl, // URL'yi buraya aktarıyoruz!
                            ),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() {
                              _selectedText = '';
                            });
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _selectedText = '';
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}