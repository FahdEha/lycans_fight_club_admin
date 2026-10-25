import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dskg4lsue';
  static const String _apiKey = '743598513257411';
  static const String _apiSecret = '6q22MvMNiFvSvZeqbCyiL4bAWec';
  static const String _folder = 't2_daily_attendance';

  static String _signature(Map<String, String> params) {
    final sorted = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final payload =
        '${sorted.map((e) => '${e.key}=${e.value}').join('&')}$_apiSecret';
    return sha1.convert(utf8.encode(payload)).toString();
  }

  /// Returns secure_url on success, null on failure.
  static Future<String?> uploadImage(File file) async {
    try {
      final timestamp =
      (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final params = {'timestamp': timestamp, 'folder': _folder};
      final signature = _signature(params);

      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ..fields['folder'] = _folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await req.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}