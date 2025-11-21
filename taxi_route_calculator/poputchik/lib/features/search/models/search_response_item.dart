import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;

class SearchResponseItem {
  final mapkit.Point point;
  final dynamic geoObject; // Заглушка

  const SearchResponseItem({
    required this.point,
    this.geoObject,
  });
}