import 'dart:collection';

import 'package:common/common.dart';
import 'package:taxi_route_calculator/features/search/state/map_search_state.dart';
import 'package:taxi_route_calculator/features/search/state/search_state.dart'
    as search_model;
import 'package:taxi_route_calculator/features/search/state/suggest_state.dart'
    as suggest_model;
import 'package:taxi_route_calculator/features/search/widgets/utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/search.dart';

final class MapSearchManager {
  static const suggestNumberLimit = 20;
  static SuggestOptions defaultSuggestOptions = SuggestOptions(
    suggestTypes: SuggestType(
      SuggestType.Geo.value | SuggestType.Biz.value | SuggestType.Transit.value,
    ),
  );

  // 🆕 Callback для интеграции с системой маршрутизации
  void Function(Point point, String address)? onAddressSelected;

  final _searchManager =
      SearchFactory.instance.createSearchManager(SearchManagerType.Combined);
  
  // 📍 Текущая GPS-позиция пользователя для приоритета саджестов
  Point? _userPosition;
  
  // 🆕 Сохраняем последний запрос с городом для правильного поиска
  String? _lastFullQuery;

  final _visibleRegion = BehaviorSubject<VisibleRegion?>()..add(null);
  final _searchQuery = BehaviorSubject<String>()..add("");
  final _searchState = BehaviorSubject<search_model.SearchState>()
    ..add(search_model.SearchOff.instance);
  final _suggestState = BehaviorSubject<suggest_model.SuggestState>()
    ..add(suggest_model.SuggestOff.instance);

  late final _throttledVisibleRegion =
      _visibleRegion.debounceTime(const Duration(seconds: 1));
  late final _suggestSession = _searchManager.createSuggestSession();

  late final _mapSearchState = Rx.combineLatest3(
    _searchQuery,
    _searchState,
    _suggestState,
    (searchQuery, searchState, suggestState) {
      return MapSearchState(searchQuery, searchState, suggestState);
    },
  ).shareValue();

  late final _searchSessionListener = SearchSessionSearchListener(
    onSearchResponse: (response) {
      print('✅ Search response: ${response.collection.children.length} items');
      final items = response.collection.children
          .map((geoObjectItem) {
            final point =
                geoObjectItem.asGeoObject()?.geometry.firstOrNull?.asPoint();

            return point?.let(
              (it) => search_model.SearchResponseItem(
                point,
                geoObjectItem.asGeoObject(),
              ),
            );
          })
          .whereType<search_model.SearchResponseItem>()
          .toList();

      final boundingBox = response.metadata.boundingBox;
      if (boundingBox == null) {
        return;
      }

      _searchState.add(
        search_model.SearchSuccess(
          items,
          {for (final item in items) item.point: item.geoObject},
          _shouldZoomToSearchResult,
          boundingBox,
        ),
      );

      // 🆕 Уведомляем интеграцию о найденных координатах
      if (items.isNotEmpty && onAddressSelected != null) {
        final firstItem = items.first;
        final address = firstItem.geoObject?.name ?? _searchQuery.value;
        print("📍 Notifying integration: ${firstItem.point.latitude}, ${firstItem.point.longitude} → '$address'");
        onAddressSelected!(firstItem.point, address);
      }
    },
    onSearchError: (error) {
      print('❌ Search error: $error');
      _searchState.add(search_model.SearchError.instance);
    },
  );

  late final _suggestSessionListener = SearchSuggestSessionSuggestListener(
    onResponse: (response) {
      print('✅✅✅ CALLBACK FIRED! Got ${response.items.length} suggest items');
      final suggestItems = response.items.take(suggestNumberLimit).map(
        (item) {
          return suggest_model.SuggestItem(
            title: item.title,
            subtitle: item.subtitle,
            onTap: () {
              print('🎯 Suggest item tapped:');
              print('   title: ${item.title}');
              print('   searchText: ${item.searchText}');
              print('   displayText: ${item.displayText}');
              print('   uri: ${item.uri}');
              print('   action: ${item.action}');
              
              setQueryText(item.displayText ?? "");

              if (item.action == SuggestItemAction.Search) {
                final uri = item.uri;
                if (uri != null) {
                  // Search by URI if exists - ГЛОБАЛЬНЫЙ ПОИСК!
                  print('✅ Using URI search (global): $uri');
                  _submitUriSearch(uri);
                } else {
                  // Otherwise, search by searchText - локальный поиск
                  print('⚠️ Using text search (local): ${item.searchText}');
                  startSearch(item.searchText);
                }
              } else {
                print('ℹ️ Action is not Search: ${item.action}');
              }
            },
          );
        },
      ).toList();
      _suggestState.add(suggest_model.SuggestSuccess(suggestItems));
    },
    onError: (error) {
      print('❌❌❌ ERROR CALLBACK FIRED! Suggest error: $error');
      _suggestState.add(suggest_model.SuggestError.instance);
    },
  )..let((it) {
    print('✅ SuggestSessionListener created: $it');
    print('   onResponse callback is: ${it.hashCode}');
  });

