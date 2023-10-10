// ignore_for_file: avoid_print
import 'package:example/offline_geocoder/geo_feature_collection.dart';
import 'package:latlong2/latlong.dart';


void main() {
  final geoCoder = GeoCoder();
  final result = geoCoder.getFromLocation(LatLng(45.992979, 8.961235));
  print(result?.sovereignt);
  print(result?.isoA2);
}

