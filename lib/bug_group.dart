import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'profile_page.dart';
import 'constants.dart';

// ── Endpoint API ────────────────────────────────────────────────────────────
const String _kGroupListPath = "/api/whatsapp/groupList";
const String baseUrl = "http://lalalucuu.alannxd.my.id:3012";

class GroupBugPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String role;
  final String expiredDate;

  const GroupBugPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<GroupBugPage> createState() => _GroupBugPageState();
}

class _GroupBugPageState extends State<GroupBugPage>
    with TickerProviderStateMixin {
  // ===== CONTROLLER =====
  final linkGroupController = TextEditingController();

  // ===== VIDEO PLAYER =====
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool isVideoInitialized = false;

  // ===== ANIMASI =====
  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ===== STATE DATA =====
  bool _isSending = false;
  bool _linkValid = false;
  int _privateSenderCount = 0;
  bool _senderLoading = true;
  List<dynamic> _privateGroups = [];
  bool _groupsLoading = true;
  Map<String, dynamic>? _selectedGroup;

  // ===== PROFIL DATA =====
  File? _profileImage;
  String _fullName = "";
  String _bio = "";
  String _memberSince = "";
  bool _isProfileRefreshing = false;

  // ===== INIT STATE =====
  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _initAnimations();
    _fetchSenderCounts();
    _fetchPrivateGroups();
    _loadProfileData();
    _loadProfileImage();
    linkGroupController.addListener(() {
      final v = _isValidGroupLink(linkGroupController.text.trim());
      if (v != _linkValid && mounted) setState(() => _linkValid = v);
    });
    _mainController.forward();
    _pulseController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfileIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfileData();
    _loadProfileImage();
  }

  // ===== ANIMASI INIT =====
  void _initAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  // ===== REFRESH PROFIL =====
  Future<void> _refreshProfileIfNeeded() async {
    if (_isProfileRefreshing) return;
    _isProfileRefreshing = true;

    final prefs = await SharedPreferences.getInstance();
    final newFullName = prefs.getString('profile_fullname_${widget.username}') ?? widget.username;
    final newBio = prefs.getString('profile_bio_${widget.username}') ?? "User App";
    final newMemberSince = prefs.getString('profile_member_since_${widget.username}') ?? _formatDateToString(DateTime.now());

    bool hasChanged = false;
    if (newFullName != _fullName) {
      _fullName = newFullName;
      hasChanged = true;
    }
    if (newBio != _bio) {
      _bio = newBio;
      hasChanged = true;
    }
    if (newMemberSince != _memberSince) {
      _memberSince = newMemberSince;
      hasChanged = true;
    }

    final imagePath = prefs.getString('profile_image_${widget.username}');
    File? newImage;
    if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      newImage = File(imagePath);
    }
    if ((newImage != null && _profileImage == null) ||
        (newImage == null && _profileImage != null) ||
        (newImage != null && _profileImage != null && newImage.path != _profileImage!.path)) {
      _profileImage = newImage;
      hasChanged = true;
    }

    if (hasChanged && mounted) {
      setState(() {});
    }

    _isProfileRefreshing = false;
  }

  // ===== VIDEO PLAYER =====
  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4');
    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _videoController.setVolume(0.8);
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: true,
            showControls: false,
            autoInitialize: true,
          );
          isVideoInitialized = true;
        });
      }
    }).catchError((error) {
      debugPrint("Video error: $error");
      if (mounted) setState(() => isVideoInitialized = false);
    });
  }

  // ===== PROFIL DATA =====
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fullName = prefs.getString('profile_fullname_${widget.username}') ?? widget.username;
      _bio = prefs.getString('profile_bio_${widget.username}') ?? "User App";
      _memberSince = prefs.getString('profile_member_since_${widget.username}') ?? _formatDateToString(DateTime.now());
    });
  }

  String _formatDateToString(DateTime date) => "${date.day}/${date.month}/${date.year}";

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${widget.username}');
    if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      if (mounted) setState(() => _profileImage = File(imagePath));
    } else {
      if (mounted) setState(() => _profileImage = null);
    }
  }

  // ===== FETCH DATA =====
  Future<void> _fetchSenderCounts() async {
    if (!mounted) return;
    setState(() => _senderLoading = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}")).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true && mounted) {
          final privList = (data['connections']?['private'] as List?) ?? [];
          setState(() {
            _privateSenderCount = privList.length;
            _senderLoading = false;
          });
        } else if (mounted) setState(() => _senderLoading = false);
      } else if (mounted) setState(() => _senderLoading = false);
    } catch (_) {
      if (mounted) setState(() => _senderLoading = false);
    }
  }

  Future<void> _fetchPrivateGroups() async {
    if (!mounted) return;
    setState(() => _groupsLoading = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl$_kGroupListPath?key=${widget.sessionKey}")).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List parsed = [];
        if (body is List) parsed = body;
        else if (body is Map) {
          if (body['groups'] is List) parsed = body['groups'];
          else if (body['data'] is List) parsed = body['data'];
          else if (body['list'] is List) parsed = body['list'];
        }
        if (mounted) {
          setState(() {
            _privateGroups = parsed;
            _groupsLoading = false;
            if (_selectedGroup != null && !parsed.any((g) => _groupKey(g) == _groupKey(_selectedGroup))) {
              _selectedGroup = null;
            }
          });
        }
      } else if (mounted) setState(() => _privateGroups = []);
    } catch (_) {
      if (mounted) setState(() => _privateGroups = []);
    } finally {
      if (mounted) setState(() => _groupsLoading = false);
    }
  }

  // ===== HELPER GROUP =====
  String _groupKey(dynamic g) {
    if (g == null) return '';
    final id = (g['id'] ?? g['groupId'] ?? '').toString();
    return id.isNotEmpty ? id : (g['inviteLink'] ?? g['link'] ?? g['subject'] ?? '').toString();
  }

  String? _groupInviteLink(dynamic g) {
    if (g == null) return null;
    if (g['inviteLink'] is String && (g['inviteLink'] as String).isNotEmpty) return g['inviteLink'];
    if (g['link'] is String && (g['link'] as String).isNotEmpty) return g['link'];
    if (g['inviteCode'] is String && (g['inviteCode'] as String).isNotEmpty) return "https://chat.whatsapp.com/${g['inviteCode']}";
    return null;
  }

  bool _isValidGroupLink(String input) => RegExp(r'https://chat\.whatsapp\.com/[a-zA-Z0-9]{22}').hasMatch(input);

  // ===== SEND GROUP BUG =====
  Future<void> _sendGroupBug() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    String linkGroup = "";
    if (_selectedGroup != null) {
      final picked = _groupInviteLink(_selectedGroup);
      if (picked != null) linkGroup = picked.trim();
    }
    if (linkGroup.isEmpty) linkGroup = linkGroupController.text.trim();

    if (linkGroup.isEmpty || !_isValidGroupLink(linkGroup)) {
      _showAlert("❌ TARGET INVALID",
          "Pilih salah satu grup pada \"List Group\" atau tempelkan link grup WhatsApp yang valid.\n(https://chat.whatsapp.com/xxxx)");
      setState(() => _isSending = false);
      return;
    }

    try {
      final url = "$baseUrl/api/whatsapp/groupBug?key=${widget.sessionKey}&linkGroup=$linkGroup&senderType=private";
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);
      if (data["valid"] == false) {
        _showAlert("❌ FAILED", data["message"]?.toString() ?? "Gagal mengirim group bug.");
      } else {
        _showSuccessPopup(linkGroup, data is Map<String, dynamic> ? data : {"data": data});
      }
    } catch (_) {
      _showAlert("❌ ERROR", "Terjadi kesalahan. Coba lagi.");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessPopup(String linkGroup, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GroupSuccessDialog(
        linkGroup: linkGroup,
        data: data,
      ),
    );
  }

  // ============================================================
  // ALERT DIALOG - DEATHTRASH THEME (RED & GOLD)
  // ============================================================
  void _showAlert(String title, String msg) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kDeathDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kDeathRed.withOpacity(0.3), width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kDeathRed, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontFamily: 'monospace',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: kDeathRed.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: kDeathRed.withOpacity(0.15)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                "OK",
                style: TextStyle(
                  color: kDeathRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'FontX',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    linkGroupController.dispose();
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isProfileRefreshing) {
        _refreshProfileIfNeeded();
      }
    });

    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
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
                  kDeathDarkBg,
                  Color(0xFF150A26),
                  Color(0xFF1F0F38),
                  Color(0xFF120821),
                  Color(0xFF06040D),
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),

          // ===== GLOW ORBS (RED & GOLD) =====
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
                      kDeathRed.withOpacity(0.15),
                      kDeathRedDark.withOpacity(0.08),
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
                      kDeathGold.withOpacity(0.08),
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
                      kDeathRed.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== GRID =====
          CustomPaint(
            size: Size.infinite,
            painter: _GroupGridPainter(accentColor: kDeathRed),
          ),

          // ===== OVERLAY =====
          Container(color: Colors.black.withOpacity(0.35)),

          // ===== MAIN CONTENT =====
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scaleIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHUD(theme),
                        const SizedBox(height: 14),
                        _buildVideoBanner(theme),
                        const SizedBox(height: 14),
                        _buildStatsRow(theme),
                        const SizedBox(height: 14),
                        _buildInputLinkArea(theme),
                        const SizedBox(height: 14),
                        _buildGroupListBox(theme),
                        const SizedBox(height: 14),
                        _buildLaunchButton(theme),
                        const SizedBox(height: 16),
                        _buildFooter(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE HUD (COMPACT)
  // ============================================================
  Widget _buildProfileHUD(ThemeProvider theme) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              username: widget.username,
              password: widget.password,
              role: widget.role,
              expiredDate: widget.expiredDate,
              sessionKey: widget.sessionKey,
            ),
          ),
        );
        if (result == true || result == null) {
          _refreshProfileIfNeeded();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kDeathCardBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: kDeathBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kDeathRed, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipOval(
                child: _profileImage != null
                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                    : Container(
                        color: kDeathDarkBg,
                        child: Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fullName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: kDeathRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: kDeathRed.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: kDeathRed,
                          size: 7,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.role.toUpperCase(),
                          style: TextStyle(
                            color: kDeathRed,
                            fontSize: 6,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _bio.length > 20 ? '${_bio.substring(0, 20)}...' : _bio,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 8,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.1),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VIDEO BANNER
  // ============================================================
  Widget _buildVideoBanner(ThemeProvider theme) {
    return isVideoInitialized && _chewieController != null
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kDeathRed.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          )
        : Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: kDeathCardBg.withOpacity(0.5),
              border: Border.all(color: kDeathRed.withOpacity(0.08), width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: kDeathRed,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Loading Video...",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  // ============================================================
  // STATS ROW (RED & GOLD THEME) - FIXED
  // ============================================================
  Widget _buildStatsRow(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kDeathBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: FontAwesomeIcons.users,
            iconColor: kDeathRed,
            title: "GROUP MODE",
            subtitle: "Mass Attack",
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.03),
          ),
          _StatItem(
            icon: FontAwesomeIcons.userShield,
            iconColor: kDeathRed,
            title: "PRIVATE SENDER",
            subtitle: _senderLoading ? "Loading..." : "$_privateSenderCount Active",
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.03),
          ),
          _StatItem(
            icon: FontAwesomeIcons.bolt,
            iconColor: kDeathGold,
            title: "GROUP READY",
            subtitle: _privateGroups.isEmpty ? "0 Group" : "${_privateGroups.length} Group",
          ),
        ], // <-- ADDED MISSING CLOSING BRACKET
      ),
    ); // <-- ADDED MISSING CLOSING PARENTHESIS
  }

  // ============================================================
  // INPUT LINK AREA
  // ============================================================
  Widget _buildInputLinkArea(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kDeathBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link_rounded,
                color: kDeathRed,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'TARGET LINK',
                style: TextStyle(
                  color: kDeathRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontFamily: 'FontX',
                ),
              ),
              const Spacer(),
              if (_linkValid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kDeathGreen.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kDeathGreen.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: kDeathGreen, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        "VALID",
                        style: TextStyle(
                          color: kDeathGreen,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kDeathCardBg.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _linkValid ? kDeathGreen.withOpacity(0.15) : kDeathBorder,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 2, 6, 2),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.whatsapp, color: _linkValid ? kDeathGreen : kDeathRed.withOpacity(0.3), size: 14),
                const SizedBox(width: 8),
                Container(width: 1, height: 20, color: Colors.white.withOpacity(0.05)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: linkGroupController,
                    keyboardType: TextInputType.url,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: "https://chat.whatsapp.com/...",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.15),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (linkGroupController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      linkGroupController.clear();
                      setState(() => _linkValid = false);
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.1),
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tempelkan link undangan grup WhatsApp di atas',
            style: TextStyle(
              color: Colors.white.withOpacity(0.12),
              fontSize: 8,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GROUP LIST BOX
  // ============================================================
  Widget _buildGroupListBox(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kDeathBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                color: kDeathRed,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'GROUP LIST',
                style: TextStyle(
                  color: kDeathRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontFamily: 'FontX',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchPrivateGroups,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kDeathRed.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kDeathRed.withOpacity(0.08)),
                  ),
                  child: _groupsLoading
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            color: kDeathRed,
                            strokeWidth: 1.5,
                          ),
                        )
                      : Text(
                          "${_privateGroups.length}",
                          style: TextStyle(
                            color: kDeathRed,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Grup yang sudah dimasuki nomor Sender Private",
            style: TextStyle(
              color: Colors.white.withOpacity(0.12),
              fontSize: 8,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 10),
          if (_groupsLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: kDeathRed,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (_privateGroups.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: kDeathDarkBg.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDeathRed.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, color: Colors.white.withOpacity(0.08), size: 24),
                  const SizedBox(height: 6),
                  Text(
                    "No groups found",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.12),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _privateGroups.map((g) => _GroupCard(
                group: g is Map ? Map<String, dynamic>.from(g) : {},
                selected: _groupKey(g) == _groupKey(_selectedGroup),
                onSelect: () {
                  final mp = (g is Map) ? Map<String, dynamic>.from(g) : <String, dynamic>{};
                  setState(() => _selectedGroup = mp);
                  final lk = _groupInviteLink(mp);
                  if (lk != null && lk.isNotEmpty) {
                    linkGroupController.text = lk;
                    _linkValid = _isValidGroupLink(lk);
                  }
                },
                theme: theme,
              )).toList(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LAUNCH BUTTON
  // ============================================================
  Widget _buildLaunchButton(ThemeProvider theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kDeathRed, kDeathRedDark],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: kDeathRed.withOpacity(0.15 * _pulseController.value),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendGroupBug,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isSending
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "LAUNCH GROUP ATTACK",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================
  Widget _buildFooter(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  kDeathRed.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [kDeathRed, kDeathGold, kDeathRed],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: Text(
              'DEATHTRASH · GROUP EXPLOIT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontFamily: 'FontX',
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '// powered by @JustRxVz',
            style: TextStyle(
              color: Colors.white.withOpacity(0.08),
              fontSize: 7,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAT ITEM
// ============================================================
class _StatItem extends StatelessWidget {
  final FaIconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, color: iconColor, size: 14),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.15),
            fontSize: 6,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 8,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// ============================================================
// GROUP CARD
// ============================================================
class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool selected;
  final VoidCallback onSelect;
  final ThemeProvider theme;

  const _GroupCard({
    required this.group,
    required this.selected,
    required this.onSelect,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final name = (group['subject'] ?? group['name'] ?? group['groupName'] ?? '-').toString();
    final idRaw = (group['id'] ?? group['groupId'] ?? group['inviteCode'] ?? '-').toString();
    final idShort = idRaw.length > 18 ? '${idRaw.substring(0, 14)}...' : idRaw;
    final members = (group['participants'] ?? group['memberCount'] ?? group['participantsCount'] ?? group['members'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kDeathDarkBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? kDeathRed.withOpacity(0.2) : kDeathBorder,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.05),
                  blurRadius: 16,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kDeathRed.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDeathRed.withOpacity(0.08)),
            ),
            child: Icon(
              Icons.group_rounded,
              color: selected ? kDeathRed : Colors.white.withOpacity(0.1),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$members members · #$idShort',
                  style: TextStyle(
                    color: selected ? kDeathRed.withOpacity(0.4) : Colors.white.withOpacity(0.1),
                    fontSize: 7,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSelect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? kDeathRed.withOpacity(0.06) : kDeathRed.withOpacity(0.02),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? kDeathRed.withOpacity(0.15) : kDeathRed.withOpacity(0.04),
                ),
              ),
              child: Text(
                selected ? "SELECTED" : "SELECT",
                style: TextStyle(
                  color: selected ? kDeathRed : Colors.white.withOpacity(0.1),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUCCESS DIALOG - DEATHTRASH THEME (FULL)
// ============================================================
class _GroupSuccessDialog extends StatefulWidget {
  final String linkGroup;
  final Map<String, dynamic> data;

  const _GroupSuccessDialog({
    required this.linkGroup,
    required this.data,
  });

  @override
  State<_GroupSuccessDialog> createState() => _GroupSuccessDialogState();
}

class _GroupSuccessDialogState extends State<_GroupSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.elasticOut,
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final groupInfo = widget.data["groupInfo"];
    final success = widget.data["success"] == true;
    final canSend = widget.data["canSendMessage"] == true;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kDeathDarkBg.withOpacity(0.95),
                    kDeathCardBg.withOpacity(0.8),
                    kDeathDarkBg.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: kDeathRed.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: kDeathGold.withOpacity(0.05),
                    blurRadius: 60,
                    spreadRadius: 10,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== HEADER ICON =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kDeathRed.withOpacity(0.15), kDeathGold.withOpacity(0.05)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kDeathGreen.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kDeathGreen.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: kDeathGreen,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== TITLE =====
                  Text(
                    'ATTACK SENT!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      fontFamily: 'FontX',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Group exploit successfully launched',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== INFO BOX =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kDeathDarkBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kDeathRed.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _infoRow("Status", success ? "✅ SUCCESS" : "⚠️ PARTIAL"),
                        const SizedBox(height: 4),
                        _infoRow("Can Send", canSend ? "✅ YES" : "❌ DISABLED"),
                        if (groupInfo != null) ...[
                          Divider(
                            height: 12,
                            color: Colors.white.withOpacity(0.03),
                          ),
                          _infoRow("Group", groupInfo["subject"]?.toString() ?? "-"),
                          _infoRow("Members", groupInfo["participants"]?.toString() ?? "-"),
                          if (groupInfo["description"] != null && groupInfo["description"].toString().isNotEmpty)
                            _infoRow("Description", groupInfo["description"].toString()),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ===== CLOSE BUTTON =====
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDeathRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "CLOSE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 2,
                          fontFamily: 'FontX',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Text(
          ": ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        Expanded(
          child: Text(
            val,
            style: TextStyle(
              color: kDeathGold,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _GroupGridPainter extends CustomPainter {
  final Color accentColor;

  _GroupGridPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const step = 30.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final accentPaint = Paint()
      ..color = accentColor.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double x = 0; x <= size.width; x += step * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }
    for (double y = 0; y <= size.height; y += step * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }

    final dotPaint = Paint()
      ..color = accentColor.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GroupGridPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}