import 'package:flutter_test/flutter_test.dart';
import 'package:example/offline_geocoder/offline_geocoder.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('Test the generated class by offline_geocoder', () {

    // Test 1: Geographic point near the Italy-Switzerland border
    const point1 = LatLng( 45.992979, 8.961235);
    final result1 = GeoCoder.getFromLocation(point1)!.isoA2;
    expect(result1, equals('CH'));

   /*  // Test 2: Geographic point near the Germany-France border
    const point2 = LatLng(48.573405, 7.734441);
    final result2 = GeoCoder.getFromLocation(point2)!.isoA2;
    expect(result2, equals('FR')); */

    // Test 3: Geographic point near the Spain-Portugal border
    const point3 = LatLng(40.437580, -7.787034);
    final result3 = GeoCoder.getFromLocation(point3)!.isoA2;
    expect(result3, equals('PT'));

    /* // Test 4: Geographic point near the USA-Canada border
    const point4 = LatLng(49.000000, -123.000000);
    final result4 = GeoCoder.getFromLocation(point4)!.isoA2;
    expect(result4, equals('US')); */

    // Test 5: Geographic point near the Brazil-Argentina border
    const point5 = LatLng(-25.000000, -54.000000);
    final result5 = GeoCoder.getFromLocation(point5)!.isoA2;
    expect(result5, equals('BR'));

    // Test 6: Geographic point near the China-Russia border
    const point6 = LatLng(53.000000, 129.000000);
    final result6 = GeoCoder.getFromLocation(point6)!.isoA2;
    expect(result6, equals('RU'));

    // Test 7: Geographic point near the India-Pakistan border
    const point7 = LatLng(30.000000, 74.000000);
    final result7 = GeoCoder.getFromLocation(point7)!.isoA2;
    expect(result7, equals('IN'));

    // Test 8: Geographic point near the South Korea-North Korea border
    const point8 = LatLng(38.000000, 126.000000);
    final result8 = GeoCoder.getFromLocation(point8)!.isoA2;
    expect(result8, equals('KP'));

    /* // Test 9: Geographic point near the Norway-Sweden border
    const point9 = LatLng(59.000000, 11.000000);
    final result9 = GeoCoder.getFromLocation(point9)!.isoA2;
    expect(result9, equals('NO')); */

    /* // Test 10: Geographic point near the Greece-Turkey border
    const point10 = LatLng(37.000000, 26.000000);
    final result10 = GeoCoder.getFromLocation(point10)!.isoA2;
    expect(result10, equals('GR')); */

    /* // Test 11: Geographic point near New Zealand
    const point11 = LatLng(-37.000000, 173.000000);
    final result11 = GeoCoder.getFromLocation(point11)!.isoA2;
    expect(result11, equals('NZ')); */

    // Test 12: Geographic point near the Egypt-Israel border
    const point12 = LatLng(30.000000, 34.000000);
    final result12 = GeoCoder.getFromLocation(point12)!.isoA2;
    expect(result12, equals('EG'));

    // Test 13: Geographic point near the Kazakhstan-Uzbekistan border
    const point13 = LatLng(44.000000, 63.000000);
    final result13 = GeoCoder.getFromLocation(point13)!.isoA2;
    expect(result13, equals('KZ'));

    // Test 14: Geographic point near the Mexico-Guatemala border
    const point14 = LatLng(15.000000, -91.000000);
    final result14 = GeoCoder.getFromLocation(point14)!.isoA2;
    expect(result14, equals('GT'));

    // Test 15: Geographic point near the Kenya-Tanzania border
    const point15 = LatLng(-2.000000, 37.000000);
    final result15 = GeoCoder.getFromLocation(point15)!.isoA2;
    expect(result15, equals('KE'));

    // Test 16: Geographic point near the Sweden-Norway border
    const point16 = LatLng(59.4888263, 11.7574877);
    final result16 = GeoCoder.getFromLocation(point16)!.isoA2;
    expect(result16, equals('SE')); 

    // Test 17: Geographic point near the Bolivia-Chile border
    const point17 = LatLng(-21.000000, -69.000000);
    final result17 = GeoCoder.getFromLocation(point17)!.isoA2;
    expect(result17, equals('CL'));

    // Test 18: Geographic point near the Nepal-India border
    const point18 = LatLng(27.000000, 88.000000);
    final result18 = GeoCoder.getFromLocation(point18)!.isoA2;
    expect(result18, equals('NP'));

   /*  // Test 19: Geographic point near the Canada-USA border
    const point19 = LatLng(49.000000, -123.000000);
    final result19 = GeoCoder.getFromLocation(point19)!.isoA2;
    expect(result19, equals('US')); */

    // Test 20: Geographic point near the Argentina-Chile border
    const point20 = LatLng(-54.000000, -68.000000);
    final result20 = GeoCoder.getFromLocation(point20)!.isoA2;
    expect(result20, equals('AR'));

    // Test 21: Geographic point near the Iran-Iraq border
    const point21 = LatLng(32.000000, 47.000000);
    final result21 = GeoCoder.getFromLocation(point21)!.isoA2;
    expect(result21, equals('IQ'));

   /*  // Test 22: Geographic point near the Finland-Russia border
    const point22 = LatLng(61.000000, 31.000000);
    final result22 = GeoCoder.getFromLocation(point22)!.isoA2;
    expect(result22, equals('RU')); */

    /* // Test 23: Geographic point near the France-Spain border
    const point23 = LatLng(42.6002246, 1.4358184);
    final result23 = GeoCoder.getFromLocation(point23)!.isoA2;
    expect(result23, equals('ES')); */

    // Test 24: Geographic point near the Peru-Brazil border
    const point24 = LatLng(-9.000000, -69.000000);
    final result24 = GeoCoder.getFromLocation(point24)!.isoA2;
    expect(result24, equals('BR'));

    // Test 25: Geographic point near Vatican
    const point25 = LatLng(41.903349, 12.453004);
    final result25 = GeoCoder.getFromLocation(point25)!.isoA2;
    expect(result25, equals('VA'));

    /* // Test 26: Geographic point Sixtin Church
    const point26 = LatLng(41.9029338, 12.45440425);
    final result26 = GeoCoder.getFromLocation(point26)!.isoA2;
    expect(result26, equals('VA')); */
  });
}
