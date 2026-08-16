// bug_sender.dart
// DEATHTRASH - SENDER CONTROL (RED & GOLD EDITION)

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'constants.dart';

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;
  final VoidCallback? onBack;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
    this.onBack,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage>
    with SingleTickerProviderStateMixin {
  // ===== STATE =====
  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  // ===== ANIMATIONS =====
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ===== HELPERS =====
  bool _isSenderConnected(Map<String, dynamic> s) => true;

  String _getSenderName(Map<String, dynamic> s) {
    if ((s['sessionName'] ?? '').toString().isNotEmpty) return s['sessionName'];
    if ((s['name'] ?? '').toString().isNotEmpty) return s['name'];
    if ((s['number'] ?? '').toString().isNotEmpty) return s['number'];
    return 'WhatsApp Sender';
  }

  // ===== LIFECYCLE =====
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchSenders();
  }

  void _initAnimations() {
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================
  // API
  // ============================================================
  Future<void> _fetchSenders() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final res = await http.get(
        Uri.parse("http://lalalucuu.alannxd.my.id:3012/mySender?key=${widget.sessionKey}"),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['valid'] == true) {
        final connList = data['privateConnections'] ?? data['connections'] ?? [];
        setState(() => senderList = connList);
      } else {
        setState(() => errorMessage = data['message'] ?? data['error'] ?? 'Failed to fetch senders');
      }
    } catch (e) {
      setState(() => errorMessage = 'Connection failed: $e');
    } finally {
      if (mounted) setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
  }

  Future<void> _addSender(String number) async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
        "http://lalalucuu.alannxd.my.id:3012/getPairing?key=${widget.sessionKey}&number=$number",
      ));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['valid'] == true) {
        _showPairingCodeDialog(number, data['pairingCode']);
        _showSnackbar('Pairing code generated!', isError: false);
        Future.delayed(const Duration(seconds: 3), () {
          _fetchSenders();
        });
      } else {
        _showSnackbar(data['message'] ?? 'Failed to generate pairing code', isError: true);
      }
    } catch (e) {
      _showSnackbar('Connection failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteSender(String senderId) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed != true) return;
    setState(() => isLoading = true);
    try {
      final res = await http.delete(Uri.parse(
        "http://lalalucuu.alannxd.my.id:3012/deleteSender?key=${widget.sessionKey}&id=$senderId",
      ));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['valid'] == true) {
        _showSnackbar('Sender deleted!', isError: false);
        _fetchSenders();
      } else {
        _showSnackbar(data['message'] ?? 'Failed to delete', isError: true);
      }
    } catch (e) {
      _showSnackbar('Connection failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ============================================================
  // SNACKBAR - DEATHTRASH THEME
  // ============================================================
  void _showSnackbar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? kDeathRed : kDeathRedDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ============================================================
  // DIALOGS - DEATHTRASH THEME
  // ============================================================
  Widget _dialogBtn({
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: isDanger
              ? LinearGradient(colors: [kDeathRed, kDeathRedDark])
              : isPrimary
                  ? LinearGradient(colors: [kDeathRed, kDeathRedDark])
                  : null,
          color: (!isDanger && !isPrimary) ? kDeathCardBg.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger
                ? kDeathRed.withOpacity(0.3)
                : isPrimary
                    ? Colors.transparent
                    : kDeathBorder,
          ),
          boxShadow: isDanger || isPrimary
              ? [BoxShadow(color: kDeathRed.withOpacity(0.3), blurRadius: 12)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: (!isDanger && !isPrimary) ? Colors.white.withOpacity(0.3) : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              fontFamily: 'ShareTechMono',
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSenderDialog() {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.8, end: 1.0),
        curve: Curves.elasticOut,
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: Dialog(
          backgroundColor: Colors.transparent,
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
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
                  child: Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    'ADD SENDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter WhatsApp number for new sender',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: kDeathCardBg.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kDeathBorder),
                  ),
                  child: TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: '628xxxxxxxxx',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.15),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: kDeathRed,
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _dialogBtn(
                        label: 'CANCEL',
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dialogBtn(
                        label: 'ADD',
                        isPrimary: true,
                        onTap: () async {
                          final number = phoneCtrl.text.trim();
                          if (number.isEmpty) {
                            _showSnackbar('Enter phone number', isError: true);
                            return;
                          }
                          Navigator.pop(context);
                          await _addSender(number);
                        },
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

  void _showPairingCodeDialog(String number, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.8, end: 1.0),
        curve: Curves.elasticOut,
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: Dialog(
          backgroundColor: Colors.transparent,
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
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
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    'PAIRING REQUIRED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Number: $number',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kDeathCardBg.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kDeathBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'PAIRING CODE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.15),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'ShareTechMono',
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: kDeathDarkBg.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kDeathRed.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kDeathRed.withOpacity(0.1),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: SelectableText(
                          code,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kDeathGold,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          _showSnackbar('Code copied!', isError: false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: kDeathRed.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kDeathRed.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                color: kDeathRed,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'COPY CODE',
                                style: TextStyle(
                                  color: kDeathRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _dialogBtn(
                        label: 'CLOSE',
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dialogBtn(
                        label: 'REFRESH',
                        isPrimary: true,
                        onTap: () {
                          Navigator.pop(context);
                          _fetchSenders();
                        },
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

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.8, end: 1.0),
        curve: Curves.elasticOut,
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: Dialog(
          backgroundColor: Colors.transparent,
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kDeathRed.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kDeathRed.withOpacity(0.15),
                    ),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: kDeathRed,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'CONFIRM DELETE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Delete this sender permanently?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _dialogBtn(
                        label: 'CANCEL',
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dialogBtn(
                        label: 'DELETE',
                        isDanger: true,
                        onTap: () => Navigator.pop(context, true),
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

  // ============================================================
  // SENDER CARD - DEATHTRASH THEME
  // ============================================================
  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final name = _getSenderName(sender);
    final phoneNumber = (sender['number'] ?? sender['phone'] ?? '').toString();
    final senderId = (sender['id'] ?? sender['sessionName'] ?? '').toString();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kDeathCardBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: kDeathBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kDeathRed, kDeathRedDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kDeathRed.withOpacity(0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.white,
                        size: 22,
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: kDeathGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: kDeathDarkBg, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: kDeathGreen.withOpacity(0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              color: Colors.white.withOpacity(0.15),
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              phoneNumber,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: kDeathGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kDeathGreen.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ONLINE',
                            style: TextStyle(
                              color: kDeathGreen,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kDeathRed.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: kDeathRed.withOpacity(0.08),
                              ),
                            ),
                            child: Text(
                              'READY',
                              style: TextStyle(
                                color: kDeathRed,
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'ShareTechMono',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    'REFRESH',
                    Icons.refresh_rounded,
                    kDeathRed,
                    _refreshSenders,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    'DELETE',
                    Icons.delete_outline_rounded,
                    kDeathRed,
                    () => _deleteSender(senderId),
                    isDanger: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isDanger ? kDeathRed.withOpacity(0.06) : kDeathRed.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDanger ? kDeathRed.withOpacity(0.08) : kDeathRed.withOpacity(0.04),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
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
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: kDeathRed.withOpacity(0.04),
                  shape: BoxShape.circle,
                  border: Border.all(color: kDeathRed.withOpacity(0.06)),
                ),
                child: FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: kDeathRed.withOpacity(0.1),
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [kDeathRed, kDeathGold],
                ).createShader(bounds),
                child: Text(
                  'NO SENDERS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add your first WhatsApp sender',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.15),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnim.value,
                    child: GestureDetector(
                      onTap: _showAddSenderDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kDeathRed, kDeathRedDark],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kDeathRed.withOpacity(0.3),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'ADD SENDER',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                fontFamily: 'ShareTechMono',
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================
  Widget _buildErrorState() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kDeathRed.withOpacity(0.06),
                  shape: BoxShape.circle,
                  border: Border.all(color: kDeathRed.withOpacity(0.08)),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: kDeathRed,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LOADING FAILED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ?? 'Unknown error occurred',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _fetchSenders,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'RETRY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          fontFamily: 'ShareTechMono',
                          letterSpacing: 1.5,
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
    );
  }

  // ============================================================
  // APP BAR - DEATHTRASH THEME
  // ============================================================
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kDeathCardBg.withOpacity(0.8),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: kDeathRed.withOpacity(0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ).createShader(bounds),
                  child: Text(
                    'SENDER CONTROL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'FontX',
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Text(
                  '${senderList.length} senders active',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.15),
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isLoading ? null : _refreshSenders,
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: kDeathCardBg.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDeathBorder),
              ),
              child: AnimatedRotation(
                turns: isRefreshing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Icon(
                  Icons.refresh_rounded,
                  color: kDeathRed,
                  size: 18,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: isLoading ? null : _showAddSenderDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              child: Row(
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'ADD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 0.5,
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
            bottom: -80,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kDeathGold.withOpacity(0.03), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ===== GRID =====
          CustomPaint(
            size: Size.infinite,
            painter: _SenderGridPainter(accentColor: kDeathRed),
          ),

          // ===== MAIN CONTENT =====
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: RefreshIndicator(
                    color: kDeathRed,
                    backgroundColor: kDeathCardBg.withOpacity(0.9),
                    onRefresh: _refreshSenders,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: isLoading && senderList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        color: kDeathRed,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading senders...',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.15),
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : errorMessage != null && senderList.isEmpty
                                ? _buildErrorState()
                                : senderList.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.builder(
                                        physics: const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                        itemCount: senderList.length,
                                        itemBuilder: (_, i) => _buildSenderCard(
                                          Map<String, dynamic>.from(senderList[i]),
                                          i,
                                        ),
                                      ),
                      ),
                    ),
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

// ============================================================
// GRID PAINTER
// ============================================================
class _SenderGridPainter extends CustomPainter {
  final Color accentColor;

  _SenderGridPainter({required this.accentColor});

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