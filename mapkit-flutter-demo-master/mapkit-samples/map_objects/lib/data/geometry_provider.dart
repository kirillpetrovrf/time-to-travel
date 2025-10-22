import 'package:common/utils/extension_utils.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';

final class GeometryProvider {
  static final _generatedList = List.generate(400, (i) => i + 200.0);

  static const startPosition = CameraPosition(
    Point(latitude: 59.935016, longitude: 30.328903),
    zoom: 15.0,
    azimuth: 0.0,
    tilt: 0.0,
  );

  static const compositePointIcon = Point(
    latitude: 59.939651,
    longitude: 30.339902,
  );
  static const animatedImagePoint = Point(
    latitude: 59.932305,
    longitude: 30.338758,
  );

  static Polygon get polygon {
    final outerRing = [
      (59.935535, 30.326926),
      (59.938961, 30.328576),
      (59.938152, 30.336384),
      (59.934600, 30.335049),
      (59.935535, 30.326926),
    ]
        .map((point) => Point(latitude: point.$1, longitude: point.$2))
        .toList()
        .let((it) => LinearRing(it));

    final innerRing = [
      (59.936698, 30.331271),
      (59.937495, 30.329910),
      (59.937854, 30.331909),
      (59.937112, 30.333312),
      (59.936698, 30.331271),
    ]
        .map((point) => Point(latitude: point.$1, longitude: point.$2))
        .toList()
        .let((it) => LinearRing(it));

    return Polygon(outerRing, [innerRing]);
  }

  static Polyline get polyline {
    final points = [
      (59.933475, 30.325256),
      (59.933947, 30.323115),
      (59.935667, 30.324070),
      (59.935901, 30.322370),
      (59.941026, 30.324789),
    ].map((point) => Point(latitude: point.$1, longitude: point.$2)).toList();

    return Polyline(points);
  }

  static Circle get circle {
    return Circle(
      const Point(
        latitude: 59.939866,
        longitude: 30.314352,
      ),
      radius: _generatedList.random(),
    );
  }

  static List<Point> clusterizedPoints = [
    (59.935535, 30.326926),
    (59.938961, 30.328576),
    (59.938152, 30.336384),
    (59.934600, 30.335049),
    (59.938386, 30.329092),
    (59.938495, 30.330557),
    (59.938854, 30.332325),
    (59.937930, 30.333767),
    (59.937766, 30.335208),
    (59.938203, 30.334316),
    (59.938607, 30.337340),
    (59.937988, 30.337596),
    (59.938168, 30.338533),
    (59.938780, 30.339794),
    (59.939095, 30.338655),
    (59.939815, 30.337967),
    (59.939365, 30.340293),
    (59.935220, 30.333730),
    (59.935792, 30.335223),
    (59.935814, 30.332945),
  ].map((point) => Point(latitude: point.$1, longitude: point.$2)).toList();
}
