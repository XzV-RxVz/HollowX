import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // ✅ UNTUK CLIPBOARD
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DeviceDashboardPage extends StatefulWidget {
  final String username;

  const DeviceDashboardPage({super.key, required this.username});

  @override
  State<DeviceDashboardPage> createState() => _DeviceDashboardPageState();
}

class _DeviceDashboardPageState extends State<DeviceDashboardPage> with TickerProviderStateMixin {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  Timer? _timer;
  String? _myUid; // ✅ UID PERMANEN USER
  bool _isLoadingUid = false;

  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  // Socket untuk Real-Time
  late IO.Socket _socket;
  
  // Animation Controllers
  late AnimationController _glowController;
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  // GLOWING GREY THEME
  final Color _primaryColor = const Color(0xFF111111);
  final Color _secondaryColor = const Color(0xFF555555);
  final Color _accentColor = const Color(0xFF111111);
  final Color _successColor = const Color(0xFF6EEB83);
  final Color _warningColor = const Color(0xFFFF9F1C);
  final Color _darkBg = const Color(0xFFFFF8E7);
  final Color _darkerBg = const Color(0xFFFFF8E7);
  final Color _surfaceColor = const Color(0xFFFFEFA3);
  final Color _cardColor = const Color(0xFFFFFFFF);
  final Color _glowColor1 = const Color(0xFF111111);
  final Color _glowColor2 = const Color(0xFF555555);
  final Color _glowColor3 = const Color(0xFF333333);
  final Color _goldColor = const Color(0xFFFFD43B);
  final Color _roseColor = const Color(0xFFFF70A6);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
    _loadOrCreateUid(); // ✅ LOAD UID PERMANEN
    _initSocket();
    
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowController.repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotateController.repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  void _initSocket() {
    try {
      _socket = IO.io(
        'http://lalalucuu.alannxd.my.id:3012',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({
              'type': 'admin', 
              'id': 'ADMIN_PANEL_${widget.username}',
              'username': widget.username,
              'operatorUid': _myUid ?? '',
            })
            .enableAutoConnect()
            .build(),
      );

      _socket.onConnect((_) {
        debugPrint("[+] Admin Socket Connected to Dashboard");
        _fetchDevices(); // ✅ FETCH DEVICES SAAT CONNECT
      });

      _socket.on('targets_list', (data) {
        debugPrint('[DASHBOARD] Targets list received: ${data['count']} devices');
        if (mounted && data['targets'] != null) {
          setState(() {
            _devices = List<dynamic>.from(data['targets']);
            _isLoading = false;
          });
        }
      });

      _socket.on('device_registered', (data) {
        debugPrint('[DASHBOARD] Device registered: ${data['deviceId']} (UID: ${data['uid']})');
        if (mounted) {
          _fetchDevices();
        }
      });

      _socket.on('heartbeat_update', (data) {
        debugPrint('[DASHBOARD] Heartbeat update: ${data['uid']}');
        if (mounted) {
          setState(() {
            int index = _devices.indexWhere((d) => 
              d['uid'] == data['uid'] || d['id'] == data['deviceId']
            );
            if (index != -1) {
              _devices[index]['battery'] = data['battery'];
              _devices[index]['status'] = data['status'] ?? 'Online';
              _devices[index]['lastSeen'] = data['lastSeen'] ?? DateTime.now().toIso8601String();
            }
          });
        }
      });

      _socket.on('target_status', (data) {
        debugPrint('[DASHBOARD] Target status: ${data['uid']} = ${data['status']}');
        if (mounted) {
          setState(() {
            int index = _devices.indexWhere((d) => 
              d['uid'] == data['uid'] || d['id'] == data['id']
            );
            if (index != -1) {
              _devices[index]['status'] = data['status'].toString().toLowerCase() == 'online' ? 'Online' : 'Offline';
              if (data['status'].toString().toLowerCase() == 'online') {
                _devices[index]['lastSeen'] = DateTime.now().toIso8601String();
              }
            }
          });
        }
      });

      _socket.on('heartbeat', (data) {
        if (mounted) {
          setState(() {
            int index = _devices.indexWhere((d) => 
              d['uid'] == data['uid'] || d['id'] == data['deviceId']
            );
            if (index != -1) {
              _devices[index]['battery'] = data['battery'];
              _devices[index]['status'] = 'Online';
              _devices[index]['lastSeen'] = DateTime.now().toIso8601String();
            }
          });
        }
      });

      _socket.on('device_info', (data) {
        if (mounted) {
          _fetchDevices();
        }
      });

      _socket.connect();
    } catch (e) {
      debugPrint("Socket error: $e");
    }
  }

