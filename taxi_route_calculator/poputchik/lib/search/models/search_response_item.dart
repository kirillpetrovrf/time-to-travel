class SearchResponseItem {
  final String title;
  final String? subtitle;
  final String? uri;
  final double? distance;

  const SearchResponseItem({
    required this.title,
    this.subtitle,
    this.uri,
    this.distance,
  });

  factory SearchResponseItem.fromMap(Map<String, dynamic> map) {
    return SearchResponseItem(
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      uri: map['uri'],
      distance: map['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'uri': uri,
      'distance': distance,
    };
  }
}