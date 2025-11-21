import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;

class SuggestItem {
  final String title;
  final String? subtitle;
  final mapkit.Point? point;

  const SuggestItem({
    required this.title,
    this.subtitle,
    this.point,
  });
}