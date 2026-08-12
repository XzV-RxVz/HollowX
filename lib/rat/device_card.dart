import 'package:flutter/material.dart';
import '../widgets/glass_theme.dart';
class RatDeviceCard extends StatelessWidget {
  final dynamic device;
  final VoidCallback onTap;

  const RatDeviceCard({super.key, required this.device, required this.onTap});

  bool get _isWin => (device['id'] ?? '').toString().startsWith('WIN-');
  bool get _isOnline => (device['status'] ?? '') == 'online';

  String get _name => (device['phoneName'] ?? device['phone_name'] ?? device['hostname'] ?? device['id'] ?? 'Unknown').toString();
  String get _model => (device['model'] ?? device['os'] ?? '-').toString();
  String get _ip => (device['ipAddress'] ?? device['ip_address'] ?? '-').toString();
  String get _battery => (device['batteryLevel'] ?? device['battery_level'] ?? device['battery'] ?? '-').toString();
  String get _os => _isWin
      ? 'Windows ${(device['release'] ?? '').toString()}'.trim()
      : 'Android ${(device['androidVersion'] ?? device['android_version'] ?? '').toString()}'.trim();

  @override
  Widget build(BuildContext context) {
    final Color accent = GlassTheme.neonGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isOnline ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: _isOnline
              ? [BoxShadow(color: accent.withOpacity(0.15), blurRadius: 12, spreadRadius: 0)]
              : [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isOnline ? accent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  border: Border.all(color: _isOnline ? accent.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isOnline ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 10)] : [],
                ),
                child: Icon(
                  _isWin ? Icons.laptop_windows_rounded : Icons.smartphone_rounded,
                  color: _isOnline ? accent : Colors.white54,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _os,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.wifi_rounded, size: 11, color: Colors.white.withOpacity(0.35)),
                        const SizedBox(width: 3),
                        Text(
                          _ip,
                          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right side: status + battery
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Online dot
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isOnline ? accent : Colors.grey.shade600,
                          shape: BoxShape.circle,
                          boxShadow: _isOnline ? [BoxShadow(color: accent, blurRadius: 6)] : [],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: _isOnline ? accent : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Battery
                  Row(
                    children: [
                      Icon(Icons.battery_std_rounded,
                          size: 13, color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 3),
                      Text(
                        _battery,
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Arrow
                  Icon(Icons.chevron_right_rounded,
                      color: accent.withOpacity(0.5), size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
