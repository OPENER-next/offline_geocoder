import 'package:latlong2/latlong.dart';
import 'package:flatbush_dart/flatbush_dart.dart';

import 'area.dart';


T? firstGeoFeatureContainingPoint<T extends GeoFeatureBase>(LatLng point, List<T> geoFeatures, Geoflatbush flatbush) {
  final nearbyFeatures = flatbush
    .around(point.longitude, point.latitude, maxDistance: 0)
    .map((i) => geoFeatures[i]);

  for (final feature in nearbyFeatures) {
    if (feature.area.containsPoint(point)) return feature;
  }
  return null;
}

abstract class GeoFeatureBase {
  final Area area;
  const GeoFeatureBase(this.area);
}
