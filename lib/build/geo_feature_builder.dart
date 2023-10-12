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
        final propertiesToExtract = options.config['extract_properties'];
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

  List<Map<String, dynamic>> buildGeoFeatureListInstance(Map<String, dynamic> geoJSONData, dynamic propertiesToExtract) {

    final features = geoJSONData['features'] as List<dynamic>;
    final List<Map<String, dynamic>> geoFeatureList = [];

    for (final Map<String, dynamic> featureData in features) {
      final Map<String, dynamic> extractedProperties = {};
      if (featureData.containsKey('properties')) {
        final Map<String, dynamic> featureProperties = featureData['properties'];
        for (final key in propertiesToExtract.keys) {
          extractedProperties.addAll({ReCase(key).camelCase : featureProperties[key]});
        }
      }
      final geometry = featureData['geometry'] as Map<String, dynamic>;
      final geometryType = geometry['type'].toString();
      final coordinates = geometry['coordinates'] as List<dynamic>;
      switch (geometryType) {
        case 'MultiPolygon':
          final List<Expression> polygons = [];
          for (final List<dynamic> geoPolygons in coordinates) {
            final polygon = buildPolygonInstance(geoPolygons);
            polygons.add(polygon);
          }
          extractedProperties.addAll({'area': buildMultiPolygonInstance(polygons)});
        case 'Polygon':
          final polygon = buildPolygonInstance(coordinates);
          extractedProperties.addAll({'area': buildMultiPolygonInstance([polygon])});
        default:
          throw 'The geometry type: $geometryType is not supported';
      }
      geoFeatureList.add(extractedProperties);
    } 
    return geoFeatureList;
  }

  Expression buildMultiPolygonInstance(List<Expression> polygons) {
    final multiPolygonRefer = refer('MultiPolygon');
    return multiPolygonRefer.newInstance([literalList(polygons)]);
  }

  Expression buildPolygonInstance(List<dynamic> geoPolygons) {
    late Expression outer;
    late List<Expression> inner;
    final List<Expression> listPoints = [];
    final List<Expression> listRings = [];

    for (int index = 0; index < geoPolygons.length; index++) {
      listPoints.clear();
      for (final List<dynamic> geoPoint in geoPolygons[index]){
        final latitude = geoPoint[0];
        final longitude = geoPoint[1];
        listPoints.add(buildLatLngInstance(latitude, longitude));
      }

    index == 0 ? 
        outer = buildRingInstance(listPoints) :
        listRings.add(buildRingInstance(listPoints));
    }

    if(listRings.isEmpty){
      inner = [buildRingInstance([])];
    }
 
    final polygonRefer = refer('Polygon');
    return polygonRefer.newInstance([outer, literalList(inner)]);
  }

  Expression buildRingInstance(List<Expression> latLngInstances) {
    final ringRefer = refer('Ring');
    return ringRefer.newInstance([literalList(latLngInstances)]);
  }

  Expression buildLatLngInstance(num latitude, num longitude) {
    final latLngRef = refer('LatLng');
    return latLngRef.newInstance([literalNum(latitude),literalNum(longitude)]);
  }

  String generateFileCode(List<Map<String, dynamic>> geoFeatureList, dynamic propertiesToExtract){
    final geoFeatureClass = buildGeoFeatureClass(propertiesToExtract);
    final geoCoderClass = buildGeoCoderClass(geoFeatureList,propertiesToExtract);
    final library = Library((b) => b
      ..directives.add(Directive.import('package:offline_geocoder/offline_geocoder.dart'))
      ..directives.add(Directive.import('package:latlong2/latlong.dart'))
      ..body.addAll([geoFeatureClass, geoCoderClass]
    ));
    final dartfmt = DartFormatter();
    return dartfmt.format('${library.accept(DartEmitter.scoped())}').toString();
  }

  Class buildGeoFeatureClass(dynamic propertiesToExtract) {
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

  Class buildGeoCoderClass(List<Map<String, dynamic>> geoFeatureList, dynamic propertiesToExtract) {
     final geoFeatureRefer = refer('GeoFeature');
     final List<Expression> geoFeatures = geoFeatureList.map((e) {
     final List<Expression> geoFeatureParameters = [];
      for (final key in propertiesToExtract.keys) {
          propertiesToExtract[key] == 'String' 
          ? geoFeatureParameters.add(refer('"${e[ReCase(key).camelCase]}"'))
          : geoFeatureParameters.add(refer('${e[ReCase(key).camelCase]}'));
      }
      geoFeatureParameters.add(e['area']);
      return geoFeatureRefer.newInstance(geoFeatureParameters);
    }).toList(); 

    final geoCoderClass = ClassBuilder()
      ..name = 'GeoCoder'
      ..fields.add(Field((b) => b
        ..name = 'geoFeatures'
        ..modifier = FieldModifier.constant
        ..static = true
        ..assignment = literalList(geoFeatures).code
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
