import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// ─────────────────────────────────────────────────────────────
// AppTheme — shared background video + button styles
// ─────────────────────────────────────────────────────────────

class VideoBg extends StatefulWidget {
  final Widget? child;
  final String videoAsset;
  const VideoBg({super.key, this.child, this.videoAsset = 'assets/videos/bg.mp4'});
  @override State<VideoBg> createState() => _VideoBgState();
}

class _VideoBgState extends State<VideoBg> {
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((_) {
        if (mounted) {
          _ctrl!.setVolume(0);
          _ctrl!.setLooping(true);
          _ctrl!.play();
          setState(() {});
        }
      }).catchError((_) {});
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    // Background video
    if (_ctrl != null && _ctrl!.value.isInitialized)
      FittedBox(fit: BoxFit.cover, child: SizedBox(
        width: _ctrl!.value.size.width,
        height: _ctrl!.value.size.height,
        child: VideoPlayer(_ctrl!),
      ))
    else
      Container(color: const Color(0xFF0B0420)),
    // Dark overlay
    Container(color: Colors.black.withOpacity(0.55)),
    // Content
    if (widget.child != null) widget.child!,
  ]);
}

// ── Button Styles ──────────────────────────────────────────────
class AppBtn {
  // Primary gradient button
  static Widget primary({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    double height = 52,
    double? width,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF00D4FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFF0066FF).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
      ]),
    ),
  );

  // Secondary outlined button
  static Widget secondary({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    double height = 48,
    double? width,
    Color color = const Color(0xFF00D4FF),
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, color: color, size: 18), const SizedBox(width: 8)],
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    ),
  );

  // Danger button
  static Widget danger({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    double height = 48,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF1744), Color(0xFFFF6B6B)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFFFF1744).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    ),
  );
}
