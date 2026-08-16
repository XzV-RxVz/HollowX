import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class NotifeControl {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static String? _deviceToken;
  static String? _currentUserId;
  static String? _currentUserRole;
  
  // ==================== INISIALISASI ====================
  static Future<void> init(String userId, String userRole) async {
    _currentUserId = userId;
    _currentUserRole = userRole;
    
    await _requestPermission();
    await _getDeviceToken();
    await _initLocalNotifications();
    _setupHandlers();
    
    // Listen token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _deviceToken = newToken;
      _sendTokenToServer(newToken);
    });
  }
  
  // ==================== REQUEST IZIN ====================
  static Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('📱 Notifikasi permission: ${settings.authorizationStatus}');
  }
  
  // ==================== AMBIL TOKEN DEVICE ====================
  static Future<void> _getDeviceToken() async {
    try {
      // ✅ FIX: APNS token dulu untuk iOS, baru FCM token
      _deviceToken = await _firebaseMessaging.getToken();
      
      if (_deviceToken != null && _deviceToken!.isNotEmpty) {
        print('📱 FCM Token diperoleh: ${_deviceToken!.substring(0, 20)}...');
        await _sendTokenToServer(_deviceToken!);
      } else {
        print('⚠️ FCM Token null - pastikan Firebase dikonfigurasi dengan benar');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }
  
  // ==================== KIRIM TOKEN KE SERVER ====================
  static Future<void> _sendTokenToServer(String token) async {
    // ✅ FIX: retry 3x kalau gagal
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http.post(
          Uri.parse("http://lalalucuu.alannxd.my.id:3012/registerToken"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'token': token,
            'userId': _currentUserId,
            'role': _currentUserRole,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          print('✅ FCM Token registered (attempt $attempt): $_currentUserId ($_currentUserRole)');
          return;
        } else {
          print('⚠️ Token register failed (${response.statusCode}), attempt $attempt');
        }
      } catch (e) {
        print('❌ Error sending token (attempt $attempt): $e');
        if (attempt < 3) await Future.delayed(const Duration(seconds: 2));
      }
    }
    print('❌ Failed to register token after 3 attempts');
  }
  
  // ==================== INIT LOCAL NOTIF ====================
  static Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(settings: settings);
  }
  
  // ==================== SETUP HANDLER ====================
  static void _setupHandlers() {
    // Notifikasi saat app aktif (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Notifikasi diterima saat app aktif');
      _showLocalNotification(message);
    });
    
    // Notifikasi diklik saat app background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Notifikasi diklik!');
      _onNotificationTap(message);
    });
    
    // Notifikasi saat app pertama kali dibuka dari notif
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🚀 App dibuka dari notifikasi');
        _onNotificationTap(message);
      }
    });
  }
  
  // ==================== TAMPILIN NOTIF DI HP ====================
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sxc_channel',
      'SxC ExecX',
      channelDescription: 'Notifikasi dari SxC ExecX',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: message.notification?.title ?? 'SxC ExecX',
      body: message.notification?.body ?? 'Ada notifikasi baru',
      notificationDetails: details,
    );
  }
  
  // ==================== HANDLE SAAT NOTIF DI KLIK ====================
  static void _onNotificationTap(RemoteMessage message) {
    // Bisa diisi navigasi ke halaman tertentu
    print('📱 Notif title: ${message.notification?.title}');
    print('📱 Notif body: ${message.notification?.body}');
  }
}

// ==================== HALAMAN KHUSUS DEV ====================
class SendPushPage extends StatefulWidget {
  final String sessionKey;
  final VoidCallback? onBack;
  
  const SendPushPage({super.key, required this.sessionKey, this.onBack});

  @override
  State<SendPushPage> createState() => _SendPushPageState();
}

class _SendPushPageState extends State<SendPushPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: const Text('Kirim Notifikasi Massal'),
        backgroundColor: const Color(0xFF1A1625),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () { if (widget.onBack != null) { widget.onBack!(); } else { Navigator.pop(context); } },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                size: 60,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Kirim Notifikasi ke Semua User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pesan akan dikirim ke semua pengguna aplikasi',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 30),
            
            // Input Pesan
            TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tulis pesan notifikasi...\n\nContoh: "Halo semua! Ada update terbaru v1.5.0, yuk update sekarang!"',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                filled: true,
                fillColor: const Color(0xFF1A1625),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1625),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📱 PREVIEW NOTIFIKASI',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SxC ExecX',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _messageController.text.isEmpty 
                                    ? 'Pesan notifikasi akan muncul disini...' 
                                    : _messageController.text,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Baru saja',
                                style: TextStyle(color: Colors.grey, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Tombol Kirim
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'KIRIM NOTIFIKASI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Notifikasi akan dikirim ke SEMUA pengguna yang sedang online!',
                      style: TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _sendNotification() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan tidak boleh kosong!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      final response = await http.post(
        Uri.parse("http://lalalucuu.alannxd.my.id:3012/sendToAll"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'title': 'SxC ExecX',
          'body': _messageController.text.trim(),
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Berhasil dikirim ke ${data['sent']} perangkat!'),
            backgroundColor: Colors.green,
          ),
        );
        _messageController.clear();
      } else {
        throw Exception(data['message'] ?? 'Gagal mengirim');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }
}