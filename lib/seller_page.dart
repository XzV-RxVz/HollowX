// DEATHTR4SH V1 GEN 2 - SELLER DASHBOARD

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'constants.dart';

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> with SingleTickerProviderStateMixin {
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();

  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  bool isLoading = false;
  
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchUsers();
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
    _mainController.dispose();
    _pulseController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    editUsernameController.dispose();
    editDayController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://lalalucuu.alannxd.my.id:3006/listUsers?key=${widget.keyToken}'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _showDialog("Info", data['message'] ?? 'Gagal memuat user.', isError: true);
      }
    } catch (_) {
      _showDialog("Error", "Gagal terhubung ke server.", isError: true);
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList
          .where((u) => u['role'] == selectedRole)
          .toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _showDialog("Peringatan", "Semua field wajib diisi.", isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          "http://lalalucuu.alannxd.my.id:3006/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d"));
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _showDialog("Sukses", "Akun berhasil dibuat!", isError: false);
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        _fetchUsers();
      } else {
        String msg = data['message'] ?? 'Gagal membuat akun.';
        if (data['invalidDay'] == true) {
          msg += " (Max 30 hari untuk Reseller)";
        }
        _showDialog("Gagal", msg, isError: true);
      }
    } catch (e) {
      _showDialog("Error", "Koneksi error: $e", isError: true);
    }
    setState(() => isLoading = false);
  }

  Future<void> _editUser() async {
    final u = editUsernameController.text.trim();
    final d = editDayController.text.trim();

    if (u.isEmpty || d.isEmpty) {
      _showDialog("Peringatan", "Semua field wajib diisi.", isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          "http://lalalucuu.alannxd.my.id:3006/editUser?key=${widget.keyToken}&username=$u&addDays=$d"));
      final data = jsonDecode(res.body);

      if (data['edited'] == true) {
        _showDialog("Sukses", "Durasi berhasil diperbarui.", isError: false);
        editUsernameController.clear();
        editDayController.clear();
        _fetchUsers();
      } else {
        _showDialog("Gagal", data['message'] ?? 'Gagal mengubah durasi.', isError: true);
      }
    } catch (e) {
      _showDialog("Error", "Koneksi error: $e", isError: true);
    }
    setState(() => isLoading = false);
  }

  void _showDialog(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0.7, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, double scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isError ? kDeathRed.withOpacity(0.2) : kDeathGold.withOpacity(0.2),
                width: 1,
              ),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: isError
                        ? LinearGradient(colors: [kDeathRed, kDeathRedDark])
                        : LinearGradient(colors: [kDeathRed, kDeathGold]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isError ? kDeathRed : kDeathGold).withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isError ? [kDeathRed, kDeathRedDark] : [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 13,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isError
                          ? LinearGradient(colors: [kDeathRed, kDeathRedDark])
                          : LinearGradient(colors: [kDeathRed, kDeathGold]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (isError ? kDeathRed : kDeathGold).withOpacity(0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      "OK",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required FaIconData icon,
    TextInputType type = TextInputType.text,
    String hint = "",
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: kDeathDarkBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDeathBorder),
        ),
        child: TextField(
          controller: controller,
          keyboardType: type,
          obscureText: obscure,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'ShareTechMono',
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.06),
              fontSize: 11,
              fontFamily: 'ShareTechMono',
            ),
            labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'ShareTechMono',
              letterSpacing: 0.5,
            ),
            prefixIcon: FaIcon(icon, color: kDeathRed, size: 16),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required FaIconData icon,
    required List<Widget> children,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kDeathCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kDeathBorder),
          boxShadow: [
            BoxShadow(
              color: kDeathRed.withOpacity(0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kDeathRed, kDeathGold],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kDeathRed.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: FaIcon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kDeathDarkBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDeathBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                  user['username'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: 'ShareTechMono',
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
                    user['username'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kDeathRed.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kDeathRed.withOpacity(0.04)),
                        ),
                        child: Text(
                          user['role'].toString().toUpperCase(),
                          style: TextStyle(
                            color: kDeathRed.withOpacity(0.2),
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'ShareTechMono',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Exp: ${user['expiredDate']}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.08),
                          fontSize: 8,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(totalPages > 10 ? 10 : totalPages, (index) {
        final page = index + 1;
        final isActive = currentPage == page;
        return GestureDetector(
          onTap: () => setState(() => currentPage = page),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(colors: [kDeathRed, kDeathRedDark])
                  : null,
              color: isActive ? null : kDeathDarkBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? Colors.transparent : kDeathBorder,
                width: 0.5,
              ),
            ),
            child: Text(
              "$page",
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontFamily: isActive ? 'ShareTechMono' : 'ShareTechMono',
              ),
            ),
          ),
        );
      }),
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
          painter: _SellerGridPainter(accentColor: kDeathRed),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildGlassCard(
                        title: "CREATE MEMBER",
                        icon: FontAwesomeIcons.userPlus,
                        children: [
                          _buildInput(
                            label: "Username Baru",
                            controller: createUsernameController,
                            icon: FontAwesomeIcons.user,
                          ),
                          _buildInput(
                            label: "Password",
                            controller: createPasswordController,
                            icon: FontAwesomeIcons.lock,
                            obscure: true,
                          ),
                          _buildInput(
                            label: "Durasi (Hari)",
                            controller: createDayController,
                            icon: FontAwesomeIcons.calendarDay,
                            type: TextInputType.number,
                            hint: "Maksimal 30 hari",
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            onPressed: isLoading ? null : _createAccount,
                            isLoading: isLoading,
                            label: "CREATE ACCOUNT",
                          ),
                        ],
                      ),
                      _buildGlassCard(
                        title: "EXTEND DURATION",
                        icon: FontAwesomeIcons.clock,
                        children: [
                          _buildInput(
                            label: "Username Target",
                            controller: editUsernameController,
                            icon: FontAwesomeIcons.userEdit,
                            hint: "Username member yang ingin diperpanjang",
                          ),
                          _buildInput(
                            label: "Tambah Hari",
                            controller: editDayController,
                            icon: FontAwesomeIcons.calendarPlus,
                            type: TextInputType.number,
                            hint: "Maksimal 30 hari",
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            onPressed: isLoading ? null : _editUser,
                            isLoading: isLoading,
                            label: "ADD DAYS",
                          ),
                        ],
                      ),
                      _buildMemberListCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
            Icon(Icons.storefront_rounded, color: kDeathRed, size: 16),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ).createShader(bounds),
              child: Text(
                'SELLER DASHBOARD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'ShareTechMono',
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
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: value, child: child),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathGold],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.2 * _pulseAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.storefront_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [kDeathRed, kDeathGold],
            ).createShader(bounds),
            child: Text(
              "SELLER DASHBOARD",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'ShareTechMono',
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: kDeathRed.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kDeathRed.withOpacity(0.04)),
            ),
            child: Text(
              "max duration - permanent",
              style: TextStyle(
                color: kDeathRed.withOpacity(0.2),
                fontSize: 9,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================
  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kDeathRed, kDeathRedDark],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kDeathRed.withOpacity(0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // MEMBER LIST CARD
  // ============================================================
  Widget _buildMemberListCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDeathBorder),
        boxShadow: [
          BoxShadow(
            color: kDeathRed.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kDeathRed.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: FaIcon(FontAwesomeIcons.users, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [kDeathRed, kDeathGold],
                ).createShader(bounds),
                child: Text(
                  "MEMBER LIST",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: kDeathDarkBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kDeathBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRole,
                dropdownColor: kDeathCardBg,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
                items: roleOptions.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    selectedRole = val;
                    _filterAndPaginate();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: kDeathRed,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Memuat data member...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.06),
                      fontSize: 9,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            )
          else if (filteredList.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    color: Colors.white.withOpacity(0.03),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tidak ada member",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.06),
                      fontSize: 11,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ..._getCurrentPageData().map((u) => _buildUserItem(u)).toList(),
                const SizedBox(height: 12),
                _buildPagination(),
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
class _SellerGridPainter extends CustomPainter {
  final Color accentColor;

  _SellerGridPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const step = 28.0;

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
  bool shouldRepaint(covariant _SellerGridPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}