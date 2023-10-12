import 'package:offline_geocoder/offline_geocoder.dart';
import 'package:latlong2/latlong.dart';

class GeoFeature extends GeoFeatureBase {
  const GeoFeature(
    this.sovereignt,
    this.isoA2,
    this.level,
    super.area,
  );

  final String sovereignt;

  final String isoA2;

  final int level;
}

class GeoCoder {
  static const geoFeatures = [
    GeoFeature(
      "Fiji",
      "FJ",
      2,
      MultiPolygon([
        Polygon(
          Ring([
            LatLng(
              180,
              -16.067133,
            ),
            LatLng(
              180,
              -16.555217,
            ),
          ]),
          [Ring([])],
        ),
        Polygon(
          Ring([
            LatLng(
              178.12557,
              -17.50481,
            ),
            LatLng(
              178.3736,
              -17.33992,
            ),
          ]),
          [Ring([])],
        ),
        Polygon(
          Ring([
            LatLng(
              -179.79332,
              -16.020882,
            ),
            LatLng(
              -179.917369,
              -16.501783,
            ),
          ]),
          [Ring([])],
        ),
      ]),
    ),
    GeoFeature(
      "United Republic of Tanzania",
      "TZ",
      2,
      MultiPolygon([
        Polygon(
          Ring([
            LatLng(
              33.903711,
              -0.95,
            ),
            LatLng(
              34.07262,
              -1.05982,
            ),
          ]),
          [Ring([])],
        )
      ]),
    ),
  ];

  static GeoFeature? getFromLocation(LatLng point) =>
      firstGeoFeatureContainingPoint<GeoFeature>(
        point,
        geoFeatures,
      );
}
