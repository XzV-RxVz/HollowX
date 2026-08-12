// DEATHTR4SH V1 GEN 2 - ZHERO PAGE

import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'home_page.dart';
import 'bug_group.dart';
import 'theme_provider.dart';
import 'constants.dart';

class zheroPege extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String role;
  final String expiredDate;
  final List<Map<String, dynamic>> listBug;

  const zheroPege({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.role,
    required this.expiredDate,
    required this.listBug,
  });

  @override
  State<zheroPege> createState() => _zheroPegeState();
}

class _zheroPegeState extends State<zheroPege> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulseAnimation;

  int _featureIndex = 0;
  final PageController _featureCtrl = PageController(viewportFraction: 0.88);
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    _featureCtrl.addListener(() {
      final p = _featureCtrl.page?.round() ?? 0;
      if (p != _featureIndex) setState(() => _featureIndex = p);
    });

    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

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
    _featureCtrl.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: kDeathDarkBg,
      body: Stack(
        children: [
          // ===== BACKGROUND =====
          Container(
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
          ),
          Positioned(
            top: -100,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kDeathRed.withOpacity(0.04),
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
                      kDeathGold.withOpacity(0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== GRID =====
          Positioned.fill(
            child: IgnorePointer(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.transparent],
                  stops: [0.0, 0.5],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: CustomPaint(
                  painter: _GridPainter(accentColor: kDeathRed),
                  child: Container(),
                ),
              ),
            ),
          ),

          // ===== MAIN CONTENT =====
          FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scaleIn,
              child: SlideTransition(
                position: _slideUp,
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildTerminalBar(theme),
                        const SizedBox(height: 16),
                        _buildStatusCard(theme),
                        const SizedBox(height: 18),
                        _buildTabs(theme),
                        const SizedBox(height: 16),
                        if (_tabIndex == 0) _buildNewsSection(theme),
                        if (_tabIndex == 1) _buildFeatureSection(theme),
                        const SizedBox(height: 20),
                        _buildFooter(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TERMINAL BAR
  // ============================================================
  Widget _buildTerminalBar(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kDeathCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDeathBorder),
        ),
        child: Row(
          children: [
            _termDot(kDeathRed),
            const SizedBox(width: 5),
            _termDot(kDeathGold),
            const SizedBox(width: 5),
            _termDot(kDeathGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "~/deathtrash/bugs/whatsapp_module",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.1),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                final blink = (_scanController.value * 2).floor().isEven;
                return Opacity(
                  opacity: blink ? 1 : 0,
                  child: Text(
                    "█",
                    style: TextStyle(
                      color: kDeathRed,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _termDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================
  Widget _buildStatusCard(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: kDeathCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kDeathBorder),
          boxShadow: [
            BoxShadow(
              color: kDeathRed.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  return Positioned(
                    top: 0,
                    left: -100 + (MediaQuery.of(context).size.width + 100) * _scanController.value,
                    child: Container(
                      width: 100,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            kDeathRed.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kDeathRed.withOpacity(0.1), kDeathRedDark.withOpacity(0.05)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kDeathRed.withOpacity(0.1)),
                          ),
                          child: Icon(Icons.bug_report_rounded, color: kDeathRed, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ACTIVE MODULE",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.1),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'ShareTechMono',
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "DEATHTR4SH Engine",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'ShareTechMono',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, _) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kDeathGreen.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: kDeathGreen.withOpacity(0.1 * _pulseAnimation.value),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: kDeathGreen.withOpacity(0.3 * _pulseAnimation.value),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: kDeathGreen.withOpacity(0.1 * _pulseAnimation.value),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "LIVE",
                                  style: TextStyle(
                                    color: kDeathGreen.withOpacity(0.2 * _pulseAnimation.value),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'ShareTechMono',
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _miniStat(theme, "2", "FEATURES"),
                        const SizedBox(width: 10),
                        _miniStat(theme, "8", "UPDATES"),
                        const SizedBox(width: 10),
                        _miniStat(theme, "100%", "ENGINE"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(ThemeProvider theme, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: kDeathDarkBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kDeathBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: kDeathRed,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'ShareTechMono',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.06),
                fontSize: 7,
                fontWeight: FontWeight.w700,
                fontFamily: 'ShareTechMono',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================
  Widget _buildTabs(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kDeathCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDeathBorder),
        ),
        child: Row(
          children: [
            _tabItem(theme, 0, "NEWS"),
            _tabItem(theme, 1, "MODULES"),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(ThemeProvider theme, int index, String label) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: [kDeathRed, kDeathRedDark])
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: kDeathRed.withOpacity(0.2), blurRadius: 12)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.white.withOpacity(0.06),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: active ? 'ShareTechMono' : 'ShareTechMono',
              letterSpacing: active ? 1 : 0,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NEWS SECTION
  // ============================================================
  Widget _buildNewsSection(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, "RECENT LOGS"),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _logCard(
                theme,
                tag: "UPDATE",
                tagColor: kDeathRed,
                title: "New Update Func",
                desc: "New Func Delay, New Blank UI, New Freeze, New Delay Hard",
              ),
              const SizedBox(height: 10),
              _logCard(
                theme,
                tag: "BUG",
                tagColor: kDeathGold,
                title: "New Bug",
                desc: "Module Bug WhatsApp Ready, pengoptimalan bug group & contact.",
              ),
              const SizedBox(height: 10),
              _logCard(
                theme,
                tag: "PATCH",
                tagColor: kDeathGreen,
                title: "New Patch",
                desc: "Fix error, stability update, fix undelivered bug issue.",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(ThemeProvider theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            "//",
            style: TextStyle(
              color: kDeathRed.withOpacity(0.1),
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.06),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'ShareTechMono',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logCard(ThemeProvider theme, {
    required String tag,
    required Color tagColor,
    required String title,
    required String desc,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(
          left: BorderSide(color: tagColor, width: 3),
          top: BorderSide(color: kDeathBorder),
          right: BorderSide(color: kDeathBorder),
          bottom: BorderSide(color: kDeathBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: tagColor.withOpacity(0.2),
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              color: Colors.white.withOpacity(0.06),
              fontSize: 10,
              fontFamily: 'ShareTechMono',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURE SECTION
  // ============================================================
  Widget _buildFeatureSection(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, "MODULES"),
        const SizedBox(height: 10),
        SizedBox(
          height: 230,
          child: PageView(
            controller: _featureCtrl,
            physics: const BouncingScrollPhysics(),
            children: [
              _featureCard(
                theme,
                icon: FontAwesomeIcons.whatsapp,
                title: 'Bug Contact',
                subtitle: 'whatsapp_number_attack.sh',
                accentColor: const Color(0xFF25D366),
                tags: const ['Fresh Function', 'New Menu', 'Tested by Creator'],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomePage(
                      username: widget.username,
                      password: widget.password,
                      sessionKey: widget.sessionKey,
                      listBug: widget.listBug,
                      role: widget.role,
                      expiredDate: widget.expiredDate,
                    ),
                  ),
                ),
              ),
              _featureCard(
                theme,
                icon: Icons.group_rounded,
                title: 'Bug Group',
                subtitle: 'whatsapp_group_attack.sh',
                accentColor: kDeathGold,
                tags: const ['Crash Group', 'New Function', '100% Work'],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupBugPage(
                      username: widget.username,
                      password: widget.password,
                      sessionKey: widget.sessionKey,
                      role: widget.role,
                      expiredDate: widget.expiredDate,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) {
            final active = i == _featureIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(colors: [kDeathRed, kDeathGold])
                    : null,
                color: active ? null : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _featureCard(
    ThemeProvider theme, {
    required dynamic icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required List<String> tags,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kDeathCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kDeathBorder),
          boxShadow: [
            BoxShadow(
              color: kDeathRed.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Center(
                    child: icon is FaIconData
                        ? FaIcon(icon, color: Colors.white, size: 20)
                        : Icon(icon as IconData, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'ShareTechMono',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.06),
                          fontSize: 9,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withOpacity(0.04)),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    color: accentColor.withOpacity(0.2),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              )).toList(),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor.withOpacity(0.04 * _pulseAnimation.value), accentColor.withOpacity(0.02)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.04 * _pulseAnimation.value),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: accentColor.withOpacity(0.2), size: 15),
                    const SizedBox(width: 4),
                    Text(
                      "EXECUTE MODULE",
                      style: TextStyle(
                        color: accentColor.withOpacity(0.2),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'ShareTechMono',
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
  // FOOTER
  // ============================================================
  Widget _buildFooter(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  kDeathRed.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [kDeathRed, kDeathGold],
            ).createShader(bounds),
            child: Text(
              'DEATHTR4SH V1 GEN 2',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'FontX',
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '// powered by @JustRxVz',
            style: TextStyle(
              color: Colors.white.withOpacity(0.02),
              fontSize: 8,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
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