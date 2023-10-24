
import 'package:build_test/build_test.dart';
import 'package:offline_geocoder/offline_geocoder.dart';
import 'package:test/test.dart';
import 'package:build/build.dart';

void main() async {
  var buildOptions = BuilderOptions(const {'source_file': 'assets/ne_110m_admin_0_countries_example.geojson',
    'output_file': 'lib/test/offline_geocoder/offline_geocoder.dart',
    'extract_properties': {"SOVEREIGNT": "String", "ISO_A2": "String", "LEVEL": "int"}
  });
  var writer = InMemoryAssetWriter();
  var reader = await PackageAssetReader.currentIsolate(rootPackage: 'offline_geocoder');
  var assets = {'offline_geocoder|${buildOptions.config['source_file']}': '',};
  var expectedOutputs = {
      'offline_geocoder|${buildOptions.config['output_file']}': decodedMatches(
          (
'''import 'package:offline_geocoder/offline_geocoder.dart';
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
        Polygon(Ring([
          LatLng(
            -16.067133,
            180,
          ),
          LatLng(
            -16.555217,
            180,
          ),
          LatLng(
            -16.801354,
            179.364143,
          ),
          LatLng(
            -17.012042,
            178.725059,
          ),
          LatLng(
            -16.63915,
            178.596839,
          ),
          LatLng(
            -16.433984,
            179.096609,
          ),
          LatLng(
            -16.379054,
            179.413509,
          ),
          LatLng(
            -16.067133,
            180,
          ),
        ])),
        Polygon(Ring([
          LatLng(
            -17.50481,
            178.12557,
          ),
          LatLng(
            -17.33992,
            178.3736,
          ),
          LatLng(
            -17.62846,
            178.71806,
          ),
          LatLng(
            -18.15059,
            178.55271,
          ),
          LatLng(
            -18.28799,
            177.93266,
          ),
          LatLng(
            -18.16432,
            177.38146,
          ),
          LatLng(
            -17.72465,
            177.28504,
          ),
          LatLng(
            -17.38114,
            177.67087,
          ),
          LatLng(
            -17.50481,
            178.12557,
          ),
        ])),
        Polygon(Ring([
          LatLng(
            -16.020882,
            -179.79332,
          ),
          LatLng(
            -16.501783,
            -179.917369,
          ),
          LatLng(
            -16.555217,
            -180,
          ),
          LatLng(
            -16.067133,
            -180,
          ),
          LatLng(
            -16.020882,
            -179.79332,
          ),
        ])),
      ]),
    ),
    GeoFeature(
      "United Republic of Tanzania",
      "TZ",
      2,
      Polygon(Ring([
        LatLng(
          -0.95,
          33.903711,
        ),
        LatLng(
          -1.05982,
          34.07262,
        ),
        LatLng(
          -3.09699,
          37.69869,
        ),
        LatLng(
          -3.67712,
          37.7669,
        ),
        LatLng(
          -4.67677,
          39.20222,
        ),
        LatLng(
          -5.90895,
          38.74054,
        ),
        LatLng(
          -6.47566,
          38.79977,
        ),
        LatLng(
          -6.84,
          39.44,
        ),
        LatLng(
          -7.1,
          39.47,
        ),
        LatLng(
          -7.7039,
          39.19469,
        ),
        LatLng(
          -8.00781,
          39.25203,
        ),
        LatLng(
          -8.48551,
          39.18652,
        ),
        LatLng(
          -9.11237,
          39.53574,
        ),
        LatLng(
          -10.0984,
          39.9496,
        ),
        LatLng(
          -10.317098,
          40.316586,
        ),
        LatLng(
          -10.3171,
          40.31659,
        ),
        LatLng(
          -10.89688,
          39.521,
        ),
        LatLng(
          -11.285202,
          38.427557,
        ),
        LatLng(
          -11.26879,
          37.82764,
        ),
        LatLng(
          -11.56876,
          37.47129,
        ),
        LatLng(
          -11.594537,
          36.775151,
        ),
        LatLng(
          -11.720938,
          36.514082,
        ),
        LatLng(
          -11.439146,
          35.312398,
        ),
        LatLng(
          -11.52002,
          34.559989,
        ),
        LatLng(
          -10.16,
          34.28,
        ),
        LatLng(
          -9.693674,
          33.940838,
        ),
        LatLng(
          -9.41715,
          33.73972,
        ),
        LatLng(
          -9.230599,
          32.759375,
        ),
        LatLng(
          -8.930359,
          32.191865,
        ),
        LatLng(
          -8.762049,
          31.556348,
        ),
        LatLng(
          -8.594579,
          31.157751,
        ),
        LatLng(
          -8.340006,
          30.74001,
        ),
        LatLng(
          -8.340007,
          30.740015,
        ),
        LatLng(
          -7.079981,
          30.199997,
        ),
        LatLng(
          -6.520015,
          29.620032,
        ),
        LatLng(
          -5.939999,
          29.419993,
        ),
        LatLng(
          -5.419979,
          29.519987,
        ),
        LatLng(
          -4.499983,
          29.339998,
        ),
        LatLng(
          -4.452389,
          29.753512,
        ),
        LatLng(
          -4.09012,
          30.11632,
        ),
        LatLng(
          -3.56858,
          30.50554,
        ),
        LatLng(
          -3.35931,
          30.75224,
        ),
        LatLng(
          -3.03431,
          30.74301,
        ),
        LatLng(
          -2.80762,
          30.52766,
        ),
        LatLng(
          -2.413855,
          30.469674,
        ),
        LatLng(
          -2.41383,
          30.46967,
        ),
        LatLng(
          -2.28725,
          30.758309,
        ),
        LatLng(
          -1.698914,
          30.816135,
        ),
        LatLng(
          -1.134659,
          30.419105,
        ),
        LatLng(
          -1.01455,
          30.76986,
        ),
        LatLng(
          -1.02736,
          31.86617,
        ),
        LatLng(
          -0.95,
          33.903711,
        ),
      ])),
    ),
  ];

  static GeoFeature? getFromLocation(LatLng point) =>
      firstGeoFeatureContainingPoint<GeoFeature>(
        point,
        geoFeatures,
      );
}
''')),
  };

  test('Class generated by builder is correct', () async {
  await testBuilder(
      geoFeatureBuilder(buildOptions), assets,
        rootPackage: 'offline_geocoder', outputs: expectedOutputs, reader: reader, writer: writer);
  });
 
}