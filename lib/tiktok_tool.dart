// tiktok_tool.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'theme_provider.dart';

class TikTokToolPage extends StatefulWidget {
  final VoidCallback onBack;
  const TikTokToolPage({super.key, required this.onBack});

  @override
  State<TikTokToolPage> createState() => _TikTokToolPageState();
}

class _TikTokToolPageState extends State<TikTokToolPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() { _isLoading = true; _hasError = false; }),
          onProgress: (p) => setState(() => _loadingProgress = p),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              setState(() { _isLoading = false; _hasError = true; });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.tiktok.com'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: _buildAppBar(theme),
      body: _hasError ? _buildErrorState(theme) : _buildBody(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider theme) {
    return AppBar(
      backgroundColor: theme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryColor, size: 20),
        onPressed: () async {
          if (await _controller.canGoBack()) {
            _controller.goBack();
          } else {
            widget.onBack();
          }
        },
      ),
      title: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('🎵', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),
          Text('TikTok', style: TextStyle(color: theme.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      actions: [
        IconButton(icon: Icon(Icons.refresh_rounded, color: theme.primaryColor), onPressed: () => _controller.reload()),
        IconButton(icon: Icon(Icons.home_rounded, color: theme.primaryColor), onPressed: () => _controller.loadRequest(Uri.parse('https://www.tiktok.com'))),
        const SizedBox(width: 4),
      ],
      bottom: _isLoading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: LinearProgressIndicator(
                value: _loadingProgress / 100,
                backgroundColor: theme.glassPrimary,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                minHeight: 3,
              ),
            )
          : null,
    );
  }

  Widget _buildBody(ThemeProvider theme) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading && _loadingProgress < 30)
          Container(
            color: theme.backgroundColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                    ),
                    child: const Center(child: Text('🎵', style: TextStyle(fontSize: 40))),
                  ),
                  const SizedBox(height: 20),
                  Text('Memuat TikTok...', style: TextStyle(color: theme.textPrimaryColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      value: _loadingProgress / 100,
                      backgroundColor: theme.glassPrimary,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$_loadingProgress%', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(ThemeProvider theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: theme.glassPrimary, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.borderColor)),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Gagal Memuat', style: TextStyle(color: theme.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Periksa koneksi internet kamu\nlalu coba lagi.', textAlign: TextAlign.center, style: TextStyle(color: theme.textSecondaryColor, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _controller.reload(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
