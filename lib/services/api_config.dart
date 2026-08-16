import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static String baseUrl = "http://lalalucuu.alannxd.my.id:3012";
  static String wsUrl = "ws://lalalucuu.alannxd.my.id:3012/ws";
  static String appType = "HOLOW-MAIN";

  static Map<String, String> getHeaders([Map<String, String>? additionalHeaders]) {
    final headers = {
      'x-app-type': appType,
      'Content-Type': 'application/json'
    };
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    return headers;
  }

  static Future<Map<String, String>> getHeadersWithSession() async {
    final headers = getHeaders();
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString("key");
      if (sessionKey != null && sessionKey.isNotEmpty) {
        headers['x-session-key'] = sessionKey;
        print("🔑 Session key added to headers: $sessionKey");
      } else {
        print("⚠️ No session key found in SharedPreferences");
      }
    } catch (e) {
      print("❌ Error getting session key: $e");
    }
    return headers;
  }

  // VERSION CONTROL
  static const String CURRENT_VERSION = "14.0.0";
  static String remoteVersion = "14.0.0";
  static String updateLink = "https://t.me/holowexc";
  static bool get isUpdateRequired => remoteVersion != CURRENT_VERSION;

  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      try {
        final res = await http.get(
          Uri.parse('https://raw.githubusercontent.com/brmenn/c/refs/heads/main/ct.json')
        ).timeout(const Duration(seconds: 5));
        
        if (res.statusCode == 200) {
          List<dynamic> jsonArr = jsonDecode(res.body);
          if (jsonArr.length >= 2) {
            baseUrl = jsonArr[0].toString();
            wsUrl = jsonArr[1].toString();
            
            await prefs.setString('api_base_url', baseUrl);
            await prefs.setString('api_ws_url', wsUrl);
            
            if (jsonArr.length >= 4) {
              remoteVersion = jsonArr[2].toString();
              updateLink = jsonArr[3].toString();
            }
            
            print("[ApiConfig] Dynamic config loaded: $baseUrl / $wsUrl");
          }
        }
      } catch (e) {
        baseUrl = prefs.getString('api_base_url') ?? baseUrl;
        wsUrl = prefs.getString('api_ws_url') ?? wsUrl;
        print("[ApiConfig] Using cache: $baseUrl / $wsUrl");
      }
    } catch (e) {
      print("Error loading config: $e");
    }
  }
}