import 'dart:async';
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/search.dart';

/// Сервис для преобразования координат в адреса (reverse geocoding)
/// Использует Yandex Search API для получения человекочитаемых адресов по Point
class ReverseGeocodingService {
  final SearchManager _searchManager = 
      SearchFactory.instance.createSearchManager(SearchManagerType.Online);
  
  SearchSession? _reverseSession;

  /// Конвертирует координаты точки в читаемый адрес
  /// 
  /// Принимает [point] с координатами и возвращает Future<String?> с адресом
  /// Возвращает null если адрес не найден или произошла ошибка
  Future<String?> getAddressFromPoint(Point point) async {
    print("🔍 Reverse geocoding for: ${point.latitude}, ${point.longitude}");
    
    final completer = Completer<String?>();
    
    final listener = SearchSessionSearchListener(
      onSearchResponse: (response) {
        try {
          print("📦 Search response received with ${response.collection.children.length} results");
          print("📦 Response metadata: ${response.collection.metadataContainer}");
          
          // Подробно логируем каждый результат
          for (int i = 0; i < response.collection.children.length; i++) {
            final child = response.collection.children[i];
            final geoObject = child.asGeoObject();
            if (geoObject != null) {
              print("   Result $i:");
              print("   - name: '${geoObject.name}'");
              print("   - descriptionText: '${geoObject.descriptionText}'");
              print("   - metadataContainer: ${geoObject.metadataContainer}");
            }
          }
          
          // Если нет результатов, попробуем поиск в радиусе
          if (response.collection.children.isEmpty) {
            print("⚠️ No results found. Trying search in radius...");
            
            // Создаем новый запрос с поиском адресов в радиусе 100 метров
            final circleListener = SearchSessionSearchListener(
              onSearchResponse: (radiusResponse) {
                print("🔍 Radius search returned ${radiusResponse.collection.children.length} results");
                if (radiusResponse.collection.children.isNotEmpty) {
                  final firstResult = radiusResponse.collection.children.first.asGeoObject();
                  if (firstResult != null && firstResult.name != null && firstResult.name!.isNotEmpty) {
                    print("✅ Found address in radius: ${firstResult.name}");
                    completer.complete(firstResult.name);
                    return;
                  }
                }
                // Если и это не сработало, возвращаем координаты
                print("⚠️ No addresses found even in radius. Using coordinates.");
                completer.complete("${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}");
              },
              onSearchError: (error) {
                print("❌ Radius search error: $error");
                completer.complete("${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}");
              },
            );
            
            // Поиск адресов в области вокруг точки (упрощенный подход)
            final bbox = BoundingBox(
              Point(latitude: point.latitude - 0.001, longitude: point.longitude - 0.001),
              Point(latitude: point.latitude + 0.001, longitude: point.longitude + 0.001),
            );
            
            _searchManager.submit(
              Geometry.fromBoundingBox(bbox), // Область поиска
              SearchOptions(resultPageSize: 10),
              circleListener,
              text: "улица", // Ищем улицы
            );
            return;
          }
          
          // Пробуем найти адрес в нескольких результатах
          String? address;
          
          for (final child in response.collection.children) {
            final geoObject = child.asGeoObject();
            if (geoObject != null) {
              // Извлекаем адрес из компонентов топонима (улица, номер дома)
              address = _extractStreetAddress(geoObject);
              
              // Если нашли адрес с улицей, используем его
              if (address != null && address.isNotEmpty) {
                print("✅ Found valid street address, using it");
                break;
              }
            }
          }
          
          if (address != null && address.isNotEmpty) {
            completer.complete(address);
          } else {
            print("⚠️ No valid address found in any result");
            completer.complete(null);
          }
        } catch (e) {
          print("❌ Error processing reverse geocoding response: $e");
          completer.complete(null);
        }
      },
      onSearchError: (error) {
        print("❌ Reverse geocoding search error: $error");
        completer.complete(null);
      },
    );

    try {
      // Отменяем предыдущий запрос если есть
      _reverseSession?.cancel();
      
      // Создаем новый поисковый запрос по точке
      // Для reverse geocoding используем пустой текст и точку как геометрию
      // ВАЖНО: SearchManagerType.Combined может возвращать бизнес-объекты без топонимов
      // Поэтому мы используем SearchOptions с правильными параметрами
      // Попробуем два подхода: обратное геокодирование и поиск по координатам
      print("🔍 Trying text search with coordinates as backup...");
      
      _reverseSession = _searchManager.submit(
        Geometry.fromPoint(point), // Конвертируем Point в Geometry
        SearchOptions(
          resultPageSize: 20, // Запрашиваем еще больше результатов
          geometry: true, // Включаем геометрию
          // Убираем все фильтры - берем любые результаты
        ),
        listener,
        text: "${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}", // Поиск по координатам
      );
      
      print("✅ Reverse geocoding request submitted successfully");
    } catch (e) {
      print("❌ Failed to submit reverse geocoding request: $e");
      completer.complete(null);
    }
    
    return completer.future.timeout(
      const Duration(seconds: 10), // Таймаут на случай зависания
      onTimeout: () {
        print("⏰ Reverse geocoding timeout");
        _reverseSession?.cancel();
        return null;
      },
    );
  }

