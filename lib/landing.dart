import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Stage { splash, welcome }

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  _Stage _stage = _Stage.splash;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goToWelcome() {
    if (mounted) setState(() => _stage = _Stage.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _stage == _Stage.splash
            ? _SplashStage(key: const ValueKey('splash'), onDone: _goToWelcome)
            : const _WelcomeStage(key: ValueKey('welcome')),
      ),
    );
  }
}

// ============================================================
// THEME COLORS - HOLLOW EXECUTION (DEEP VIOLET & CYAN)
// ============================================================
class HollowExecutionTheme {
  static const Color bgBlack = Color(0xFF07030F);
  static const Color deepPurple = Color(0xFF4C1D95);
  static const Color violet700 = Color(0xFF3B1A6E);
  static const Color violet500 = Color(0xFF7C3AED);
  static const Color cyanAccent = Color(0xFF4DE8E8);
  static const Color magentaAccent = Color(0xFFE879F9);
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textDim = Color(0xFFD8B4FE); // Ungu muda transparan
}

// ============================================================
// STAGE 1: SPLASH (Siluet Image + Animasi Reveal)
// ============================================================
class _SplashStage extends StatefulWidget {
  final VoidCallback onDone;
  const _SplashStage({super.key, required this.onDone});

  @override
  State<_SplashStage> createState() => _SplashStageState();
}

