// admin_page.dart
// DEATHTRASH - ADMIN COMMAND CENTER (RED & GOLD EDITION)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'constants.dart';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['reseller', 'member', 'xvip', 'owner', 'owner', 'moderator', 'xfounder', 'executive'];
  String selectedRole = 'member';
  String searchQuery = '';

  int currentPage = 1;
  int itemsPerPage = 12;

  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';
  bool isLoading = false;

  late AnimationController _mainAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;

    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _mainAnimController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimController, curve: Curves.easeOutCubic),
    );

    _mainAnimController.forward();
    _fetchUsers();
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    super.dispose();
  }

  // ============================================================
  // API
  // ============================================================
  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://lalalucuu.alannxd.my.id:3006/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _applyFilters();
      } else {
        _showAlert("Access Denied", data['message'] ?? 'Unauthorized');
      }
    } catch (_) {
      _showAlert("Connection Error", "Failed to load users.");
    }
    setState(() => isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) {
        final roleMatch = u['role'] == selectedRole;
        final searchMatch = searchQuery.isEmpty ||
            u['username'].toLowerCase().contains(searchQuery.toLowerCase());
        return roleMatch && searchMatch;
      }).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _showAlert("Error", "Enter username to delete.");
      return;
    }
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
        'http://lalalucuu.alannxd.my.id:3006/deleteUser?key=$sessionKey&username=$username',
      ));
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _showAlert("Success", "User '${data['user']['username']}' deleted.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _showAlert("Failed", data['message'] ?? 'Delete failed.');
      }
    } catch (_) {
      _showAlert("Error", "Server connection failed.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();
    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _showAlert("Error", "All fields are required.");
      return;
    }
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
        'http://lalalucuu.alannxd.my.id:3006/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole',
      ));
      final data = jsonDecode(res.body);
      if (data['created'] == true) {
        _showAlert("Success", "Account '${data['user']['username']}' created.");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        setState(() => newUserRole = 'member');
        _fetchUsers();
      } else {
        _showAlert("Failed", data['message'] ?? 'Create failed.');
      }
    } catch (_) {
      _showAlert("Error", "Server connection failed.");
    }
    setState(() => isLoading = false);
  }

  // ============================================================
  // ALERT DIALOG - DEATHTRASH THEME
  // ============================================================
  void _showAlert(String title, String message) {
    final bool isSuccess = title.contains("Success") || title.contains("Created");
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          tween: Tween(begin: 0.8, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (ctx, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kDeathDarkBg,
                  kDeathCardBg,
                  kDeathDarkBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSuccess ? kDeathGreen.withOpacity(0.3) : kDeathRed.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSuccess ? kDeathGreen : kDeathRed).withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (isSuccess ? kDeathGreen : kDeathRed).withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isSuccess ? kDeathGreen : kDeathRed).withOpacity(0.15),
                    ),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: isSuccess ? kDeathGreen : kDeathRed,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSuccess ? [kDeathGreen, kDeathGreen.withOpacity(0.6)] : [kDeathRed, kDeathRedDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isSuccess ? kDeathGreen : kDeathRed).withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      "CLOSE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 2,
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

  // ============================================================
  // CONFIRM DIALOG - DEATHTRASH THEME
  // ============================================================
  Future<bool?> _showConfirmDialog(String username) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.8, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (ctx, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kDeathDarkBg, kDeathCardBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: kDeathRed.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.15),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kDeathRed.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: kDeathRed.withOpacity(0.15)),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: kDeathRed,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "CONFIRM DELETE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Delete user '$username' permanently?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: kDeathCardBg.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kDeathBorder),
                          ),
                          child: Center(
                            child: Text(
                              "CANCEL",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                fontFamily: 'ShareTechMono',
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 44,
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
                              "DELETE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                fontFamily: 'ShareTechMono',
                                letterSpacing: 1.5,
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

  // ============================================================
  // REUSABLE WIDGETS
  // ============================================================

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool isLoading = false,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDanger ? [kDeathRed, kDeathRedDark] : [kDeathRed, kDeathRedDark],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isDanger ? kDeathRed : kDeathRed).withOpacity(0.3),
              blurRadius: 16,
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDeathBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
          prefixIcon: Icon(icon, color: kDeathRed, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDeathBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: kDeathDarkBg,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: kDeathRed),
          items: options.map((r) => DropdownMenuItem(
            value: r,
            child: Text(
              r.toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    int animDelay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + animDelay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kDeathCardBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kDeathBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
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
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: kDeathRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map user, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 30)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.scale(scale: 0.9 + (v * 0.1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kDeathCardBg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kDeathRed.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kDeathRed, kDeathRedDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kDeathRed.withOpacity(0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user['username'][0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'ShareTechMono',
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
                        user['username'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: kDeathRed.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: kDeathRed.withOpacity(0.06)),
                        ),
                        child: Text(
                          user['role'].toString().toUpperCase(),
                          style: TextStyle(
                            color: kDeathRed,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Exp: ${user['expiredDate']}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 8,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final confirm = await _showConfirmDialog(user['username']);
                if (confirm == true) {
                  deleteController.text = user['username'];
                  _deleteUser();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: kDeathRed.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kDeathRed.withOpacity(0.06)),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: kDeathRed.withOpacity(0.3),
                  size: 14,
                ),
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
      children: List.generate(totalPages, (index) {
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
              color: isActive ? null : kDeathCardBg.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? kDeathRed.withOpacity(0.2) : kDeathBorder,
              ),
            ),
            child: Text(
              "$page",
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: kDeathCardBg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kDeathBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathRedDark],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.white, size: 12),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 7,
                    fontFamily: 'monospace',
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
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
    return Scaffold(
      backgroundColor: kDeathDarkBg,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kDeathDarkBg,
                  kDeathCardBg,
                  Color(0xFF150A26),
                  kDeathDarkBg,
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // Glow Orbs
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kDeathRed.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kDeathGold.withOpacity(0.04), Colors.transparent],
                ),
              ),
            ),
          ),

          // Grid
          CustomPaint(
            size: Size.infinite,
            painter: _AdminGridPainter(accentColor: kDeathRed),
          ),

          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ===== HEADER =====
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [kDeathRed, kDeathRedDark],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: kDeathRed.withOpacity(0.3),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [kDeathRed, kDeathGold],
                              ).createShader(bounds),
                              child: Text(
                                "DEATHTRASH USER CENTER",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'ShareTechMono',
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildBadge("v1.0"),
                                const SizedBox(width: 8),
                                _buildBadge("Gen 3.0"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ===== STATS =====
                      Row(
                        children: [
                          _buildStatChip(
                            icon: Icons.people_alt_rounded,
                            label: "TOTAL",
                            value: "${filteredList.length}",
                          ),
                          const SizedBox(width: 10),
                          _buildStatChip(
                            icon: Icons.grid_view_rounded,
                            label: "PAGE",
                            value: "$currentPage/${totalPages == 0 ? 1 : totalPages}",
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ===== SEARCH =====
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: kDeathCardBg.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kDeathBorder),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                              _applyFilters();
                            });
                          },
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: "Search username...",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.15),
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                            prefixIcon: Icon(Icons.search_rounded, color: kDeathRed, size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.2), size: 16),
                                    onPressed: () {
                                      setState(() {
                                        searchQuery = '';
                                        _applyFilters();
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),

                      // ===== FILTER ROLE =====
                      _buildSection(
                        title: "FILTER ROLE",
                        icon: Icons.filter_alt_rounded,
                        animDelay: 0,
                        children: [
                          _buildDropdown(
                            value: selectedRole,
                            options: roleOptions,
                            onChanged: (v) {
                              if (v != null) {
                                selectedRole = v;
                                _applyFilters();
                              }
                            },
                          ),
                        ],
                      ),

                      // ===== CREATE ACCOUNT =====
                      _buildSection(
                        title: "CREATE ACCOUNT",
                        icon: Icons.person_add_alt_1_rounded,
                        animDelay: 50,
                        children: [
                          _buildInput(
                            label: "Username",
                            controller: createUsernameController,
                            icon: Icons.person_outline_rounded,
                          ),
                          _buildInput(
                            label: "Password",
                            controller: createPasswordController,
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                          ),
                          _buildInput(
                            label: "Duration (Days)",
                            controller: createDayController,
                            icon: Icons.calendar_today_outlined,
                            type: TextInputType.number,
                          ),
                          _buildDropdown(
                            value: newUserRole,
                            options: roleOptions,
                            onChanged: (v) => setState(() => newUserRole = v ?? 'member'),
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            label: "CREATE ACCOUNT",
                            icon: Icons.person_add_rounded,
                            isLoading: isLoading,
                            onTap: _createAccount,
                          ),
                        ],
                      ),

                      // ===== DELETE ACCOUNT =====
                      _buildSection(
                        title: "DELETE ACCOUNT",
                        icon: Icons.person_remove_alt_1_rounded,
                        animDelay: 100,
                        children: [
                          _buildInput(
                            label: "Target Username",
                            controller: deleteController,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            label: "DELETE ACCOUNT",
                            icon: Icons.delete_rounded,
                            isLoading: isLoading,
                            isDanger: true,
                            onTap: _deleteUser,
                          ),
                        ],
                      ),

                      // ===== USER LIST =====
                      _buildSection(
                        title: "USER LIST",
                        icon: Icons.people_rounded,
                        animDelay: 150,
                        children: [
                          isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: kDeathRed,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                )
                              : filteredList.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.person_off_rounded,
                                            color: Colors.white.withOpacity(0.05),
                                            size: 40,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "No users found",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.1),
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 0.8,
                                          ),
                                          itemCount: _getCurrentPageData().length,
                                          itemBuilder: (ctx, idx) {
                                            final user = _getCurrentPageData()[idx];
                                            return _buildUserCard(user, idx);
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        _buildPagination(),
                                      ],
                                    ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Footer
                      Text(
                        "DEATHTRASH · USER CENTER",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.04),
                          fontSize: 9,
                          fontFamily: 'ShareTechMono',
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDeathRed.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: kDeathRed.withOpacity(0.5),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _AdminGridPainter extends CustomPainter {
  final Color accentColor;

  _AdminGridPainter({required this.accentColor});

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}