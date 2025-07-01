import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:http/http.dart' as http;

class HttpService {
  static String baseUrl = 'https://88cloud.dpdns.org'; // 可根据实际情况动态修改

  // 如果需要动态域名
  static Future<void> initialize() async {
    baseUrl = await DomainService.fetchValidDomain();
  }

  // 统一GET请求
  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
      if (kDebugMode) print("GET $url response: ${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("GET $url failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) print('GET $url error: $e');
      rethrow;
    }
  }

  // 统一POST请求，始终带Content-Type: application/json
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {'Content-Type': 'application/json'};
    final mergedHeaders = {...?headers, ...defaultHeaders};

    try {
      final response = await http
          .post(
            url,
            headers: mergedHeaders,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20));
      if (kDebugMode) print("POST $url response: ${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("POST $url failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) print('POST $url error: $e');
      rethrow;
    }
  }
}
