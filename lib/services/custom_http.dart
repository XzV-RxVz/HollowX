import 'package:http/http.dart' as original_http;
import 'package:http/http.dart' show Response;
import 'dart:convert';
import 'api_config.dart';

// FUNGSI UNTUK PROSES URL
Uri _processUrl(Uri url) {
  final dynamicUrl = Uri.parse(ApiConfig.baseUrl);
  
  if (url.host == dynamicUrl.host) {
    return url.replace(
      scheme: dynamicUrl.scheme,
      host: dynamicUrl.host,
      port: dynamicUrl.port,
    );
  }
  return url;
}

Future<Response> get(Uri url, {Map<String, String>? headers}) async {
  final newUrl = _processUrl(url);
  final sessionHeaders = await ApiConfig.getHeadersWithSession();
  
  // Gabungkan headers
  final allHeaders = Map<String, String>.from(sessionHeaders);
  if (headers != null) {
    allHeaders.addAll(headers);
  }
  
  print("🔄 GET: ${url.path} -> $newUrl");
  print("📋 Headers: $allHeaders");
  
  return original_http.get(
    newUrl, 
    headers: allHeaders
  );
}

Future<Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final newUrl = _processUrl(url);
  final sessionHeaders = await ApiConfig.getHeadersWithSession();
  
  // Gabungkan headers
  final allHeaders = Map<String, String>.from(sessionHeaders);
  if (headers != null) {
    allHeaders.addAll(headers);
  }
  
  print("🔄 POST: ${url.path} -> $newUrl");
  print("📋 Headers: $allHeaders");
  print("📦 Body: $body");
  
  return original_http.post(
    newUrl, 
    headers: allHeaders, 
    body: body, 
    encoding: encoding
  );
}

Future<Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final newUrl = _processUrl(url);
  final sessionHeaders = await ApiConfig.getHeadersWithSession();
  
  final allHeaders = Map<String, String>.from(sessionHeaders);
  if (headers != null) {
    allHeaders.addAll(headers);
  }
  
  return original_http.put(
    newUrl, 
    headers: allHeaders, 
    body: body, 
    encoding: encoding
  );
}

Future<Response> delete(Uri url, {Map<String, String>? headers}) async {
  final newUrl = _processUrl(url);
  final sessionHeaders = await ApiConfig.getHeadersWithSession();
  
  final allHeaders = Map<String, String>.from(sessionHeaders);
  if (headers != null) {
    allHeaders.addAll(headers);
  }
  
  return original_http.delete(
    newUrl, 
    headers: allHeaders
  );
}