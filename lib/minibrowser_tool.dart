// minibrowser_tool.dart
// SxC ExecX - Tools Section
// Mini Browser dengan URL bar bebas

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'theme_provider.dart';

class MiniBrowserToolPage extends StatefulWidget {
  const MiniBrowserToolPage({super.key});

  @override
  State<MiniBrowserToolPage> createState() => _MiniBrowserToolPageState();
}

class _MiniBrowserToolPageState extends State<MiniBrowserToolPage> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://www.google.com');
  bool _isLoading = true;
  bool _hasError = false;
  int _loadingProgress = 0;
  bool _isEditingUrl = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() {
            _isLoading = true;
            _hasError = false;
            _urlController.text = url;
          }),
          onProgress: (p) => setState(() => _loadingProgress = p),
          onPageFinished: (url) => setState(() {
            _isLoading = false;
            _urlController.text = url;
          }),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              setState(() { _isLoading = false; _hasError = true; });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  void _navigateTo(String input) {
    String url = input.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Kalau ada spasi atau bukan domain, jadikan query Google
      if (url.contains(' ') || !url.contains('.')) {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      } else {
        url = 'https://$url';
      }
    }
    _controller.loadRequest(Uri.parse(url));
    setState(() => _isEditingUrl = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: _buildAppBar(theme),
        body: _hasError ? _buildErrorState(theme) : _buildBody(theme),
      ),
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
            if (mounted) Navigator.pop(context);
          }
        },
      ),
      title: GestureDetector(
        onTap: () => setState(() => _isEditingUrl = true),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: theme.glassPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isEditingUrl ? theme.primaryColor : theme.borderColor,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(Icons.public_rounded, color: theme.textSecondaryColor, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: _isEditingUrl
                    ? TextField(
                        controller: _urlController,
                        autofocus: true,
                        style: TextStyle(color: theme.textPrimaryColor, fontSize: 12),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        onSubmitted: _navigateTo,
                        textInputAction: TextInputAction.go,
                      )
                    : Text(
                        _urlController.text,
                        style: TextStyle(color: theme.textSecondaryColor, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              if (_isEditingUrl)
                GestureDetector(
                  onTap: () {
                    _urlController.clear();
                  },
                  child: Icon(Icons.close_rounded, color: theme.textSecondaryColor, size: 16),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(icon: Icon(Icons.refresh_rounded, color: theme.primaryColor, size: 20), onPressed: () => _controller.reload()),
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
        if (_isLoading && _loadingProgress < 20)
          Container(
            color: theme.backgroundColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [theme.primaryColor, theme.accentColor]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.public_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text('Memuat halaman...', style: TextStyle(color: theme.textPrimaryColor, fontSize: 14, fontWeight: FontWeight.w600)),
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
            Text('Halaman tidak bisa dibuka.\nCek URL atau koneksi internet.', textAlign: TextAlign.center, style: TextStyle(color: theme.textSecondaryColor, fontSize: 13)),
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
