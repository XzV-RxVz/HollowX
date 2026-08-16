// DEATHTR4SH V1 GEN 2 - OWNER DASHBOARD

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'role_helper.dart';
import 'constants.dart';

class OwnerPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String currentUserRole;

  const OwnerPage({
    super.key,
    required this.sessionKey,
    required this.username,
    this.currentUserRole = 'developer',
  });

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> with TickerProviderStateMixin {
  late String sessionKey;
  late String currentUserRole;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  late List<String> allRoleList;
  String selectedFilterRole = 'all';
  String searchQuery = '';

  List<String> creatableRoleList = [];
  String selectedCreateRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 20;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final deleteController = TextEditingController();
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
    sessionKey = widget.sessionKey;
    currentUserRole = widget.currentUserRole;
    
    _initAnimations();
    _initRoleLists();
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

  void _initRoleLists() {
    allRoleList = ['all', ...getAllRoles()];
    creatableRoleList = creatableRoles(currentUserRole);
    if (creatableRoleList.isNotEmpty) {
      selectedCreateRole = creatableRoleList.first;
    }
    selectedFilterRole = 'all';
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    deleteController.dispose();
    editUsernameController.dispose();
    editDayController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://lalalucuu.alannxd.my.id:3012/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _applyFilter();
      } else {
        _showDialog("Error", data['message'] ?? 'Gagal memuat user.', isError: true);
      }
    } catch (_) {
      _showDialog("Error", "Gagal terhubung ke server.", isError: true);
    }
    setState(() => isLoading = false);
  }

  void _applyFilter() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) {
        final roleMatch = selectedFilterRole == 'all' || 
            u['role'].toString().toLowerCase() == selectedFilterRole.toLowerCase();
        final searchMatch = searchQuery.isEmpty ||
            u['username'].toLowerCase().contains(searchQuery.toLowerCase());
        return roleMatch && searchMatch;
      }).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    if (filteredList.isEmpty) return [];
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    if (start >= filteredList.length) return [];
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => filteredList.isEmpty ? 1 : (filteredList.length / itemsPerPage).ceil();

  bool _canDeleteUser(String targetRole) => canDeleteUser(currentUserRole, targetRole);
  bool _canEditUser(String targetRole) => canEditUser(currentUserRole, targetRole);

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _showDialog("Error", "Masukkan username yang ingin dihapus.", isError: true);
      return;
    }

    final targetUser = fullUserList.firstWhere(
      (u) => u['username'] == username,
      orElse: () => null,
    );

    if (targetUser == null) {
      _showDialog("Error", "User tidak ditemukan.", isError: true);
      return;
    }

    final targetRole = targetUser['role'].toString().toLowerCase();
    if (!_canDeleteUser(targetRole)) {
      _showDialog("Akses Ditolak",
          "Anda tidak memiliki izin untuk menghapus user dengan role ${roleLabel(targetRole)}.",
          isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://lalalucuu.alannxd.my.id:3012/deleteUser?key=$sessionKey&username=$username'),
      );
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _showDialog("Sukses", "User '${data['user']['username']}' telah dihapus.", isError: false);
        deleteController.clear();
        _fetchUsers();
      } else {
        _showDialog("Gagal", data['message'] ?? 'Gagal menghapus user.', isError: true);
      }
    } catch (_) {
      _showDialog("Error", "Gagal menghubungi server.", isError: true);
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _showDialog("Error", "Semua field wajib diisi.", isError: true);
      return;
    }

    if (!canCreateRole(currentUserRole, selectedCreateRole)) {
      _showDialog("Akses Ditolak",
          "Anda tidak memiliki izin untuk membuat user dengan role ${roleLabel(selectedCreateRole)}.",
          isError: true);
      return;
    }

    final days = int.tryParse(d);
    final maxDur = maxDays(currentUserRole);
    if (days != null && days > maxDur) {
      _showDialog("Peringatan",
          "Maksimal durasi untuk ${roleLabel(currentUserRole)} adalah $maxDur hari.",
          isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        'http://lalalucuu.alannxd.my.id:3012/userAdd?key=$sessionKey&username=$u&password=$p&day=$d&role=$selectedCreateRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _showDialog("Sukses", "Akun '${data['user']['username']}' berhasil dibuat sebagai ${roleLabel(selectedCreateRole)}.", isError: false);
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        selectedCreateRole = creatableRoleList.isNotEmpty ? creatableRoleList.first : 'member';
        _fetchUsers();
      } else {
        _showDialog("Gagal", data['message'] ?? 'Gagal membuat akun.', isError: true);
      }
    } catch (_) {
      _showDialog("Error", "Gagal menghubungi server.", isError: true);
    }
    setState(() => isLoading = false);
  }

  Future<void> _editUser() async {
    final u = editUsernameController.text.trim();
    final d = editDayController.text.trim();

    if (u.isEmpty || d.isEmpty) {
      _showDialog("Error", "Semua field wajib diisi.", isError: true);
      return;
    }

    final targetUser = fullUserList.firstWhere(
      (user) => user['username'] == u,
      orElse: () => null,
    );

    if (targetUser == null) {
      _showDialog("Error", "User tidak ditemukan.", isError: true);
      return;
    }

    final targetRole = targetUser['role'].toString().toLowerCase();
    if (!_canEditUser(targetRole)) {
      _showDialog("Akses Ditolak",
          "Anda tidak memiliki izin untuk mengedit user dengan role ${roleLabel(targetRole)}.",
          isError: true);
      return;
    }

    final days = int.tryParse(d);
    final maxDur = maxDays(currentUserRole);
    if (days != null && days > maxDur) {
      _showDialog("Peringatan",
          "Maksimal tambahan durasi untuk ${roleLabel(currentUserRole)} adalah $maxDur hari.",
          isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        'http://lalalucuu.alannxd.my.id:3012/editUser?key=$sessionKey&username=$u&addDays=$d',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['edited'] == true) {
        _showDialog("Sukses", "Durasi user '$u' berhasil diperbarui.", isError: false);
        editUsernameController.clear();
        editDayController.clear();
        _fetchUsers();
      } else {
        _showDialog("Gagal", data['message'] ?? 'Gagal mengubah durasi.', isError: true);
      }
    } catch (_) {
      _showDialog("Error", "Gagal menghubungi server.", isError: true);
    }
    setState(() => isLoading = false);
  }

  void _showExtendDialog(String username) {
    editUsernameController.text = username;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          tween: Tween(begin: 0.7, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (ctx, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kDeathRed.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 2,
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
                  child: Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    "PERPANJANG DURASI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Masukkan jumlah hari untuk $username",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 12,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: kDeathDarkBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kDeathBorder),
                  ),
                  child: TextField(
                    controller: editDayController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'ShareTechMono',
                    ),
                    decoration: InputDecoration(
                      hintText: "Jumlah hari (maks ${maxDays(currentUserRole)})",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.06),
                        fontSize: 11,
                        fontFamily: 'ShareTechMono',
                      ),
                      prefixIcon: Icon(Icons.calendar_today_rounded, color: kDeathRed, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 44,
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
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'ShareTechMono',
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
                        onTap: () async {
                          Navigator.pop(context);
                          await _editUser();
                        },
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
                              "TAMBAH",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                fontFamily: 'ShareTechMono',
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

  void _showDialog(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          tween: Tween(begin: 0.7, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (ctx, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.all(16),
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
                  spreadRadius: 2,
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

  Future<bool?> _showConfirmDialog(String username) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.7, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (ctx, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kDeathRed.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 2,
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
                    color: kDeathRed.withOpacity(0.04),
                    shape: BoxShape.circle,
                    border: Border.all(color: kDeathRed.withOpacity(0.04)),
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: kDeathRed, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  "KONFIRMASI HAPUS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Yakin ingin menghapus user '$username'?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 13,
                    fontFamily: 'ShareTechMono',
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
                            color: kDeathCardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kDeathBorder),
                          ),
                          child: Center(
                            child: Text(
                              "BATAL",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'ShareTechMono',
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
                              "HAPUS",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                fontFamily: 'ShareTechMono',
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

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required FaIconData icon,
    TextInputType type = TextInputType.text,
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
            labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'ShareTechMono',
              letterSpacing: 0.5,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: FaIcon(icon, color: kDeathRed, size: 16),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
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
        color: kDeathDarkBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDeathBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: kDeathCardBg,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'ShareTechMono',
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: kDeathRed, size: 20),
          items: options.map((r) => DropdownMenuItem(
            value: r,
            child: Text(
              r == 'all' ? '📋 SEMUA ROLE' : roleLabel(r).toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'ShareTechMono',
                letterSpacing: 0.5,
              ),
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required LinearGradient gradient,
    required Color glowColor,
    required VoidCallback onTap,
    IconData? icon,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.2),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
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
                        fontSize: 11,
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

  Widget _buildCard({
    required String title,
    required FaIconData icon,
    required List<Widget> children,
    int animDelay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + animDelay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
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

  Widget _buildUserGridItem(Map user, int index) {
    final targetRole = user['role'].toString().toLowerCase();
    final canDelete = _canDeleteUser(targetRole);
    final canEdit = _canEditUser(targetRole);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.scale(scale: 0.9 + (v * 0.1), child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kDeathDarkBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kDeathBorder),
        ),
        child: Column(
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed.withOpacity(0.1), kDeathRedDark.withOpacity(0.05)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Container(
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
                      user['username'][0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kDeathRed.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kDeathRed.withOpacity(0.04)),
                    ),
                    child: Text(
                      roleLabel(targetRole).toUpperCase(),
                      style: TextStyle(
                        color: kDeathRed.withOpacity(0.2),
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Exp: ${user['expiredDate']}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.08),
                      fontSize: 8,
                      fontFamily: 'ShareTechMono',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (canEdit)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showExtendDialog(user['username']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: kDeathRed.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kDeathRed.withOpacity(0.04)),
                              ),
                              child: Icon(Icons.edit_calendar_rounded, color: kDeathRed, size: 14),
                            ),
                          ),
                        ),
                      if (canEdit && canDelete) const SizedBox(width: 6),
                      if (canDelete)
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final confirm = await _showConfirmDialog(user['username']);
                              if (confirm == true) {
                                deleteController.text = user['username'];
                                _deleteUser();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: kDeathRed.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kDeathRed.withOpacity(0.04)),
                              ),
                              child: Icon(Icons.delete_outline_rounded, color: kDeathRed, size: 14),
                            ),
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
    final maxDur = maxDays(currentUserRole);
    final canCreate = creatableRoleList.isNotEmpty;

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
          painter: _OwnerGridPainter(),
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
                      _buildHeader(maxDur),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildCard(
                        title: "FILTER ROLE",
                        icon: FontAwesomeIcons.filter,
                        animDelay: 0,
                        children: [
                          _buildDropdown(
                            value: selectedFilterRole,
                            options: allRoleList,
                            onChanged: (v) {
                              if (v != null) {
                                selectedFilterRole = v;
                                _applyFilter();
                              }
                            },
                          ),
                        ],
                      ),
                      if (canCreate)
                        _buildCard(
                          title: "BUAT AKUN",
                          icon: FontAwesomeIcons.userPlus,
                          animDelay: 50,
                          children: [
                            _buildInput(label: "Username", controller: createUsernameController, icon: FontAwesomeIcons.user),
                            _buildInput(label: "Password", controller: createPasswordController, icon: FontAwesomeIcons.lock, obscure: true),
                            _buildInput(
                              label: "Durasi (Hari)",
                              controller: createDayController,
                              icon: FontAwesomeIcons.calendarDay,
                              type: TextInputType.number,
                            ),
                            _buildDropdown(
                              value: selectedCreateRole,
                              options: creatableRoleList,
                              onChanged: (v) => setState(() => selectedCreateRole = v ?? 'member'),
                            ),
                            const SizedBox(height: 8),
                            _buildActionButton(
                              label: "BUAT AKUN",
                              gradient: LinearGradient(colors: [kDeathRed, kDeathRedDark]),
                              glowColor: kDeathRed,
                              icon: Icons.person_add_rounded,
                              isLoading: isLoading,
                              onTap: _createAccount,
                            ),
                          ],
                        ),
                      _buildCard(
                        title: "PERPANJANG DURASI",
                        icon: FontAwesomeIcons.clock,
                        animDelay: 100,
                        children: [
                          _buildInput(label: "Username Target", controller: editUsernameController, icon: FontAwesomeIcons.userEdit),
                          _buildInput(
                            label: "Tambah Hari",
                            controller: editDayController,
                            icon: FontAwesomeIcons.calendarPlus,
                            type: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            label: "TAMBAH HARI",
                            gradient: LinearGradient(colors: [kDeathRed, kDeathRedDark]),
                            glowColor: kDeathRed,
                            icon: Icons.calendar_today_rounded,
                            isLoading: isLoading,
                            onTap: _editUser,
                          ),
                        ],
                      ),
                      _buildCard(
                        title: "HAPUS AKUN",
                        icon: FontAwesomeIcons.userSlash,
                        animDelay: 150,
                        children: [
                          _buildInput(label: "Username Target", controller: deleteController, icon: FontAwesomeIcons.user),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            label: "HAPUS AKUN",
                            gradient: LinearGradient(colors: [kDeathRed, kDeathRedDark]),
                            glowColor: kDeathRed,
                            icon: Icons.delete_rounded,
                            isLoading: isLoading,
                            onTap: _deleteUser,
                          ),
                        ],
                      ),
                      _buildCard(
                        title: "DAFTAR USER",
                        icon: FontAwesomeIcons.users,
                        animDelay: 200,
                        children: [
                          isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
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
                                          'LOADING USERS...',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.04),
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'ShareTechMono',
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : filteredList.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(Icons.person_off_rounded, color: Colors.white.withOpacity(0.03), size: 48),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Tidak ada user ditemukan.",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.06),
                                                fontSize: 11,
                                                fontFamily: 'ShareTechMono',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.7,
                                          ),
                                          itemCount: _getCurrentPageData().length,
                                          itemBuilder: (ctx, idx) {
                                            final user = _getCurrentPageData()[idx];
                                            return _buildUserGridItem(user, idx);
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        _buildPagination(),
                                      ],
                                    ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "DEATHTR4SH V1 GEN 2",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.02),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'ShareTechMono',
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
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
            Icon(Icons.workspace_premium_rounded, color: kDeathRed, size: 16),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ).createShader(bounds),
              child: Text(
                'OWNER DASHBOARD',
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
  Widget _buildHeader(int maxDur) {
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
                child: Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [kDeathRed, kDeathGold],
            ).createShader(bounds),
            child: Text(
              "DEATHTR4SH",
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kDeathRed.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kDeathRed.withOpacity(0.04)),
                ),
                child: Text(
                  "V1 GEN 2",
                  style: TextStyle(
                    color: kDeathRed.withOpacity(0.2),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kDeathGold.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kDeathGold.withOpacity(0.04)),
                ),
                child: Text(
                  roleLabel(currentUserRole).toUpperCase(),
                  style: TextStyle(
                    color: kDeathGold.withOpacity(0.2),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          if (maxDur > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: kDeathRed.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDeathRed.withOpacity(0.04)),
              ),
              child: Text(
                "Max Durasi: $maxDur Hari",
                style: TextStyle(
                  color: kDeathRed.withOpacity(0.15),
                  fontSize: 9,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATS ROW
  // ============================================================
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.people_alt_rounded,
          label: "Total User",
          value: "${filteredList.length}",
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          icon: Icons.grid_view_rounded,
          label: "Halaman",
          value: "$currentPage / ${totalPages == 0 ? 1 : totalPages}",
        ),
      ],
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kDeathCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDeathBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathGold],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 9, fontFamily: 'ShareTechMono')),
                Text(value, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'ShareTechMono')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDeathBorder),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            _applyFilter();
          });
        },
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'ShareTechMono',
        ),
        decoration: InputDecoration(
          hintText: "Cari username...",
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.06),
            fontSize: 11,
            fontFamily: 'ShareTechMono',
          ),
          prefixIcon: Icon(Icons.search_rounded, color: kDeathRed, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.1), size: 16),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      _applyFilter();
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _OwnerGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 24.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final accentPaint = Paint()
      ..color = kDeathRed.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += step * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }
    for (double y = 0; y <= size.height; y += step * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }

    final dotPaint = Paint()
      ..color = kDeathRed.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}