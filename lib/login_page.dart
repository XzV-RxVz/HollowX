import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

const Color kBgBlack = Color(0xFF07030F);
const Color kDeepPurple = Color(0xFF4C1D95);
const Color kViolet500 = Color(0xFF7C3AED);
const Color kCyanAccent = Color(0xFF4DE8E8);
const Color kCardBg = Color(0xFF0A0018);

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
              color: kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isError ? kDeepPurple.withOpacity(0.4) : kCyanAccent.withOpacity(0.2),
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
                    color: isError ? kDeepPurple.withOpacity(0.2) : kCyanAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.error_outline : Icons.info_outline,
                    color: isError ? kViolet500 : kCyanAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
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
                    fontFamily: 'Rajdhani',
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
                              border: Border.all(color: kViolet500.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "Contact",
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  color: kViolet500,
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
                            color: kViolet500,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              "Close",
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
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
      backgroundColor: kBgBlack,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, -0.3),
                  radius: 1.2,
                  colors: [
                    kDeepPurple.withOpacity(0.8),
                    kBgBlack,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
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
                      Image.asset(
                        'assets/images/TitleX.png',
                        width: MediaQuery.of(context).size.width * 0.9,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      SlideTransition(
                        position: _slideAnim,
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    'assets/images/BannerX.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
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
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildButton(),
                      const SizedBox(height: 32),
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
                                  "Powered By @JustRxVz - @alannxd",
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
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
                              "HOLLOW EXECUTION v14",
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
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
            fontFamily: 'Rajdhani',
            color: Colors.white.withOpacity(0.4),
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
              color: kDeepPurple.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                icon,
                color: kCyanAccent.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  obscureText: isPassword ? _obscurePassword : false,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter $label",
                    hintStyle: TextStyle(
                      fontFamily: 'Rajdhani',
                      color: Colors.white.withOpacity(0.2),
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
                              color: Colors.white.withOpacity(0.2),
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
              colors: [kDeepPurple, kViolet500, kCyanAccent],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kViolet500.withOpacity(0.3),
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
                    "LOGIN",
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kViolet500.withOpacity(0.08)
      ..strokeWidth = 1;

    const double gridSize = 60;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}