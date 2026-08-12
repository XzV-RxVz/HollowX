import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';
import 'bug_group.dart';
import 'theme_provider.dart';

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
  // Animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Popup contact & warning
  bool _showContactPopup = false;
  bool _showWarningToast = false;
  late AnimationController _popupCtrl;
  late Animation<double> _popupScale;
  late Animation<double> _popupFade;

  // Feature
  int _featureIndex = 0;
  final PageController _featureCtrl = PageController(viewportFraction: 0.88);

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // Popup animations
    _popupCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _popupScale = CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOutBack);
    _popupFade = CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOut);

    _featureCtrl.addListener(() {
      final p = _featureCtrl.page?.round() ?? 0;
      if (p != _featureIndex) setState(() => _featureIndex = p);
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  void _openContact() {
    setState(() => _showContactPopup = true);
    _popupCtrl.forward(from: 0);
  }

  void _closeContact() async {
    await _popupCtrl.reverse();
    if (mounted) setState(() => _showContactPopup = false);
  }

  void _triggerWarning() async {
    setState(() => _showWarningToast = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _showWarningToast = false);
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _popupCtrl.dispose();
    _featureCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      // Tidak menggunakan backgroundColor agar gradient muncul penuh
      body: _buildBackground(
        theme,
        Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      _buildNewsSection(theme),
                      const SizedBox(height: 28),
                      _buildFeatureSection(theme),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildFooter(theme),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ BACKGROUND ============
  Widget _buildBackground(ThemeProvider theme, Widget child) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [
            theme.primaryColor.withOpacity(0.15),
            theme.backgroundColor,
            theme.backgroundColor,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(accentColor: theme.primaryColor),
        child: child,
      ),
    );
  }

  // ============ NEWS SECTION  ============
  Widget _buildNewsSection(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _fireIcon(theme),
              const SizedBox(width: 9),
              Text('XZHERO BUG ( LATEST NEWS )', style: TextStyle(color: theme.textPrimaryColor, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _newsCard(theme, icon: Icons.code_rounded, title: 'New Update Func !!', items: const ['New Func Delay', 'New Crash UI', 'New Crash X Delay', 'New Delay Hard', 'New Crash Home']),
              const SizedBox(width: 14),
              _newsCard(theme, icon: FontAwesomeIcons.bug, title: 'New Bug', items: const ['Bug Command Ready', 'Pengoptimalan Bug Group', 'Pengoptimalan Bug Basic']),
              const SizedBox(width: 14),
              _newsCard(theme, icon: Icons.bolt_rounded, title: 'Hot Patch', items: const ['Fix Crash Report', 'Stability Update', 'Speed Boost x2']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fireIcon(ThemeProvider theme) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.local_fire_department, color: theme.primaryColor.withOpacity(0.7), size: 26),
          Icon(Icons.local_fire_department, color: theme.accentColor.withOpacity(0.8), size: 20),
          Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 13),
        ],
      ),
    );
  }

  Widget _newsCard(ThemeProvider theme, {required IconData icon, required String title, required List<String> items}) {
    return Container(
      width: 252,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.primaryColor.withOpacity(0.2), theme.glassPrimary]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 0.8),
        boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8)), BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(top: -24, left: -24, child: Container(width: 76, height: 76, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
            Positioned(bottom: -30, right: -30, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: theme.primaryColor, size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(title, style: TextStyle(color: theme.textPrimaryColor, fontSize: 13, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: theme.primaryColor.withOpacity(0.6), size: 13),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item, style: TextStyle(color: theme.textSecondaryColor, fontSize: 11))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ FEATURE SECTION ============
  Widget _buildFeatureSection(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.widgets_rounded, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text('BUG FEATURE', style: TextStyle(color: theme.textPrimaryColor, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: theme.accentColor, borderRadius: BorderRadius.circular(6)), child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 232,
          child: PageView(
            controller: _featureCtrl,
            physics: const BouncingScrollPhysics(),
            children: [
              _featureCard(theme, icon: FontAwesomeIcons.whatsapp, title: 'BUG NUMBER', items: const ['Func Terbaru', 'Crash UI New', 'Mudah Dan Praktis', 'Sudah Diuji Oleh Developer'], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage(username: widget.username, password: widget.password, sessionKey: widget.sessionKey, listBug: widget.listBug, role: widget.role, expiredDate: widget.expiredDate)))),
              _featureCard(theme, icon: Icons.group_rounded, title: 'BUG GROUP', items: const ['Crash Group WA', 'Flood Group Log', 'Group Freeze', 'Mass Spam'], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupBugPage(username: widget.username, password: widget.password, sessionKey: widget.sessionKey, role: widget.role, expiredDate: widget.expiredDate)))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) {
            final active = i == _featureIndex;
            return AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 4), width: active ? 22 : 7, height: 7, decoration: BoxDecoration(color: active ? theme.primaryColor : theme.textSecondaryColor.withOpacity(0.3), borderRadius: BorderRadius.circular(4)));
          }),
        ),
      ],
    );
  }

  Widget _featureCard(ThemeProvider theme, {required IconData icon, required String title, required List<String> items, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.glassPrimary, theme.glassSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 1.2),
          boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: 1), BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(4, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(top: -22, left: -22, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
              Positioned(bottom: -32, right: -32, child: Container(width: 105, height: 105, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
              Padding(
                padding: const EdgeInsets.all(19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 1)), child: Icon(icon, color: theme.primaryColor, size: 21)),
                        const SizedBox(width: 13),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: TextStyle(color: theme.primaryColor, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                            Text('Tap to launch', style: TextStyle(color: theme.textSecondaryColor.withOpacity(0.6), fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: theme.primaryColor.withOpacity(0.7), size: 13),
                              const SizedBox(width: 9),
                              Text(item, style: TextStyle(color: theme.textSecondaryColor, fontSize: 11.5)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ FOOTER ============
  Widget _buildFooter(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.glassPrimary, theme.glassSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 0.8),
        boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.15), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Text('By: Xzhero Team', style: TextStyle(color: theme.textPrimaryColor, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
          const SizedBox(height: 5),
          Text('Powered by the best team in the universe.', style: TextStyle(color: theme.textSecondaryColor.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }
}

// ============ GRID PAINTER  ============
class _GridPainter extends CustomPainter {
  final Color accentColor;
  _GridPainter({required this.accentColor});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 0.8..style = PaintingStyle.stroke;
    const gridSize = 30.0;
    for (double x = 0; x <= size.width; x += gridSize) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y <= size.height; y += gridSize) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    final accentPaint = Paint()..color = accentColor.withOpacity(0.08)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    for (double x = 0; x <= size.width; x += gridSize * 5) canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    for (double y = 0; y <= size.height; y += gridSize * 5) canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
  }
  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.accentColor != accentColor;
}