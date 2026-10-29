import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// The Apps Script URL is public configuration. Account actions validate an ID
/// token; the public catalog returns allowlisted fields only. Secrets stay server-side.
class TrustedBackend {
  static const url = String.fromEnvironment(
    'HARVEST_BACKEND_URL',
    defaultValue: 'https://script.google.com/macros/s/AKfycbzrVxOkY9A-HQHLRCSSUdPxepUHUp-yy4H619oIe-gWZaGNXWoBxfRTvvq2L57gVi2I/exec',
  );
  static bool get enabled => url.isNotEmpty;

  static Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> data = const {},
  ]) async {
    if (!enabled) throw StateError('The account service is not configured.');
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Sign in again to continue.');
    return _request(action, data, token);
  }

  static Future<Map<String, dynamic>> publicCatalog(
    Map<String, dynamic> cursors,
  ) => _request('publicCatalog', {'cursors': cursors}, null);

  static Future<Map<String, dynamic>> _request(
    String action,
    Map<String, dynamic> data,
    String? token,
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(url))
        ..followRedirects = false
        ..headers['Content-Type'] = 'text/plain;charset=utf-8'
        ..body = jsonEncode({'action': action, 'idToken': token, 'data': data});
      var response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 45)),
      );
      // ContentService returns a one-time URL. Follow only Google's HTTPS host,
      // using GET without carrying credentials to the response URL.
      if ([301, 302, 303].contains(response.statusCode)) {
        final target = Uri.tryParse(response.headers['location'] ?? '');
        if (target == null ||
            target.scheme != 'https' ||
            target.host != 'script.googleusercontent.com') {
          throw StateError('The account service returned an invalid response.');
        }
        response = await client
            .get(target)
            .timeout(const Duration(seconds: 30));
      }
      if (response.statusCode != 200) {
        throw StateError('The account service is unavailable. Please retry.');
      }
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['error'] is Map) {
        throw StateError(
          result['error']['message'] as String? ?? 'Please retry.',
        );
      }
      return Map<String, dynamic>.from(result['data'] as Map);
    } on FormatException {
      throw StateError('The account service could not respond. Please retry.');
    } finally {
      client.close();
    }
  }
}
