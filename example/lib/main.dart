// ignore_for_file: avoid_print
import 'package:example/offline_geocoder/offline_geocoder.dart';
import 'package:latlong2/latlong.dart';


void main() {
  final result = GeoCoder.getFromLocation(const LatLng(45.992979, 8.961235));
  print(result?.sovereignt);
  print(result?.isoA2);
}