  SearchSession? _searchSession;
  bool _shouldZoomToSearchResult = false;

  ValueStream<MapSearchState> get mapSearchState => _mapSearchState;

  void setQueryText(String query) {
    print('🔎 setQueryText: "$query"');
    _searchQuery.add(query);
    
    // 🆕 Сохраняем полный запрос ТОЛЬКО если он содержит город
    if (_queryContainsCity(query)) {
      _lastFullQuery = query;
      print('💾 Saved full query with city: "$query"');
    } else {
      // 🧹 Очищаем сохранённый запрос, если новый запрос без города
      // (пользователь начал вводить новый адрес)
      _lastFullQuery = null;
    }
  }

  void setVisibleRegion(VisibleRegion region) {
    print('🗺️ setVisibleRegion: SW(${region.bottomLeft.latitude},${region.bottomLeft.longitude}) NE(${region.topRight.latitude},${region.topRight.longitude})');
    _visibleRegion.add(region);
  }

  void startSearch([String? query]) {
    var searchQuery = query ?? _searchQuery.value;
    print('🚀 startSearch with query: "$searchQuery"');
    
    // 🆕 Если запрос не содержит город, но у нас есть сохранённый запрос с городом,
    // используем сохранённый полный запрос (так как адрес из саджеста теряет город)
    if (!_queryContainsCity(searchQuery) && _lastFullQuery != null) {
      print('🔄 Query has no city, but we have saved full query: "$_lastFullQuery"');
      print('   Using saved full query for search');
      searchQuery = _lastFullQuery!;
    }
    
    final region = _visibleRegion.value;
    if (region == null) {
      print('❌ No visible region available');
      return;
    }

    // 🎯 Определяем область поиска в зависимости от наличия города в запросе
    Geometry searchGeometry;
    final hasExplicitCity = _queryContainsCity(searchQuery);
    
    if (hasExplicitCity) {
      // Если указан город → создаём большой полигон для всей России
      final russiaPolygon = Polygon(
        LinearRing([
          const Point(latitude: 41.0, longitude: 19.0),   // Юго-запад
          const Point(latitude: 41.0, longitude: 180.0),  // Юго-восток
          const Point(latitude: 82.0, longitude: 180.0),  // Северо-восток
          const Point(latitude: 82.0, longitude: 19.0),   // Северо-запад
          const Point(latitude: 41.0, longitude: 19.0),   // Замыкаем полигон
        ]),
        [],
      );
      searchGeometry = Geometry.fromPolygon(russiaPolygon);
      print('🌐 Query contains city "$searchQuery" → using wide search area (all Russia)');
    } else if (_userPosition != null) {
      // Если НЕТ города И есть GPS → маленький полигон вокруг пользователя
      const delta = 0.2;
      final localPolygon = Polygon(
        LinearRing([
          Point(latitude: _userPosition!.latitude - delta, longitude: _userPosition!.longitude - delta),
          Point(latitude: _userPosition!.latitude - delta, longitude: _userPosition!.longitude + delta),
          Point(latitude: _userPosition!.latitude + delta, longitude: _userPosition!.longitude + delta),
          Point(latitude: _userPosition!.latitude + delta, longitude: _userPosition!.longitude - delta),
          Point(latitude: _userPosition!.latitude - delta, longitude: _userPosition!.longitude - delta),
        ]),
        [],
      );
      searchGeometry = Geometry.fromPolygon(localPolygon);
      print('📍 No city in query → using local search area around user position');
      print('   User position: (${_userPosition!.latitude}, ${_userPosition!.longitude})');
    } else {
      // Fallback: используем видимую область карты
      searchGeometry = VisibleRegionUtils.toPolygon(region);
      print('🗺️ Using visible region for search (no city, no GPS)');
    }

    _submitSearch(searchQuery, searchGeometry);
  }

  void reset() {
    _searchSession?.cancel();
    _searchSession = null;
    _searchState.add(search_model.SearchOff.instance);
    _resetSuggest();
    _searchQuery.add("");
  }

  /// Performs the search again when the map position changes
  Stream<void> subscribeForSearch() {
    return _throttledVisibleRegion
        .whereType<VisibleRegion>()
        .where((_) =>
          _searchState.value is search_model.SearchSuccess ||
          _searchState.value is search_model.SearchError
        )
        .map(
          (region) => _searchSession?.let((it) {
            it.setSearchArea(VisibleRegionUtils.toPolygon(region));
            it.resubmit(_searchSessionListener);
            _searchState.add(search_model.SearchLoading.instance);
            _shouldZoomToSearchResult = false;
          }),
        );
  }

  /// Resubmitting suggests when query, region or searchState changes
  Stream<void> subscribeForSuggest() {
    return Rx.combineLatest2(
      _searchQuery,
      _throttledVisibleRegion,
      (searchQuery, region) {
        if (searchQuery.isNotEmpty && region != null) {
          _submitSuggest(searchQuery, region.toBoundingBox());
        } else {
          _resetSuggest();
        }
      },
    );
  }

