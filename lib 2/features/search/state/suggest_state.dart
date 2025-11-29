import 'package:flutter/foundation.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';

sealed class SuggestState {}

final class SuggestOff extends SuggestState {
  static SuggestOff instance = SuggestOff._();

  SuggestOff._();
}

final class SuggestLoading extends SuggestState {
  static SuggestLoading instance = SuggestLoading._();

  SuggestLoading._();
}

final class SuggestError extends SuggestState {
  static SuggestError instance = SuggestError._();

  SuggestError._();
}

final class SuggestSuccess extends SuggestState {
  final List<SuggestItem> suggestItems;

  SuggestSuccess(this.suggestItems);
}

final class SuggestItem {
  final SpannableString title;
  final SpannableString? subtitle;
  final VoidCallback onTap;
  final String searchText; // Полный адрес для поиска (с городом и краем)
  final String displayText; // Текст для отображения в поле

  const SuggestItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.searchText,
    required this.displayText,
  });

  @override
  String toString() =>
      "SuggestItem(title: ${title.text}, subtitle: ${subtitle?.text}, searchText: $searchText)";
}
