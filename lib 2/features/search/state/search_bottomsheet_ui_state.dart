import 'dart:async';

import 'package:common/common.dart';
import 'map_search_state.dart';
import 'search_state.dart';
import 'suggest_state.dart';

final class SearchBottomSheetUiState {
  final String searchQuery;
  final List<SuggestItem> suggestItems;
  final String searchAndSuggestStatus;
  final bool isSearchButtonEnabled;
  final bool isResetButtonEnabled;
  final bool isCategoryButtonsVisible;
  final bool isTextFieldEnabled;

  const SearchBottomSheetUiState({
    required this.searchQuery,
    required this.suggestItems,
    required this.searchAndSuggestStatus,
    required this.isSearchButtonEnabled,
    required this.isResetButtonEnabled,
    required this.isCategoryButtonsVisible,
    required this.isTextFieldEnabled,
  });
}

extension _SearchStateToTextStatus on SearchState {
  String toTextStatus() {
    return switch (this) {
      final SearchError _ => "Ошибка",
      final SearchLoading _ => "Загрузка",
      final SearchOff _ => "Выкл",
      final SearchSuccess _ => "Успешно",
    };
  }
}

extension _SuggestStateToTextStatus on SuggestState {
  String toTextStatus() {
    return switch (this) {
      final SuggestError _ => "Ошибка",
      final SuggestLoading _ => "Загрузка",
      final SuggestOff _ => "Выкл",
      final SuggestSuccess _ => "Успешно",
    };
  }
}

extension MapSearchStateToSearchBottomSheetUiState on Stream<MapSearchState> {
  Stream<SearchBottomSheetUiState> toBottomSheetUiState() {
    return map((mapSearchState) {
      final searchQuery = mapSearchState.searchQuery;
      final suggestsItems = mapSearchState.suggestState
          .castOrNull<SuggestSuccess>()
          ?.suggestItems;
      final searchAndSuggestStatus =
          "Поиск: ${mapSearchState.searchState.toTextStatus()}; "
          "Предложения: ${mapSearchState.suggestState.toTextStatus()}";
      final isSearchButtonEnabled = searchQuery.isNotBlank;
      final isResetButtonEnabled =
          searchQuery.isNotBlank && mapSearchState.searchState is! SearchOff;
      final isCategoryButtonsVisible = searchQuery.isBlank;
      const isTextFieldEnabled = true;

      return SearchBottomSheetUiState(
        searchQuery: searchQuery,
        suggestItems: suggestsItems ?? [],
        searchAndSuggestStatus: searchAndSuggestStatus,
        isSearchButtonEnabled: isSearchButtonEnabled,
        isResetButtonEnabled: isResetButtonEnabled,
        isCategoryButtonsVisible: isCategoryButtonsVisible,
        isTextFieldEnabled: isTextFieldEnabled,
      );
    });
  }
}
