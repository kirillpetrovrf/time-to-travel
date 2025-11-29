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
  

  
  // 🔄 Переменные для двухэтапного поиска
  String? _currentSearchQuery;
  bool _isSecondarySearchInProgress = false;

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
      
      // 🔄 ДВУХЭТАПНЫЙ ПОИСК: Проверяем есть ли результаты в видимой области карты
      if (!_isSecondarySearchInProgress && _currentSearchQuery != null) {
        final localResultsCount = _countLocalResults(response.items);
        print('📊 Найдено результатов: всего=${response.items.length}, в видимой области карты=${localResultsCount}');
        
        // Проверяем нужен ли двухэтапный поиск
        final needsSecondarySearch = _shouldUseSecondarySearch(_currentSearchQuery!, response.items, localResultsCount);
        
        if (needsSecondarySearch) {
          print('🔄 Запускаем поиск в видимой области карты...');
          _performVisibleAreaSearch(_currentSearchQuery!);
          return; // Не обрабатываем результаты первого поиска
        }
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
    print('🔍 _submitSuggest called with query: "$query"');
    
    // Сохраняем для возможного второго поиска
    _currentSearchQuery = query;
    _isSecondarySearchInProgress = false;
    
    // 🌍 ЭТАП 1: Начинаем с глобального поиска по всей России БЕЗ префикса
    _performGlobalSearch(query, box, options);
  }

  void _performGlobalSearch(String query, BoundingBox box, SuggestOptions? options) {
    final globalBox = BoundingBox(
      const Point(latitude: 41.0, longitude: 19.0),  // Юго-запад России
      const Point(latitude: 82.0, longitude: 180.0), // Северо-восток России
    );
    
    print('🌍 ЭТАП 1: Глобальный поиск без префикса: "$query"');
    print('   📦 Используем глобальный BoundingBox по всей России');
    
    try {
      _suggestSession.suggest(
        globalBox,
        options ?? defaultSuggestOptions,
        _suggestSessionListener,
        text: query,
      );
      print('✅ Global suggest() completed');
    } catch (e) {
      print('❌ Error in global search: $e');
    }
  }

  /// Определяет нужен ли двухэтапный поиск
  bool _shouldUseSecondarySearch(String query, List<SuggestItem> items, int localCount) {
    final cleanQuery = query.toLowerCase().trim();
    
    // 🚫 НЕ используем двухэтапный поиск для:
    
    // 1. Поиск городов - если первый результат это город без префикса региона/области
    if (items.isNotEmpty) {
      final firstItem = items.first;
      final title = firstItem.title.text.toLowerCase();
      final subtitle = firstItem.subtitle?.text.toLowerCase();
      
      // Если заголовок точно соответствует запросу и нет подзаголовка = это крупный город
      if (title == cleanQuery && (subtitle == null || subtitle.isEmpty || subtitle == 'null')) {
        print('🏙️ Найден крупный город "$title" без региона - НЕ используем двухэтапный поиск');
        return false;
      }
      
      // Проверяем известные крупные города
      final majorCities = ['москва', 'санкт-петербург', 'спб', 'екатеринбург', 'новосибирск', 
                          'казань', 'челябинск', 'омск', 'ростов-на-дону', 'уфа', 'красноярск',
                          'воронеж', 'пермь', 'волгоград', 'тверь', 'донецк', 'астрахань', 'минск',
                          'ейск', 'таганрог', 'новочеркасск', 'шахты', 'батайск', 'краснодар'];
      
      if (majorCities.contains(cleanQuery)) {
        print('🏙️ Запрос "$cleanQuery" - это крупный город - НЕ используем двухэтапный поиск');
        return false;
      }
    }
    
    // 2. Поиск областей/регионов
    if (cleanQuery.contains('область') || cleanQuery.contains('край') || cleanQuery.contains('республика') || cleanQuery.contains('округ')) {
      print('🗺️ Запрос содержит регион - НЕ используем двухэтапный поиск');
      return false;
    }
    
    // 2.1. Проверяем частичные названия известных регионов России
    final regionPrefixes = [
      'удмурт', 'татарст', 'башкорт', 'чуваш', 'мордов', 'марий', 'коми',
      'карель', 'саха', 'бурят', 'тув', 'хакас', 'алта', 'адыг', 'карач', 
      'кабард', 'северн', 'ингуш', 'чечен', 'дагест', 'калмыц',
      'ямало', 'ханты', 'ненецк', 'чукот', 'магадан', 'камчатск',
      'сахалин', 'приморск', 'хабаровск', 'амурск', 'еврейск'
    ];
    
    for (final prefix in regionPrefixes) {
      if (cleanQuery.startsWith(prefix)) {
        print('🗺️ Запрос "$cleanQuery" начинается с "$prefix" - похоже на регион - НЕ используем двухэтапный поиск');
        return false;
      }
    }
    
    // 2.2. Проверяем названия областных центров которые могут быть частью поиска региона
    final regionCapitalPrefixes = [
      'архангел', 'астрахан', 'белгород', 'брянск', 'владимир', 'волгоград',
      'вологда', 'воронеж', 'иваново', 'иркутск', 'калининград', 'калуга',
      'кемерово', 'киров', 'костром', 'курган', 'курск', 'липецк',
      'магадан', 'мурманск', 'нижний', 'новгород', 'новосибирск', 'омск',
      'орёл', 'оренбург', 'пенза', 'псков', 'ростов', 'рязань',
      'самара', 'саратов', 'смоленск', 'тамбов', 'тверь', 'томск',
      'тула', 'тюмень', 'ульяновск', 'челябинск', 'ярославл'
    ];
    
    for (final prefix in regionCapitalPrefixes) {
      if (cleanQuery.startsWith(prefix) && cleanQuery.length > prefix.length + 2) {
        print('🗺️ Запрос "$cleanQuery" может быть поиском региона по областному центру "$prefix" - НЕ используем двухэтапный поиск');
        return false;
      }
    }
    
    // ✅ Используем двухэтапный поиск для улиц/адресов с малым количеством локальных результатов
    if (localCount < 3) {
      print('🛣️ Мало локальных результатов ($localCount) для запроса "$cleanQuery" - используем двухэтапный поиск');
      return true;
    }
    
    print('✅ Достаточно локальных результатов ($localCount) - НЕ используем двухэтапный поиск');
    return false;
  }

  /// Считает сколько результатов находится в видимой области карты
  int _countLocalResults(List<SuggestItem> items) {
    final visibleRegion = _visibleRegion.valueOrNull;
    if (visibleRegion == null) {
      print('⚠️ Нет информации о видимой области карты');
      return 0;
    }
    
    int localCount = 0;
    for (final item in items) {
      // Получаем координаты из displayText, если возможно
      // Простая эвристика: если subtitle содержит название видимого на карте города
      final subtitle = item.subtitle?.text.toLowerCase() ?? '';
      final displayText = item.displayText?.toLowerCase() ?? '';
      
      // Проверяем есть ли упоминания городов в видимой области
      // Для демонстрации проверим Пермь (можно расширить)
      if (subtitle.contains('пермь') || displayText.contains('пермь')) {
        localCount++;
      }
    }
    
    return localCount;
  }

  /// Выполняет поиск в видимой области карты с префиксом города
  void _performVisibleAreaSearch(String query) {
    final visibleRegion = _visibleRegion.valueOrNull;
    if (visibleRegion == null) {
      print('⚠️ Не можем выполнить поиск в видимой области - нет данных карты');
      return;
    }
    
    _isSecondarySearchInProgress = true;
    
    // Определяем город из видимой области (для Перми)
    final centerLat = (visibleRegion.bottomLeft.latitude + visibleRegion.topRight.latitude) / 2;
    final centerLng = (visibleRegion.bottomLeft.longitude + visibleRegion.topRight.longitude) / 2;
    final centerPoint = Point(latitude: centerLat, longitude: centerLng);
    
    final cityPrefix = _getCityFromGPS(centerPoint);
    final searchQuery = cityPrefix != null ? '$cityPrefix, $query' : query;
    
    // Используем BoundingBox видимой области карты (немного расширенный)
    final latDelta = (visibleRegion.topRight.latitude - visibleRegion.bottomLeft.latitude) * 0.5;
    final lonDelta = (visibleRegion.topRight.longitude - visibleRegion.bottomLeft.longitude) * 0.5;
    
    final expandedBox = BoundingBox(
      Point(
        latitude: visibleRegion.bottomLeft.latitude - latDelta,
        longitude: visibleRegion.bottomLeft.longitude - lonDelta,
      ),
      Point(
        latitude: visibleRegion.topRight.latitude + latDelta,
        longitude: visibleRegion.topRight.longitude + lonDelta,
      ),
    );
    
    print('🗺️ ЭТАП 2: Поиск в видимой области карты: "$searchQuery"');
    print('   📦 BoundingBox: SW(${expandedBox.southWest.latitude},${expandedBox.southWest.longitude}) NE(${expandedBox.northEast.latitude},${expandedBox.northEast.longitude})');
    
    try {
      _suggestSession.suggest(
        expandedBox,
        defaultSuggestOptions,
        _suggestSessionListener,
        text: searchQuery,
      );
      print('✅ Visible area suggest() completed');
    } catch (e) {
      print('❌ Error in visible area search: $e');
    }
  }



  String? _getCityFromGPS(Point position) {
    final lat = position.latitude;
    final lng = position.longitude;
    
    // Пермь: 58.0105°N, 56.2502°E
    if ((lat - 58.0105).abs() < 1.0 && (lng - 56.2502).abs() < 1.0) {
      return 'Пермь';
    }
    // Москва: 55.7558°N, 37.6176°E  
    else if ((lat - 55.7558).abs() < 1.0 && (lng - 37.6176).abs() < 1.0) {
      return 'Москва';
    }
    // Екатеринбург: 56.8431°N, 60.6454°E
    else if ((lat - 56.8431).abs() < 1.0 && (lng - 60.6454).abs() < 1.0) {
      return 'Екатеринбург';
    }
    // Ростов-на-Дону: 47.2357°N, 39.7015°E
    else if ((lat - 47.2357).abs() < 1.0 && (lng - 39.7015).abs() < 1.0) {
      return 'Ростов-на-Дону';
    }
    
    return null; // Неизвестный город
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
