import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double? distanceMeters;
  final double? durationSeconds;
  final String provider;

  const RouteResult({
    required this.points,
    required this.provider,
    this.distanceMeters,
    this.durationSeconds,
  });
}

class RoutingService {
  static const List<String> _osrmProviders = [
    'https://router.project-osrm.org',
    'https://routing.openstreetmap.de/routed-car',
  ];

  const RoutingService();

  Future<RouteResult> getDrivingRoute({
    required LatLng origin,
    required LatLng destination,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    Object? lastError;

    for (final provider in _osrmProviders) {
      try {
        final uri = Uri.parse(
          '$provider/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=false&alternatives=false',
        );

        final response = await http.get(uri).timeout(timeout);
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }

        final payload = json.decode(response.body) as Map<String, dynamic>;
        if (payload['code'] != 'Ok') {
          throw Exception('Routing response code: ${payload['code']}');
        }

        final routes = (payload['routes'] as List<dynamic>? ?? const []);
        if (routes.isEmpty) {
          throw Exception('No routes returned');
        }

        final route = routes.first as Map<String, dynamic>;
        final geometry = route['geometry'] as Map<String, dynamic>?;
        final coordinates = (geometry?['coordinates'] as List<dynamic>? ?? const []);

        final points = <LatLng>[];
        for (final pair in coordinates) {
          if (pair is! List || pair.length < 2) continue;
          final lng = (pair[0] as num?)?.toDouble();
          final lat = (pair[1] as num?)?.toDouble();
          if (lat == null || lng == null) continue;
          points.add(LatLng(lat, lng));
        }

        if (points.length < 2) {
          throw Exception('Route geometry is empty');
        }

        return RouteResult(
          points: points,
          distanceMeters: (route['distance'] as num?)?.toDouble(),
          durationSeconds: (route['duration'] as num?)?.toDouble(),
          provider: provider,
        );
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('All routing providers failed: $lastError');
  }
}