class _SplashStageState extends State<_SplashStage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _progress;
  late Animation<double> _subtitleFade;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigated) {
        _navigated = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) widget.onDone();
        });
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Deep Space
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.7, -0.3),
                radius: 1.2,
                colors: [
                  HollowExecutionTheme.deepPurple.withOpacity(0.8),
                  HollowExecutionTheme.bgBlack,
                ],
              ),
            ),
          ),
        ),
        // GRID LINES (Tanpa Partikel Bintang)
        Positioned.fill(
          child: CustomPaint(
            painter: _GridLinesPainter(),
          ),
        ),
        // Konten
        Positioned.fill(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Siluet Image (16:9, Transparan)
                    Opacity(
                      opacity: _fadeIn.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              HollowExecutionTheme.deepPurple,
                              HollowExecutionTheme.cyanAccent,
                            ],
                          ).createShader(bounds),
                          child: Image.asset(
                            'assets/images/TitleX.png',
                            width: MediaQuery.of(context).size.width * 0.9,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Subtitle System
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          HollowExecutionTheme.deepPurple,
                          HollowExecutionTheme.cyanAccent,
                        ],
                      ).createShader(bounds),
                      child: Opacity(
                        opacity: _subtitleFade.value,
                        child: const Text(
                          "VERSION 14.0",
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Progress Bar
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              height: 2,
                              color: Colors.white.withOpacity(0.05),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _progress.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          HollowExecutionTheme.deepPurple,
                                          HollowExecutionTheme.cyanAccent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: HollowExecutionTheme.cyanAccent
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "INITIALIZING",
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  color: Colors.white.withOpacity(0.15),
                                  fontSize: 9,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "${(_progress.value * 100).toInt()}%",
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STAGE 2: WELCOME (3 Slide + Fingerprint Scanner)
// ============================================================
class _WelcomeStage extends StatefulWidget {
  const _WelcomeStage({super.key});

  @override
  State<_WelcomeStage> createState() => _WelcomeStageState();
}

class _WelcomeStageState extends State<_WelcomeStage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp1;
  late Animation<Offset> _slideUp2;

  final ScrollController _scrollController = ScrollController();
  bool _hasEntered = false;

  // State untuk Fingerprint
  bool _isScanning = false;
  bool _isAuthenticated = false;
  String _fpStatus = "TAP TO SCAN";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideUp1 = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _slideUp2 = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
    ));

    _controller.forward();

    // Scroll listener untuk 3x scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasEntered) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final scrollPercent = maxScroll > 0 ? (currentScroll / maxScroll) * 100 : 0;

    // Deteksi sudah di slide ke 3 (akhir)
    if (scrollPercent >= 85 && !_hasEntered) {
      _hasEntered = true;
    }
  }

  // LOGIKA FINGERPRINT
  void _onFingerprintTap() {
    if (_isScanning || _isAuthenticated) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isScanning = true;
      _fpStatus = "SCANNING...";
    });

    // Simulasi scan 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      HapticFeedback.heavyImpact();
      setState(() {
        _isScanning = false;
        _isAuthenticated = true;
        _fpStatus = "ACCESS GRANTED";
      });

      // Navigasi ke Login
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed("/login");
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Deep Space
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HollowExecutionTheme.bgBlack,
                  HollowExecutionTheme.deepPurple.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        // GRID LINES (Tanpa Partikel Bintang)
        Positioned.fill(
          child: CustomPaint(
            painter: _GridLinesPainter(),
          ),
        ),
        // Scroll Container (3 Slide)
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ============ SLIDE 1: INTRO ============
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp1,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      HollowExecutionTheme.deepPurple,
                                      HollowExecutionTheme.cyanAccent,
                                    ],
                                  ).createShader(bounds),
                                  child: Image.asset(
                                    'assets/images/TitleX.png',
                                    width: MediaQuery.of(context).size.width *
                                        0.9,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "VERSION 14.0",
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 8,
                                    color: HollowExecutionTheme.cyanAccent
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp2,
                            child: Text(
                              "A new layer of disruption. Stealth, stability, and precision engineered into every interaction.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                color: HollowExecutionTheme.textDim
                                    .withOpacity(0.5),
                                fontSize: 13,
                                height: 1.7,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                        FadeTransition(
                          opacity: _fadeIn,
                          child: const Column(
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: HollowExecutionTheme.violet500,
                                size: 32,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Powered By @JustRxVz - @alannxd",
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  color: Colors.white54,
                                  fontSize: 10,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ============ SLIDE 2: FEATURES ============
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp1,
                            child: Text(
                              "WHAT'S NEW?",
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 18,
                                letterSpacing: 6,
                                color: HollowExecutionTheme.violet500,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _InfoCard(
                          icon: Icons.memory_rounded,
                          title: "NEW SYSTEM ENGINE",
                          subtitle: " a more stable and maintained system",
                          color: HollowExecutionTheme.cyanAccent,
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.hub_rounded,
                          title: "NEW INTERFACE",
                          subtitle: "Minimal design. Max focus.",
                          color: HollowExecutionTheme.violet500,
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.security_rounded,
                          title: "SECURE ACCESS",
                          subtitle: "Military grade encryption.",
                          color: HollowExecutionTheme.magentaAccent,
                        ),
                        const SizedBox(height: 80),
                        const Text(
                          "Powered By @JustRxVz - @alannxd",
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ============ SLIDE 3: AUTHENTICATION ============
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Judul Auth
                        Text(
                          "AUTHENTICATION",
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 24,
                            letterSpacing: 6,
                            color: HollowExecutionTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Place your finger to verify identity",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Fingerprint Scanner
                        GestureDetector(
                          onTap: _onFingerprintTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isScanning || _isAuthenticated
                                  ? HollowExecutionTheme.cyanAccent
                                      .withOpacity(0.08)
                                  : Colors.white.withOpacity(0.02),
                              border: Border.all(
                                color: _isScanning || _isAuthenticated
                                    ? HollowExecutionTheme.cyanAccent
                                    : Colors.white.withOpacity(0.1),
                                width: 2,
                              ),
                              boxShadow: _isScanning || _isAuthenticated
                                  ? [
                                      BoxShadow(
                                        color: HollowExecutionTheme.cyanAccent
                                            .withOpacity(0.2),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: _isAuthenticated
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: HollowExecutionTheme.cyanAccent,
                                      size: 50,
                                    )
                                  : Icon(
                                      Icons.fingerprint_rounded,
                                      color: _isScanning
                                          ? HollowExecutionTheme.cyanAccent
                                          : Colors.white.withOpacity(0.4),
                                      size: 60,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _fpStatus,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 14,
                            letterSpacing: 3,
                            color: _isScanning || _isAuthenticated
                                ? HollowExecutionTheme.cyanAccent
                                : Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// WIDGETS & PAINTERS
// ============================================================
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HollowExecutionTheme.deepPurple.withOpacity(0.1),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Painter untuk Grid Lines (Garis Kotak Ungu Transparan)
class _GridLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HollowExecutionTheme.violet500.withOpacity(0.05)
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
  bool shouldRepaint(covariant _GridLinesPainter oldDelegate) => false;
}