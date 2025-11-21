import 'dart:collection';

import '../../../features/search/state/map_search_state.dart';
import '../../../features/search/state/search_state.dart' as search_model;
import '../../../features/search/state/suggest_state.dart' as suggest_model;
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/search.dart';

final class MapSearchManager {
  static const suggestNumberLimit = 20;
  static SuggestOptions defaultSuggestOptions = SuggestOptions(
    suggestTypes: SuggestType(
      SuggestType.Geo.value | SuggestType.Biz.value | SuggestType.Transit.value,
    ),
  );

  // Callback для интеграции с системой маршрутизации
  void Function(Point point, String address)? onAddressSelected;

  final _searchManager = SearchFactory.instance.createSearchManager(SearchManagerType.Combined);

  VisibleRegion? _visibleRegion;
  String _searchQuery = "";
  search_model.SearchState _searchState = search_model.SearchOff.instance;
  suggest_model.SuggestState _suggestState = suggest_model.SuggestOff.instance;

  late final _suggestSession = _searchManager.createSuggestSession();

  late final _searchSessionListener = SearchSessionSearchListener(
    onSearchResponse: (response) {
      print('✅ Search response: ${response.collection.children.length} items');
      final items = response.collection.children
          .map((geoObjectItem) {
            final point = geoObjectItem.asGeoObject()?.geometry.firstOrNull?.asPoint();

            return point != null ? search_model.SearchResponseItem(point, geoObjectItem.asGeoObject()) : null;
          })
          .whereType<search_model.SearchResponseItem>()
          .toList();

      final boundingBox = response.metadata.boundingBox;
      if (boundingBox == null) {
        return;
      }

      _searchState = search_model.SearchSuccess(
        items,
        {for (final item in items) item.point: item.geoObject},
        _shouldZoomToSearchResult,
        boundingBox,
      );

      // Уведомляем интеграцию о найденных координатах
      if (items.isNotEmpty && onAddressSelected != null) {
        final firstItem = items.first;
        final address = firstItem.geoObject?.name ?? _searchQuery;
        print("📍 Notifying integration: ${firstItem.point.latitude}, ${firstItem.point.longitude} → '$address'");
        onAddressSelected!(firstItem.point, address);
      }
    },
    onSearchError: (error) {
      print('❌ Search error: $error');
      _searchState = search_model.SearchError.instance;
    },
  );

  late final _suggestSessionListener = SearchSuggestSessionSuggestListener(
    onResponse: (response) {
      print('✅ Got ${response.items.length} suggest items');
      final suggestItems = response.items.take(suggestNumberLimit).map(
        (item) {
          return suggest_model.SuggestItem(
            title: item.title,
            subtitle: item.subtitle,
            onTap: () {
              setQueryText(item.displayText ?? "");

              if (item.action == SuggestItemAction.Search) {
                final uri = item.uri;
                if (uri != null) {
                  _submitUriSearch(uri);
                } else {
                  startSearch(item.searchText);
                }
              }
            },
          );
        },
      ).toList();
      _suggestState = suggest_model.SuggestSuccess(suggestItems);
    },
    onError: (error) {
      print('❌ Suggest error: $error');
      _suggestState = suggest_model.SuggestError.instance;
    },
  );

  SearchSession? _searchSession;
  bool _shouldZoomToSearchResult = false;

  // Методы для совместимости с существующим кодом
  Future<List<SuggestItem>> searchSuggestions(String query) async {
    print('🔍 searchSuggestions: "$query"');
    
    if (query.isEmpty) return [];
    
    // Используем BoundingBox по умолчанию если нет visible region
    final box = _visibleRegion?.toBoundingBox() ?? BoundingBox(
      Point(latitude: 55.5, longitude: 37.3), // Москва примерно
      Point(latitude: 56.0, longitude: 38.0),
    );
    
    _submitSuggest(query, box);
    
    // Для совместимости возвращаем пустой список
    // В реальности результаты придут через callback
    return [];
  }

  Future<Point?> geocodeAddress(String address) async {
    print('📍 geocodeAddress: "$address"');
    
    final region = _visibleRegion;
    if (region == null) {
      print('❌ No visible region available');
      return null;
    }

    // Простая реализация - в реальности нужно дождаться результата поиска
    // Возвращаем null, результат придет через callback
    startSearch(address);
    return null;
  }

  MapSearchState get mapSearchState => MapSearchState(_searchQuery, _searchState, _suggestState);

  void setQueryText(String query) {
    print('🔎 setQueryText: "$query"');
    _searchQuery = query;
  }

  void setVisibleRegion(VisibleRegion region) {
    print('🗺️ setVisibleRegion: SW(${region.bottomLeft.latitude},${region.bottomLeft.longitude}) NE(${region.topRight.latitude},${region.topRight.longitude})');
    _visibleRegion = region;
  }

  void startSearch([String? query]) {
    print('🚀 startSearch with query: "${query ?? _searchQuery}"');
    final region = _visibleRegion;
    if (region == null) {
      print('❌ No visible region available');
      return;
    }

    final polygonRegion = VisibleRegionUtils.toPolygon(region);
    _submitSearch(query ?? _searchQuery, polygonRegion);
  }

  void reset() {
    _searchSession?.cancel();
    _searchSession = null;
    _searchState = search_model.SearchOff.instance;
    _resetSuggest();
    _searchQuery = "";
  }

  void dispose() {
    _searchSession?.cancel();
    // Cleanup resources
  }

  void _submitUriSearch(String uri) {
    _searchSession?.cancel();
    _searchSession = _searchManager.searchByURI(
      SearchOptions(),
      _searchSessionListener,
      uri: uri,
    );
    _shouldZoomToSearchResult = true;
  }

  void _submitSearch(String query, Geometry geometry) {
    _searchSession?.cancel();
    _searchSession = _searchManager.submit(
      geometry,
      SearchOptions(resultPageSize: 32),
      _searchSessionListener,
      text: query,
    );
    _searchState = search_model.SearchLoading.instance;
    _shouldZoomToSearchResult = true;
  }

  void _submitSuggest(String query, BoundingBox box, [SuggestOptions? options]) {
    print('🌐 Submitting suggest for: "$query"');
    
    try {
      _suggestSession.suggest(
        box,
        options ?? defaultSuggestOptions,
        _suggestSessionListener,
        text: query,
      );
      print('✅ suggest() call completed successfully');
    } catch (e, stackTrace) {
      print('❌ Exception during suggest() call: $e');
    }
    
    _suggestState = suggest_model.SuggestLoading.instance;
  }

  void _resetSuggest() {
    _suggestSession.reset();
    _suggestState = suggest_model.SuggestOff.instance;
  }
}