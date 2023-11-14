import 'dart:core';
import 'dart:io';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';
import 'package:flatbush_dart/flatbush_dart.dart';

import 'latlng_bounds.dart';

Builder geoFeatureBuilder(BuilderOptions options) => GeoFeatureBuilder(options);


class GeoFeatureBuilder implements Builder{

  final BuilderOptions options;

  GeoFeatureBuilder(this.options);

  static const _src = 'package:offline_geocoder/offline_geocoder.dart';

  @override
  Map<String, List<String>> get buildExtensions => {
    options.config['source_file'] : [ options.config['output_file'] ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final AssetId inputId = buildStep.inputId;
    try {
      final geoJSONData = await _readFile(File(inputId.path));
      final propertiesToExtract = options.config['extract_properties'].map<String,String>(
        (key, value) => MapEntry<String, String>(key.toString(), value.toString())
      );

      final library = Library((b) => b
        // ignore all linter rules for generated files
        ..ignoreForFile.add('type=lint')
        ..body.add(buildGeoFeatureClass(propertiesToExtract))
        ..body.add(buildGeoCoderClass(geoJSONData, propertiesToExtract))
      );
      final code = DartFormatter(fixes: StyleFix.all).format(library.accept(
        DartEmitter(allocator: Allocator()),
      ).toString());

      final outputId = AssetId(
        inputId.package,
        inputId.path.replaceFirst(
          options.config['source_file'],options.config['output_file'],
        ),
      );
      await buildStep.writeAsString(outputId, code);
    } catch (e, s) {
      throw('Failed to generate GeoCoder class: $e', s);
    }
  }

  Future<Map<String, dynamic>> _readFile(File inputFile) async {
    if (!(await inputFile.exists())) {
      throw FileSystemException('The file ${inputFile.path} does not exist');
    }
    try {
      final data = await inputFile.readAsString();
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      throw FileSystemException('The file $e can not be read');
    }
  }

  /// Builds `class GeoFeature extends GeoFeatureBase { ... }`

  Class buildGeoFeatureClass(Map<String, String> propertiesToExtract) {
    final classFields = propertiesToExtract.entries.map((entry) {
      return Field((b) => b
        ..modifier = FieldModifier.final$
        ..name = ReCase(entry.key).camelCase
        ..type = refer(entry.value)
      );
    });
    final constructorParameters = propertiesToExtract.keys.map((name) {
      return Parameter((b) => b
        ..name = ReCase(name).camelCase
        ..named = true
        ..toThis = true
      );
    });

    return Class((b) => b
      ..name = 'GeoFeature'
      ..extend = refer('GeoFeatureBase', _src)
      ..fields.addAll(classFields)
      ..constructors.add(Constructor((b) => b
        ..constant = true
        ..requiredParameters.addAll(constructorParameters)
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'area'
          ..named = true
          ..toSuper = true
        )),
      )),
    );
  }

  /// Builds `class GeoCoder { ... }`

  Class buildGeoCoderClass(Map<String, dynamic> geoJSONData, Map<String, String> propertiesToExtract) {
    final features = geoJSONData['features'].cast<Map<String, dynamic>>();
    final geoflatbushInstance = buildGeoflatbushInstance(features);
    final geoFeatureList = buildGeoFeatureListInstance(features, propertiesToExtract);

    return Class((b) => b
      ..name = 'GeoCoder'
      ..abstract = true
      ..fields.add(Field((b) => b
        ..name = 'geoFeatures'
        ..modifier = FieldModifier.constant
        ..static = true
        ..assignment = geoFeatureList.code
      ))
      ..fields.add(Field((b) => b
        ..name = '_flatbushData'
        ..modifier = FieldModifier.final$
        ..static = true
        ..assignment = geoflatbushInstance.code
      ))
      ..methods.add(Method((b) => b
        ..name = 'getFromLocation'
        ..static = true
        ..returns = refer('GeoFeature?')
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'point'
          ..type = refer('LatLng', _src)
        ))
        ..body = refer('firstGeoFeatureContainingPoint<GeoFeature>', _src)
          .call([
            refer('point'), refer('geoFeatures'), refer('_flatbushData'),
          ]).code,
      )),
    );
  }

  /// 1. Calculates flatbush indexes
  /// 2. Stores all indexes as a base64 string
  /// 3. Builds a `Geoflatbush` instance that consumes the previous calculated index data
  /// ```dart
  /// Geoflatbush(
  ///   (Flatbush.from(
  ///     base64Decode(r'data_string'.buffer
  ///   ) as Flatbush<TypedData, double>)
  /// )
  /// ```
  Expression buildGeoflatbushInstance(List<Map<String, dynamic>> features) {
    // double64 to store precise lat lng
    final flatbush = Flatbush.double64(features.length, nodeSize: 3);
    for (final feature in features) {
      final bounds = LatLngBounds.fromGeoJsonGeometry(feature['geometry']);
      flatbush.add(
        minX: bounds.minX, minY: bounds.minY,
        maxX: bounds.maxX, maxY: bounds.maxY,
      );
    }
    flatbush.finish();
    // convert flatbush index to base64 string so it can be easily stored in code.
    final base64DataString = base64Encode(flatbush.data.asUint8List());

    final geoFlatbushRef = refer('Geoflatbush', _src);
    final flatbushFromRef = refer('Flatbush.from', _src);
    final flatbushTypedRef = TypeReference((b) => b
      ..symbol = 'Flatbush'
      ..url = _src
      ..types.add(refer('TypedData', 'dart:typed_data'))
      ..types.add(refer('double'),
    ));
    final base64DecodeRef = refer('base64Decode', 'dart:convert');

    return geoFlatbushRef.newInstance([
      flatbushFromRef.call([
        base64DecodeRef.call([
          literalString(base64DataString, raw: true),
        ]).property('buffer'),
      // required because type cannot be inferred correctly
      ]).asA(flatbushTypedRef),
    ]);
  }

  /// Builds `[ GeoFeature(...), GeoFeature(...), ... ]`

  LiteralListExpression buildGeoFeatureListInstance(List<Map<String, dynamic>> features, Map<String, String> propertiesToExtract) {
    final geoFeatureRefer = refer('GeoFeature', _src);

    final geoFeatures = features.map((feature) {
      // build parameters from selected properties
      final featureProperties = feature['properties'];
      final geoFeatureParameters = [
        for (final key in propertiesToExtract.keys) literal(featureProperties[key]),
      ];
      // build area parameter
      final featureGeometry = feature['geometry'];
      final geometryType = featureGeometry['type'] as String;
      final coordinatesGeoJSON = featureGeometry['coordinates'] as List<dynamic>;
      switch (geometryType) {
        case 'MultiPolygon':
          final coordinates = coordinatesGeoJSON.map<Iterable<Iterable<List<num>>>>(
            (e) => (e as Iterable).map<Iterable<List<num>>>(
              (e) => (e as Iterable).map<List<num>>((e) => e.cast<num>()),
            ),
          );
          geoFeatureParameters.add(buildMultiPolygonInstance(coordinates));
        case 'Polygon':
          final coordinates = coordinatesGeoJSON.map<Iterable<List<num>>>(
            (e) => (e as Iterable).map<List<num>>((e) => e.cast<num>()),
          );
          geoFeatureParameters.add(buildPolygonInstance(coordinates));
        default:
          throw 'The geometry type: $geometryType is not supported';
      }
      return geoFeatureRefer.newInstance(geoFeatureParameters);
    });

    return literalList(geoFeatures);
  }

  /// Builds `MultiPolygon([Polygon(...), Polygon(...), ...])`

  Expression buildMultiPolygonInstance(Iterable<Iterable<Iterable<List<num>>>> coordinates) {
    final multiPolygonRefer = refer('MultiPolygon', _src);
    final polygons = coordinates.map(buildPolygonInstance);
    return multiPolygonRefer.newInstance([literalList(polygons)]);
  }

  /// Builds `Polygon(Ring(...), [Ring(...), ...])`

  Expression buildPolygonInstance(Iterable<Iterable<List<num>>> coordinates) {
    final List<Expression> inner = [];
    final polygonRefer = refer('Polygon', _src);
    final iterator = coordinates.iterator;
    // outer ring
    iterator.moveNext();
    final outer = buildRingInstance(iterator.current);
    // inner rings
    while (iterator.moveNext()) {
      inner.add(buildRingInstance(iterator.current));
    }
    if (inner.isEmpty){
      return polygonRefer.newInstance([outer]);
    }
    else {
      return polygonRefer.newInstance([outer, literalList(inner)]);
    }
  }

  /// Builds `Ring([LatLng(...), ...])`

  Expression buildRingInstance(Iterable<List<num>> coordinates) {
    final ringRefer = refer('Ring', _src);
    final listPoints = coordinates.map(
      (geoPoint) => buildLatLngInstance(geoPoint[1], geoPoint[0]),
    );
    return ringRefer.newInstance([literalList(listPoints)]);
  }

  /// Builds `LatLng(...)`

  Expression buildLatLngInstance(num latitude, num longitude) {
    final latLngRef = refer('LatLng', _src);
    return latLngRef.newInstance([literalNum(latitude),literalNum(longitude)]);
  }
}
