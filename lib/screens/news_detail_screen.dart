import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsUrl;
  final String title;

  const NewsDetailScreen({super.key, required this.newsUrl, required this.title});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late final WebViewController _controller;
  bool _isLoading = true; // Sayfa yükleniyor mu?

  @override
  void initState() {
    super.initState();
    
    // WebView Ayarları
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Siteler düzgün çalışsın diye JS açık
      ..setBackgroundColor(const Color(0xFF171A21))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint("Web Hatası: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.newsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171A21),
      appBar: AppBar(
        title: Text(
          widget.title, // Haberin başlığı kısaca üstte yazsın
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF171A21),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Sayfayı Yenileme Butonu
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Web Sitesi
          WebViewWidget(controller: _controller),
          
          // 2. Yükleniyor Göstergesi (Sayfa açılana kadar döner)
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
        ],
      ),
    );
  }
}