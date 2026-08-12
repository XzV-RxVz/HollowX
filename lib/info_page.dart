// DEATHTR4SH V1 GEN 2 - INFO CENTER

import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme_provider.dart';
import 'constants.dart';

class InfoPage extends StatefulWidget {
  final String sessionKey;

  const InfoPage({super.key, required this.sessionKey});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? serverInfo;
  bool isLoading = true;

  bool isApiOnline = false;
  int apiPingMs = 0;
  Color apiStatusColor = kDeathRed;
  String apiStatusText = "Checking...";
  Timer? _pingTimer;
  int _pingAttempts = 0;

  late AnimationController _mainController;
  late AnimationController _glowController;
  late AnimationController _scanController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _glowPulse;
  late Animation<double> _scanLine;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchServerInfo();
    _startApiPingLoop();
    _mainController.forward();
    _glowController.forward();
    _scanController.forward();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _fadeIn = CurvedAnimation(parent: _mainController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic));
    _glowPulse = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _scanLine = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _scanController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _mainController.dispose();
    _glowController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _fetchServerInfo() async {
    try {
      final res = await http.get(
        Uri.parse('http://lalalucuu.alannxd.my.id:3006/getServerInfo?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 && mounted) {
        setState(() {
          serverInfo = jsonDecode(res.body);
          isLoading = false;
        });
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startApiPingLoop() {
    _checkApiPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _checkApiPing();
    });
  }

  Future<void> _checkApiPing() async {
    final start = DateTime.now();
    _pingAttempts++;
    try {
      final res = await http.get(
        Uri.parse('http://lalalucuu.alannxd.my.id:3006/ping?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 3));

      final end = DateTime.now();
      final duration = end.difference(start).inMilliseconds;

      if (res.statusCode == 200 && mounted) {
        setState(() {
          isApiOnline = true;
          apiPingMs = duration;
          if (duration < 200) {
            apiStatusColor = kDeathGreen;
          } else if (duration < 500) {
            apiStatusColor = kDeathGold;
          } else {
            apiStatusColor = kDeathRed;
          }
          apiStatusText = "Online (${duration}ms)";
        });
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isApiOnline = false;
          apiPingMs = 0;
          apiStatusColor = kDeathRed;
          apiStatusText = "Offline";
        });
      }
    }
  }

  // ============================================================
  // CLICKABLE WRAPPER
  // ============================================================
  Widget _clickableWrapper({
    required Widget child,
    required VoidCallback onTap,
    bool haptic = true,
  }) {
    return GestureDetector(
      onTap: () {
        if (haptic) {
          HapticFeedback.lightImpact();
        }
        onTap();
      },
      child: child,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: kDeathDarkBg,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    kDeathRed.withOpacity(0.03),
                    kDeathDarkBg,
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      color: kDeathRed,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LOADING SERVER INFO...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.1),
                      fontSize: 10,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final List<Map<String, String>> rulesList = [
      {"title": "No Account Trading", "desc": "Akun tidak boleh ditukar dengan barang, jasa, atau akun lain."},
      {"title": "No Account Sharing", "desc": "Setiap akun bersifat pribadi dan hanya boleh digunakan oleh pemilik."},
      {"title": "No Account Selling", "desc": "Penjualan akun hanya boleh dilakukan oleh role yang diizinkan."},
      {"title": "No Illegal Duration Selling", "desc": "Dilarang menjual akses harian, mingguan, trial di luar ketentuan."},
      {"title": "No Price Undercutting", "desc": "Dilarang merusak atau menurunkan harga di bawah ketentuan."},
      {"title": "No Spam & Toxic", "desc": "Dilarang spam, toxic, atau konten negatif yang mengganggu."},
    ];

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
                  kDeathRed.withOpacity(0.06),
                  kDeathDarkBg.withOpacity(0.8),
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

          // ===== MAIN CONTENT =====
          SafeArea(
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
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 16),
                        _buildStatusCard(theme),
                        const SizedBox(height: 16),
                        if (serverInfo != null) _buildServerInfoCard(theme),
                        const SizedBox(height: 16),
                        _buildRulesSection(rulesList, theme),
                        const SizedBox(height: 16),
                        _buildSanctionCard(theme),
                        const SizedBox(height: 16),
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
  // HEADER
  // ============================================================
  Widget _buildHeader(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _clickableWrapper(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed.withOpacity(0.1), kDeathRedDark.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kDeathRed.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kDeathRed,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    'INFO CENTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kDeathRed, kDeathRedDark],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'V1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _glowPulse,
            builder: (context, _) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: kDeathRed.withOpacity(0.2 * _glowPulse.value),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.1 * _glowPulse.value),
                    blurRadius: 12,
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
  // STATUS CARD
  // ============================================================
  Widget _buildStatusCard(ThemeProvider theme) {
    return _clickableWrapper(
      onTap: () {
        _checkApiPing();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.refresh_rounded, color: kDeathRed, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Checking server status...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            backgroundColor: kDeathCardBg,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: kDeathRed.withOpacity(0.1)),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
          children: [
            // Scan Line Animation
            Stack(
              children: [
                AnimatedBuilder(
                  animation: _scanLine,
                  builder: (context, _) => Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          kDeathRed.withOpacity(0.05 * _scanLine.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        apiStatusColor.withOpacity(0.1),
                        apiStatusColor.withOpacity(0.02),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: apiStatusColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _glowPulse,
                      builder: (context, _) => Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: apiStatusColor.withOpacity(0.1 * _glowPulse.value),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: apiStatusColor.withOpacity(0.1 * _glowPulse.value),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isApiOnline ? Icons.dns_rounded : Icons.dns_rounded,
                            color: apiStatusColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: apiStatusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: apiStatusColor.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "SERVER STATUS",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [apiStatusColor, apiStatusColor.withOpacity(0.5)],
              ).createShader(bounds),
              child: Text(
                apiStatusText.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, kDeathRed.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security_rounded, size: 10, color: Colors.white.withOpacity(0.1)),
                const SizedBox(width: 4),
                Text(
                  "Protected by DEATHTR4SH Security",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.08),
                    fontSize: 8,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              "Tap to refresh ping",
              style: TextStyle(
                color: Colors.white.withOpacity(0.04),
                fontSize: 7,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SERVER INFO CARD
  // ============================================================
  Widget _buildServerInfoCard(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "SERVER INFO",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kDeathRed.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kDeathRed.withOpacity(0.04)),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: kDeathRed.withOpacity(0.2),
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            label: "SERVER",
            value: serverInfo?['server_name']?.toString() ?? "DEATHTR4SH Node",
            icon: Icons.computer_rounded,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            label: "VERSION",
            value: serverInfo?['version']?.toString() ?? "V1 GEN 2",
            icon: Icons.code_rounded,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            label: "UPTIME",
            value: serverInfo?['uptime']?.toString() ?? "99.9%",
            icon: Icons.timer_rounded,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            label: "USERS",
            value: serverInfo?['total_users']?.toString() ?? "Unknown",
            icon: Icons.people_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: kDeathDarkBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDeathBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kDeathRed.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDeathRed.withOpacity(0.04)),
            ),
            child: Icon(icon, size: 14, color: kDeathRed),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kDeathGold.withOpacity(0.02),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kDeathGold.withOpacity(0.02)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 9,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RULES SECTION
  // ============================================================
  Widget _buildRulesSection(List<Map<String, String>> rulesList, ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDeathBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "RULES & REGULATIONS",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathRedDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${rulesList.length}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rulesList.asMap().entries.map((entry) {
            final index = entry.key;
            final rule = entry.value;
            final isEven = index % 2 == 0;
            return _clickableWrapper(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Rule ${index + 1}: ${rule['title']}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    backgroundColor: kDeathCardBg,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: kDeathRed.withOpacity(0.1)),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isEven ? kDeathDarkBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isEven ? kDeathBorder : Colors.transparent,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kDeathRed.withOpacity(0.1), kDeathRedDark.withOpacity(0.04)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: kDeathRed.withOpacity(0.05),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: kDeathRed.withOpacity(0.2),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
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
                            rule['title']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'ShareTechMono',
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            rule['desc']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.1),
                              fontSize: 8,
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.03),
                      size: 14,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ============================================================
  // SANCTION CARD
  // ============================================================
  Widget _buildSanctionCard(ThemeProvider theme) {
    return _clickableWrapper(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: kDeathCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: kDeathRed.withOpacity(0.2), width: 1),
            ),
            title: Row(
              children: [
                Icon(Icons.gavel_rounded, color: kDeathRed),
                const SizedBox(width: 10),
                Text(
                  "SANCTIONS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kDeathRed.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kDeathRed.withOpacity(0.04)),
                  ),
                  child: Text(
                    "⚠️ Account will be permanently deleted!",
                    style: TextStyle(
                      color: kDeathRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "• No tolerance for violations\n• No refund will be given\n• All data will be erased",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.8,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: kDeathRed.withOpacity(0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: kDeathRed.withOpacity(0.04)),
                  ),
                ),
                child: Text(
                  "UNDERSTOOD",
                  style: TextStyle(
                    color: kDeathRed.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kDeathRed.withOpacity(0.04),
              kDeathRedDark.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: kDeathRed.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kDeathRed.withOpacity(0.04),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kDeathRed.withOpacity(0.04),
                ),
              ),
              child: Icon(Icons.gavel_rounded, color: kDeathRed, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SANCTIONS",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    "Account will be permanently deleted!",
                    style: TextStyle(
                      color: kDeathRed.withOpacity(0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: kDeathRed.withOpacity(0.1),
              size: 14,
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
    return Column(
      children: [
        _clickableWrapper(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "DEATHTR4SH V1 GEN 2",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),
                backgroundColor: kDeathCardBg,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: kDeathRed.withOpacity(0.1)),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(16),
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
                  child: Icon(Icons.info_outline_rounded, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "By using this application, you agree to all rules and terms above.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.08),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      height: 1.4,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kDeathRed, kDeathGold],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "DEATHTR4SH V1 GEN 2",
          style: TextStyle(
            color: Colors.white.withOpacity(0.03),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            fontFamily: 'ShareTechMono',
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}