library offline_geocoder;
export '/src/geo_feature_base.dart';
export '/src/area.dart';

import 'package:build/build.dart';
import 'build/geo_feature_builder.dart';

Builder geoFeatureBuilder(BuilderOptions options) => GeoFeatureBuilder(options);
