# offline_geocoder

An agnostic package to reverse geocode locations from a presupplied `geojson` file. No internet connection or external services required as your geocoder is generated once ahead of time.

## Usage

### 1. Get your source GeoJSON `FeatureCollection`

You can get public domain licensed geo data from https://github.com/nvkelso/natural-earth-vector like [country borders](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_admin_0_countries.geojson).

#### Example `.geojson` file:
```geojson
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "NAME": "Fiji",
        "LEVEL": 2
      },
      "geometry": {
        "type": "MultiPolygon",
        "coordinates": [ ... ]
      }
    },
    ...
  ]
}
```

### 2. Create `build.yaml` config file

Add the [build_runner](https://pub.dev/packages/build_runner) package as a `dev_dependency` to your `pubspec.yaml`.
Then create a `build.yaml` file to make use of the `offline_geocoder` builder.

#### Example `build.yaml`

```yaml
targets:
  $default:
    builders:
      offline_geocoder:
        options:
          # define the location of the GeoJSON file that contains your FeatureCollection
          source_file: 'assets/ne_110m_admin_0_countries.geojson'
          # define the output location of the generated GeoCoder dart file
          output_file: 'lib/services/offline_geocoder.dart'
          # specify which properties you want to extract from the GeoJSON including their dart type
          extract_properties: {"NAME": "String", "LEVEL": "int"}
```

### 3. Generate and use the `GeoCoder`

Run `dart run build_runner build` or `dart watch build_runner build` from your project directory to generate the `GeoCoder` class.
Import the generated dart file and use the geocoder like this:
```dart
final result = GeoCoder.getFromLocation(point);
```

#### Example `main.dart`:

```dart
import 'package:latlong2/latlong.dart';
import '/services/offline_geocoder.dart';

void main() {
  final result = GeoCoder.getFromLocation(const LatLng(-18.1248, 178.4501));
  print(result?.name);
  print(result?.level);
}
```