  void dispose() {
    _visibleRegion.close();
    _searchQuery.close();
    _searchState.close();
    _suggestState.close();
  }

  /// Устанавливает текущую GPS-позицию пользователя
  /// Вызывается при получении геолокации
  void setUserPosition(Point position) {
    _userPosition = position;
    print('📍 User position updated: (${position.latitude}, ${position.longitude})');
  }

  /// Проверяет, содержит ли запрос название города
  /// Список из 60+ крупных городов России
  bool _queryContainsCity(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Список крупных городов России для быстрой проверки
    const cities = [
      'москва', 'санкт-петербург', 'питер', 'екатеринбург', 'екб',
      'новосибирск', 'казань', 'нижний новгород', 'челябинск',
      'самара', 'омск', 'ростов-на-дону', 'ростов', 'уфа', 'красноярск',
      'воронеж', 'пермь', 'волгоград', 'краснодар', 'саратов',
      'тюмень', 'тольятти', 'ижевск', 'барнаул', 'ульяновск',
      'иркутск', 'хабаровск', 'ярославль', 'владивосток', 'махачкала',
      'томск', 'оренбург', 'кемерово', 'новокузнецк', 'рязань',
      'набережные челны', 'астрахань', 'пенза', 'липецк', 'киров',
      'чебоксары', 'калининград', 'тула', 'курск', 'сочи',
      'ставрополь', 'улан-удэ', 'магнитогорск', 'иваново', 'брянск',
      'белгород', 'сургут', 'владимир', 'архангельск', 'чита',
      'нижний тагил', 'калуга', 'смоленск', 'волжский', 'курган'
    ];
    
    return cities.any((city) => lowerQuery.contains(city));
  }

  void _submitUriSearch(String uri) {
    print('🌍 _submitUriSearch called with URI: $uri');
    _searchSession?.cancel();
    _searchSession = _searchManager.searchByURI(
      SearchOptions(),
      _searchSessionListener,
      uri: uri,
    );
    print('✅ URI search session created');
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
    _searchState.add(search_model.SearchLoading.instance);
    _shouldZoomToSearchResult = true;
  }

  void _submitSuggest(
    String query,
    BoundingBox box, [
    SuggestOptions? options,
  ]) {
    BoundingBox effectiveBox;
    
    // 🎯 Определяем, указал ли пользователь город в запросе
    final hasExplicitCity = _queryContainsCity(query);
    
    if (hasExplicitCity) {
      // Если указан конкретный город → используем широкий bbox (вся Россия)
      effectiveBox = BoundingBox(
        const Point(latitude: 41.0, longitude: 19.0),  // Юго-запад России
        const Point(latitude: 82.0, longitude: 180.0), // Северо-восток России
      );
      print('🌐 Query contains city name → using wide BoundingBox (all Russia)');
      print('   Query: "$query"');
    } else if (_userPosition != null) {
      // Если НЕТ города в запросе И есть GPS → маленький bbox вокруг пользователя
      // Создаём BoundingBox ~22км вокруг текущей позиции (≈0.2 градуса)
      const latDelta = 0.2;
      const lonDelta = 0.2;
      effectiveBox = BoundingBox(
        Point(
          latitude: _userPosition!.latitude - latDelta,
          longitude: _userPosition!.longitude - lonDelta,
        ),
        Point(
          latitude: _userPosition!.latitude + latDelta,
          longitude: _userPosition!.longitude + lonDelta,
        ),
      );
      print('📍 No city in query → using local BoundingBox around user position');
      print('   User position: (${_userPosition!.latitude}, ${_userPosition!.longitude})');
      print('   BoundingBox: SW(${effectiveBox.southWest.latitude},${effectiveBox.southWest.longitude}) NE(${effectiveBox.northEast.latitude},${effectiveBox.northEast.longitude})');
    } else {
      // Fallback: если нет ни города, ни GPS → используем bbox видимой области карты
      effectiveBox = box;
      print('🗺️ Using visible region BoundingBox (no city, no GPS)');
    }
    
    print('🌐 Submitting suggest for: "$query"');
    print('   Listener object: $_suggestSessionListener');
    print('   Listener hashCode: ${_suggestSessionListener.hashCode}');
    
    try {
      _suggestSession.suggest(
        effectiveBox,
        options ?? defaultSuggestOptions,
        _suggestSessionListener,
        text: query,
      );
      print('✅ suggest() call completed successfully');
    } catch (e, stackTrace) {
      print('❌ Exception during suggest() call: $e');
      print('   Stack trace: $stackTrace');
    }
    
    _suggestState.add(suggest_model.SuggestLoading.instance);
    print('📊 SuggestLoading state added to stream');
  }

  void _resetSuggest() {
    _suggestSession.reset();
    _suggestState.add(suggest_model.SuggestOff.instance);
  }
}
