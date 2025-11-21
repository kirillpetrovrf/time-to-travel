class SuggestItem {
  final String title;
  final String? subtitle;
  final String? uri;

  const SuggestItem({
    required this.title,
    this.subtitle,
    this.uri,
  });

  factory SuggestItem.fromMap(Map<String, dynamic> map) {
    return SuggestItem(
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      uri: map['uri'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'uri': uri,
    };
  }
}