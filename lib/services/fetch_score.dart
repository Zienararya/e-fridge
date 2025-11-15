// services/fetch_score.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static const String _baseUrl =
      'https://pauluswindi-prediction-sarima-api.hf.space';

  /// Memanggil endpoint /score dan mengembalikan kategori (mis. "Aman" / "Tidak Aman").
  /// Mengembalikan null jika gagal atau response tidak sesuai.
  static Future<String?> fetchKategori({
    int? deviceId,
    String lokasi = 'kulkas',
  }) async {
    try {
      int? id = deviceId;
      if (id == null) {
        final prefs = await SharedPreferences.getInstance();
        final deviceIdStr = prefs.getString('device_id');
        id = int.tryParse(deviceIdStr ?? '');
      }

      if (id == null) {
        return null;
      }

      final uri = Uri.parse('$_baseUrl/score');
      final resp = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'lokasi': lokasi, 'device_id': id}),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final skoring = json['skoring'];
        if (skoring is Map<String, dynamic>) {
          final kategori = skoring['kategori'];
          if (kategori is String) return kategori;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Memanggil endpoint /predict dan mengembalikan prediksi berikutnya
  /// dalam bentuk map: { 'suhu': double, 'kelembapan': double }
  /// Mengembalikan null jika gagal atau response tidak sesuai.
  static Future<Map<String, double>?> fetchPrediksiNext({
    int? deviceId,
    String lokasi = 'kulkas',
    int steps = 1,
  }) async {
    try {
      int? id = deviceId;
      if (id == null) {
        final prefs = await SharedPreferences.getInstance();
        final deviceIdStr = prefs.getString('device_id');
        id = int.tryParse(deviceIdStr ?? '');
      }

      if (id == null) return null;

      final uri = Uri.parse('$_baseUrl/predict');
      final resp = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'lokasi': lokasi, 'device_id': id, 'steps': steps}),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final pred = json['prediksi'];
        if (pred is List && pred.isNotEmpty && pred[0] is Map) {
          final m = pred[0] as Map;
          final suhu = (m['suhu'] as num?)?.toDouble();
          final kelembapan = (m['kelembapan'] as num?)?.toDouble();
          if (suhu != null && kelembapan != null) {
            return {'suhu': suhu, 'kelembapan': kelembapan};
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
