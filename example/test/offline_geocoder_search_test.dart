import 'package:flutter_test/flutter_test.dart';
import 'package:example/offline_geocoder/offline_geocoder.dart';
import 'package:latlong2/latlong.dart';

Future<void> main() async {

  const coordinatesByCity = {
    'JP': LatLng(35.682839, 139.759455), // Tokyo, Japan
    'AU': LatLng(-33.867868, 151.209609), // Sydney, Australia
    'TR': LatLng(41.008238, 28.978359),  // Istanbul, Turkey
    'IT': LatLng(45.440847, 12.315515), // Venice, Italy
    'US': LatLng(21.285002, -157.835672), // Honolulu, USA
    'MV': LatLng(4.174893, 73.509347),   // Malé, Maldives
    'FJ': LatLng(-18.141600, 178.444828), // Suva, Fiji
    'MU': LatLng(-20.163905, 57.504137),  // Port Louis, Mauritius
    'ES': LatLng(38.906103, 1.420314), // Ibiza, Spain
    'LS': LatLng(-29.342362, 27.519617), // Maseru, Lesotho
  };

  for (final entry in coordinatesByCity.entries) {
    final country = entry.key;
    final coordinate = entry.value;
    final result = GeoCoder.getFromLocation(coordinate);
    var actualCountryCode = '';
    if (result != null) {
      actualCountryCode = result.isoA2;
    }
    test('Test for country $country', () {
      expect(actualCountryCode, country);
    });
  }
}

