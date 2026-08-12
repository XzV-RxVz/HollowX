// DEATHTR4SH V1 GEN 2 - SPAM BOT TELEGRAM

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'constants.dart';

class SpamBotPage extends StatefulWidget {
  final String sessionKey;
  const SpamBotPage({super.key, required this.sessionKey});

  @override
  State<SpamBotPage> createState() => _SpamBotPageState();
}

class _SpamBotPageState extends State<SpamBotPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _delayController = TextEditingController(text: "1000");
  final TextEditingController _countController = TextEditingController(text: "10");
  bool _isSpamming = false;
  int _progress = 0;
  int _total = 0;

  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
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
    super.dispose();
  }

  Future<void> _startSpam() async {
    final token = _tokenController.text.trim();
    final id = _idController.text.trim();
    final msg = _msgController.text.trim();
    final count = int.tryParse(_countController.text) ?? 0;
    final delay = int.tryParse(_delayController.text) ?? 1000;

    if (token.isEmpty || id.isEmpty || msg.isEmpty) {
      _showSnackBar('Semua field harus diisi!', isError: true);
      return;
    }

    if (count <= 0 || count > 100) {
      _showSnackBar('Count harus antara 1-100', isError: true);
      return;
    }

    setState(() {
      _isSpamming = true;
      _progress = 0;
      _total = count;
    });

    for (int i = 0; i < count; i++) {
      if (!_isSpamming) break;
      try {
        final response = await http.post(
          Uri.parse("https://api.telegram.org/bot$token/sendMessage"),
          body: {"chat_id": id, "text": msg},
        ).timeout(const Duration(seconds: 5));

        setState(() => _progress = i + 1);
        
        if (response.statusCode != 200) {
          _showSnackBar('Error: ${response.statusCode}', isError: true);
          break;
        }
      } catch (e) {
        _showSnackBar('Error: $e', isError: true);
        break;
      }
      await Future.delayed(Duration(milliseconds: delay));
    }

    if (mounted) {
      setState(() {
        _isSpamming = false;
        _progress = 0;
        _total = 0;
      });
      if (_progress == count) {
        _showSnackBar('Spam Completed! ✅', isError: false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? kDeathRed.withOpacity(0.8) : kDeathGreen.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isError ? kDeathRed : kDeathGreen, width: 0.5),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

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
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildInputCard(
                      // FIX: Ganti FontAwesomeIcons.bot dengan Icons.smart_toy_rounded
                      Icons.smart_toy_rounded,
                      "Bot Token",
                      _tokenController,
                      "123456:ABC-DEF...",
                    ),
                    _buildInputCard(
                      FontAwesomeIcons.idBadge,
                      "Target ID",
                      _idController,
                      "987654321",
                    ),
                    _buildInputCard(
                      FontAwesomeIcons.commentDots,
                      "Message",
                      _msgController,
                      "Hello world...",
                      maxLines: 3,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputCard(
                            Icons.timer_rounded,
                            "Delay (ms)",
                            _delayController,
                            "1000",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputCard(
                            Icons.numbers_rounded,
                            "Count",
                            _countController,
                            "10",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isSpamming) _buildProgressIndicator(),
                    const SizedBox(height: 16),
                    _buildActionButton(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                  ],
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathRedDark],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                // FIX: Ganti FontAwesomeIcons.bot dengan Icons.smart_toy_rounded
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ).createShader(bounds),
              child: Text(
                'SPAM BOT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
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
  // HEADER CARD
  // ============================================================
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kDeathRed.withOpacity(0.08), kDeathRedDark.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDeathRed.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathGold],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.2 * _pulseAnimation.value),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                FontAwesomeIcons.telegram,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    'TELEGRAM SPAMMER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'FontX',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Text(
                  'Kirim spam pesan ke Telegram',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.15),
                    fontSize: 10,
                    fontFamily: 'ShareTechMono',
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
  // INPUT CARD
  // ============================================================
  Widget _buildInputCard(
    dynamic icon,
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDeathBorder),
        boxShadow: [
          BoxShadow(
            color: kDeathRed.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon is FaIconData
                  ? FaIcon(icon, color: kDeathRed, size: 14)
                  : Icon(icon as IconData, color: kDeathRed, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'ShareTechMono',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.06),
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS INDICATOR
  // ============================================================
  Widget _buildProgressIndicator() {
    final progress = _total > 0 ? _progress / _total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDeathBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.1),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$_progress / $_total',
                style: TextStyle(
                  color: kDeathRed.withOpacity(0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: kDeathDarkBg,
              valueColor: AlwaysStoppedAnimation<Color>(kDeathRed),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================
  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSpamming ? kDeathRedDark : kDeathRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: _isSpamming ? kDeathRed : kDeathRed.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        onPressed: _isSpamming ? () => setState(() => _isSpamming = false) : _startSpam,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSpamming ? Icons.stop_rounded : Icons.send_rounded,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _isSpamming ? "STOP SPAM" : "SEND SPAM",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDeathBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: kDeathGold.withOpacity(0.1),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gunakan dengan bijak. Spam berlebihan dapat menyebabkan akun Telegram terkena ban.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.06),
                fontSize: 9,
                fontFamily: 'ShareTechMono',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}