import 'package:latlong2/latlong.dart';

// run `dart run build_runner build` or `dart run build_runner watch` to generate the import file
import 'offline_geocoder/offline_geocoder.dart';


void main() {
  final result = GeoCoder.getFromLocation(const LatLng(-18.1248, 178.4501));
  print(result?.name);
  print(result?.isoA2);
  print(result?.level);
}
