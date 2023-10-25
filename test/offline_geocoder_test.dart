import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

// run with: `dart run build_runner test` to generate the import file
import 'offline_geocoder.dart';

void main() {
  const coordinatesByCity = {
    ('Japan', 'JP', 2): LatLng(35.682839, 139.759455), // Tokyo, Japan
    ('Australia', 'AU', 2): LatLng(-33.867868, 151.209609), // Sydney, Australia
    ('Brazil', 'BR', 2): LatLng(-22.9068, -43.1729),  // Rio de Janeiro, Brazil
    ('Italy', 'IT', 2): LatLng(45.440847, 12.315515), // Venice, Italy
    ('United States of America', 'US', 2): LatLng(21.285002, -157.835672), // Honolulu, USA
    ('Canada', 'CA', 2): LatLng(49.2827, -123.1207),   // Vancouver, Canada
    ('Fiji', 'FJ', 2): LatLng(-18.141600, 178.444828), // Suva, Fiji
    ('Spain', 'ES', 2): LatLng(41.3851, 2.1734),  // Barcelona, Spain
    ('South Africa', 'ZA', 2): LatLng(-33.9249, 18.4241), // Cape Town, South Africa
    ('Lesotho', 'LS', 2): LatLng(-29.342362, 27.519617), // Maseru, Lesotho
  };

  for (final MapEntry(key: countryData, value: coordinate) in coordinatesByCity.entries) {
    final result = GeoCoder.getFromLocation(coordinate);
    test('Test country: ${countryData.$1}', () {
      expect(result?.name, countryData.$1);
      expect(result?.isoA2, countryData.$2);
      expect(result?.level, countryData.$3);
    });
  }
}
