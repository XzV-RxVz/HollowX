// contact_page.dart
// DEATHTRASH - SUPPORT CENTER (RED & GOLD EDITION)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'constants.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;

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
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 250,
                height: 250,
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
            bottom: 50,
            left: -50,
            child: IgnorePointer(
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
          ),

          // ===== GRID =====
          CustomPaint(
            size: Size.infinite,
            painter: _ContactGridPainter(accentColor: kDeathRed),
          ),

          // ===== MAIN CONTENT =====
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Custom AppBar
                  _buildCustomAppBar(context),
                  const SizedBox(height: 16),

                  // Hero Icon
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (ctx, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(scale: value, child: child),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kDeathRed, kDeathRedDark],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [kDeathRed, kDeathGold],
                    ).createShader(bounds),
                    child: Text(
                      "SUPPORT CENTER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'FontX',
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Connect with us through our social platforms",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Contact Cards
                  Column(
                    children: [
                      _buildContactCard(
                        label: "TELEGRAM",
                        icon: FontAwesomeIcons.telegram,
                        color: const Color(0xFF0088cc),
                        username: "@JustRxVz",
                        url: "https://t.me/JustRxVz",
                        delay: 0,
                      ),
                      const SizedBox(height: 12),
                      _buildContactCard(
                        label: "WHATSAPP",
                        icon: FontAwesomeIcons.whatsapp,
                        color: const Color(0xFF25D366),
                        username: "+6289675523385",
                        url: "https://wa.me/6289675523385",
                        delay: 100,
                      ),
                      const SizedBox(height: 12),
                      _buildContactCard(
                        label: "TIKTOK",
                        icon: FontAwesomeIcons.tiktok,
                        color: Colors.white,
                        username: "@therxvz",
                        url: "https://www.tiktok.com/@therxvz",
                        delay: 200,
                      ),
                      const SizedBox(height: 12),
                      _buildContactCard(
                        label: "INSTAGRAM",
                        icon: FontAwesomeIcons.instagram,
                        color: const Color(0xFFE4405F),
                        username: "tidak tersedia",
                        url: "tidak tersedia",
                        delay: 300,
                        isDisabled: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kDeathRed, kDeathGold],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "DEATHTRASH · SUPPORT",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.04),
                            fontSize: 9,
                            fontFamily: 'FontX',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR - DEATHTRASH THEME
  // ============================================================
  Widget _buildCustomAppBar(BuildContext context) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
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
        const Spacer(),
        // Title badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kDeathRed, kDeathRedDark],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: kDeathRed.withOpacity(0.2),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            "CONTACT",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 2,
            ),
          ),
        ),
        const Spacer(),
        // Placeholder for symmetry
        const SizedBox(width: 38),
      ],
    );
  }

  // ============================================================
  // CONTACT CARD - DEATHTRASH THEME
  // ============================================================
  Widget _buildContactCard({
    required String label,
    required FaIconData icon,
    required Color color,
    required String username,
    required String url,
    required int delay,
    bool isDisabled = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: isDisabled ? null : () => _launchUrl(url),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kDeathCardBg.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDisabled ? kDeathBorder : kDeathRed.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: kDeathRed.withOpacity(0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDisabled ? kDeathCardBg.withOpacity(0.3) : color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDisabled ? kDeathBorder : color.withOpacity(0.08),
                  ),
                ),
                child: FaIcon(
                  icon,
                  color: isDisabled ? Colors.white.withOpacity(0.05) : color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDisabled ? Colors.white.withOpacity(0.1) : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'FontX',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      style: TextStyle(
                        color: isDisabled ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isDisabled
                      ? LinearGradient(
                          colors: [kDeathCardBg, kDeathBorder],
                        )
                      : LinearGradient(
                          colors: [kDeathRed, kDeathRedDark],
                        ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isDisabled
                      ? []
                      : [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                ),
                child: Icon(
                  isDisabled ? Icons.block_rounded : Icons.arrow_forward_ios_rounded,
                  color: isDisabled ? Colors.white.withOpacity(0.05) : Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _ContactGridPainter extends CustomPainter {
  final Color accentColor;

  _ContactGridPainter({required this.accentColor});

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