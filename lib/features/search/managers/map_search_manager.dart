import 'dart:collection';

import 'package:common/common.dart';
import '../state/map_search_state.dart';
import '../state/search_state.dart' as search_model;
import '../state/suggest_state.dart' as suggest_model;
import '../widgets/utils.dart';
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

  // 📍 Callback для интеграции с системой маршрутизации
  void Function(Point point, String address)? onAddressSelected;

  final _searchManager =
      SearchFactory.instance.createSearchManager(SearchManagerType.Combined);

  final _visibleRegion = BehaviorSubject<VisibleRegion?>()..add(null);
  final _searchQuery = BehaviorSubject<String>()..add("");
  final _searchState = BehaviorSubject<search_model.SearchState>()
    ..add(search_model.SearchOff.instance);
  final _suggestState = BehaviorSubject<suggest_model.SuggestState>()
    ..add(suggest_model.SuggestOff.instance);
  
  // 📍 Текущая GPS-позиция пользователя для приоритета саджестов
  Point? _userPosition;

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
            final geoObj = geoObjectItem.asGeoObject();
            final point = geoObj?.geometry.firstOrNull?.asPoint();
            final name = geoObj?.name ?? '';
            
            if (point == null) {
              print('⚠️ Skipping item without point: ${geoObj?.name ?? "unnamed"}');
              return null;
            }

            // 🚧 Фильтруем технические дорожные объекты
            final isRoadCode = RegExp(r'^\d+[КНР]-\d+').hasMatch(name);
            if (isRoadCode) {
              print('🚧 Skipping road code: $name');
              return null;
            }

            return search_model.SearchResponseItem(
              point,
              geoObjectItem.asGeoObject(),
            );
          })
          .whereType<search_model.SearchResponseItem>()
          .toList();

      print('📊 Parsed ${items.length} items with valid points from ${response.collection.children.length} total');

      final boundingBox = response.metadata.boundingBox;
      
      // 🆕 СНАЧАЛА вызываем callback (как в taxi_route_calculator)
      print('🔍 Checking callback conditions: items.length=${items.length}, onAddressSelected=${onAddressSelected != null}');
      if (items.isNotEmpty && onAddressSelected != null) {
        // 🔍 Выводим ВСЕ результаты для анализа
        print('📋 ALL ${items.length} SEARCH RESULTS:');
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          final geoObj = item.geoObject;
          final name = geoObj?.name ?? 'unnamed';
          final description = geoObj?.descriptionText ?? 'no description';
          print('   [$i] ${item.point.latitude}, ${item.point.longitude} → $name ($description)');
        }
        
        // 🎯 Ищем результат, который ТОЧНО соответствует запросу
        final query = _searchQuery.value.toLowerCase();
        print('🔎 Search query: "$query"');
        
        // Попытка найти точное совпадение по городу в description
        var bestItem = items.first; // По умолчанию первый
        
        // Если в запросе есть "екатеринбург", ищем результат с Екатеринбургом
        if (query.contains('екатеринбург')) {
          final ekbItem = items.firstWhere(
            (item) {
              final desc = item.geoObject?.descriptionText?.toLowerCase() ?? '';
              return desc.contains('екатеринбург') || desc.contains('свердловская');
            },
            orElse: () => items.first,
          );
          bestItem = ekbItem;
          final foundCity = ekbItem.geoObject?.descriptionText?.toLowerCase().contains('екатеринбург') ?? false;
          if (foundCity) {
            print('🎯✅ Found Екатеринбург result: ${ekbItem.geoObject?.descriptionText}');
          } else {
            print('⚠️ Екатеринбург NOT found in results! Using first item: ${ekbItem.geoObject?.descriptionText}');
          }
        } else if (query.contains('москва')) {
          final mskItem = items.firstWhere(
            (item) {
              final desc = item.geoObject?.descriptionText?.toLowerCase() ?? '';
              return desc.contains('москва');
            },
            orElse: () => items.first,
          );
          bestItem = mskItem;
          final foundCity = mskItem.geoObject?.descriptionText?.toLowerCase().contains('москва') ?? false;
          if (foundCity) {
            print('🎯✅ Found Москва result: ${mskItem.geoObject?.descriptionText}');
          } else {
            print('⚠️ Москва NOT found in results! Using first item: ${mskItem.geoObject?.descriptionText}');
          }
        } else if (query.contains('донецк')) {
          // 🎯 Приоритизация правильного Донецка (ДНР) над Донецком Ростовской области
          final donetskDNR = items.firstWhere(
            (item) {
              // Донецк ДНР имеет координаты около 48.0159°, 37.8031°
              final lat = item.point.latitude;
              final lng = item.point.longitude;
              final name = item.geoObject?.name?.toLowerCase() ?? '';
              final desc = item.geoObject?.descriptionText?.toLowerCase() ?? '';
              
              // Проверяем координаты (с погрешностью 0.5°) и отсутствие "ростовская область"
              final isDonetskDNR = (lat - 48.0159).abs() < 0.5 && 
                                   (lng - 37.8031).abs() < 0.5 && 
                                   !desc.contains('ростовская');
              
              print('   🔍 Checking item: $name ($desc)');
              print('     Coords: $lat, $lng');
              print('     Is Donetsk DNR: $isDonetskDNR');
              
              return isDonetskDNR;
            },
            orElse: () => items.first,
          );
          bestItem = donetskDNR;
          
          final lat = donetskDNR.point.latitude;
          final lng = donetskDNR.point.longitude;
          final isActuallyDNR = (lat - 48.0159).abs() < 0.5 && (lng - 37.8031).abs() < 0.5;
          
          if (isActuallyDNR) {
            print('🎯✅ PRIORITIZED Донецк ДНР: ${donetskDNR.geoObject?.descriptionText}');
            print('     Coordinates: $lat, $lng');
          } else {
            print('⚠️ Донецк ДНР NOT found in results! Using first item: ${donetskDNR.geoObject?.descriptionText}');
            print('     Coordinates: $lat, $lng');
          }
        }
        
        final address = bestItem.geoObject?.name ?? _searchQuery.value;
        print("📍 ABOUT TO CALL onAddressSelected callback!");
        print("   Selected item point: ${bestItem.point.latitude}, ${bestItem.point.longitude}");
        print("   Address: '$address'");
        print("   Description: '${bestItem.geoObject?.descriptionText}'");
        
        try {
          onAddressSelected!(bestItem.point, address);
          print("✅ onAddressSelected callback completed successfully");
        } catch (e, stackTrace) {
          print("❌ ERROR in onAddressSelected callback: $e");
          print("   Stack trace: $stackTrace");
        }
      } else {
        print('❌ Callback NOT called: items.isEmpty=${items.isEmpty}, onAddressSelected is null=${onAddressSelected == null}');
      }
      
      // Проверяем boundingBox только для UI state
      if (boundingBox == null) {
        print('⚠️ No boundingBox in response - skipping UI state update');
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
    },
    onSearchError: (error) {
      print('❌ Search error: $error');
      _searchState.add(search_model.SearchError.instance);
    },
  );

  late final _suggestSessionListener = SearchSuggestSessionSuggestListener(
    onResponse: (response) {
      print('✅✅✅ CALLBACK FIRED! Got ${response.items.length} suggest items');
      
      // 📋 Логируем все suggest items для диагностики
      print('📋 ALL SUGGEST ITEMS:');
      for (int i = 0; i < response.items.length; i++) {
        final item = response.items[i];
        print('   [$i] title: "${item.title}"');
        print('       subtitle: "${item.subtitle ?? "null"}"');
        print('       displayText: "${item.displayText ?? "null"}"');
        print('       searchText: "${item.searchText}"');
      }
      
      // 🎯 Приоритизация Донецка ДНР в suggest results
      var itemsList = response.items.toList();
      final query = _searchQuery.value.toLowerCase();
      
      if (query.contains('донецк')) {
        print('🔄 Prioritizing Донецк ДНР in suggest results...');
        
        // Ищем правильный Донецк (без "Ростовская область")
        final donetskDNRIndex = itemsList.indexWhere((item) {
          final title = item.title.text.toLowerCase();
          final subtitle = item.subtitle?.text.toLowerCase() ?? '';
          final displayText = item.displayText?.toLowerCase() ?? '';
          
          // Проверяем что это именно "Донецк" (не другие города с "донецк" в названии)
          // и НЕ содержит "ростовская область"
          final isDonetskCity = title == 'донецк';
          final isNotRostovRegion = !subtitle.contains('ростовская область') && 
                                   !displayText.contains('ростовская область');
          
          print('   🔍 Suggest item: "$title" / "$subtitle"');
          print('     isDonetskCity: $isDonetskCity, isNotRostovRegion: $isNotRostovRegion');
          
          return isDonetskCity && isNotRostovRegion;
        });
        
        // Если нашли правильный Донецк и он не на первом месте - перемещаем его
        if (donetskDNRIndex > 0) {
          final donetskDNRItem = itemsList.removeAt(donetskDNRIndex);
          itemsList.insert(0, donetskDNRItem);
          print('🎯✅ MOVED Донецк ДНР from position $donetskDNRIndex to position 0');
          print('     Title: "${donetskDNRItem.title.text}"');
          print('     Subtitle: "${donetskDNRItem.subtitle?.text ?? "null"}"');
        } else if (donetskDNRIndex == 0) {
          print('✅ Донецк ДНР already at position 0 - no reordering needed');
        } else {
          print('⚠️ Донецк ДНР not found in suggest results');
        }
      }

      final suggestItems = itemsList.take(suggestNumberLimit).map(
        (item) {
          return suggest_model.SuggestItem(
            title: item.title,
            subtitle: item.subtitle,
            searchText: item.searchText, // Полный адрес для поиска
            displayText: item.displayText ?? item.title.text, // Для отображения
            onTap: () {
              // ❌ НЕ вызываем setQueryText - это триггерит новый suggest!
              // setQueryText(item.displayText ?? "");

              if (item.action == SuggestItemAction.Search) {
                final uri = item.uri;
                if (uri != null) {
                  // Search by URI if exists
                  _submitUriSearch(uri);
                } else {
                  // Otherwise, search by searchText
                  startSearch(item.searchText);
                }
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
  }

  void setVisibleRegion(VisibleRegion region) {
    print('🗺️ setVisibleRegion: SW(${region.bottomLeft.latitude},${region.bottomLeft.longitude}) NE(${region.topRight.latitude},${region.topRight.longitude})');
    _visibleRegion.add(region);
  }

  void startSearch([String? query]) {
    print('🚀 startSearch with query: "${query ?? _searchQuery.value}"');
    final region = _visibleRegion.value;
    if (region == null) {
      print('❌ No visible region available');
      return;
    }

    // 🌍 Используем расширенный BoundingBox для глобального поиска по всей России
    // Россия: примерно от 41°N до 82°N, от 19°E до 180°E
    final expandedBox = BoundingBox(
      const Point(latitude: 41.0, longitude: 19.0),  // Юго-запад России
      const Point(latitude: 82.0, longitude: 180.0), // Северо-восток России
    );
    final expandedGeometry = Geometry.fromBoundingBox(expandedBox);
    print('🌍 Using expanded BoundingBox for global search across all Russia');
    
    _submitSearch(query ?? _searchQuery.value, expandedGeometry);
  }

  void reset() {
    _searchSession?.cancel();
    _searchSession = null;
    _searchState.add(search_model.SearchOff.instance);
    _resetSuggest();
    _searchQuery.add("");
  }

  /// 📍 Установить текущую GPS-позицию пользователя для приоритета саджестов
  void setUserPosition(Point position) {
    _userPosition = position;
    print('📍 User position updated: (${position.latitude}, ${position.longitude})');
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
            it.setSearchArea(Geometry.fromPolygon(_regionToPolygon(region)));
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
        // 🔢 Минимум 3 символа для подсказок (было isNotEmpty)
        if (searchQuery.length >= 3 && region != null) {
          // 🌍 Используем BoundingBox видимой области карты (работает для всего мира!)
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
    print('🔍 _submitSearch called with query: "$query"');
    _searchSession?.cancel();
    _searchSession = _searchManager.submit(
      geometry,
      SearchOptions(resultPageSize: 32),
      _searchSessionListener,
      text: query,
    );
    print('✅ Search session submitted with expanded geometry');
    _searchState.add(search_model.SearchLoading.instance);
    _shouldZoomToSearchResult = true;
  }

  void _submitSuggest(
    String query,
    BoundingBox box, [
    SuggestOptions? options,
  ]) {
    BoundingBox effectiveBox;
    
    print('🔍 _submitSuggest called with query: "$query"');
    
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
      // Создаём BoundingBox ~20км вокруг текущей позиции (≈0.2 градуса)
      final latDelta = 0.2;
      final lonDelta = 0.2;
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
    
    try {
      _suggestSession.suggest(
        effectiveBox,
        options ?? defaultSuggestOptions,
        _suggestSessionListener,
        text: query,
      );
      print('✅ suggest() call completed successfully');
    } catch (e) {
      print('❌ Error calling suggest(): $e');
    }
  }
  
  /// Проверяет, содержит ли запрос название города
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



  void _resetSuggest() {
    _suggestSession.reset();
    _suggestState.add(suggest_model.SuggestOff.instance);
  }

  // Helper method to convert VisibleRegion to Polygon
  Polygon _regionToPolygon(VisibleRegion region) {
    final points = [
      region.bottomLeft,
      Point(latitude: region.bottomLeft.latitude, longitude: region.topRight.longitude),
      region.topRight,
      Point(latitude: region.topRight.latitude, longitude: region.bottomLeft.longitude),
    ];
    
    return Polygon(
      LinearRing(points),
      [],
    );
  }
}