  /// Извлекает адрес из GeoObject
  /// Приоритет: 
  /// 1. geoObject.name (готовый форматированный адрес от Yandex) 
  /// 2. toponymMetadata components (собираем из компонентов)
  /// 3. descriptionText (запасной вариант)
  String? _extractStreetAddress(GeoObject geoObject) {
    try {
      print("🔍 Extracting address from GeoObject");
      print("   name: ${geoObject.name}");
      print("   descriptionText: ${geoObject.descriptionText}");
      
      // ПРИОРИТЕТ 1: Сначала проверяем готовый адрес в name
      // Именно здесь Yandex возвращает готовый адрес типа "улица Революции, 48В"
      if (geoObject.name != null && geoObject.name!.isNotEmpty) {
        final name = geoObject.name!;
        print("✅ Using ready address from name: '$name'");
        return name;
      }
      
      // ПРИОРИТЕТ 2: Пробуем собрать адрес из компонентов топонима
      final toponymMetadata = geoObject.metadataContainer.get(SearchToponymObjectMetadata.factory);
      
      if (toponymMetadata != null) {
        final address = toponymMetadata.address;
        final components = address.components;
        
        print("📍 Found ${components.length} address components");
        
        // Собираем адрес из компонентов
        String? street;
        String? house;
        String? locality;
        
        for (final component in components) {
          final kind = component.kinds.firstOrNull?.name;
          print("  Component: ${component.name} (kind: $kind)");
          
          switch (kind) {
            case 'street':
              street = component.name;
              break;
            case 'house':
              house = component.name;
              break;
            case 'locality':
              locality = component.name;
              break;
          }
        }
        
        // Возвращаем адрес только если есть улица
        if (street == null) {
          print("⚠️ No street found in components, skipping");
          return null;
        }
        
        // Формируем адрес: улица + дом + город
        final List<String> addressParts = [street];
        
        if (house != null) {
          addressParts.add(house);
        }
        
        if (locality != null) {
          addressParts.add(locality);
        }
        
        final result = addressParts.join(', ');
        print("✅ Built address from components: '$result'");
        return result;
      }
      
      // ПРИОРИТЕТ 3: Запасной вариант - descriptionText
      if (geoObject.descriptionText != null && geoObject.descriptionText!.isNotEmpty) {
        final desc = geoObject.descriptionText!;
        print("📍 Using description as fallback: '$desc'");
        // Проверяем, что это похоже на адрес (содержит запятую или номер)
        if (desc.contains(',') || RegExp(r'\d').hasMatch(desc)) {
          return desc;
        }
      }
      
      print("⚠️ No suitable address found in geo object");
      return null;
      
    } catch (e) {
      print("❌ Error extracting street address: $e");
      return null;
    }
  }

  /// Освобождение ресурсов
  void dispose() {
    print("🗑️ Disposing ReverseGeocodingService");
    _reverseSession?.cancel();
  }
}