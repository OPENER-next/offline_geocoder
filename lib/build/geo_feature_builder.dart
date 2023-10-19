import 'dart:core';
import 'dart:io';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';

class GeoFeatureBuilder implements Builder{

  final BuilderOptions options;

  GeoFeatureBuilder(this.options);
  
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
        final geoFeatureList = buildGeoFeatureListInstance(geoJSONData, propertiesToExtract);
        final code = generateFileCode(geoFeatureList,propertiesToExtract);
        final outputId = AssetId(inputId.package, inputId.path
          .replaceFirst(options.config['source_file'],options.config['output_file'])
        );
        await buildStep.writeAsString(outputId, code);
    } catch (e) {
        print('Failed to generate class: $e');
    }
  }

  String generateFileCode(LiteralListExpression geoFeatureList, Map<String, String> propertiesToExtract){
    final geoFeatureClass = buildGeoFeatureClass(propertiesToExtract);
    final geoCoderClass = buildGeoCoderClass(geoFeatureList);
    final library = Library((b) => b
      ..directives.add(Directive.import('package:offline_geocoder/offline_geocoder.dart'))
      ..directives.add(Directive.import('package:latlong2/latlong.dart'))
      ..body.addAll([geoFeatureClass, geoCoderClass]
    ));
    final dartfmt = DartFormatter();
    return dartfmt.format('${library.accept(DartEmitter.scoped())}').toString();
  }

  Future<Map<String, dynamic>> _readFile(File inputFile) async {
    if (!inputFile.existsSync()) {
      throw FileSystemException('The file ${inputFile.path} does not exist');
    }
    String data;
    try {
      data = await inputFile.readAsString();
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      throw FileSystemException('The file $e can not be read');
    }
  }

  LiteralListExpression buildGeoFeatureListInstance(Map<String, dynamic> geoJSONData, Map<String, String> propertiesToExtract) {
    final features = geoJSONData['features'].cast<Map<String, dynamic>>(); 
    final geoFeatureRefer = refer('GeoFeature');
    final List<Expression> geoFeatureList = [];
    for (final featureData in features) {
      final List<Expression> geoFeatureParameters = [];
      if (featureData.containsKey('properties')) {
        final featureProperties = featureData['properties'];
        for (final key in propertiesToExtract.keys) {
          propertiesToExtract[key] == 'String' 
          ? geoFeatureParameters.add(refer('"${featureProperties[key]}"'))
          : geoFeatureParameters.add(refer('${featureProperties[key]}'));
        }
      }
      final geometry = featureData['geometry'];
      final geometryType = geometry['type'].toString();
      final coordinates = geometry['coordinates'] as List<dynamic>;
      switch (geometryType) {
        case 'MultiPolygon':
          final multiPolygons = coordinates.map<Iterable<Iterable<List<num>>>>(
            (e) => (e as Iterable).map<Iterable<List<num>>>(
              (e) => (e as Iterable).map<List<num>>((e) => e.cast<num>()),
            )
          );
          geoFeatureParameters.add(buildMultiPolygonInstance(multiPolygons));
        case 'Polygon':
          final geoPolygons = coordinates.map<Iterable<List<num>>>(
            (e) => (e as Iterable).map<List<num>>((e) => e.cast<num>()),
          );
          geoFeatureParameters.add(buildPolygonInstance(geoPolygons));
        default:
          throw 'The geometry type: $geometryType is not supported';
      }
      geoFeatureList.add(geoFeatureRefer.newInstance(geoFeatureParameters));
    } 
    return literalList(geoFeatureList);
  }

  Expression buildMultiPolygonInstance(Iterable<Iterable<Iterable<List<num>>>> multiPolygons) {
    final multiPolygonRefer = refer('MultiPolygon');
    final List<Expression> polygons = [];
    for (final geoPolygons in multiPolygons) {
      final polygon = buildPolygonInstance(geoPolygons);
      polygons.add(polygon);
    }
    return multiPolygonRefer.newInstance([literalList(polygons)]);
  }

  Expression buildPolygonInstance(Iterable<Iterable<List<num>>> geoPolygons) {
    late Expression outer;
    final List<Expression> inner = [];
    final polygonRefer = refer('Polygon');
    final iterator = geoPolygons.iterator;
    iterator.moveNext();
    outer = buildRingInstance(iterator.current);
    while(iterator.moveNext()) {
      inner.add(buildRingInstance(iterator.current));
    } 
    if(inner.isEmpty){
      return polygonRefer.newInstance([outer]);
    }
    else{
      return polygonRefer.newInstance([outer, literalList(inner)]);
    }
  }

  Expression buildRingInstance(Iterable<List<num>>coordinates) {
    final ringRefer = refer('Ring');
    final List<Expression> listPoints = [];
    for(final geoPoint in coordinates){
      final latitude = geoPoint[1];
      final longitude = geoPoint[0];
      listPoints.add(buildLatLngInstance(latitude, longitude));
    }
    return ringRefer.newInstance([literalList(listPoints)]);
  }

  Expression buildLatLngInstance(num latitude, num longitude) {
    final latLngRef = refer('LatLng');
    return latLngRef.newInstance([literalNum(latitude),literalNum(longitude)]);
  }

  Class buildGeoFeatureClass(Map<String, String> propertiesToExtract) {
    final List<Field> classFields = [];
    final List<Parameter> constructorParameters = [];
    propertiesToExtract.forEach((key, value) { 
      classFields.add(Field((b) => b
        ..modifier = FieldModifier.final$
        ..name = ReCase(key).camelCase 
        ..type = Reference(value,'dart:core').type
        )
      );
      constructorParameters.add(Parameter((b) => b
        ..name = ReCase(key).camelCase
        ..named = true
        ..toThis = true
        )
      );
    });
    final geoFeatureClass = ClassBuilder()
      ..name = 'GeoFeature'
      ..extend = refer('GeoFeatureBase')
      ..fields.addAll(classFields)
      ..constructors.add(Constructor((b) => b
        ..constant = true
        ..requiredParameters.addAll(constructorParameters)
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'area'
          ..named = true
          ..toSuper = true
        ))
      ));
    return geoFeatureClass.build();
  }

  Class buildGeoCoderClass(LiteralListExpression geoFeatureList) {
    final geoCoderClass = ClassBuilder()
      ..name = 'GeoCoder'
      ..fields.add(Field((b) => b
        ..name = 'geoFeatures'
        ..modifier = FieldModifier.constant
        ..static = true
        ..assignment = geoFeatureList.code
      ))
      ..methods.add(Method((b) => b
        ..name = 'getFromLocation'
        ..static = true 
        ..returns = refer('GeoFeature?')
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'point'
          ..type = refer('LatLng')))
        ..body = refer('firstGeoFeatureContainingPoint<GeoFeature>')
          .call([refer('point'), refer('geoFeatures')]).code
      ))
    ;
    return geoCoderClass.build();
  }
}
