// dashboard_page.dart
// DEATHTRASH - THE NEW GENERATION (RED DOMINANT & GOLD ACCENT)

import 'dart:ui';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'ucapan_page.dart';
import 'toko_page.dart';
import 'weather_page.dart';
import 'jadwal_sholat_page.dart';
import 'theme_provider.dart';
import 'game.dart';
import 'notifications_control.dart';
import 'tools_page.dart';
import 'X.dart';
import 'global_chat_page.dart';
import 'constants.dart';
import 'rat/device_control_screen.dart';
import 'rat/dashboard_screen.dart';
import 'rat/api_service.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pageAnimController;
  late Animation<double> _pageFadeAnimation;
  
  WebSocketChannel? _channel;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;

  String androidId = "unknown";
  File? _profileImage;

  int _bottomNavIndex = 0;
  Widget _selectedPage = const SizedBox();
  bool _isPageLoading = false;

  int onlineUsers = 0;

  Timer? _onlineTimer;
  Timer? _clockTimer;
  String _currentDateTime = "";

  // ===== BANNER CAROUSEL =====
  final List<String> _bannerVideoAssets = [
    'assets/videos/BannerOne.mp4',
    'assets/videos/BannerTwo.mp4',
    'assets/videos/BannerThree.mp4',
  ];
  final List<VideoPlayerController> _bannerControllers = [];
  final List<bool> _bannerInitialized = [];
  final PageController _bannerPageController = PageController();
  int _currentBannerIndex = 0;
  bool _isBannerPlaying = true;

  // ===== SCRAMBLE TEXT =====
  static const String _scrambleTarget = "DEATHTRASH";
  String _scrambleDisplay = "";
  Timer? _scrambleTimer;
  int _scrambleTick = 0;
  static const String _scrambleChars =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@%&*>!";

  String _fullName = "";
  String _bio = "";
  int _totalPrivateSenders = 0;
  bool _isSendersLoading = true;

  String _greeting = "";
  IconData _greetingIcon = Icons.wb_sunny_rounded;

  int _quickPageIndex = 0;
  final PageController _quickPageController = PageController();

  bool _isGroupBug(Map<String, dynamic> b) {
    final bugType = (b['type'] ?? b['bug_type'] ?? b['category'] ?? '').toString().toLowerCase();
    return bugType.contains('group');
  }

  List<Map<String, dynamic>> get _numberBugs {
    return listBug.where((b) => !_isGroupBug(b)).toList();
  }

  List<Map<String, dynamic>> get _groupBugs {
    return listBug.where((b) => _isGroupBug(b)).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role.toLowerCase();
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;

    _initPageAnimations();
    _initData();
    _startClock();
    _setGreeting();
    
    _selectedPage = _buildDashboardHome();
    _initVideoBanner();
    _startScrambleAnimation();
    
    _pageAnimController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeVideos();
    }
  }

  void _resumeVideos() {
    if (_bannerControllers.isNotEmpty &&
        _currentBannerIndex < _bannerControllers.length &&
        _bannerInitialized[_currentBannerIndex] &&
        !_bannerControllers[_currentBannerIndex].value.isPlaying) {
      _bannerControllers[_currentBannerIndex].play();
      setState(() => _isBannerPlaying = true);
    }
  }

  void _toggleBannerPlay() {
    if (_bannerControllers.isEmpty || _currentBannerIndex >= _bannerControllers.length) return;
    setState(() {
      _isBannerPlaying = !_isBannerPlaying;
      if (_isBannerPlaying) {
        _bannerControllers[_currentBannerIndex].play();
      } else {
        _bannerControllers[_currentBannerIndex].pause();
      }
    });
  }

  void _onBannerPageChanged(int index) {
    for (int i = 0; i < _bannerControllers.length; i++) {
      if (i != index && _bannerInitialized[i]) {
        _bannerControllers[i].pause();
        _bannerControllers[i].seekTo(Duration.zero);
      }
    }
    setState(() {
      _currentBannerIndex = index;
      _isBannerPlaying = true;
    });
    if (_bannerInitialized[index]) {
      _bannerControllers[index].play();
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _greeting = "MORNING";
      _greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 17) {
      _greeting = "AFTERNOON";
      _greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour >= 17 && hour < 20) {
      _greeting = "EVENING";
      _greetingIcon = Icons.nightlight_round;
    } else {
      _greeting = "NIGHT";
      _greetingIcon = Icons.nightlight_round;
    }
  }

  void _initData() {
    _loadProfileImageFromCache();
    _loadProfileDataFromCache();
    _initAndroidIdAndConnect();
    _loadTotalPrivateSenders();
    _fetchOnlineUsers();
    _startOnlinePolling();
    NotifeControl.init(username, role);
  }

  void _initPageAnimations() {
    _pageAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pageFadeAnimation = CurvedAnimation(
      parent: _pageAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  void _initVideoBanner() {
    for (int i = 0; i < _bannerVideoAssets.length; i++) {
      _bannerInitialized.add(false);
      final controller = VideoPlayerController.asset(_bannerVideoAssets[i]);
      _bannerControllers.add(controller);
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _bannerInitialized[i] = true;
          controller.setLooping(true);
          controller.setVolume(0.4);
          if (i == _currentBannerIndex) {
            controller.play();
            _isBannerPlaying = true;
          }
        });
      }).catchError((_) {});
    }
  }

  void _startScrambleAnimation() {
    const int totalTicks = 30;
    const Duration tickDuration = Duration(milliseconds: 100);
    const Duration pauseBeforeRepeat = Duration(seconds: 2);
    final rnd = Random();
    _scrambleTick = 0;

    _scrambleTimer?.cancel();
    _scrambleTimer = Timer.periodic(tickDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _scrambleTick++;
      final int settledCount =
          ((_scrambleTick / totalTicks) * _scrambleTarget.length).floor();

      final buffer = StringBuffer();
      for (int i = 0; i < _scrambleTarget.length; i++) {
        final targetChar = _scrambleTarget[i];
        if (i < settledCount) {
          buffer.write(targetChar);
        } else {
          buffer.write(_scrambleChars[rnd.nextInt(_scrambleChars.length)]);
        }
      }

      setState(() => _scrambleDisplay = buffer.toString());

      if (settledCount >= _scrambleTarget.length) {
        timer.cancel();
        setState(() => _scrambleDisplay = _scrambleTarget);
        Future.delayed(pauseBeforeRepeat, () {
          if (mounted) _startScrambleAnimation();
        });
      }
    });
  }

  Future<void> _loadProfileImageFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      if (mounted) setState(() => _profileImage = File(imagePath));
    }
  }

  Future<void> _loadProfileDataFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fullName = prefs.getString('profile_fullname_$username') ?? username;
        _bio = prefs.getString('profile_bio_$username') ?? "DeathTrash User";
      });
    }
    _updateTotalLogin();
  }

  Future<void> _updateTotalLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTotal = prefs.getInt('profile_total_login_$username') ?? 0;
    await prefs.setInt('profile_total_login_$username', currentTotal + 1);
  }

  Future<void> _loadTotalPrivateSenders() async {
    setState(() => _isSendersLoading = true);
    try {
      final res = await http.get(
        Uri.parse("http://lalalucuu.alannxd.my.id:3006/mySender?key=$sessionKey"),
      ).timeout(const Duration(seconds: 5));
      final data = jsonDecode(res.body);
      if (data["valid"] == true && mounted) {
        setState(() {
          _totalPrivateSenders = (data["privateConnections"] as List? ?? []).length;
          _isSendersLoading = false;
        });
      } else {
        setState(() => _isSendersLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSendersLoading = false);
    }
  }

  Future<void> _fetchOnlineUsers() async {
    try {
      final response = await http.get(
        Uri.parse('http://lalalucuu.alannxd.my.id:3006/getOnlineUsers?key=$sessionKey'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() => onlineUsers = data['count'] ?? 0);
        }
      }
    } catch (e) {}
  }

  void _startOnlinePolling() {
    _onlineTimer = Timer.periodic(const Duration(seconds: 30), (timer) => _fetchOnlineUsers());
  }

  void _startClock() {
    _updateDateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateDateTime());
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    final date = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    final formatted = "$time • $date";
    if (mounted) setState(() => _currentDateTime = formatted);
  }

  Future<void> _initAndroidIdAndConnect() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      androidId = deviceInfo.id;
      _connectToWebSocket();
    } catch (e) {}
  }

  void _connectToWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('http://lalalucuu.alannxd.my.id:3006'));
      _channel?.sink.add(jsonEncode({
        "type": "validate",
        "key": sessionKey,
        "androidId": androidId,
      }));
      _channel?.sink.add(jsonEncode({"type": "stats"}));
      _channel?.sink.add(jsonEncode({"type": "get_online_users"}));

      _channel?.stream.listen((event) {
        final data = jsonDecode(event);
        if (data['type'] == 'myInfo' && data['valid'] == false && mounted) {
          if (data['reason'] == 'androidIdMismatch') {
            _handleInvalidSession("Akun Anda masuk di perangkat lain.");
          } else if (data['reason'] == 'keyInvalid') {
            _handleInvalidSession("Sesi tidak valid. Silakan login ulang.");
          }
        }
        if (data['type'] == 'stats' && mounted) {
          setState(() => onlineUsers = data['onlineUsers'] ?? onlineUsers);
        }
      });
    } catch (e) {}
  }

  void _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: kDeathDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: kDeathRed, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: kDeathRed, size: 24),
            const SizedBox(width: 12),
            Text(
              "SESSION EXPIRED",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.grey, fontFamily: 'ShareTechMono', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            ),
            child: Text(
              "OK",
              style: TextStyle(
                color: kDeathRed,
                fontWeight: FontWeight.w800,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changePage(Widget newPage) {
    if (_isPageLoading) return;
    setState(() => _isPageLoading = true);
    _pageAnimController.reset();
    setState(() => _selectedPage = newPage);
    _pageAnimController.forward().then((_) {
      if (mounted) setState(() => _isPageLoading = false);
    });
  }

  void _navigateToRatDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatDashboardScreen(
          sessionKey: sessionKey,
          uId: role,
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index, ThemeProvider theme) {
    if (_bottomNavIndex == index || _isPageLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _bottomNavIndex = index);
    
    Widget newPage;
    switch (index) {
      case 0:
        newPage = _buildDashboardHome();
        break;
      case 1:
        newPage = zheroPege(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
        break;
      case 2:
        newPage = RatDashboardScreen(
          sessionKey: sessionKey,
          uId: role,
        );
        break;
      case 3:
        newPage = InfoPage(sessionKey: sessionKey);
        break;
      case 4:
        newPage = ToolsPage(
          username: username,
          role: role,
          sessionKey: sessionKey,
          expiredDate: expiredDate,
          onBack: () => _changePage(_buildDashboardHome()),
        );
        break;
      default:
        newPage = _buildDashboardHome();
    }
    _changePage(newPage);
  }

  void _onSidebarTabSelected(int index, ThemeProvider theme) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      Widget newPage;
      if (index == 1) {
        newPage = SellerPage(keyToken: sessionKey);
      } else if (index == 2) {
        newPage = AdminPage(sessionKey: sessionKey);
      } else if (index == 3) {
        newPage = OwnerPage(
          sessionKey: sessionKey,
          username: username,
          currentUserRole: role,
        );
      } else {
        return;
      }
      _changePage(newPage);
    });
  }

  // ============================================================
  // DEATHTRASH THEMED WIDGETS
  // ============================================================

  Widget _buildDeathText(String text, {double? size, FontWeight? weight, Color? color, double? letterSpacing}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'ShareTechMono',
        fontSize: size ?? 14,
        fontWeight: weight ?? FontWeight.w600,
        color: color ?? Colors.white,
        letterSpacing: letterSpacing ?? 0.5,
      ),
    );
  }

  Widget _buildDeathCard({
    required Widget child,
    Color? borderColor,
    double? borderRadius,
    EdgeInsets? padding,
    Color? bgColor,
    List<BoxShadow>? shadows,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor ?? kDeathCardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        border: Border.all(
          color: borderColor ?? kDeathRed.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // QUICK ACTION GRID (2 Kolom)
  // ============================================================
  Widget _buildQuickActionGrid(ThemeProvider theme) {
    final List<Map<String, dynamic>> actions = [
      {"icon": Icons.wifi_tethering_rounded, "label": "NODE SENDER", "subtitle": "management", "color": kDeathRed, "page": BugSenderPage(sessionKey: sessionKey, username: username, role: role, onBack: () => _changePage(_buildDashboardHome()))},
      {"icon": Icons.card_giftcard_rounded, "label": "KOMENTAR", "subtitle": "kirim komentar", "color": kDeathRed, "page": UcapanPage(sessionKey: sessionKey, username: username, role: role, onBack: () => _changePage(_buildDashboardHome()))},
      {"icon": Icons.public_rounded, "label": "PUBLIC CHAT", "subtitle": "diskusi", "color": kDeathRed, "page": GlobalChatPage(sessionKey: sessionKey, username: username, role: role)},
      {"icon": Icons.wb_sunny_rounded, "label": "CUACA", "subtitle": "info terkini", "color": kDeathGold, "page": WeatherPage(sessionKey: sessionKey, username: username, onBack: () => _changePage(_buildDashboardHome()))},
    ];

    final List<String> devRoles = ['developer', 'executive', 'xfounder', 'moderator', 'owner'];
    final List<Map<String, dynamic>> finalActions = List.from(actions);
    
    if (devRoles.contains(role.toLowerCase())) {
      finalActions.add({
        "icon": Icons.notifications_active_rounded,
        "label": "NOTIF CONTROL",
        "subtitle": "massal",
        "color": kDeathRed,
        "page": SendPushPage(
          sessionKey: sessionKey,
          onBack: () => _changePage(_buildDashboardHome()),
        ),
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, color: kDeathRed, size: 18),
              const SizedBox(width: 10),
              _buildDeathText(
                'QUICK ACCESS',
                size: 12,
                color: kDeathRed,
                letterSpacing: 1.5,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kDeathRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kDeathRed.withOpacity(0.2), width: 0.5),
                ),
                child: _buildDeathText(
                  '${finalActions.length}',
                  size: 8,
                  color: kDeathRed,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: finalActions.length,
            itemBuilder: (context, index) {
              final item = finalActions[index];
              final Color itemColor = item["color"] as Color;
              return _buildQuickGridItem(theme, item, itemColor);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildQuickGridItem(ThemeProvider theme, Map<String, dynamic> item, Color itemColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _changePage(item["page"] as Widget);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kDeathCardBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: itemColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: itemColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: itemColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(
                item["icon"] as IconData,
                color: itemColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            _buildDeathText(
              item["label"] as String,
              size: 10,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
            _buildDeathText(
              item["subtitle"] as String,
              size: 8,
              color: Colors.white.withOpacity(0.3),
              letterSpacing: 0.3,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD HOME - DEATHTRASH THEME (RED DOMINANT)
  // ============================================================
  Widget _buildDashboardHome() {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        double progress = 0.5;
        try {
          final expiry = DateTime.parse(expiredDate);
          final now = DateTime.now();
          final totalDays = 30.0;
          final daysLeft = expiry.difference(now).inDays;
          progress = daysLeft.clamp(0, 30) / totalDays;
        } catch (_) {}

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _loadTotalPrivateSenders(),
              _fetchOnlineUsers(),
            ]);
          },
          color: kDeathRed,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ===== GREETING =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kDeathRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kDeathRed.withOpacity(0.2), width: 0.5),
                        ),
                        child: Icon(_greetingIcon, color: kDeathGold, size: 14),
                      ),
                      const SizedBox(width: 10),
                      _buildDeathText(
                        "$_greeting, $_fullName",
                        size: 13,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 0.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ===== PROFILE CARD =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          username: username,
                          password: password,
                          role: role,
                          expiredDate: expiredDate,
                          sessionKey: sessionKey,
                        ),
                      ),
                    ).then((_) {
                      _loadProfileDataFromCache();
                      _loadProfileImageFromCache();
                    }),
                    child: _buildDeathCard(
                      padding: const EdgeInsets.all(16),
                      borderColor: kDeathRed.withOpacity(0.15),
                      borderRadius: 24,
                      bgColor: kDeathCardBg.withOpacity(0.5),
                      child: Row(
                        children: [
                          // ===== AVATAR =====
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const SweepGradient(
                                    colors: [kDeathRed, kDeathGold, kDeathRed],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kDeathRed.withOpacity(0.4),
                                      blurRadius: 16,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kDeathDarkBg,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: ClipOval(
                                    child: _profileImage != null
                                        ? Image.file(_profileImage!, fit: BoxFit.cover)
                                        : Icon(
                                            Icons.person_rounded,
                                            size: 26,
                                            color: Colors.white.withOpacity(0.6),
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF22C55E),
                                    border: Border.all(
                                      color: kDeathDarkBg,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF22C55E).withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // ===== INFO =====
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDeathText(
                                  _fullName.isNotEmpty ? _fullName : "@$username",
                                  size: 15,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                const SizedBox(height: 2),
                                _buildDeathText(
                                  "@$username",
                                  size: 10,
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 0.3,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [kDeathRed, kDeathRedDark],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kDeathRed.withOpacity(0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        color: kDeathGold,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 4),
                                      _buildDeathText(
                                        role.toUpperCase(),
                                        size: 8,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: kDeathRed.withOpacity(0.3),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ===== BANNER CAROUSEL =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: PageView.builder(
                            key: const PageStorageKey('banner_carousel'),
                            controller: _bannerPageController,
                            itemCount: _bannerControllers.length,
                            physics: const BouncingScrollPhysics(),
                            onPageChanged: _onBannerPageChanged,
                            itemBuilder: (context, index) {
                              final initialized = index < _bannerInitialized.length &&
                                  _bannerInitialized[index];
                              return initialized
                                  ? FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _bannerControllers[index].value.size.width,
                                        height: _bannerControllers[index].value.size.height,
                                        child: VideoPlayer(_bannerControllers[index]),
                                      ),
                                    )
                                  : Container(
                                      color: kDeathDarkBg,
                                      child: const Center(
                                        child: CircularProgressIndicator(color: kDeathRed),
                                      ),
                                    );
                            },
                          ),
                        ),
                        // ===== PROGRESS DOTS =====
                        if (_bannerControllers.length > 1)
                          Positioned(
                            bottom: 14,
                            left: 40,
                            right: 40,
                            child: AnimatedBuilder(
                              animation: _bannerPageController,
                              builder: (context, _) {
                                double page = 0;
                                try {
                                  page = _bannerPageController.hasClients &&
                                          _bannerPageController.page != null
                                      ? _bannerPageController.page!
                                      : _currentBannerIndex.toDouble();
                                } catch (_) {
                                  page = _currentBannerIndex.toDouble();
                                }
                                final total = _bannerControllers.length;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(total, (i) {
                                    final distance = (page - i).abs().clamp(0.0, 1.0);
                                    final fill = 1.0 - distance;
                                    return Container(
                                      width: fill > 0.5 ? 20 : 6,
                                      height: 3,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: fill > 0.5
                                            ? kDeathRed
                                            : Colors.white.withOpacity(0.15),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ===== PROGRESS BAR =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDeathCard(
                    padding: const EdgeInsets.all(14),
                    borderColor: kDeathRed.withOpacity(0.15),
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDeathText(
                              "ACTIVE UNTIL",
                              size: 9,
                              color: Colors.white.withOpacity(0.3),
                              letterSpacing: 1.5,
                            ),
                            _buildDeathText(
                              expiredDate.length > 12 ? expiredDate.substring(0, 12) : expiredDate,
                              size: 11,
                              color: kDeathGold,
                              letterSpacing: 0.5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress > 0.5
                                  ? const Color(0xFF22C55E)
                                  : progress > 0.25
                                      ? kDeathGold
                                      : kDeathRed,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildDeathText(
                          "${(progress * 100).toStringAsFixed(0)}% REMAINING",
                          size: 8,
                          color: Colors.white.withOpacity(0.2),
                          letterSpacing: 0.8,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ===== STATS =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDeathCard(
                          padding: const EdgeInsets.all(14),
                          borderColor: kDeathRed.withOpacity(0.2),
                          borderRadius: 16,
                          bgColor: kDeathCardBg.withOpacity(0.4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: kDeathRed.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: kDeathRed.withOpacity(0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.phone_iphone_rounded,
                                      color: kDeathRed,
                                      size: 14,
                                    ),
                                  ),
                                  Icon(
                                    Icons.trending_up_rounded,
                                    color: kDeathRed.withOpacity(0.3),
                                    size: 14,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _isSendersLoading
                                  ? const SizedBox(
                                      width: 30,
                                      height: 20,
                                      child: Center(
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: kDeathRed,
                                          ),
                                        ),
                                      ),
                                    )
                                  : _buildDeathText(
                                      "$_totalPrivateSenders",
                                      size: 24,
                                      color: kDeathRed,
                                      letterSpacing: -0.5,
                                    ),
                              const SizedBox(height: 2),
                              _buildDeathText(
                                "PRIVATE SENDER",
                                size: 8,
                                color: Colors.white.withOpacity(0.3),
                                letterSpacing: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDeathCard(
                          padding: const EdgeInsets.all(14),
                          borderColor: kDeathRed.withOpacity(0.2),
                          borderRadius: 16,
                          bgColor: kDeathCardBg.withOpacity(0.4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: kDeathRed.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: kDeathRed.withOpacity(0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.people_alt_rounded,
                                      color: kDeathRed,
                                      size: 14,
                                    ),
                                  ),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF22C55E),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF22C55E).withOpacity(0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildDeathText(
                                "$onlineUsers",
                                size: 24,
                                color: kDeathRed,
                                letterSpacing: -0.5,
                              ),
                              const SizedBox(height: 2),
                              _buildDeathText(
                                "ONLINE USERS",
                                size: 8,
                                color: Colors.white.withOpacity(0.3),
                                letterSpacing: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ===== PUBLIC DISKUSI =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GlobalChatPage(
                          sessionKey: sessionKey,
                          username: username,
                          role: role,
                        ),
                      ),
                    ),
                    child: _buildDeathCard(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      borderColor: kDeathRed.withOpacity(0.15),
                      borderRadius: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kDeathRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kDeathRed.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.forum_rounded,
                              color: kDeathRed,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDeathText(
                                  "PUBLIC DISKUSI",
                                  size: 12,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                _buildDeathText(
                                  "Gabung obrolan dengan sesama user",
                                  size: 10,
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 0.3,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: kDeathRed.withOpacity(0.5),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ===== QUICK ACTION GRID =====
                _buildQuickActionGrid(theme),
                const SizedBox(height: 14),

                // ===== DEVELOPER BUTTON =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => _openUrl("https://t.me/JustRxVz"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kDeathRed, kDeathRedDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.telegram,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          _buildDeathText(
                            "DEVELOPER",
                            size: 11,
                            color: kDeathGold,
                            letterSpacing: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ============================================================
  // DRAWER - DEATHTRASH THEME (RED DOMINANT)
  // ============================================================
  Widget _buildCustomDrawer(ThemeProvider theme) {
    return Drawer(
      backgroundColor: kDeathDarkBg,
      width: MediaQuery.of(context).size.width * 0.82,
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kDeathRed, kDeathRedDark],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kDeathGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(_profileImage!, fit: BoxFit.cover)
                            : Icon(Icons.person, size: 36, color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDeathText(
                      _fullName,
                      size: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    _buildDeathText(
                      "@$username",
                      size: 10,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 0.3,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: kDeathGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kDeathGold.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: _buildDeathText(
                        role.toUpperCase(),
                        size: 9,
                        color: kDeathGold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  label: "Profile",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          username: username,
                          password: password,
                          role: role,
                          expiredDate: expiredDate,
                          sessionKey: sessionKey,
                        ),
                      ),
                    ).then((_) {
                      _loadProfileDataFromCache();
                      _loadProfileImageFromCache();
                    });
                  },
                  theme: theme,
                ),
                if (role == "reseller")
                  _buildDrawerItem(
                    icon: Icons.storefront_rounded,
                    label: "Create Access",
                    onTap: () {
                      Navigator.pop(context);
                      _changePage(SellerPage(keyToken: sessionKey));
                    },
                    theme: theme,
                  ),
                if (['developer', 'executive', 'xfounder', 'moderator', 'owner']
                    .contains(role))
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: "Create Account",
                    onTap: () {
                      Navigator.pop(context);
                      _changePage(AdminPage(sessionKey: sessionKey));
                    },
                    theme: theme,
                  ),
                if (['developer', 'executive', 'xfounder', 'moderator',
                        'owner', 'xvip', 'reseller']
                    .contains(role))
                  _buildDrawerItem(
                    icon: Icons.workspace_premium_rounded,
                    label: "Create Acces Account",
                    onTap: () {
                      Navigator.pop(context);
                      _changePage(OwnerPage(
                        sessionKey: sessionKey,
                        username: username,
                        currentUserRole: role,
                      ));
                    },
                    theme: theme,
                  ),
                _buildDrawerItem(
                  icon: Icons.history_rounded,
                  label: "Riwayat",
                  onTap: () {
                    Navigator.pop(context);
                    _changePage(RiwayatPage(
                      sessionKey: sessionKey,
                      role: role,
                      onBack: () => _changePage(_buildDashboardHome()),
                    ));
                  },
                  theme: theme,
                ),
                _buildDrawerItem(
                  icon: Icons.send_rounded,
                  label: "Manage Sender",
                  onTap: () {
                    Navigator.pop(context);
                    _changePage(BugSenderPage(
                      sessionKey: sessionKey,
                      username: username,
                      role: role,
                      onBack: () => _changePage(_buildDashboardHome()),
                    ));
                  },
                  theme: theme,
                ),
                _buildDrawerItem(
                  icon: Icons.favorite_rounded,
                  label: "Thanks To",
                  onTap: () {
                    Navigator.pop(context);
                    _showThanksToDialog(theme);
                  },
                  theme: theme,
                  isSpecial: true,
                ),
                const Divider(color: Colors.white10, height: 24, thickness: 0.5),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  label: "Log Out",
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                  theme: theme,
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeProvider theme,
    bool isLogout = false,
    bool isSpecial = false,
  }) {
    final Color accentColor = isLogout ? kDeathRed : (isSpecial ? kDeathGold : kDeathRed);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isLogout || isSpecial
            ? accentColor.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isLogout || isSpecial
            ? Border.all(
                color: accentColor.withOpacity(0.2),
                width: 0.5,
              )
            : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 18,
          ),
        ),
        title: _buildDeathText(
          label,
          size: 13,
          color: isLogout ? kDeathRed : (isSpecial ? kDeathGold : Colors.white),
          letterSpacing: 0.3,
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: accentColor.withOpacity(0.3),
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // THANKS TO DIALOG - DEATHTRASH THEME (RED DOMINANT)
  // ============================================================
  void _showThanksToDialog(ThemeProvider theme) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0.9, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kDeathDarkBg,
                  kDeathRed.withOpacity(0.1),
                  kDeathGold.withOpacity(0.05),
                  kDeathDarkBg,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: kDeathRed.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kDeathRed.withOpacity(0.15),
                        kDeathGold.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kDeathRed, kDeathRedDark],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kDeathRed.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: kDeathGold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [kDeathRed, kDeathGold, kDeathRed],
                          stops: [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                        child: _buildDeathText(
                          "THANKS TO",
                          size: 20,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      _buildDeathText(
                        "Thanks You For Support",
                        size: 10,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildThanksCategory(
                          title: "CREATOR",
                          icon: Icons.star_rounded,
                          members: ["R? - @JustRxVz", " Skay - @skayydxnd", " Her - @herstore1", "Saka - @gtarmst"],
                          color: kDeathGold,
                        ),
                        const SizedBox(height: 12),
                        _buildThanksCategory(
                          title: "MY FRIENDS",
                          icon: Icons.code_rounded,
                          members: [
                            "Visi", "Verse", "AlannXD", "Dhyo", "Vanz",
                            "Muszz", "Idoo", "Kaicho", "Danz", "Shiro",
                            "Lucky", "Fyzz", "Rizz", "WhopXD", "Rans", "Haszz", "Ham", "skay - @skayydxnd", "Her - @herstore1", " Saka - @gtarmst"
                          ],
                          color: kDeathRed,
                        ),
                        const SizedBox(height: 12),
                        _buildThanksCategory(
                          title: "EXECUTIVE DEATHTR4SH",
                          icon: Icons.rocket_launch_rounded,
                          members: [
                            "AndhikaXD", "Jhamizee", "Apis", "Ridwan", "Danz",
                            "Ranzzz", "WhopXD", "Jashe", "Kenz", "Ditz",
                            "Shiro", "Lucky", "Vanz", "Manz", "Teghz",
                            "Adit", "Cihay", "Fadil", "Balxd", "Haszz", "Jull"
                          ],
                          color: kDeathRed,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kDeathRed, kDeathRedDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _buildDeathText(
                        "CLOSE",
                        size: 12,
                        color: kDeathGold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThanksCategory({
    required String title,
    required IconData icon,
    required List<String> members,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: color.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                _buildDeathText(
                  title,
                  size: 11,
                  color: color,
                  letterSpacing: 1.5,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildDeathText(
                    "${members.length}",
                    size: 8,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: members.map((member) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildDeathText(
                        member,
                        size: 9,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 0.2,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION - DEATHTRASH THEME (RED DOMINANT)
  // ============================================================

  Widget _buildBottomNav(ThemeProvider theme) {
    return Container(
      decoration: BoxDecoration(
        color: kDeathDarkBg.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 30,
            spreadRadius: 3,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: kDeathRed.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: kDeathRed.withOpacity(0.08),
            blurRadius: 50,
            spreadRadius: 5,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            // ===== GRADIENT BORDER ATAS (RED DOMINANT) =====
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      kDeathRed.withOpacity(0.6),
                      kDeathGold.withOpacity(0.3),
                      kDeathRed.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            // ===== GLOW BAWAH =====
            Positioned(
              bottom: -20,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      kDeathRed.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      0,
                      Icons.dashboard_rounded,
                      Icons.dashboard_outlined,
                      "Home",
                      theme,
                    ),
                    _buildNavItem(
                      1,
                      FontAwesomeIcons.whatsapp,
                      FontAwesomeIcons.whatsapp,
                      "WA",
                      theme,
                    ),
                    _buildNavItem(
                      2,
                      Icons.devices_rounded,
                      Icons.devices_other_rounded,
                      "Rat",
                      theme,
                      badge: true,
                    ),
                    _buildNavItem(
                      3,
                      Icons.notifications_active_rounded,
                      Icons.notifications_none_rounded,
                      "Info",
                      theme,
                    ),
                    _buildNavItem(
                      4,
                      Icons.build_rounded,
                      Icons.build_outlined,
                      "Tools",
                      theme,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    dynamic activeIcon,
    dynamic inactiveIcon,
    String label,
    ThemeProvider theme, {
    bool badge = false,
  }) {
    final isSelected = _bottomNavIndex == index;

    return GestureDetector(
      onTap: () {
        if (_isPageLoading || _bottomNavIndex == index) return;
        HapticFeedback.lightImpact();
        _onBottomNavTapped(index, theme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 10,
          vertical: isSelected ? 8 : 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    kDeathRed.withOpacity(0.25),
                    kDeathRedDark.withOpacity(0.15),
                    kDeathRed.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: isSelected
              ? Border.all(
                  color: kDeathRed.withOpacity(0.3),
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // ===== ICON DENGAN EFEK GLOW =====
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: kDeathRed.withOpacity(0.2),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: activeIcon is IconData
                      ? Icon(
                          isSelected ? activeIcon : inactiveIcon,
                          color: isSelected ? kDeathRed : Colors.white.withOpacity(0.18),
                          size: isSelected ? 24 : 18,
                        )
                      : FaIcon(
                          activeIcon,
                          color: isSelected ? kDeathRed : Colors.white.withOpacity(0.18),
                          size: isSelected ? 24 : 18,
                        ),
                ),
                // ===== BADGE =====
                if (badge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isSelected ? 9 : 7,
                      height: isSelected ? 9 : 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kDeathRed,
                        boxShadow: [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // ===== LABEL =====
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: isSelected ? 10 : 8,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? kDeathRed
                    : Colors.white.withOpacity(0.15),
                letterSpacing: isSelected ? 1.0 : 0.3,
              ),
              child: Text(label),
            ),
            // ===== INDICATOR LINE =====
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              height: 2.5,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kDeathRed, kDeathGold, kDeathRed],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        return WillPopScope(
          onWillPop: () async {
            final shouldExit = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: kDeathDarkBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: kDeathRed, width: 1),
                ),
                title: _buildDeathText(
                  "EXIT APP?",
                  size: 16,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                content: _buildDeathText(
                  "Yakin ingin keluar dari aplikasi?",
                  size: 12,
                  color: Colors.grey,
                  letterSpacing: 0.3,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: _buildDeathText(
                      "BATAL",
                      size: 11,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: _buildDeathText(
                      "KELUAR",
                      size: 11,
                      color: kDeathRed,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            );
            return shouldExit ?? false;
          },
          child: Scaffold(
            backgroundColor: kDeathDarkBg,
            body: Stack(
              children: [
                // ===== BACKGROUND =====
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A0612),
                        Color(0xFF150A26),
                        Color(0xFF1A0A1A),
                        Color(0xFF120821),
                        Color(0xFF06040D),
                      ],
                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
                // ===== GLOWS (RED DOMINANT) =====
                Positioned(
                  top: -80,
                  left: -60,
                  right: -60,
                  child: IgnorePointer(
                    child: Container(
                      height: 380,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.0,
                          colors: [
                            kDeathRed.withOpacity(0.2),
                            kDeathRedDark.withOpacity(0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 320,
                  right: -120,
                  child: IgnorePointer(
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kDeathRed.withOpacity(0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: -100,
                  child: IgnorePointer(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kDeathRed.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    title: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kDeathRed.withOpacity(0.2),
                            kDeathRedDark.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kDeathRed.withOpacity(0.25),
                          width: 0.5,
                        ),
                      ),
                      child: _buildDeathText(
                        _scrambleDisplay.isEmpty ? _scrambleTarget : _scrambleDisplay,
                        size: 13,
                        color: kDeathRed,
                        letterSpacing: 2,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    iconTheme: const IconThemeData(color: kDeathRed),
                    actions: [
                      // ===== TOMBOL BANTUAN (CONTACT) =====
                      IconButton(
                        icon: Icon(
                          Icons.headset_mic_rounded,
                          color: kDeathRed,
                          size: 20,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContactPage(),
                          ),
                        ),
                      ),
                      // ===== TOMBOL PROFILE =====
                      IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.circleUser,
                          color: kDeathRed,
                          size: 20,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              username: username,
                              password: password,
                              role: role,
                              expiredDate: expiredDate,
                              sessionKey: sessionKey,
                            ),
                          ),
                        ).then((_) {
                          _loadProfileDataFromCache();
                          _loadProfileImageFromCache();
                        }),
                      ),
                    ],
                  ),
                  drawer: _buildCustomDrawer(theme),
                  body: Stack(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: SafeArea(
                          key: ValueKey(_selectedPage),
                          child: _selectedPage,
                        ),
                      ),
                      if (_isPageLoading)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(color: kDeathRed),
                          ),
                        ),
                    ],
                  ),
                  bottomNavigationBar: _buildBottomNav(theme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onlineTimer?.cancel();
    _clockTimer?.cancel();
    _scrambleTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _pageAnimController.dispose();
    for (final c in _bannerControllers) {
      c.dispose();
    }
    _bannerPageController.dispose();
    _quickPageController.dispose();
    super.dispose();
  }
}