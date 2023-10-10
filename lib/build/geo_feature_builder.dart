import 'dart:io';
import 'package:geojson/geojson.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';

class GeoFeatureBuilder implements Builder{

  @override
  Map<String, List<String>> get buildExtensions => {
    options.config['source_file'] : ['${options.config['output_file_location']}geo_feature_collection.dart']
  };

  late Map<dynamic, dynamic> propertiesToExtract ;
  final List<Map<String, dynamic>> finalGeoFeatureList = [];
  final BuilderOptions options;

  GeoFeatureBuilder(this.options);

  @override
  Future<void> build(BuildStep buildStep) async {

    final AssetId inputId = buildStep.inputId;

    try {
        final features = await featuresFromGeoJsonFile(File(inputId.path));
        propertiesToExtract = options.config['extract_properties'];
        extractData(features);
        final String code = createClass();
        final lastSegment = inputId.uri.pathSegments.last;
        final outputId = AssetId(inputId.package, inputId.path
          .replaceFirst(inputId.path.toString().replaceAll(lastSegment, ''), options.config['output_file_location'])
          .replaceFirst(lastSegment, 'geo_feature_collection.dart'),
        );
        await buildStep.writeAsString(outputId, code);
    } catch (e) {
        print('Failed to generate class: $e');
    }
  }

  void extractData(GeoJsonFeatureCollection data) {
    for (final feature in data.collection) {
      final Map<String, dynamic> extractedProperties = {};
      for (final key in propertiesToExtract.keys) {
        extractedProperties.addAll({ReCase(key).camelCase : feature.properties![key]});
      }
      if (feature.geometry.runtimeType == GeoJsonPolygon){
        final polygon = convertPolygonData(feature.geometry);
        extractedProperties.addAll({'area': refer('MultiPolygon')
          .newInstance([literalList([[polygon]])])});
      }
      else if (feature.geometry.runtimeType == GeoJsonMultiPolygon){
        final polygons = [];
        for (final geoPolygon in feature.geometry.polygons) {
          final polygon = convertPolygonData(geoPolygon);
          polygons.add(polygon);
        }
        extractedProperties.addAll({'area': refer('MultiPolygon').newInstance([literalList([polygons])])});
      } 
      finalGeoFeatureList.add(extractedProperties);
    }
  }

  dynamic convertPolygonData(GeoJsonPolygon geoJsonPolygon){
    late dynamic outer,inner;
    final dynamic listRings = [];
    for (int index = 0; index < geoJsonPolygon.geoSeries.length; index++) {
      final points = [];
      for (final geopoint in geoJsonPolygon.geoSeries[index].geoPoints){
        points.add(refer('LatLng').newInstance([literalNum(geopoint.latitude),literalNum(geopoint.longitude)]));
      }
      index == 0 ? 
        outer = refer('Ring').newInstance([literalList([points])]) :
        listRings.add(refer('Ring').newInstance([literalList([points])]));
    }

    if(listRings.isEmpty){
      inner = literalList([[]]);
    }
    else{
      inner = literalList([listRings]);
    }
    return refer('Polygon').newInstance([refer(outer.toString()), refer(inner.toString())]);
}

  String createClass(){
    final library = Library((b) => b
      ..directives.add(Directive.import('package:offline_geocoder/offline_geocoder.dart'))
      ..directives.add(Directive.import('package:latlong2/latlong.dart'))
      ..body.addAll([geoFeatureClass().build(), geoCoderClass().build()]));

    final dartfmt = DartFormatter();
    return dartfmt.format('${library.accept(DartEmitter.scoped())}').toString();
  }

  ClassBuilder geoFeatureClass(){

    final classFields = propertiesToExtract.entries.map((entry) { 
      return Field((b) => b
        ..modifier = FieldModifier.final$
        ..name = ReCase(entry.key).camelCase 
        ..type = Reference(entry.value,'dart:core').type);
    });

    final constructorParameters = propertiesToExtract.entries.map((entry) {
      return Parameter((b) => b
        ..name = ReCase(entry.key).camelCase
        ..named = true
        ..toThis = true);
    });

    return ClassBuilder()
      ..name = 'GeoFeature'
      ..extend = refer('GeoFeatureBase')
      ..fields.addAll(classFields)
      ..constructors.add(Constructor((b) => b
        ..constant = true
        ..requiredParameters.addAll(constructorParameters)
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'area'
          ..named = true
          ..toSuper = true))
      ));
  }

  ClassBuilder geoCoderClass(){

     final geoFeatures = finalGeoFeatureList.map((e) {
      final List<Reference> geoFeatureParameters = [];
      for (final key in propertiesToExtract.keys) {
          propertiesToExtract[key] == 'String' 
          ? geoFeatureParameters.add(refer("'${e[ReCase(key).camelCase]}'"))
          : geoFeatureParameters.add(refer('${e[ReCase(key).camelCase]}'));
      }
      geoFeatureParameters.add(e['area']);
      return refer('GeoFeature').newInstance(geoFeatureParameters);
    }).toList();

    print(geoFeatures.toString());
    return ClassBuilder()
      ..name = 'GeoCoder'
      ..constructors.add(Constructor((b) => b))
      ..fields.add(Field((b) => b
        ..name = 'Test'
        ..modifier = FieldModifier.final$
        ..assignment = literalList([geoFeatures], refer('List<GeoFeature>')).code))
      ..methods.add(Method((b) => b
        ..name = 'getFromLocation'
        //..static = true 
        ..returns = refer('GeoFeature?')
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'point'
          ..type = refer('LatLng')))
        ..body = refer('firstGeoFeatureContainingPoint<GeoFeature>').call([refer('point'), refer('geoFeatures')]).code))
    ;
  }
}
