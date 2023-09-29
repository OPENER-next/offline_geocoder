import 'package:latlong2/latlong.dart';

/// Interface for geographic area shapes.

abstract class Area {

  /// Checks whether a given point is inside the area of the shape.

  bool containsPoint(LatLng point);
}

/// A simple polygon without holes.

class Ring implements Area {
  final List<LatLng> points;
  const Ring(this.points);

  @override
  bool containsPoint(LatLng point) {
    // Ray casting algorithm
    // derived from: https://stackoverflow.com/a/13951139

    var lastPoint = points.last;
    var isInside = false;
    final x = point.longitude;
    for (final pathPoint in points) {
      var x1 = lastPoint.longitude;
      var x2 = pathPoint.longitude;
      var dx = x2 - x1;

      if (dx.abs() > 180.0) {
        // we have, most likely, just jumped the dateline; normalise the numbers.
        if (x > 0) {
          while (x1 < 0) {
            x1 += 360;
          }
          while (x2 < 0) {
            x2 += 360;
          }
        }
        else {
          while (x1 > 0) {
            x1 -= 360;
          }
          while (x2 > 0) {
            x2 -= 360;
          }
        }
        dx = x2 - x1;
      }

      if ((x1 <= x && x2 > x) || (x1 >= x && x2 < x)) {
        final grad = (pathPoint.latitude - lastPoint.latitude) / dx;
        final intersectAtLat = lastPoint.latitude + ((x - x1) * grad);

        if (intersectAtLat > point.latitude) {
          isInside = !isInside;
        }
      }
      lastPoint = pathPoint;
    }

    return isInside;
  }
}

/// A polygon with an outer boundary and multiple inner holes.

class Polygon implements Area {
  final Ring outer;
  final List<Ring> inner;
  const Polygon(this.outer, [this.inner = const []]);

  @override
  bool containsPoint(LatLng point) {
    return
      outer.containsPoint(point) &&
      inner.every((r) => !r.containsPoint(point));
  }
}

/// Multiple none overlapping polygons.

class MultiPolygon implements Area {
  final List<Polygon> polygons;
  const MultiPolygon(this.polygons);

  @override
  bool containsPoint(LatLng point) {
    return polygons.any((p) => p.containsPoint(point));
  }
}
