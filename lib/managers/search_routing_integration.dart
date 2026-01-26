import 'dart:async';
import '../services/reverse_geocoding_service.dart';
import '../features/search/managers/map_search_manager.dart';
import '../managers/route_points_manager.dart';
import '../models/route_point.dart'; // ✅ Единый RoutePointType
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:flutter/widgets.dart';

/// Координатор интеграции между поиском адресов и системой маршрутизации
/// 
/// Обеспечивает двунаправленную синхронизацию:
/// - Тап по карте → автоматическое заполнение поля адреса
/// - Выбор адреса → автоматическая установка точки на карте
class SearchRoutingIntegration {
  final MapSearchManager searchManager;
  final RoutePointsManager routeManager;
  final ReverseGeocodingService _reverseService = ReverseGeocodingService();

  // Контроллеры полей ввода для программного обновления текста
  TextEditingController? _fromController;
  TextEditingController? _toController;

  // Флаги для предотвращения циклических обновлений
  bool _isUpdatingFromMap = false;
  bool _isUpdatingFromSearch = false;

  SearchRoutingIntegration({
    required this.searchManager,
    required this.routeManager,
  });

  /// Устанавливает контроллеры полей ввода для синхронизации
  void setFieldControllers({
    TextEditingController? fromController,
    TextEditingController? toController,
  }) {
    _fromController = fromController;
    _toController = toController;
    print("🔗 Field controllers set: FROM=${fromController != null}, TO=${toController != null}");
  }

  /// Инициализация интеграции
  void initialize() {
    print("🔗 Initializing SearchRoutingIntegration");
    _setupSearchToRouteSync();
  }

  /// Обработка тапа по карте с автозаполнением адреса
  /// 
  /// Этот метод вызывается когда пользователь тапнул по карте
  /// Он установит точку маршрута И попытается получить адрес для поля ввода
  Future<void> handleMapTap(Point point, RoutePointType pointType) async {
    if (_isUpdatingFromSearch) {
      print("🔄 Skipping map tap - updating from search");
      return; // Избегаем циклов
    }
    
    _isUpdatingFromMap = true;
    
    try {
      print("🗺️ Map tap integration: $pointType at ${point.latitude}, ${point.longitude}");
      
      // 1. Ставим точку на карте (существующая логика)
      routeManager.setPoint(pointType, point);
      
      // 2. Получаем адрес через reverse geocoding (асинхронно)
      final address = await _reverseService.getAddressFromPoint(point);
      
      if (address != null && address.isNotEmpty) {
        // 3. Заполняем соответствующее поле ввода
        if (pointType == RoutePointType.from) {
          _updateFromField(address);
        } else {
          _updateToField(address);
        }
        
        print("✅ Integration completed: $pointType → '$address'");
      } else {
        print("⚠️ No address found for point, using coordinates only");
      }
    } catch (e) {
      print("❌ Map tap integration error: $e");
      // Не прерываем работу - основная функциональность должна работать
    } finally {
      _isUpdatingFromMap = false;
    }
  }

  /// Обработка выбора адреса с установкой точки на карте
  /// 
  /// Этот метод вызывается когда пользователь выбрал адрес из поиска
  /// Он установит точку маршрута на основе координат найденного адреса
  void handleAddressSelection(Point point, String address, RoutePointType pointType) {
    if (_isUpdatingFromMap) {
      print("🔄 Skipping address selection - updating from map");
      return; // Избегаем циклов
    }
    
    _isUpdatingFromSearch = true;
    
    try {
      print("🔍 Address selection integration: $pointType → '$address'");
      print("📍 Setting point: ${point.latitude}, ${point.longitude}");
      
      // Устанавливаем точку маршрута на основе координат из поиска
      routeManager.setPoint(pointType, point);
      
      // Обновляем поле ввода выбранным адресом
      if (pointType == RoutePointType.from) {
        _updateFromField(address);
      } else {
        _updateToField(address);
      }
      
      print("✅ Address integration completed");
    } catch (e) {
      print("❌ Address selection integration error: $e");
    } finally {
      _isUpdatingFromSearch = false;
    }
  }

  /// Обработка выбора адреса из suggest списка
  /// 
  /// DEPRECATED: Этот метод больше не нужен, т.к. MainScreen напрямую вызывает handleAddressSelection
  /// через callback onAddressSelected. Оставлен для обратной совместимости.
  @Deprecated("Use handleAddressSelection directly through onAddressSelected callback")
  Future<void> handleSuggestSelection(String address, RoutePointType pointType) async {
    print("⚠️ handleSuggestSelection is deprecated - handleAddressSelection will be called automatically");
    // Не делаем ничего - callback в MainScreen обработает всё
  }

  /// Настройка синхронизации от поиска к маршруту
  void _setupSearchToRouteSync() {
    // Пока что заглушка - конкретная реализация будет добавлена
    // когда расширим MapSearchManager hooks
    print("🔧 Search to route sync setup completed");
  }

  /// Обновление поля "Откуда"
  void _updateFromField(String address) {
    try {
      if (_fromController != null && !_isUpdatingFromSearch) {
        print("📝 Updating FROM field: '$address'");
        _fromController!.text = address;
        // Также обновляем поисковый менеджер если нужно
        // searchManager.setQueryText(address); // Может понадобиться позже
      } else {
        print("⚠️ FROM controller not available or updating from search");
      }
    } catch (e) {
      print("❌ Error updating FROM field: $e");
    }
  }

  /// Обновление поля "Куда"  
  void _updateToField(String address) {
    try {
      if (_toController != null && !_isUpdatingFromSearch) {
        print("📝 Updating TO field: '$address'");
        _toController!.text = address;
        // Также обновляем поисковый менеджер если нужно
        // searchManager.setQueryText(address); // Может понадобиться позже
      } else {
        print("⚠️ TO controller not available or updating from search");
      }
    } catch (e) {
      print("❌ Error updating TO field: $e");
    }
  }

  /// Получение текущего активного типа поля
  /// Пока что возвращаем FROM как дефолт, позже можно сделать умнее
  RoutePointType getCurrentFieldType() {
    // TODO: Реализовать логику определения активного поля
    // Можно отслеживать focus состояние полей или получать из RoutePointsManager
    return RoutePointType.from;
  }

  /// Освобождение ресурсов
  void dispose() {
    print("🗑️ Disposing SearchRoutingIntegration");
    _reverseService.dispose();
  }
}