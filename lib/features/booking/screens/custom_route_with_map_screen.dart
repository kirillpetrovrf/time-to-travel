import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, TextStyle;
import 'package:yandex_maps_mapkit/yandex_map.dart';
import 'package:yandex_maps_mapkit/directions.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../../services/yandex_maps_service.dart';
import '../../../services/price_calculator_service.dart';
import '../../../services/calculator_settings_service.dart';
import '../../../services/reverse_geocoding_service.dart';
import '../../../models/calculator_settings.dart';
import '../../../models/price_calculation.dart';
import '../../../models/route_point.dart';
import '../../../managers/route_points_manager.dart';
import '../../../managers/search_routing_integration.dart';
import '../../../features/search/managers/map_search_manager.dart';
import '../../../features/search/state/map_search_state.dart';
import '../../../features/search/state/search_state.dart';
import '../../../utils/extensions.dart';
import '../../../listeners/map_input_listener.dart';

/// Экран "Свободный маршрут" с картой как в Яндекс.Такси
class CustomRouteWithMapScreen extends StatefulWidget {
  const CustomRouteWithMapScreen({super.key});

  @override
  State<CustomRouteWithMapScreen> createState() =>
      _CustomRouteWithMapScreenState();
}

class _CustomRouteWithMapScreenState extends State<CustomRouteWithMapScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  final YandexMapsService _mapsService = YandexMapsService.instance;
  final PriceCalculatorService _priceService = PriceCalculatorService.instance;
  final CalculatorSettingsService _settingsService =
      CalculatorSettingsService.instance;

  bool _isCalculating = false;
  PriceCalculation? _calculation;
  double? _distanceKm;
  String? _errorMessage;
  CalculatorSettings? _settings;

  // 🆕 НОВАЯ АРХИТЕКТУРА: Менеджеры
  final MapSearchManager _mapSearchManager = MapSearchManager();
  final ReverseGeocodingService _reverseGeocodingService = ReverseGeocodingService();
  late final RoutePointsManager _routePointsManager;
  SearchRoutingIntegration? _integration;
  
  // Yandex Map - новый API
  mapkit.MapWindow? _mapWindow;
  
  // 🆕 Routing для автоматического расчета
  DrivingSession? _drivingSession;
  late final DrivingRouter _drivingRouter;
  var _drivingRoutes = <DrivingRoute>[];
  late final mapkit.MapObjectCollection _routesCollection;

  // 🆕 Input listener для тапов по карте
  late final MapInputListenerImpl _inputListener;
  
  // 🆕 Состояние выбора точек
  RoutePointType _selectedPointType = RoutePointType.from;
  bool _isPointSelectionEnabled = true;
  bool _routeCompleted = false;
  
  // Subscriptions
  StreamSubscription<void>? _pointsChangedSubscription;

  // UI состояние
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    print('🎯 CustomRouteWithMapScreen initState()');
    
    // Инициализируем MapInputListener для тапов по карте
    _inputListener = MapInputListenerImpl(
      onMapTapCallback: (map, point) {
        print("🗺️ Тап по карте: ${point.latitude}, ${point.longitude}");
        
        if (!_isPointSelectionEnabled) {
          print("🚫 Выбор точек отключен, маршрут завершен");
          return;
        }
        
        // Устанавливаем точку напрямую
        _routePointsManager.setPoint(_selectedPointType, point);
        print("✅ Точка установлена: $_selectedPointType");
        
        final pointTypeForThisTap = _selectedPointType;
        
        // Автоматически переключаемся на следующую точку
        if (_selectedPointType == RoutePointType.from) {
          setState(() {
            _selectedPointType = RoutePointType.to;
          });
          print("🔄 Переключено на TO");
        } else {
          setState(() {
            _isPointSelectionEnabled = false;
            _routeCompleted = true;
          });
          print("✅ Маршрут завершен!");
        }
        
        // Reverse geocoding для отображения адреса
        _reverseGeocodingService.getAddressFromPoint(point).then((address) {
          final displayText = address ?? "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
          setState(() {
            if (pointTypeForThisTap == RoutePointType.from) {
              _fromController.text = displayText;
            } else {
              _toController.text = displayText;
            }
          });
        });
      },
      onMapLongTapCallback: (map, point) {
        print("📍 Длинный тап по карте");
      },
    );
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getSettings();
      setState(() {
        _settings = settings;
      });
    } catch (e) {
      print('❌ Ошибка загрузки настроек: $e');
      setState(() {
        _settings = CalculatorSettings.defaultSettings;
      });
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _pointsChangedSubscription?.cancel();
    _mapSearchManager.dispose();
    _reverseGeocodingService.dispose();
    _integration?.dispose();
    super.dispose();
  }

  void _onMapCreated(mapkit.MapWindow mapWindow) async {
    _mapWindow = mapWindow;

    print('🗺️ [MAP] ========== ИНИЦИАЛИЗАЦИЯ КАРТЫ ==========');
    print('🗺️ [MAP] MapWindow создан: ${_mapWindow != null}');

    try {
      print('🗺️ [MAP] ✅ Map доступна');

      // Устанавливаем начальную позицию на Пермь
      final permPoint = mapkit.Point(latitude: 58.0105, longitude: 56.2502);
      print('🗺️ [MAP] Перемещаем камеру на: $permPoint');

      _mapWindow!.map.move(
        mapkit.CameraPosition(
          permPoint,
          zoom: 11.0,
          azimuth: 0,
          tilt: 0,
        ),
      );
      print('🗺️ [MAP] ✅ Камера перемещена');

      // 🆕 Инициализация коллекций и менеджеров
      final routePointsCollection = mapWindow.map.mapObjects.addCollection();
      _routesCollection = mapWindow.map.mapObjects.addCollection();
      
      print('🔧 Инициализация RoutePointsManager...');
      _routePointsManager = RoutePointsManager(
        mapObjects: routePointsCollection,
        onPointsChanged: (points) {
          print('📍 Точки изменились: ${points.length} точек');
          _onRouteParametersUpdated();
        },
      );
      await _routePointsManager.init();
      print('✅ RoutePointsManager инициализирован');
      
      // Инициализация роутера
      _drivingRouter = DirectionsFactory.instance.createDrivingRouter(DrivingRouterType.Combined);
      print('✅ DrivingRouter инициализирован');
      
      // Добавляем input listener для тапов
      print('🎯 Добавление MapInputListener...');
      mapWindow.map.addInputListener(_inputListener);
      print('✅ MapInputListener добавлен');

      setState(() {
        _isMapReady = true;
      });

      print('🗺️ [MAP] ========== ✅ КАРТА ГОТОВА К РАБОТЕ ==========');
    } catch (e, stackTrace) {
      print('🗺️ [MAP] ❌ ОШИБКА при инициализации карты:');
      print('🗺️ [MAP] Ошибка: $e');
      print('🗺️ [MAP] StackTrace: $stackTrace');
    }
  }
  
  // 🆕 Обработчик изменения точек маршрута
  void _onRouteParametersUpdated() {
    print('🔄 Обновление параметров маршрута...');
    final fromPoint = _routePointsManager.fromPoint;
    final toPoint = _routePointsManager.toPoint;
    
    if (fromPoint != null && toPoint != null) {
      print('✅ Обе точки установлены, строим маршрут');
      _requestDrivingRoute();
    } else {
      print('⚠️ Не все точки установлены: from=${fromPoint != null}, to=${toPoint != null}');
      setState(() {
        _calculation = null;
        _distanceKm = null;
      });
    }
  }
  
  // 🆕 Запрос маршрута через Yandex Driving Router
  void _requestDrivingRoute() {
    final fromPoint = _routePointsManager.fromPoint;
    final toPoint = _routePointsManager.toPoint;
    if (fromPoint == null || toPoint == null) return;
    
    print('🚗 Запрос маршрута: $fromPoint → $toPoint');
    
    _drivingSession?.cancel();
    
    const drivingOptions = DrivingOptions(routesCount: 1);
    const vehicleOptions = DrivingVehicleOptions();
    
    final requestPoints = [
      mapkit.RequestPoint(fromPoint, mapkit.RequestPointType.Waypoint, null, null, null),
      mapkit.RequestPoint(toPoint, mapkit.RequestPointType.Waypoint, null, null, null),
    ];
    
    final listener = DrivingSessionRouteListener(
      onDrivingRoutes: (routes) {
        print('🎉 Получено ${routes.length} маршрутов');
        if (routes.isNotEmpty) {
          final route = routes.first;
          final distanceKm = route.metadata.weight.distance.value / 1000;
          print('📏 Расстояние: $distanceKm км');
          
          setState(() {
            _drivingRoutes = routes;
          });
          
          _calculatePriceForDistance(distanceKm);
          _drawRoute(route);
        }
      },
      onDrivingRoutesError: (error) {
        print('❌ Ошибка построения маршрута: $error');
        setState(() {
          _errorMessage = 'Не удалось построить маршрут';
          _calculation = null;
        });
      },
    );
    
    _drivingSession = _drivingRouter.requestRoutes(
      drivingOptions,
      vehicleOptions,
      listener,
      points: requestPoints,
    );
  }
  
  // 🆕 Расчет стоимости для известного расстояния
  Future<void> _calculatePriceForDistance(double distanceKm) async {
    try {
      final calculation = await _priceService.calculatePrice(distanceKm);
      
      setState(() {
        _distanceKm = distanceKm;
        _calculation = calculation;
        _errorMessage = null;
      });
      
      print('💰 Стоимость рассчитана: ${calculation.finalPrice}₽');
    } catch (e) {
      print('❌ Ошибка расчета стоимости: $e');
      setState(() {
        _errorMessage = 'Ошибка расчета стоимости';
      });
    }
  }
  
  // 🆕 Отрисовка маршрута на карте
  void _drawRoute(DrivingRoute route) {
    _routesCollection.clear();
    
    final polyline = _routesCollection.addPolylineWithGeometry(route.geometry);
    
    polyline.setStrokeColor(const Color.fromARGB(255, 0, 122, 255));
    polyline.strokeWidth = 5.0;
    polyline.outlineColor = const Color.fromARGB(128, 255, 255, 255);
    polyline.outlineWidth = 1.0;
    
    print('✅ Маршрут отрисован на карте');
  }

  Future<void> _calculateRoute() async {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();

    if (from.isEmpty || to.isEmpty) {
      setState(() {
        _errorMessage = 'Введите адреса отправления и назначения';
        _calculation = null;
      });
      return;
    }

    setState(() {
      _isCalculating = true;
      _errorMessage = null;
      _calculation = null;
    });

    try {
      print('🗺️ Начинаем расчет маршрута...');
      print('🗺️ Откуда: $from');
      print('🗺️ Куда: $to');

      // 1. Получаем маршрут через Yandex API
      final routeInfo = await _mapsService.calculateRoute(from, to);

      if (routeInfo == null) {
        throw Exception('Не удалось построить маршрут');
      }

      print('✅ Маршрут получен: ${routeInfo.distance} км');

      // 2. Рассчитываем стоимость
      final calculation = await _priceService.calculatePrice(
        routeInfo.distance,
      );

      print('💰 Стоимость: ${calculation.finalPrice}₽');

      setState(() {
        _calculation = calculation;
        _distanceKm = routeInfo.distance;
        _isCalculating = false;
      });
    } catch (e) {
      print('❌ Ошибка: $e');
      setState(() {
        _errorMessage = 'Не удалось построить маршрут: ${e.toString()}';
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Свободный маршрут',
          style: const TextStyle(color: CupertinoColors.label),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.info_circle),
          onPressed: () => _showInfoDialog(theme),
        ),
      ),
      child: Stack(
        children: [
          // Карта на весь экран - новый API
          YandexMap(
            onMapCreated: _onMapCreated,
          ),

          // Оверлей с полями ввода
          SafeArea(
            child: SizedBox.expand(
              child: Column(
                children: [
                  // Верхняя панель с полями ввода
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.systemBackground.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Поле "Откуда"
                        Container(
                          decoration: BoxDecoration(
                            color: theme.secondarySystemBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CupertinoTextField(
                            controller: _fromController,
                            placeholder: 'Откуда (город, улица, дом)',
                            padding: const EdgeInsets.all(16),
                            decoration: null,
                            style: TextStyle(color: theme.label),
                            placeholderStyle: TextStyle(
                              color: theme.secondaryLabel.withOpacity(0.5),
                            ),
                            prefix: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Icon(
                                CupertinoIcons.location,
                                color: theme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Поле "Куда"
                        Container(
                          decoration: BoxDecoration(
                            color: theme.secondarySystemBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CupertinoTextField(
                            controller: _toController,
                            placeholder: 'Куда (город, улица, дом)',
                            padding: const EdgeInsets.all(16),
                            decoration: null,
                            style: TextStyle(color: theme.label),
                            placeholderStyle: TextStyle(
                              color: theme.secondaryLabel.withOpacity(0.5),
                            ),
                            prefix: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Icon(
                                CupertinoIcons.location_solid,
                                color: theme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Кнопка расчета
                        CupertinoButton.filled(
                          onPressed: _isCalculating ? null : _calculateRoute,
                          child: _isCalculating
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : const Text(
                                  'Рассчитать стоимость',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Гибкое пространство между панелями
                  const Spacer(),

                  // Нижняя панель с результатом (гибкая для клавиатуры)
                  if (_calculation != null || _errorMessage != null)
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.systemBackground.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: _errorMessage != null
                            ? _buildErrorContent(theme)
                            : _buildResultContent(theme),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Индикатор загрузки карты
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Расстояние и формула
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
                      color: theme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Кнопка бронирования
          CupertinoButton.filled(
            onPressed: () => _bookTrip(),
            child: const Text(
              'Забронировать',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(CustomTheme theme) {
    final settings = _settings ?? CalculatorSettings.defaultSettings;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Как работает калькулятор?'),
        content: Text(
          '\nФормула расчета:\n\n'
          '${settings.baseCost}₽ (базовая стоимость)\n+ '
          '${settings.costPerKm}₽ × расстояние (км)\n\n'
          'Минимальная стоимость: ${settings.minPrice}₽\n\n'
          '${settings.roundToThousands ? "Округление до тысяч вверх" : "Без округления"}',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Понятно'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
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
