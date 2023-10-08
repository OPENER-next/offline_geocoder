import 'dart:io';
import 'package:geojson/geojson.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';

class GeoFeatureBuilder implements Builder{

  @override
  Map<String, List<String>> get buildExtensions => {
    options.config['source_file'] : ['lib/offline_geocoder/geo_feature_collection.dart']
  };

  final Map<String, String> propertiesToExtract = {};
  late String dataFolderPath;
  final List<Map<String, dynamic>> finalGeoFeatureList = [];
  final BuilderOptions options;

  GeoFeatureBuilder(this.options);

  @override
  Future<void> build(BuildStep buildStep) async {

    final AssetId inputId = buildStep.inputId;

    try {
        final features = await featuresFromGeoJsonFile(File(inputId.path));
        readConfiguration();
        extractData(features);
        final String code = createClass();
        final lastSegment = inputId.uri.pathSegments.last;
        final outputId = AssetId(inputId.package, inputId.path
          .replaceFirst(inputId.path.toString().replaceAll(lastSegment, ''), 'lib/offline_geocoder/')
          .replaceFirst(lastSegment, 'geo_feature_collection.dart'),
        );
        await buildStep.writeAsString(outputId, code);
    } catch (e) {
        print('Failed to generate class: $e');
    }
  }

  void readConfiguration(){

    final extractedProperties = options.config['extract_properties']
                          .toString()
                          .replaceAll('[', '')
                          .replaceAll(']', '')
                          .replaceAll('{', '')
                          .replaceAll('}', '')
                          .split(',');
    for (final element in extractedProperties) {
      final property = element.split(':');
      if (property.length == 2){
        propertiesToExtract.addAll({property[0].trim() : property[1].trim()});
      }
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
        extractedProperties.addAll({'area': 'MultiPolygon([$polygon])'});
      }
      else if (feature.geometry.runtimeType == GeoJsonMultiPolygon){
        final List<String> polygons = [];
        for (final geopPolygon in feature.geometry.polygons) {
          polygons.add(convertPolygonData(geopPolygon));
        }
        extractedProperties.addAll({'area': 'MultiPolygon($polygons)'});
      } 
      finalGeoFeatureList.add(extractedProperties);
    }
  }

  String convertPolygonData(GeoJsonPolygon geoJsonPolygon){
    late List<String> outer = [];
      final List<String> inner = [];
      for (int index = 0; index < geoJsonPolygon.geoSeries.length; index++) {
        final List<String> points = [];
        for (final geopoint in geoJsonPolygon.geoSeries[index].geoPoints){
          points.add('LatLng(${geopoint.latitude},${geopoint.longitude})');
        }
        index == 0 ? outer = points : inner.add('Ring($points)');
      }
    return 'Polygon(Ring($outer),$inner)';
  }

  String createClass(){

    final List<Field> classFields = [];
    final List<Parameter> constructorParameters = [];

    propertiesToExtract.forEach((key, value) { 
      classFields.add(Field((b) => b
        ..modifier = FieldModifier.final$
        ..name = ReCase(key).camelCase 
        ..type = Reference(value,'dart:core').type));
      constructorParameters.add(Parameter((b) => b
          ..name = ReCase(key).camelCase
          ..named = true
          ..toThis = true));
    });
    constructorParameters.add(Parameter((b) => b
            ..name = 'area'
            ..named = true
            ..toSuper = true
    ));

    final geoFeatureClass = ClassBuilder()
      ..name = 'GeoFeature'
      ..extend = refer('GeoFeatureBase')
      ..fields.addAll(classFields)
      ..constructors.add(Constructor((b) => b
        ..constant = true
        ..requiredParameters.addAll(constructorParameters)
      ));

    final geoFeatureCollection = finalGeoFeatureList.map((e) {
      var constructor = '';
      for (final key in propertiesToExtract.keys) {
          final propertyValue = propertiesToExtract[key] == 'String' 
          ? '\'${e[ReCase(key).camelCase].toString()}\',' 
          : '${e[ReCase(key).camelCase].toString()},';
           constructor = '$constructor $propertyValue';
      }
      constructor = '$constructor ${e['area']}';
      return 'GeoFeature($constructor)';
    }).toList();

    final geoFeatureCollectionClass = ClassBuilder()
      ..name = 'GeoFeatureCollection'
      ..extend = refer('GeoFeatureCollectionBase')
      ..constructors.add(Constructor((b) => b))
      ..fields.add(Field((b) => b
        ..name = 'geoFeatureCollection'
        ..modifier = FieldModifier.final$
        ..assignment = Code(geoFeatureCollection.toString())
        ..type = refer('List<GeoFeature>')
      ));

    final library = Library((b) => b
      ..directives.add(Directive.import('package:offline_geocoder/offline_geocoder.dart'))
      ..directives.add(Directive.import('package:latlong2/latlong.dart'))
      ..body.addAll([geoFeatureClass.build(), geoFeatureCollectionClass.build()]));

    final dartfmt = DartFormatter();
    return dartfmt.format('${library.accept(DartEmitter.scoped())}').toString();
  } 
}
