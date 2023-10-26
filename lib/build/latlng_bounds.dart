import 'dart:math';

import 'package:latlong2/latlong.dart';


class LatLngBounds {
  late final LatLng _sw;
  late final LatLng _ne;

  LatLngBounds(
    LatLng corner1,
    LatLng corner2,
  ) : this.fromPoints([corner1, corner2]);

  LatLngBounds.fromPoints(Iterable<LatLng> points) : assert(
    points.length >= 2,
    'LatLngBounds requires at least 2 LatLng points',
  ) {
    double minX = 180;
    double maxX = -180;
    double minY = 90;
    double maxY = -90;

    for (final point in points) {
      minX = min(minX, point.longitude);
      minY = min(minY, point.latitude);
      maxX = max(maxX, point.longitude);
      maxY = max(maxY, point.latitude);
    }

    _sw = LatLng(minY, minX);
    _ne = LatLng(maxY, maxX);
  }

  /// Expects a Geometry Object
  /// See: https://geojson.org/geojson-spec.html#geometry-objects

  factory LatLngBounds.fromGeoJsonGeometry(Map<String, dynamic> geometry) {
    final String geometryType = geometry['type'];
    final List<dynamic> coordinates = geometry['coordinates'];

    switch (geometryType) {
      case 'MultiPolygon':
        final points = coordinates
          .expand((e) => e.first)
          .map<LatLng>((p) => LatLng(p[1].toDouble(), p[0].toDouble()));
        return LatLngBounds.fromPoints(points);

      case 'Polygon':
        final points = coordinates.first
          .map<LatLng>((p) => LatLng(p[1].toDouble(), p[0].toDouble()));
        return LatLngBounds.fromPoints(points);

      default:
        throw 'The geometry type: $geometryType is not supported';
    }
  }

  double get minX => _sw.longitude;
  double get maxX => _ne.longitude;
  double get minY => _sw.latitude;
  double get maxY => _ne.latitude;

  @override
  int get hashCode => Object.hash(_sw, _ne);

  @override
  bool operator ==(Object other) =>
      other is LatLngBounds && other._sw == _sw && other._ne == _ne;
}
