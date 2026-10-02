import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/drop_off_point.dart';

class DropOffService {
  DropOffService({http.Client? client}) : _client = client ?? http.Client();

  static const cirestEpci = '249740093';
  static const _cacheKey = 'drop_off_points_cirest';
  static const _cacheAtKey = 'drop_off_points_cirest_at';
  static const _ttl = Duration(days: 7);
  static const _endpoint =
      'https://data.ademe.fr/data-fair/api/v1/datasets/longue-vie-aux-objets-acteurs-de-leconomie-circulaire/lines';

  final http.Client _client;

  Future<List<DropOffPoint>> loadPoints({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final cached = _readCache(prefs);
      if (cached != null) return cached;
    }

    try {
      final fresh = await _fetchRemote();
      await _writeCache(prefs, fresh);
      return fresh;
    } catch (_) {
      return _readCache(prefs, ignoreTtl: true) ?? [];
    }
  }

  Future<List<DropOffPoint>> _fetchRemote() async {
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'qs': 'code_epci:$cirestEpci',
        'size': '1000',
        'select': [
          'identifiant',
          'nom',
          'nom_commercial',
          'adresse',
          'ville',
          'code_postal',
          'latitude',
          'longitude',
          'telephone',
          'horaires_description',
          'horaires_osm',
          'consignes_dacces',
          'type_dacteur',
          'lieu_prestation',
          'trier',
          'paternite',
          'site_web',
        ].join(','),
      },
    );

    final response = await _client
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'NotiWaste/1.0 (Sainte-Rose, La Reunion)',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('ADEME HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map;
    final results = body['results'] as List<dynamic>? ?? [];
    final points = <DropOffPoint>[];
    for (final raw in results) {
      if (raw is! Map) continue;
      final point = DropOffPoint.tryParse(Map<String, dynamic>.from(raw));
      if (point != null) points.add(point);
    }
    points.sort((a, b) => a.displayName.compareTo(b.displayName));
    return points;
  }

  List<DropOffPoint>? _readCache(
    SharedPreferences prefs, {
    bool ignoreTtl = false,
  }) {
    final raw = prefs.getString(_cacheKey);
    final cachedAtMs = prefs.getInt(_cacheAtKey);
    if (raw == null || cachedAtMs == null) return null;
    if (!ignoreTtl) {
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
      );
      if (age > _ttl) return null;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final points = <DropOffPoint>[];
    for (final rawPoint in decoded) {
      if (rawPoint is! Map) continue;
      final point = DropOffPoint.tryParse(Map<String, dynamic>.from(rawPoint));
      if (point != null) points.add(point);
    }
    return points;
  }

  Future<void> _writeCache(
    SharedPreferences prefs,
    List<DropOffPoint> points,
  ) async {
    await prefs.setString(
      _cacheKey,
      jsonEncode(points.map((point) => point.toJson()).toList()),
    );
    await prefs.setInt(_cacheAtKey, DateTime.now().millisecondsSinceEpoch);
  }
}
