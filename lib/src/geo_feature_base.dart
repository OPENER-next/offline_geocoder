import 'package:latlong2/latlong.dart';

import 'area.dart';


T? firstGeoFeatureContainingPoint<T extends GeoFeatureBase>(LatLng point, Iterable<T> geoFeatures) {
  for (final feature in geoFeatures) {
    if (feature.area.containsPoint(point)) return feature;
  }
  return null;
}

abstract class GeoFeatureBase {
  final Area area;
  const GeoFeatureBase(this.area);
}
