// change_password_page.dart
// DEATHTRASH - SECURITY CENTER (RED & GOLD EDITION)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';

class ChangePasswordPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const ChangePasswordPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with TickerProviderStateMixin {
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  late AnimationController _mainAnimCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _formAnim;

  // Password strength variables
  String _passwordStrength = '';
  double _strengthPercent = 0.0;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _mainAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _mainAnimCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimCtrl, curve: Curves.easeOutCubic),
    );
    _formAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimCtrl, curve: Curves.easeOutBack),
    );

    newPassCtrl.addListener(_checkPasswordStrength);
    confirmPassCtrl.addListener(_checkPasswordMatch);
  }

  void _checkPasswordStrength() {
    final password = newPassCtrl.text;
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _strengthPercent = 0.0;
      });
      return;
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    double percent = (score / 6) * 100;
    String strength;
    if (percent < 30) strength = 'WEAK';
    else if (percent < 60) strength = 'FAIR';
    else if (percent < 85) strength = 'GOOD';
    else strength = 'STRONG';

    setState(() {
      _strengthPercent = percent;
      _passwordStrength = strength;
    });
  }

  void _checkPasswordMatch() {
    final newPass = newPassCtrl.text;
    final confirmPass = confirmPassCtrl.text;
    setState(() {
      _passwordsMatch = confirmPass.isNotEmpty && newPass == confirmPass;
    });
  }

  Color _getStrengthColor() {
    if (_strengthPercent < 30) return kDeathRed;
    if (_strengthPercent < 60) return kDeathGold;
    if (_strengthPercent < 85) return kDeathGreen;
    return kDeathGreen;
  }

  @override
  void dispose() {
    _mainAnimCtrl.dispose();
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    newPassCtrl.removeListener(_checkPasswordStrength);
    confirmPassCtrl.removeListener(_checkPasswordMatch);
    super.dispose();
  }

  // ============================================================
  // API
  // ============================================================
  Future<void> _changePassword() async {
    final oldPass = oldPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("All fields are required.", isSuccess: false);
      return;
    }
    if (newPass != confirmPass) {
      _showMessage("New password doesn't match confirmation.", isSuccess: false);
      return;
    }
    if (_strengthPercent < 30 && newPass.isNotEmpty) {
      _showMessage("Password is too weak. Use stronger combination.", isSuccess: false);
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("http://lalalucuu.alannxd.my.id:3006/changepass"),
        body: {
          "username": widget.username,
          "oldPass": oldPass,
          "newPass": newPass,
          "sessionKey": widget.sessionKey,
        },
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _showMessage("Password updated successfully!", isSuccess: true);
        oldPassCtrl.clear();
        newPassCtrl.clear();
        confirmPassCtrl.clear();
        _passwordStrength = '';
        _strengthPercent = 0.0;
        _passwordsMatch = false;
      } else {
        _showMessage(data['message'] ?? "Failed to update password", isSuccess: false);
      }
    } catch (e) {
      _showMessage("Connection error: $e", isSuccess: false);
    }
    setState(() => isLoading = false);
  }

  // ============================================================
  // DIALOG - DEATHTRASH THEME
  // ============================================================
  void _showMessage(String msg, {required bool isSuccess}) {
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
                colors: [kDeathDarkBg, kDeathCardBg],
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
                  blurRadius: 30,
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
                const SizedBox(height: 14),
                Text(
                  isSuccess ? "SUCCESS!" : "ERROR",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'FontX',
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  msg,
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
                    height: 44,
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
                    child: Center(
                      child: Text(
                        "CLOSE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'FontX',
                          letterSpacing: 2,
                        ),
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
  // INPUT FIELD - DEATHTRASH THEME
  // ============================================================
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText != null ? kDeathRed.withOpacity(0.3) : kDeathBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: errorText != null ? kDeathRed.withOpacity(0.5) : Colors.white.withOpacity(0.15),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(icon, color: kDeathRed, size: 18),
              ),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white.withOpacity(0.15),
                    size: 18,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: kDeathRed, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    errorText,
                    style: TextStyle(
                      color: kDeathRed,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STRENGTH METER - DEATHTRASH THEME
  // ============================================================
  Widget _buildStrengthMeter() {
    if (newPassCtrl.text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStrengthColor(),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "Strength: $_passwordStrength",
                style: TextStyle(
                  color: _getStrengthColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _strengthPercent / 100,
              backgroundColor: kDeathCardBg.withOpacity(0.3),
              color: _getStrengthColor(),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MATCH INDICATOR
  // ============================================================
  Widget _buildMatchIndicator() {
    if (confirmPassCtrl.text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            _passwordsMatch ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: _passwordsMatch ? kDeathGreen : kDeathRed,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _passwordsMatch ? "Password match" : "Password doesn't match",
            style: TextStyle(
              color: _passwordsMatch ? kDeathGreen : kDeathRed,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECURITY TIPS - DEATHTRASH THEME
  // ============================================================
  Widget _buildSecurityTips() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDeathBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathRedDark],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 10),
              ),
              const SizedBox(width: 6),
              Text(
                "SECURITY REQUIREMENTS",
                style: TextStyle(
                  color: kDeathRed,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTip("Min 8 characters", newPassCtrl.text.length >= 8),
          _buildTip("Uppercase (A-Z)", newPassCtrl.text.contains(RegExp(r'[A-Z]'))),
          _buildTip("Lowercase (a-z)", newPassCtrl.text.contains(RegExp(r'[a-z]'))),
          _buildTip("Number (0-9)", newPassCtrl.text.contains(RegExp(r'[0-9]'))),
          _buildTip("Symbol (!@#...)", newPassCtrl.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
        ],
      ),
    );
  }

  Widget _buildTip(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isMet ? kDeathGreen : Colors.white.withOpacity(0.05),
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.15),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR - DEATHTRASH THEME
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kDeathCardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kDeathBorder),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kDeathRed,
            size: 16,
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        child: Text(
          "SECURITY",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            fontFamily: 'FontX',
            letterSpacing: 2,
          ),
        ),
      ),
      actions: const [SizedBox(width: 12)],
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
          // ===== BACKGROUND =====
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
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),

          // ===== GLOW ORBS =====
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kDeathRed.withOpacity(0.06), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kDeathGold.withOpacity(0.04), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ===== GRID =====
          CustomPaint(
            size: Size.infinite,
            painter: _PassGridPainter(accentColor: kDeathRed),
          ),

          // ===== MAIN CONTENT =====
          FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // ===== HERO ICON =====
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kDeathRed, kDeathRedDark],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kDeathRed.withOpacity(0.3),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== TITLE =====
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [kDeathRed, kDeathGold],
                      ).createShader(bounds),
                      child: Text(
                        "SECURITY CENTER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'FontX',
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Update password for @${widget.username}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.15),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== FORM CARD =====
                    ScaleTransition(
                      scale: _formAnim,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kDeathCardBg.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kDeathBorder),
                          boxShadow: [
                            BoxShadow(
                              color: kDeathRed.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card header
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [kDeathRed, kDeathRedDark],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kDeathRed.withOpacity(0.15),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.key_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "UPDATE PASSWORD",
                                  style: TextStyle(
                                    color: kDeathRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'FontX',
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              height: 1,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    kDeathRed.withOpacity(0.08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            // Inputs
                            _buildInput(
                              controller: oldPassCtrl,
                              label: "CURRENT PASSWORD",
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscureOld,
                              onToggle: () => setState(() => _obscureOld = !_obscureOld),
                            ),

                            _buildInput(
                              controller: newPassCtrl,
                              label: "NEW PASSWORD",
                              icon: Icons.vpn_key_rounded,
                              obscure: _obscureNew,
                              onToggle: () => setState(() => _obscureNew = !_obscureNew),
                            ),

                            _buildStrengthMeter(),

                            _buildInput(
                              controller: confirmPassCtrl,
                              label: "CONFIRM PASSWORD",
                              icon: Icons.enhanced_encryption_rounded,
                              obscure: _obscureConfirm,
                              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              errorText: (!_passwordsMatch && confirmPassCtrl.text.isNotEmpty)
                                  ? "Password doesn't match"
                                  : null,
                            ),

                            _buildMatchIndicator(),
                            _buildSecurityTips(),

                            const SizedBox(height: 12),

                            // Submit button
                            GestureDetector(
                              onTap: isLoading ? null : _changePassword,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: isLoading
                                      ? LinearGradient(
                                          colors: [kDeathCardBg, kDeathBorder],
                                        )
                                      : LinearGradient(
                                          colors: [kDeathRed, kDeathRedDark],
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isLoading
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: kDeathRed.withOpacity(0.3),
                                            blurRadius: 16,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: isLoading
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.lock_reset_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "UPDATE",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'FontX',
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Footer
                    Text(
                      "DEATHTRASH · SECURITY v3.0",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.04),
                        fontSize: 9,
                        fontFamily: 'FontX',
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
// GRID PAINTER
// ============================================================
class _PassGridPainter extends CustomPainter {
  final Color accentColor;

  _PassGridPainter({required this.accentColor});

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