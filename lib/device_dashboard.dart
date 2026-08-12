// DEATHTR4SH V1 GEN 2 - DEVICE DASHBOARD

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'device_permission.dart';
import 'control_panel.dart';
import 'theme_provider.dart';
import 'constants.dart';
import 'config.dart';

class DeviceDashboardPage extends StatefulWidget {
  final String username;
  final String role;
  final String sessionKey;
  const DeviceDashboardPage({
    super.key, 
    this.username = '', 
    this.role = '', 
    this.sessionKey = ''
  });
  
  @override
  State<DeviceDashboardPage> createState() => _DDState();
}

class _DDState extends State<DeviceDashboardPage> with SingleTickerProviderStateMixin {
  // ===== STATE =====
  List<dynamic> _visible = [];
  bool _loading = true;
  String? _errorMsg;
  String _pairId = '';
  
  // Animations
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulseAnimation;
  
  bool get _isOwner => true;
  
  PermissionResult? _perm;
  Timer? _timer;
  
  // Search
  String _searchQuery = '';
  List<dynamic> _filteredDevices = [];

  // Stats
  int _totalDevices = 0;
  int _onlineDevices = 0;
  int _offlineDevices = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadAll();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _loadAll());
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
    _timer?.cancel();
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose(); 
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      setState(() => _filteredDevices = List.from(_visible));
    } else {
      setState(() {
        _filteredDevices = _visible.where((d) {
          final model = (d['model']?.toString() ?? '').toLowerCase();
          final id = (d['id']?.toString() ?? '').toLowerCase();
          final query = _searchQuery.toLowerCase();
          return model.contains(query) || id.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    try {
      final pRes = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/rat/pairid?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 8));
      if (pRes.statusCode == 200) {
        final pd = jsonDecode(pRes.body);
        if (pd['valid'] == true && pd['pairId'] != null) {
          if (mounted) setState(() => _pairId = pd['pairId'].toString());
        }
      }

      final dRes = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/rat/my-devices?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (dRes.statusCode != 200) {
        setState(() { _loading = false; _errorMsg = 'Server error ${dRes.statusCode}'; });
        return;
      }

      final body = jsonDecode(dRes.body);
      if (body['valid'] != true) {
        setState(() { _loading = false; _errorMsg = body['message'] ?? 'Error'; });
        return;
      }

      List<dynamic> devices = List<dynamic>.from(body['devices'] ?? []);

      final now = DateTime.now();
      int online = 0, offline = 0;
      for (var d in devices) {
        try {
          final seen = DateTime.parse(d['lastSeen']?.toString() ?? '');
          d['online'] = now.difference(seen).inSeconds < 30;
          if (d['online'] == true) online++; else offline++;
        } catch (_) { d['online'] = false; offline++; }
      }

      devices.sort((a, b) {
        if (a['online'] == true && b['online'] != true) return -1;
        if (a['online'] != true && b['online'] == true) return 1;
        return 0;
      });

      PermissionResult perm = PermissionResult(approved: true, allDevices: true, devices: []);

      if (mounted) setState(() {
        _visible = devices;
        _filteredDevices = List.from(devices);
        _perm = perm;
        _loading = false;
        _errorMsg = null;
        _totalDevices = devices.length;
        _onlineDevices = online;
        _offlineDevices = offline;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _errorMsg = e.toString(); });
    }
  }

  void _copyPairId() {
    if (_pairId.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _pairId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'ID Pairing berhasil disalin!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'ShareTechMono',
        ),
      ),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: kDeathCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: kDeathGold.withOpacity(0.2)),
      ),
    ));
  }

  void _showPairIdDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0.7, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kDeathRed.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kDeathRed, kDeathGold],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kDeathRed.withOpacity(0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [kDeathRed, kDeathGold],
                        ).createShader(bounds),
                        child: Text(
                          "PAIRING ID",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'FontX',
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Bagikan ID ini ke target",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.15),
                          fontSize: 11,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kDeathDarkBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kDeathBorder),
                  ),
                  child: SelectableText(
                    _pairId,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kDeathGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: kDeathCardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kDeathBorder),
                            ),
                            child: Center(
                              child: Text(
                                "Tutup",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.2),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  fontFamily: 'FontX',
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _copyPairId();
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kDeathRed, kDeathRedDark],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: kDeathRed.withOpacity(0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Salin",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      fontFamily: 'FontX',
                                      letterSpacing: 1,
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
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    
    return Scaffold(
      backgroundColor: kDeathDarkBg,
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
        child: CustomPaint(
          painter: _DeviceGridPainter(accentColor: kDeathRed),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(),
            body: FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scaleIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: _loading
                      ? _buildLoadingState()
                      : Column(
                          children: [
                            _buildStatsHeader(),
                            if (_errorMsg != null) _buildErrorBanner(),
                            _buildSearchToolbar(),
                            Expanded(
                              child: _filteredDevices.isEmpty
                                  ? _buildEmptyState()
                                  : RefreshIndicator(
                                      color: kDeathRed,
                                      backgroundColor: kDeathCardBg.withOpacity(0.9),
                                      onRefresh: _loadAll,
                                      child: GridView.builder(
                                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 0.75
                                        ),
                                        itemCount: _filteredDevices.length,
                                        itemBuilder: (ctx, i) => _buildDeviceCard(ctx, _filteredDevices[i], i),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // ─── APP BAR ──────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
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
            Icon(Icons.devices_rounded, color: kDeathRed, size: 16),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ).createShader(bounds),
              child: Text(
                'DEVICE HUB',
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
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kDeathRed, kDeathRedDark],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kDeathRed.withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            widget.role.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kDeathCardBg.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kDeathBorder),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: kDeathRed,
              size: 18,
            ),
          ),
          onPressed: () {
            setState(() { _loading = true; _errorMsg = null; });
            _loadAll();
          },
        ),
      ],
    );
  }

  // ─── LOADING STATE ────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              color: kDeathRed,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING DEVICES...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.04),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  // ─── STATS HEADER ─────────────────────────────────────────────────────────
  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          // Baris 1: User Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kDeathRed.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.devices_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [kDeathRed, kDeathGold],
                      ).createShader(bounds),
                      child: Text(
                        '@${widget.username}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'FontX',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.role.toUpperCase()} • Premium Access',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.1),
                        fontSize: 9,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'V1',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'FontX',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Baris 2: Stats
          Row(
            children: [
              _buildStatItem('TOTAL', '$_totalDevices', kDeathGold),
              _buildStatDivider(),
              _buildStatItem('ONLINE', '$_onlineDevices', kDeathRed),
              _buildStatDivider(),
              _buildStatItem('OFFLINE', '$_offlineDevices', Colors.grey),
            ],
          ),
          
          // Baris 3: Pair ID
          if (_pairId.isNotEmpty) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _showPairIdDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kDeathDarkBg,
                  borderRadius: BorderRadius.circular(14),
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
                      child: Icon(Icons.link_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PAIRING ID',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.1),
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'FontX',
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _pairId,
                            style: TextStyle(
                              color: kDeathGold,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kDeathRed, kDeathRedDark],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'COPY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'FontX',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: label == 'ONLINE' ? _pulseAnimation.value : 1.0,
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'FontX',
                    shadows: [
                      Shadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.08),
              fontSize: 7,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.03),
    );
  }
  
  // ─── ERROR BANNER ─────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDeathRed.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDeathRed.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: kDeathRed, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMsg!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMsg = null),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.1),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  // ─── SEARCH TOOLBAR ──────────────────────────────────────────────────────
  Widget _buildSearchToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathGold],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'CONNECTED DEVICES',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.1),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathRed, kDeathRedDark],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_filteredDevices.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'FontX',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DevicePermissionManagerPage(
                      sessionKey: widget.sessionKey,
                      allDevices: _visible
                    )
                  ));
                  _loadAll();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kDeathRed.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kDeathRed.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.manage_accounts_rounded, size: 12, color: kDeathRed.withOpacity(0.2)),
                      const SizedBox(width: 4),
                      Text(
                        'Kelola',
                        style: TextStyle(
                          color: kDeathRed.withOpacity(0.2),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'FontX',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kDeathBorder),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilter();
              },
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
              decoration: InputDecoration(
                hintText: "Cari device...",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.06),
                  fontSize: 11,
                  fontFamily: 'ShareTechMono',
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.06),
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.06),
                          size: 16,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyFilter();
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.02),
              border: Border.all(color: Colors.white.withOpacity(0.02)),
            ),
            child: Icon(
              _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.devices_other_rounded,
              color: Colors.white.withOpacity(0.03),
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty ? 'TIDAK DITEMUKAN' : 'BELUM ADA DEVICE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.06),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada device dengan "$_searchQuery"'
                : 'Belum ada device terhubung',
            style: TextStyle(
              color: Colors.white.withOpacity(0.04),
              fontSize: 10,
              fontFamily: 'ShareTechMono',
            ),
          ),
          if (!_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kDeathCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kDeathBorder),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kDeathRed, kDeathGold],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CARA HUBUNGKAN DEVICE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.1),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'FontX',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      _buildStep('1', 'Install APK di HP target'),
                      _buildStep('2', 'Masukkan ID Pairing yang tersedia'),
                      _buildStep('3', 'Device otomatis muncul di sini'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.08),
                fontSize: 10,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ─── DEVICE CARD ──────────────────────────────────────────────────────────
  Widget _buildDeviceCard(BuildContext context, dynamic device, int index) {
    final on = device['online'] == true;
    final statusColor = on ? kDeathRed : Colors.grey;
    final battery = device['battery']?.toString() ?? '?';
    final model = device['model']?.toString() ?? 'Unknown';
    final id = device['id']?.toString() ?? '-';
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ControlCenterPage(targetDevice: device, role: widget.role))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kDeathCardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: on ? kDeathRed.withOpacity(0.15) : kDeathBorder,
              width: on ? 1.5 : 1,
            ),
            boxShadow: on ? [
              BoxShadow(
                color: kDeathRed.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.04)),
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: statusColor,
                      size: 16,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.04)),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          on ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: statusColor.withOpacity(0.2),
                            fontSize: 6,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'FontX',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Device Name
              Text(
                model,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                id.length > 12 ? '${id.substring(0, 12)}...' : id,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.06),
                  fontSize: 7,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              
              // Bottom: Battery
              Row(
                children: [
                  Icon(
                    Icons.battery_charging_full_rounded,
                    color: Colors.white.withOpacity(0.06),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$battery%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.1),
                      fontSize: 8,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: on ? kDeathRed.withOpacity(0.04) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '●',
                      style: TextStyle(
                        color: on ? kDeathRed.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
                        fontSize: 6,
                      ),
                    ),
                  ),
                ],
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
class _DeviceGridPainter extends CustomPainter {
  final Color accentColor;
  
  _DeviceGridPainter({required this.accentColor});
  
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
  bool shouldRepaint(covariant _DeviceGridPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}