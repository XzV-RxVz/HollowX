// profile_page.dart
// DEATHTR4SH - PROFILE (RED & GOLD EDITION)

import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'change_password_page.dart';
import 'theme_provider.dart';
import 'constants.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;

  const ProfilePage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // STATE
  // ============================================================
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  String _bio = "";
  String _telegramUsername = "";
  String _fullName = "";
  String _memberSince = "";
  int _totalLogin = 0;

  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  // ============================================================
  // ANIMATIONS
  // ============================================================
  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadAllData();
    _loadProfileImage();
    _mainController.forward();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );
  }

  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('profile_fullname_${widget.username}') ?? widget.username;
      _bio = prefs.getString('profile_bio_${widget.username}') ?? "";
      _telegramUsername = prefs.getString('profile_telegram_${widget.username}') ?? "";
      _memberSince = prefs.getString('profile_member_since_${widget.username}') ??
          _formatDateToString(DateTime.now());
      _totalLogin = prefs.getInt('profile_total_login_${widget.username}') ?? 0;
    });
    _bioController.text = _bio;
    _telegramController.text = _telegramUsername;
    _fullNameController.text = _fullName;
  }

  String _formatDateToString(DateTime date) =>
      "${date.day}/${date.month}/${date.year}";

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${widget.username}');
    if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      setState(() => _profileImage = File(imagePath));
    }
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_fullname_${widget.username}', _fullName);
    await prefs.setString('profile_bio_${widget.username}', _bio);
    await prefs.setString('profile_telegram_${widget.username}', _telegramUsername);
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================
  Future<void> _showImageSourceDialog() async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: kDeathDarkBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(color: kDeathRed.withOpacity(0.15)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: kDeathRed.withOpacity(0.06)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kDeathRed, kDeathRedDark],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "Profile Photo",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kDeathRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt, color: kDeathRed, size: 18),
                ),
                title: Text(
                  "Camera",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.2),
                  size: 18,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kDeathRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library, color: kDeathRed, size: 18),
                ),
                title: Text(
                  "Gallery",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.2),
                  size: 18,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${widget.username}', imageFile.path);
        setState(() => _profileImage = imageFile);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // ============================================================
  // EDIT DIALOG - DEATHTR4SH THEME
  // ============================================================
  void _showEditDialog() {
    _bioController.text = _bio;
    _telegramController.text = _telegramUsername;
    _fullNameController.text = _fullName;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0.8, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, double scale, child) =>
              Transform.scale(scale: scale, child: child),
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
                color: kDeathRed.withOpacity(0.2),
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
                    gradient: const LinearGradient(
                      colors: [kDeathRed, kDeathRedDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kDeathRed.withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    "Edit Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildEditField(
                  controller: _fullNameController,
                  hint: "Full Name",
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 10),
                _buildEditField(
                  controller: _bioController,
                  hint: "Bio",
                  icon: Icons.description_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                _buildEditField(
                  controller: _telegramController,
                  hint: "Telegram Username",
                  icon: FontAwesomeIcons.telegram,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kDeathBorder),
                          ),
                          child: Center(
                            child: Text(
                              "CANCEL",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
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
                        onTap: () async {
                          setState(() {
                            _fullName = _fullNameController.text.trim();
                            _bio = _bioController.text.trim();
                            _telegramUsername = _telegramController.text.trim();
                          });
                          await _saveProfileData();
                          if (mounted) Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
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
                              "SAVE",
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

  Widget _buildEditField({
    required TextEditingController controller,
    required String hint,
    required dynamic icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDeathBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.15),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          prefixIcon: icon is FaIconData
              ? FaIcon(icon, color: kDeathRed, size: 16)
              : Icon(icon as IconData, color: kDeathRed, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: ScaleTransition(
        scale: _scaleIn,
        child: SlideTransition(
          position: _slideUp,
          child: Scaffold(
            backgroundColor: kDeathDarkBg,
            appBar: _buildAppBar(),
            body: Stack(
              children: [
                _buildBackground(),
                _buildDecorations(),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildAvatar(),
                      const SizedBox(height: 14),
                      _buildUsername(),
                      const SizedBox(height: 6),
                      _buildRoleBadge(),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.person_outline_rounded,
                        label: "FULL NAME",
                        value: _fullName.isEmpty ? "Not set" : _fullName,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: Icons.description_outlined,
                        label: "BIO",
                        value: _bio.isEmpty ? "Not set" : _bio,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: FontAwesomeIcons.telegram,
                        label: "TELEGRAM",
                        value: _telegramUsername.isEmpty ? "Not set" : "@$_telegramUsername",
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: Icons.verified_user_outlined,
                        label: "ROLE",
                        value: widget.role.toUpperCase(),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: Icons.calendar_today_outlined,
                        label: "EXPIRES",
                        value: widget.expiredDate,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: Icons.history_rounded,
                        label: "TOTAL LOGIN",
                        value: "$_totalLogin times",
                      ),
                      const SizedBox(height: 20),
                      _buildChangePasswordButton(),
                      const SizedBox(height: 16),
                      _buildFooter(),
                    ],
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
  // UI COMPONENTS
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
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
        child: Text(
          "PROFILE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'ShareTechMono',
            letterSpacing: 2,
          ),
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
        onPressed: () => Navigator.pop(context, true),
      ),
      actions: [
        GestureDetector(
          onTap: _showEditDialog,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kDeathRed, kDeathRedDark],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [
            kDeathRed.withOpacity(0.08),
            kDeathDarkBg,
            kDeathDarkBg,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildDecorations() {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _ProfileGridPainter(accentColor: kDeathRed),
        ),
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [kDeathRed.withOpacity(0.08), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [kDeathGold.withOpacity(0.04), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [kDeathRed, kDeathGold, kDeathRed],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: kDeathGold.withOpacity(0.15),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: ClipOval(
                child: _profileImage != null
                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                    : Center(
                        child: FaIcon(
                          FontAwesomeIcons.userAstronaut,
                          size: 48,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kDeathRed, kDeathRedDark],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: kDeathDarkBg, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: kDeathRed.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsername() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [kDeathRed, kDeathGold],
      ).createShader(bounds),
      child: Text(
        widget.username,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'ShareTechMono',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kDeathRed.withOpacity(0.1), kDeathGold.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDeathRed.withOpacity(0.15)),
      ),
      child: Text(
        widget.role.toUpperCase(),
        style: TextStyle(
          color: kDeathRed,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDeathBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.calendar_today_outlined,
              label: "MEMBER SINCE",
              value: _memberSince,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withOpacity(0.04),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.history_rounded,
              label: "LOGIN",
              value: "$_totalLogin",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kDeathRed.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kDeathRed, size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 7,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required dynamic icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDeathBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kDeathRed, kDeathRedDark],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: icon is FaIconData
                ? FaIcon(icon, color: Colors.white, size: 14)
                : Icon(icon as IconData, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: kDeathRed.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordPage(
                username: widget.username,
                sessionKey: widget.sessionKey,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kDeathRed, kDeathRedDark],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: kDeathRed.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "CHANGE PASSWORD",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 1,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "DEATHTR4SH",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.08),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 1,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kDeathGold, kDeathRed],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'v3.0 · powered by @JustRxVz',
            style: TextStyle(
              color: Colors.white.withOpacity(0.04),
              fontSize: 7,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bioController.dispose();
    _telegramController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _ProfileGridPainter extends CustomPainter {
  final Color accentColor;

  _ProfileGridPainter({required this.accentColor});

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
  bool shouldRepaint(covariant _ProfileGridPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}