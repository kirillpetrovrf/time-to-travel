import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, TextStyle;
import 'package:yandex_maps_mapkit/yandex_map.dart';
import 'package:yandex_maps_mapkit/directions.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../../services/price_calculator_service.dart';
import '../../../services/reverse_geocoding_service.dart';
import '../../../models/price_calculation.dart';
import '../../../models/route_point.dart';
import '../../../managers/route_points_manager.dart';
import '../../../listeners/map_input_listener.dart';

/// Экран "Свободный маршрут" — карта на весь экран (как Yandex.Taxi)
/// 
/// 🎯 КАК ПОЛЬЗОВАТЬСЯ:
/// 1. Тапните по карте → появится красная точка (ОТКУДА)
/// 2. Тапните еще раз → появится синяя точка (КУДА)
/// 3. Автоматически построится маршрут и рассчитается стоимость
class CustomRouteWithMapScreen extends StatefulWidget {
  const CustomRouteWithMapScreen({super.key});

  @override
  State<CustomRouteWithMapScreen> createState() =>
      _CustomRouteWithMapScreenState();
}

class _CustomRouteWithMapScreenState extends State<CustomRouteWithMapScreen> {
  // Сервисы
  final PriceCalculatorService _priceService = PriceCalculatorService.instance;
  final ReverseGeocodingService _reverseGeocodingService = ReverseGeocodingService();

  // Менеджеры
  late final RoutePointsManager _routePointsManager;
  late final DrivingRouter _drivingRouter;
  late final MapInputListenerImpl _inputListener;
  late final DrivingSessionRouteListener _drivingRouteListener;

  // Yandex Map
  mapkit.MapWindow? _mapWindow;
  late final mapkit.MapObjectCollection _routesCollection;
  
  // Состояние
  DrivingSession? _drivingSession;
  RoutePointType _selectedPointType = RoutePointType.from;
  bool _isPointSelectionEnabled = true;
  bool _isMapReady = false;
  
  // Результаты
  String? _fromAddress;
  String? _toAddress;
  PriceCalculation? _calculation;
  double? _distanceKm;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🎯 CustomRouteWithMapScreen initState()');
    
    // Слушатель тапов по карте
    _inputListener = MapInputListenerImpl(
      onMapTapCallback: (map, point) {
        _onMapTap(point);
      },
      onMapLongTapCallback: (map, point) {
        // Можно добавить сброс точек
      },
    );
    
