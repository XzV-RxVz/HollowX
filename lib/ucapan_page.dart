// DEATHTR4SH V1 GEN 2 - UCAPAN PAGE

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'constants.dart';

class UcapanPage extends StatefulWidget {
  final String? sessionKey;
  final String? username;
  final String? role;
  final VoidCallback? onBack;

  const UcapanPage({
    super.key,
    this.sessionKey,
    this.username,
    this.role,
    this.onBack,
  });

  @override
  State<UcapanPage> createState() => _UcapanPageState();
}

class _UcapanPageState extends State<UcapanPage>
    with SingleTickerProviderStateMixin {
  List<UcapanModel> _ucapanList = [];
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _pesanController = TextEditingController();
  bool _isLoading = true;
  String? _sessionKey;
  String? _username;
  String? _role;

  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;

  final List<String> _forbiddenWords = [
    'anjing', 'bangsat', 'kontol', 'memek', 'ngentot', 'jembut', 'peler',
    'toket', 'goblok', 'tolol', 'babi', 'asu', 'sialan', 'brengsek',
    'kampret', 'bajingan', 'tai', 'ampas'
  ];

  String _filterText(String text) {
    String filtered = text;
    for (String word in _forbiddenWords) {
      if (filtered.toLowerCase().contains(word.toLowerCase())) {
        filtered = filtered.replaceAll(RegExp(word, caseSensitive: false), '****');
      }
    }
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initData();
    _mainController.forward();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _mainController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionKey = widget.sessionKey ?? prefs.getString('sessionKey') ?? '';
    _username = widget.username ?? prefs.getString('username') ?? '';
    _role = widget.role ?? prefs.getString('role') ?? 'member';

    _namaController.text = _username ?? '';
    await _loadUcapan();
  }

  Future<void> _loadUcapan() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://lalalucuu.alannxd.my.id:3012/getUcapan?key=$_sessionKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _ucapanList = (data['ucapan'] as List)
                .map((item) => UcapanModel.fromJson(item))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading ucapan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tambahUcapan() async {
    final nama = _namaController.text.trim();
    final pesan = _pesanController.text.trim();

    if (nama.isEmpty || pesan.isEmpty) {
      _showSnackBar('Nama dan pesan tidak boleh kosong', isError: true);
      return;
    }

    if (pesan.length > 500) {
      _showSnackBar('Pesan maksimal 500 karakter', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://lalalucuu.alannxd.my.id:3012/addUcapan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': _sessionKey,
          'nama': _filterText(nama),
          'pesan': _filterText(pesan),
        }),
      );

      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        _pesanController.clear();
        await _loadUcapan();

        if (mounted) {
          _showSnackBar('Ucapan berhasil dikirim!', isError: false);
        }
      } else {
        _showSnackBar(data['message'] ?? 'Gagal mengirim ucapan', isError: true);
      }
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Gagal mengirim ucapan', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _likeUcapan(String id, String type) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://lalalucuu.alannxd.my.id:3012/likeUcapan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': _sessionKey,
          'id': id,
          'type': type,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            final index = _ucapanList.indexWhere((u) => u.id == id);
            if (index != -1) {
              _ucapanList[index] = UcapanModel(
                id: _ucapanList[index].id,
                nama: _ucapanList[index].nama,
                pesan: _ucapanList[index].pesan,
                waktu: _ucapanList[index].waktu,
                likes: data['likes'],
                dislikes: data['dislikes'],
              );
            }
          });

          String message = '';
          if (data['action'] == 'liked') message = 'Berhasil like';
          else if (data['action'] == 'unliked') message = 'Batal like';
          else if (data['action'] == 'disliked') message = 'Berhasil dislike';
          else if (data['action'] == 'undisliked') message = 'Batal dislike';

          _showSnackBar(message, isError: false);
        }
      }
    } catch (e) {
      print('Error like: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUcapan(String id) async {
    if (_role != 'owner') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDeathCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kDeathRed, size: 24),
            const SizedBox(width: 10),
            Text(
              'HAPUS UCAPAN',
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
        content: Text(
          'Yakin ingin menghapus ucapan ini?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 13,
            fontFamily: 'ShareTechMono',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              backgroundColor: kDeathCardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: kDeathBorder),
              ),
            ),
            child: Text(
              'BATAL',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: kDeathRed.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: kDeathRed.withOpacity(0.2)),
              ),
            ),
            child: Text(
              'HAPUS',
              style: TextStyle(
                color: kDeathRed,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('http://lalalucuu.alannxd.my.id:3012/deleteUcapan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': _sessionKey,
          'id': id,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        await _loadUcapan();
        _showSnackBar('Ucapan berhasil dihapus', isError: false);
      }
    } catch (e) {
      print('Error delete: $e');
    }
  }

  String _formatWaktu(String isoString) {
    try {
      final waktu = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(waktu);

      if (diff.inMinutes < 1) return 'baru saja';
      if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
      if (diff.inDays < 1) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${diff.inDays ~/ 7} minggu lalu';
    } catch (e) {
      return 'baru saja';
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? kDeathRed.withOpacity(0.8) : kDeathRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isError ? kDeathRed : kDeathGold, width: 0.5),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showTambahUcapanDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutBack,
          builder: (context, double scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kDeathCardBg, kDeathDarkBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kDeathRed.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.1),
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
                      colors: [kDeathRed, kDeathGold],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kDeathRed.withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    "KIRIM UCAPAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontFamily: 'FontX',
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Kirim ucapan spesial untuk aplikasi",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 11,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: kDeathDarkBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kDeathBorder),
                  ),
                  child: TextField(
                    controller: _namaController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'ShareTechMono',
                    ),
                    decoration: InputDecoration(
                      hintText: "Nama Anda",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.1),
                        fontSize: 12,
                        fontFamily: 'ShareTechMono',
                      ),
                      prefixIcon: Icon(Icons.person, color: kDeathRed, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: kDeathDarkBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kDeathBorder),
                  ),
                  child: TextField(
                    controller: _pesanController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'ShareTechMono',
                    ),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Pesan ucapan...",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.1),
                        fontSize: 12,
                        fontFamily: 'ShareTechMono',
                      ),
                      prefixIcon: Icon(Icons.edit_note, color: kDeathRed, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kDeathGold.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kDeathGold.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: kDeathGold, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dilarang menggunakan kata-kata kasar',
                          style: TextStyle(
                            color: kDeathGold.withOpacity(0.3),
                            fontSize: 10,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: kDeathCardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kDeathBorder),
                          ),
                          child: Center(
                            child: Text(
                              "BATAL",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'FontX',
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _tambahUcapan();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kDeathRed, kDeathRedDark],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kDeathRed.withOpacity(0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "KIRIM",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'FontX',
                                letterSpacing: 1,
                              ),
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeathDarkBg,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.8,
            colors: [
              kDeathRed.withOpacity(0.04),
              kDeathDarkBg,
            ],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(accentColor: kDeathRed),
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scaleIn,
              child: SlideTransition(
                position: _slideUp,
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                color: kDeathRed,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'LOADING UCAPAN...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.06),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'FontX',
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _ucapanList.isEmpty
                        ? _buildEmptyState()
                        : _buildUcapanList(),
              ),
            ),
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
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kDeathRed.withOpacity(0.15), kDeathRedDark.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kDeathRed.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard_rounded, color: kDeathRed, size: 16),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ).createShader(bounds),
              child: Text(
                'UCAPAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kDeathCardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kDeathBorder),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: kDeathRed,
            size: 16,
          ),
        ),
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kDeathRed, kDeathRedDark],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: kDeathRed.withOpacity(0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            onPressed: _showTambahUcapanDialog,
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
        tween: Tween<double>(begin: 0, end: 1),
        curve: Curves.easeOutBack,
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed.withOpacity(0.04), kDeathGold.withOpacity(0.02)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: kDeathRed.withOpacity(0.04)),
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                size: 64,
                color: kDeathRed.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'BELUM ADA UCAPAN',
              style: TextStyle(
                color: Colors.white.withOpacity(0.08),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jadilah yang pertama mengirim ucapan',
              style: TextStyle(
                color: Colors.white.withOpacity(0.04),
                fontSize: 10,
                fontFamily: 'ShareTechMono',
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showTambahUcapanDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathRedDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kDeathRed.withOpacity(0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "BUAT UCAPAN PERTAMA",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        fontFamily: 'FontX',
                        letterSpacing: 1,
                      ),
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

  // ============================================================
  // UCAPAN LIST
  // ============================================================
  Widget _buildUcapanList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: _ucapanList.length,
      itemBuilder: (context, index) {
        final ucapan = _ucapanList[index];
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutBack,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kDeathBorder),
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kDeathRed, kDeathGold],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          ucapan.nama.isNotEmpty ? ucapan.nama[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'FontX',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ucapan.nama,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              fontFamily: 'FontX',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ucapan.pesan,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontFamily: 'ShareTechMono',
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 10, color: Colors.white.withOpacity(0.1)),
                              const SizedBox(width: 4),
                              Text(
                                _formatWaktu(ucapan.waktu),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.1),
                                  fontSize: 9,
                                  fontFamily: 'ShareTechMono',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_role == 'owner')
                      GestureDetector(
                        onTap: () => _deleteUcapan(ucapan.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kDeathRed.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kDeathRed.withOpacity(0.04)),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: kDeathRed.withOpacity(0.2),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _likeUcapan(ucapan.id, 'like'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kDeathRed.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kDeathRed.withOpacity(0.04)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.thumb_up_alt_outlined, color: kDeathRed, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${ucapan.likes}',
                              style: TextStyle(
                                color: kDeathRed.withOpacity(0.3),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _likeUcapan(ucapan.id, 'dislike'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.02)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.thumb_down_alt_outlined, color: Colors.white.withOpacity(0.1), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${ucapan.dislikes}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.1),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// MODEL
// ============================================================
class UcapanModel {
  final String id;
  final String nama;
  final String pesan;
  final String waktu;
  final int likes;
  final int dislikes;

  UcapanModel({
    required this.id,
    required this.nama,
    required this.pesan,
    required this.waktu,
    required this.likes,
    required this.dislikes,
  });

  factory UcapanModel.fromJson(Map<String, dynamic> json) {
    return UcapanModel(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      pesan: json['pesan'] ?? '',
      waktu: json['waktu'] ?? DateTime.now().toIso8601String(),
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
    );
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _GridPainter extends CustomPainter {
  final Color accentColor;

  _GridPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final accentPaint = Paint()
      ..color = accentColor.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }

    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }

    final dotPaint = Paint()
      ..color = accentColor.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += gridSize) {
      for (double y = 0; y <= size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}