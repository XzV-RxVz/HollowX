// login_page.dart
// DEATHTR4SH - Neon Elegant Login (No Logo)

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;
  
  File? _profileImage;
  String? _lastUsername;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  // Elegant DEATHTR4SH Colors
  static const Color _primaryRed = Color(0xFFDC143C);
  static const Color _accentRed = Color(0xFFFF1744);
  static const Color _goldAccent = Color(0xFFFFD700);
  static const Color _darkBg = Color(0xFF000000);
  static const Color _cardBg = Color(0xFF0A0000);

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _initAnim();
    initLogin();
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString("username");
    
    if (savedUsername != null && savedUsername.isNotEmpty) {
      _lastUsername = savedUsername;
      final imagePath = prefs.getString('profile_image_$savedUsername');
      if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
        setState(() {
          _profileImage = File(imagePath);
        });
      }
    }
    
    if (_profileImage == null) {
      final defaultImagePath = prefs.getString('profile_image_default');
      if (defaultImagePath != null && defaultImagePath.isNotEmpty && File(defaultImagePath).existsSync()) {
        setState(() {
          _profileImage = File(defaultImagePath);
        });
      }
    }
  }

  void _initAnim() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
          "http://lalalucuu.alannxd.my.id:3012/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");
      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);
        if (data['valid'] == true && mounted) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username: savedUser,
                password: savedPass,
                role: data['role'],
                sessionKey: data['key'],
                expiredDate: data['expiredDate'],
                listBug: (data['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (data['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("http://lalalucuu.alannxd.my.id:3012/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        if (mounted) {
          _showPopup(
            title: "Access Expired",
            message: "Your access has expired. Please renew.",
            showContact: true,
            isError: true,
          );
        }
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? "").toLowerCase();
        if (errorMsg.contains("perangkat") ||
            errorMsg.contains("device") ||
            errorMsg.contains("another")) {
          if (mounted) {
            _showPopup(
              title: "Active Session",
              message: "Account is logged in on another device.",
              isError: true,
            );
          }
        } else {
          if (mounted) {
            _showPopup(
              title: "Login Failed",
              message: "Invalid username or password.",
              isError: true,
            );
          }
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username: username,
                password: password,
                role: validData['role'],
                sessionKey: validData['key'],
                expiredDate: validData['expiredDate'],
                listBug: (validData['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (validData['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showPopup(
          title: "Connection Error",
          message: "Failed to connect to server.",
          isError: true,
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _showPopup({
    required String title,
    required String message,
    bool showContact = false,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0.9, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, double scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isError ? _primaryRed.withOpacity(0.2) : _goldAccent.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isError ? _primaryRed.withOpacity(0.1) : _goldAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.error_outline : Icons.info_outline,
                    color: isError ? _primaryRed : _goldAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (showContact)
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await launchUrl(Uri.parse("https://t.me/JustRxVz"),
                                mode: LaunchMode.externalApplication);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: _primaryRed.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "Contact",
                                style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  color: _primaryRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (showContact) const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _primaryRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              "Close",
                              style: TextStyle(
                                fontFamily: 'ShareTechMono',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
  void dispose() {
    _controller.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // ===== BACKGROUND HITAM POLOS =====
          Container(
            color: _darkBg,
          ),
          
          // ===== GLOW ORBS (SEDIKIT) =====
          Positioned(
            top: -150,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primaryRed.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentRed.withOpacity(0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // ===== MAIN CONTENT =====
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ===== APP NAME - NEON EFFECT =====
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnim.value,
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  _primaryRed,
                                  _goldAccent,
                                  _accentRed,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(bounds),
                              child: Text(
                                "DEATHTR4SH",
                                style: TextStyle(
                                  fontFamily: 'FontX',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 30,
                                      color: _primaryRed.withOpacity(0.6),
                                    ),
                                    Shadow(
                                      blurRadius: 60,
                                      color: _primaryRed.withOpacity(0.3),
                                    ),
                                    Shadow(
                                      blurRadius: 80,
                                      color: _goldAccent.withOpacity(0.15),
                                    ),
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // ===== SUBTITLE - NEON =====
                      Text(
                        "THE NEW GENERATION",
                        style: TextStyle(
                          fontFamily: 'FontX',
                          color: _primaryRed.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(
                              blurRadius: 15,
                              color: _primaryRed.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // ===== CREDIT =====
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: _primaryRed.withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "New Era DeathTr4sh",
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            color: Colors.white.withOpacity(0.15),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      // ===== FORM CARD =====
                      SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _cardBg.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _primaryRed.withOpacity(0.12),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.03),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildInput(
                                  userController,
                                  "Username",
                                  Icons.person_outline,
                                  false,
                                ),
                                const SizedBox(height: 20),
                                _buildInput(
                                  passController,
                                  "Password",
                                  Icons.lock_outline,
                                  true,
                                ),
                                const SizedBox(height: 32),
                                _buildButton(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ===== FOOTER =====
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 30,
                                  height: 1,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "SECURE",
                                  style: TextStyle(
                                    fontFamily: 'ShareTechMono',
                                    color: Colors.white.withOpacity(0.06),
                                    fontSize: 8,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 30,
                                  height: 1,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "DEATHTR4SH v1",
                              style: TextStyle(
                                fontFamily: 'FontX',
                                color: Colors.white.withOpacity(0.03),
                                fontSize: 8,
                                letterSpacing: 2,
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
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isPassword,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            color: Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryRed.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                icon,
                color: _primaryRed.withOpacity(0.4),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  obscureText: isPassword ? _obscurePassword : false,
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter $label",
                    hintStyle: TextStyle(
                      fontFamily: 'ShareTechMono',
                      color: Colors.white.withOpacity(0.1),
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: isPassword
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withOpacity(0.15),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "$label required";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: GestureDetector(
        onTap: isLoading ? null : login,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _accentRed],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _primaryRed.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  )
                : Text(
                    "Login",
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}