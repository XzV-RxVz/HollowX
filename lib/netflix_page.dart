import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class NetflixPage extends StatefulWidget {
  const NetflixPage({super.key});

  @override
  State<NetflixPage> createState() => _NetflixPageState();
}

class _NetflixPageState extends State<NetflixPage> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String _errorMessage = "";
  bool _hasError = false;

  static const Color _netflixRed = Color(0xFFE50914);
  static const Color _bgDark = Color(0xFF0A0A0A);
  static const Color _textDim = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    setState(() {
      _hasError = false;
      _errorMessage = "";
      _isLoading = true;
      _loadingProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: BoxDecoration(
            color: _bgDark,
            border: Border(
              bottom: BorderSide(
                color: _netflixRed.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildHeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '[ ',
                    style: TextStyle(
                      color: _netflixRed,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                    ),
                  ),
                  const Text(
                    'NETFLIX',
                    style: TextStyle(
                      color: _netflixRed,
                      fontFamily: 'Orbitron',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: _netflixRed,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    ' ]',
                    style: TextStyle(
                      color: _netflixRed,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: _loadingProgress > 0
                            ? _loadingProgress / 100.0
                            : null,
                        color: _netflixRed,
                        strokeWidth: 2,
                      ),
                    ),
                  const SizedBox(width: 8),
                  _buildHeaderButton(
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      _webViewController?.reload();
                      _initWebView();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_hasError)
            _buildErrorView()
          else
            _buildWebView(),
          if (_isLoading && !_hasError)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress > 0 ? _loadingProgress / 100.0 : null,
                backgroundColor: Colors.transparent,
                color: _netflixRed,
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _netflixRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _netflixRed.withOpacity(0.25),
          ),
        ),
        child: Icon(
          icon,
          color: _netflixRed,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('https://www.netflix.com/browse'),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        useHybridComposition: true,
        databaseEnabled: true,
        domStorageEnabled: true,
        supportZoom: false,
        useShouldOverrideUrlLoading: true,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
        userAgent:
            'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _hasError = false;
            _errorMessage = "";
          });
        }
      },
      onProgressChanged: (controller, progress) {
        if (mounted) {
          setState(() {
            _loadingProgress = progress.toDouble();
          });
        }
      },
      onLoadStop: (controller, url) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      onReceivedError: (controller, request, error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = "Gagal memuat halaman\n${error.description}";
          });
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        final code = errorResponse.statusCode;
        if (code != null && code >= 400) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage =
                  "HTTP Error $code\n${errorResponse.reasonPhrase ?? 'Unknown error'}";
            });
          }
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
          debugPrint(
            "Netflix Console: ${consoleMessage.message}",
          );
        }
      },
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: _bgDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _netflixRed.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _netflixRed.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.movie_filter_outlined,
                  color: _netflixRed,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "NETFLIX",
                style: TextStyle(
                  color: _netflixRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : "Terjadi kesalahan saat memuat halaman",
                style: const TextStyle(
                  color: _textDim,
                  fontSize: 10,
                  fontFamily: 'Orbitron',
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRetryButton(
                    label: "RETRY",
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      _webViewController?.reload();
                      _initWebView();
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildRetryButton(
                    label: "BACK",
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _netflixRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _netflixRed.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _netflixRed, size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _netflixRed,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}