import 'dart:async';
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/search.dart';

/// Сервис для преобразования координат в адреса (reverse geocoding)
class ReverseGeocodingService {
  final SearchManager _searchManager = 
      SearchFactory.instance.createSearchManager(SearchManagerType.Online);
  
  SearchSession? _reverseSession;

  /// Конвертирует координаты точки в читаемый адрес
  Future<String?> getAddressFromPoint(Point point) async {
    print("🔍 Reverse geocoding for: ${point.latitude}, ${point.longitude}");
    
    final completer = Completer<String?>();
    
    final listener = SearchSessionSearchListener(
      onSearchResponse: (response) {
        try {
          print("📦 Search response received with ${response.collection.children.length} results");
          
          if (response.collection.children.isEmpty) {
            print("⚠️ No results found");
            completer.complete("${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}");
            return;
          }
          
          // Берем первый результат
          final firstResult = response.collection.children.first.asGeoObject();
          if (firstResult != null && firstResult.name != null && firstResult.name!.isNotEmpty) {
            String address = firstResult.name!;
            
            // Добавляем город если есть в описании
            if (firstResult.descriptionText != null && firstResult.descriptionText!.isNotEmpty) {
              final description = firstResult.descriptionText!;
              final parts = description.split(',').map((e) => e.trim()).toList();
              if (parts.isNotEmpty) {
                final city = parts[0];
                if (!address.contains(city)) {
                  address = '$city, $address';
                }
              }
            }
            
            print("✅ Found address: $address");
            completer.complete(address);
          } else {
            print("⚠️ No valid address found");
            completer.complete("${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}");
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
      
      _reverseSession = _searchManager.submit(
        Geometry.fromPoint(point),
        SearchOptions(
          resultPageSize: 10,
          geometry: true,
        ),
        listener,
        text: "${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}",
      );
      
      print("✅ Reverse geocoding request submitted");
    } catch (e) {
      print("❌ Failed to submit reverse geocoding request: $e");
      completer.complete(null);
    }
    
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print("⏰ Reverse geocoding timeout");
        _reverseSession?.cancel();
        return null;
      },
    );
  }

  void dispose() {
    _reverseSession?.cancel();
  }
}