  void _initializeVideo() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized = true;
            });
            _videoController.setLooping(true);
            _videoController.play();
            _videoController.setVolume(0);
          }
        }).catchError((error) {
          debugPrint('Video initialization error: $error');
          if (mounted) setState(() => _videoError = true);
        });
    } catch (e) {
      debugPrint('Video controller creation error: $e');
      if (mounted) setState(() => _videoError = true);
    }
  }

  // ✅ FUNGSI LOAD ATAU BUAT UID (PERMANEN)
  Future<void> _loadOrCreateUid() async {
    setState(() => _isLoadingUid = true);
    
    try {
      // Cek apakah UID sudah ada di server
      final response = await http.get(
        Uri.parse("http://lalalucuu.alannxd.my.id:3012/api/get-uid/${widget.username}"),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['uid'] != null) {
          setState(() {
            _myUid = data['uid'];
            _isLoadingUid = false;
          });
          _fetchDevices(); // ✅ FETCH DEVICES SETELAH UID LOAD
          return;
        }
      }
      
      // Jika belum ada, buat UID baru
      await _createNewUid();
    } catch (e) {
      debugPrint("Error loading UID: $e");
      setState(() => _isLoadingUid = false);
    }
  }

  // ✅ FUNGSI BUAT UID BARU DI SERVER
  Future<void> _createNewUid() async {
    try {
      final response = await http.post(
        Uri.parse("http://lalalucuu.alannxd.my.id:3012/api/generate-uid"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _myUid = data['uid'];
            _isLoadingUid = false;
          });
          _fetchDevices(); // ✅ FETCH DEVICES SETELAH UID DIBUAT
        }
      }
    } catch (e) {
      debugPrint("Error creating UID: $e");
      setState(() => _isLoadingUid = false);
    }
  }

  // ✅ FUNGSI SALIN UID
  void _copyUID(String uid) {
    Clipboard.setData(ClipboardData(text: uid));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF111111), size: 18),
            const SizedBox(width: 8),
            const Text(
              'UID DISALIN!',
              style: TextStyle(
                color: Color(0xFF111111),
                fontWeight: FontWeight.w900,
                fontFamily: 'Rajdhani',
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                uid,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF111111).withOpacity(0.7),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6EEB83),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xFF111111), width: 2),
        ),
      ),
    );
  }

  // ✅ WIDGET GENERATE UID SECTION
  Widget _buildUIDGeneratorSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD43B),
        border: Border.all(color: const Color(0xFF111111), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF111111), offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFFFFD43B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "MY UID",
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: "Rajdhani",
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (_myUid != null)
                GestureDetector(
                  onTap: () => _copyUID(_myUid!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF111111), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3)),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, color: Color(0xFFFFD43B), size: 16),
                        SizedBox(width: 4),
                        Text(
                          "SALIN",
                          style: TextStyle(
                            color: Color(0xFFFFD43B),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Rajdhani",
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Tampilkan UID atau loading
          if (_isLoadingUid)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF111111),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_myUid != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Color(0xFF111111), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _myUid!,
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: "monospace",
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _copyUID(_myUid!),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: Color(0xFF4D96FF),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "UID permanen untuk akun ${widget.username}",
                    style: TextStyle(
                      color: Color(0xFF111111).withOpacity(0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Rajdhani",
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Bagikan UID ini ke target untuk mendaftarkan device",
                    style: TextStyle(
                      color: Color(0xFF111111).withOpacity(0.4),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Rajdhani",
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              "UID belum tersedia",
              style: TextStyle(
                color: Color(0xFF111111).withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: "Rajdhani",
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFFFFF8E7)),
        Positioned(
          top: -70,
          right: -40,
          child: Transform.rotate(
            angle: 0.08,
            child: Container(
              width: 240,
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF4D96FF),
                border: Border.all(color: const Color(0xFF111111), width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF111111),
                    offset: Offset(12, 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -35,
          child: Transform.rotate(
            angle: -0.06,
            child: Container(
              width: 210,
              height: 115,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD43B),
                border: Border.all(color: const Color(0xFF111111), width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF111111),
                    offset: Offset(10, 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF111111), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF111111),
            offset: Offset(7, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socket.disconnect();
    _socket.dispose();
    _videoController.dispose();
    _searchController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  // ✅ FETCH DEVICES - FILTER BERDASARKAN UID
  Future<void> _fetchDevices() async {
    try {
      final uri = _myUid != null 
          ? "http://lalalucuu.alannxd.my.id:3012/api/list-targets?username=${widget.username}&uid=$_myUid"
          : "http://lalalucuu.alannxd.my.id:3012/api/list-targets?username=${widget.username}";
      
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        if (mounted) {
          List<dynamic> allDevices = jsonDecode(response.body);
          
          // Filter device yang terdaftar dengan UID user ini
          List<dynamic> myDevices = allDevices.where((device) {
            if (_myUid != null) {
              return device['uid'] == _myUid || device['admin'] == widget.username;
            }
            return device['admin'] == widget.username;
          }).toList();
          
          setState(() {
            _devices = myDevices;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching devices: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredDevices {
    if (_searchQuery.isEmpty) return _devices;
    return _devices.where((d) {
      String searchStr = "${d['model']} ${d['id']} ${d['ip']} ${d['uid']}".toLowerCase();
      return searchStr.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  bool _isDeviceReallyOnline(dynamic device) {
    if (device['status'] == 'Offline') return false;
    if (device['lastSeen'] == null) return false;

    try {
      DateTime lastSeen = DateTime.parse(device['lastSeen'].toString());
      DateTime now = DateTime.now();
      
      if (now.difference(lastSeen).inSeconds > 20) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildNeonHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFD43B),
          border: Border(
            top: BorderSide(color: Color(0xFF111111), width: 4),
            left: BorderSide(color: Color(0xFF111111), width: 4),
            right: BorderSide(color: Color(0xFF111111), width: 4),
            bottom: BorderSide(color: Color(0xFF111111), width: 7),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -18,
              child: Transform.rotate(
                angle: 0.18,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5C5C),
                    border: Border.all(color: const Color(0xFF111111), width: 4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4D96FF),
                      border: Border.fromBorderSide(BorderSide(color: Color(0xFF111111), width: 4)),
                      boxShadow: [
                        BoxShadow(color: Color(0xFF111111), offset: Offset(5, 5)),
                      ],
                    ),
                    child: const Icon(Icons.hub_rounded, color: Color(0xFF111111), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "DEVICE // HQ",
                          style: TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Rajdhani",
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "COMMAND BOARD • ${widget.username.toUpperCase()}",
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            fontFamily: "Rajdhani",
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isLoading = true);
                      _fetchDevices();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFFFF),
                        border: Border.fromBorderSide(BorderSide(color: Color(0xFF111111), width: 3)),
                        boxShadow: [
                          BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4)),
                        ],
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Color(0xFF111111), size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color valueColor) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 86),
        decoration: BoxDecoration(
          color: valueColor == _successColor
              ? const Color(0xFF6EEB83)
              : valueColor == _roseColor
                  ? const Color(0xFFFF5C5C)
                  : const Color(0xFFFFFFFF),
          border: const Border.fromBorderSide(BorderSide(color: Color(0xFF111111), width: 3)),
          boxShadow: const [
            BoxShadow(color: Color(0xFF111111), offset: Offset(5, 5)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 27,
                height: 0.9,
                fontWeight: FontWeight.w900,
                fontFamily: "Rajdhani",
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              color: const Color(0xFF111111),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontFamily: "Rajdhani",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFF111111), width: 3)),
        boxShadow: [
          BoxShadow(color: Color(0xFF111111), offset: Offset(5, 5)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: Color(0xFF111111),
          fontSize: 13,
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w800,
        ),
        decoration: const InputDecoration(
          hintText: "SEARCH DEVICE / IP / ID / UID",
          hintStyle: TextStyle(
            color: Color(0xFF777777),
            fontSize: 11,
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF111111), size: 21),
          suffixIcon: Icon(Icons.tune_rounded, color: Color(0xFFFF5C5C), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(dynamic device, int index) {
    final bool isActive = _isDeviceReallyOnline(device);
    final Color statusColor = isActive ? const Color(0xFF6EEB83) : const Color(0xFFFF5C5C);
    final String model = (device['model'] ?? "UNKNOWN DEVICE").toString();
    final String release = device['release'] != null ? "ANDROID ${device['release']}" : "ANDROID OS";
    final String id = (device['id'] ?? "NO-ID").toString();
    final String uid = (device['uid'] ?? "NO-UID").toString();
    final String battery = device['battery']?.toString() ?? "N/A";

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/control_panel',
          arguments: {
            "device": device,
            "operator": widget.username,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: index.isEven ? const Color(0xFFFFFFFF) : const Color(0xFFFFEFA3),
          border: const Border.fromBorderSide(BorderSide(color: Color(0xFF111111), width: 3)),
          boxShadow: const [
            BoxShadow(color: Color(0xFF111111), offset: Offset(6, 6)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF111111),
              child: Row(
                children: [
                  Text(
                    "#${(index + 1).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      color: Color(0xFFFFD43B),
                      fontFamily: "Rajdhani",
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "UID: $uid",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontFamily: "Rajdhani",
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _copyUID(uid),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD43B),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: const Color(0xFF111111), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, size: 10, color: Color(0xFF111111)),
                          SizedBox(width: 3),
                          Text(
                            "SALIN",
                            style: TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              fontFamily: "Rajdhani",
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    color: statusColor,
                    child: Text(
                      isActive ? "● ONLINE" : "○ OFFLINE",
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontFamily: "Rajdhani",
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: statusColor,
                      border: const Border.fromBorderSide(
                        BorderSide(color: Color(0xFF111111), width: 3),
                      ),
                    ),
                    child: const Icon(
                      Icons.smartphone_rounded,
                      color: Color(0xFF111111),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Rajdhani",
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          release,
                          style: const TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: "Rajdhani",
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          id.length > 24 ? "${id.substring(0, 24)}…" : id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 8,
                            fontFamily: "monospace",
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.battery_charging_full_rounded,
                              color: Color(0xFF111111).withOpacity(0.5),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$battery%",
                              style: const TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                fontFamily: "Rajdhani",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyUID(uid),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD43B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF111111), width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2)),
                        ],
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        color: Color(0xFF111111),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFF111111), size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _glowColor1.withOpacity(0.1), Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 8),
            _buildFooterText("ACTIVE"),
            const SizedBox(width: 20),
            Container(width: 1, height: 10, color: Color(0xFF111111).withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Color(0xFF111111).withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor2),
            const SizedBox(width: 8),
            _buildFooterText("SECURE"),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "VXOR • DEVICE MANAGEMENT",
          style: TextStyle(
            color: Color(0xFF111111).withOpacity(0.1),
            fontSize: 8,
            letterSpacing: 3,
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 5)],
      ),
    );
  }

  Widget _buildFooterText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Color(0xFF111111).withOpacity(0.25),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        fontFamily: 'Rajdhani',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _devices.length;
    final int activeCount = _devices.where((d) => _isDeviceReallyOnline(d)).length;
    final int offlineCount = totalCount - activeCount;
    final filteredList = _filteredDevices;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildNeonHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Row(
                    children: [
                      _buildStatBox("TOTAL", totalCount.toString(), const Color(0xFFFFFFFF)),
                      const SizedBox(width: 10),
                      _buildStatBox("ONLINE", activeCount.toString(), const Color(0xFF6EEB83)),
                      const SizedBox(width: 10),
                      _buildStatBox("OFFLINE", offlineCount.toString(), const Color(0xFFFF5C5C)),
                    ],
                  ),
                ),
                
                // ✅ SECTION UID PERMANEN
                _buildUIDGeneratorSection(),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _buildSearchBar(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: const Color(0xFF111111),
                        child: const Text(
                          "TARGETS",
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontFamily: "Rajdhani",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${filteredList.length} RECORDS",
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          fontFamily: "Rajdhani",
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.drag_indicator_rounded, size: 18, color: Color(0xFF111111)),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF111111),
                            strokeWidth: 4,
                          ),
                        )
                      : filteredList.isEmpty
                          ? Center(
                              child: Container(
                                margin: const EdgeInsets.all(24),
                                padding: const EdgeInsets.all(24),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5C5C),
                                  border: Border.fromBorderSide(
                                    BorderSide(color: Color(0xFF111111), width: 4),
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Color(0xFF111111), offset: Offset(7, 7)),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.devices_other_rounded, size: 42, color: Color(0xFF111111)),
                                    SizedBox(height: 10),
                                    Text(
                                      "NO DEVICES FOUND",
                                      style: TextStyle(
                                        color: Color(0xFF111111),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        fontFamily: "Rajdhani",
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "Bagikan UID Anda ke target untuk mendaftar",
                                      style: TextStyle(
                                        color: Color(0xFF111111),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                        fontFamily: "Rajdhani",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  return _buildDeviceCard(filteredList[index], index);
                                },
                              ),
                            ),
                ),
                _buildFooter(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}