import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DomainService {
  static const String ossDomain = 'https://telegram-channels.github.io/config.json';

  static Future<String> fetchValidDomain() async {
    try {
      final response = await http
          .get(Uri.parse(ossDomain))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> websites = json.decode(response.body) as List<dynamic>;
        for (final website in websites) {
          if (website is Map<String, dynamic> && website['url'] is String) {
            final String domain = website['url'];
            if (kDebugMode) print('检查域名: $domain');
            if (await _checkDomainAccessibility(domain)) {
              if (kDebugMode) print('有效域名: $domain');
              return domain;
            }
          }
        }
        throw Exception('No accessible domains found in $ossDomain');
      } else {
        throw Exception('Failed to fetch $ossDomain: status ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching valid domain from $ossDomain: $e');
      rethrow;
    }
  }

  static Future<bool> _checkDomainAccessibility(String domain) async {
    try {
      final response = await http
          .get(Uri.parse('$domain/api/v1/guest/comm/config'))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