    // Слушатель маршрутов (создаем ОДИН РАЗ!)
    _drivingRouteListener = DrivingSessionRouteListener(
      onDrivingRoutes: (routes) {
        print('✅ onDrivingRoutes вызван! routes.length=${routes.length}');
        if (!mounted) {
          print('⚠️ Widget не mounted, прерываем');
          return;
        }
        
        print('🎉 Получено ${routes.length} маршрутов');
        if (routes.isNotEmpty) {
          final route = routes.first;
          final distanceKm = route.metadata.weight.distance.value / 1000;
          print('📏 Расстояние: $distanceKm км');
          
          _calculatePriceForDistance(distanceKm);
          _drawRoute(route);
        }
      },
      onDrivingRoutesError: (error) {
        print('❌ onDrivingRoutesError вызван!');
        print('❌ Error details: $error');
        print('❌ Error type: ${error.runtimeType}');
        
        if (!mounted) {
          print('⚠️ Widget не mounted, прерываем');
          return;
        }
        
        print('❌ Ошибка построения маршрута: $error');
        setState(() {
          _errorMessage = 'Не удалось построить маршрут';
          _calculation = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _drivingSession?.cancel();
    _reverseGeocodingService.dispose();
    super.dispose();
  }

  void _onMapCreated(mapkit.MapWindow mapWindow) async {
    _mapWindow = mapWindow;

    print('🗺️ [MAP] ========== ИНИЦИАЛИЗАЦИЯ КАРТЫ ==========');

    try {
      // Пермь — начальная позиция
      final permPoint = mapkit.Point(latitude: 58.0105, longitude: 56.2502);
      _mapWindow!.map.move(
        mapkit.CameraPosition(permPoint, zoom: 11.0, azimuth: 0, tilt: 0),
      );
      print('🗺️ [MAP] ✅ Камера на Пермь');

      // Коллекции для маркеров и маршрутов
      final routePointsCollection = mapWindow.map.mapObjects.addCollection();
      _routesCollection = mapWindow.map.mapObjects.addCollection();
      
      // Инициализация RoutePointsManager
      print('🔧 Инициализация RoutePointsManager...');
      _routePointsManager = RoutePointsManager(
        mapObjects: routePointsCollection,
        onPointsChanged: (points) {
          print('📍 Точки изменились: ${points.length}');
          _onRouteParametersUpdated();
        },
      );
      await _routePointsManager.init();
      print('✅ RoutePointsManager инициализирован');
      
      // Инициализация DrivingRouter
      _drivingRouter = DirectionsFactory.instance.createDrivingRouter(DrivingRouterType.Combined);
      print('✅ DrivingRouter инициализирован');
      
      // Добавляем слушатель тапов
      mapWindow.map.addInputListener(_inputListener);
      print('✅ MapInputListener добавлен');

      setState(() {
        _isMapReady = true;
      });

      print('🗺️ [MAP] ========== ✅ КАРТА ГОТОВА ==========');
    } catch (e, stackTrace) {
      print('❌ Ошибка инициализации карты: $e\n$stackTrace');
    }
  }

  void _onMapTap(mapkit.Point point) {
    print("🗺️ [_onMapTap] Тап по карте: ${point.latitude}, ${point.longitude}");
    print("🗺️ [_onMapTap] _isPointSelectionEnabled: $_isPointSelectionEnabled");
    print("🗺️ [_onMapTap] _selectedPointType: $_selectedPointType");
    
    if (!_isPointSelectionEnabled) {
      print("🚫 [_onMapTap] Выбор точек отключен, маршрут завершен");
      return;
    }
    
    // Устанавливаем точку
    _routePointsManager.setPoint(_selectedPointType, point);
    print("✅ Точка установлена: $_selectedPointType");
    
    final pointTypeForThisTap = _selectedPointType;
    
    // Переключаем на следующую точку
    if (_selectedPointType == RoutePointType.from) {
      setState(() {
        _selectedPointType = RoutePointType.to;
      });
      print("🔄 Переключено на TO");
    } else {
      setState(() {
        _isPointSelectionEnabled = false;
      });
      print("✅ Обе точки установлены!");
    }
    
    // Получаем адрес для UI
    _reverseGeocodingService.getAddressFromPoint(point).then((address) {
      if (!mounted) return; // Проверка перед setState
      
      final displayText = address ?? 
        "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
      
      setState(() {
        if (pointTypeForThisTap == RoutePointType.from) {
          _fromAddress = displayText;
        } else {
          _toAddress = displayText;
        }
      });
      print("📍 Адрес получен: $displayText");
    });
  }

  void _onRouteParametersUpdated() {
    final fromPoint = _routePointsManager.fromPoint;
    final toPoint = _routePointsManager.toPoint;
    
    if (fromPoint != null && toPoint != null) {
      print('✅ Обе точки установлены, строим маршрут');
      _requestDrivingRoute();
    } else {
      print('⚠️ Не все точки: from=${fromPoint != null}, to=${toPoint != null}');
      setState(() {
        _calculation = null;
        _distanceKm = null;
      });
    }
  }

  void _requestDrivingRoute() {
    final fromPoint = _routePointsManager.fromPoint;
    final toPoint = _routePointsManager.toPoint;
    if (fromPoint == null || toPoint == null) {
      print('⚠️ Невозможен запрос: from=$fromPoint, to=$toPoint');
      return;
    }
    
    print('🚗 Запрос маршрута: $fromPoint → $toPoint');
    print('🔧 DrivingRouter: $_drivingRouter');
    
    _drivingSession?.cancel();
    
    const drivingOptions = DrivingOptions(routesCount: 1);
    const vehicleOptions = DrivingVehicleOptions();
    
    final requestPoints = [
      mapkit.RequestPoint(fromPoint, mapkit.RequestPointType.Waypoint, null, null, null),
      mapkit.RequestPoint(toPoint, mapkit.RequestPointType.Waypoint, null, null, null),
    ];
    
    print('📍 RequestPoints created: ${requestPoints.length}');
    print('🎧 Using listener: ${_drivingRouteListener.hashCode}');
    
    print('🔄 Вызываем requestRoutes...');
    try {
      _drivingSession = _drivingRouter.requestRoutes(
        drivingOptions,
        vehicleOptions,
        _drivingRouteListener, // Используем ЕДИНЫЙ listener!
        points: requestPoints,
      );
      print('✅ requestRoutes вызван, session: $_drivingSession');
    } catch (e, stackTrace) {
      print('❌ EXCEPTION при requestRoutes: $e');
      print('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> _calculatePriceForDistance(double distanceKm) async {
    try {
      final calculation = await _priceService.calculatePrice(distanceKm);
      
      if (!mounted) return; // Проверка перед setState
      
      setState(() {
        _distanceKm = distanceKm;
        _calculation = calculation;
        _errorMessage = null;
      });
      
      print('💰 Стоимость: ${calculation.finalPrice}₽');
    } catch (e) {
      if (!mounted) return; // Проверка перед setState
      
      print('❌ Ошибка расчета: $e');
      setState(() {
        _errorMessage = 'Ошибка расчета стоимости';
      });
    }
  }

  void _drawRoute(DrivingRoute route) {
    _routesCollection.clear();
    
    final polyline = _routesCollection.addPolylineWithGeometry(route.geometry);
    
    polyline.setStrokeColor(const Color.fromARGB(255, 0, 122, 255));
    polyline.strokeWidth = 5.0;
    polyline.outlineColor = const Color.fromARGB(128, 255, 255, 255);
    polyline.outlineWidth = 1.0;
    
    print('✅ Маршрут отрисован');
  }

  void _clearRoute() {
    _routePointsManager.removePoint(RoutePointType.from);
    _routePointsManager.removePoint(RoutePointType.to);
    _routesCollection.clear();
    _drivingSession?.cancel();
    
    setState(() {
      _fromAddress = null;
      _toAddress = null;
      _calculation = null;
      _distanceKm = null;
      _errorMessage = null;
      _selectedPointType = RoutePointType.from;
      _isPointSelectionEnabled = true;
    });
    
    print('🗑️ Маршрут очищен');
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      child: Stack(
        children: [
          // 🗺️ КАРТА НА ВЕСЬ ЭКРАН
          YandexMap(
            onMapCreated: _onMapCreated,
          ),

          // 🔙 Кнопка "Назад" (верхний левый угол)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.systemBackground.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.back,
                    color: theme.label,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // 📍 ПАНЕЛЬ С АДРЕСАМИ (сверху справа)
          if (_fromAddress != null || _toAddress != null)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.systemBackground.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_fromAddress != null) ...[
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: CupertinoColors.systemRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _fromAddress!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.label,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_toAddress != null) ...[
                        if (_fromAddress != null) const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: CupertinoColors.systemBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _toAddress!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.label,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // 💰 НИЖНЯЯ ПАНЕЛЬ С РЕЗУЛЬТАТОМ
          if (_calculation != null || _errorMessage != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.secondarySystemBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _errorMessage != null
                      ? _buildErrorContent(theme)
                      : _buildResultContent(theme),
                ),
              ),
            ),

          // ⏳ ИНДИКАТОР ЗАГРУЗКИ КАРТЫ
          if (!_isMapReady)
            Container(
              color: theme.systemBackground.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(radius: 20),
                    SizedBox(height: 16),
                    Text('Загрузка карты...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(CustomTheme theme) {
    return Row(
      children: [
        const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: CupertinoColors.systemRed,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _errorMessage!,
            style: TextStyle(fontSize: 14, color: theme.label),
          ),
        ),
      ],
    );
  }

  Widget _buildResultContent(CustomTheme theme) {
    final calc = _calculation!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Расстояние и цена
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Расстояние',
                  style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_distanceKm!.toStringAsFixed(1)} км',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.label,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Стоимость',
                  style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                ),
                const SizedBox(height: 4),
                Text(
                  '${calc.finalPrice} ₽',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.systemRed,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Кнопки
        Row(
          children: [
            // Кнопка "Очистить"
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.all(14),
                color: theme.secondarySystemBackground,
                onPressed: _clearRoute,
                child: Text(
                  'Очистить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.label,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Кнопка "Забронировать"
            Expanded(
              flex: 2,
              child: CupertinoButton(
                padding: const EdgeInsets.all(14),
                color: theme.systemRed,
                onPressed: () => _bookTrip(),
                child: const Text(
                  'Забронировать',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _bookTrip() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Бронирование'),
        content: const Text(
          'Функция бронирования в разработке.\n\nДля заказа свяжитесь с диспетчером.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
