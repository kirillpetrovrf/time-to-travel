// ⚠️ РЕЗЕРВНАЯ КОПИЯ СТАРОГО КОДА
// Создана: 12.11.2025
// Причина: Переход на новую архитектуру с картой на весь экран (как Yandex.Taxi)
// Этот файл НЕ используется в приложении

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

/// ⚠️ СТАРАЯ ВЕРСИЯ - НЕ ИСПОЛЬЗУЕТСЯ
/// Экран "Свободный маршрут" с текстовыми полями и кнопкой
class CustomRouteWithMapScreenOldBackup extends StatefulWidget {
  const CustomRouteWithMapScreenOldBackup({super.key});

  @override
  State<CustomRouteWithMapScreenOldBackup> createState() =>
      _CustomRouteWithMapScreenOldBackupState();
}

class _CustomRouteWithMapScreenOldBackupState extends State<CustomRouteWithMapScreenOldBackup> {
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

  // Менеджеры
  final MapSearchManager _mapSearchManager = MapSearchManager();
  final ReverseGeocodingService _reverseGeocodingService = ReverseGeocodingService();
  late final RoutePointsManager _routePointsManager;
  SearchRoutingIntegration? _integration;
  
  // Yandex Map
  mapkit.MapWindow? _mapWindow;
  
  // Routing
  DrivingSession? _drivingSession;
  late final DrivingRouter _drivingRouter;
  var _drivingRoutes = <DrivingRoute>[];
  late final mapkit.MapObjectCollection _routesCollection;

  // Input listener
  late final MapInputListenerImpl _inputListener;
  
  // Состояние выбора точек
  RoutePointType _selectedPointType = RoutePointType.from;
  bool _isPointSelectionEnabled = true;
  bool _routeCompleted = false;
  
  StreamSubscription<void>? _pointsChangedSubscription;

  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    _inputListener = MapInputListenerImpl(
      onMapTapCallback: (map, point) {
        if (!_isPointSelectionEnabled) return;
        
        _routePointsManager.setPoint(_selectedPointType, point);
        
        final pointTypeForThisTap = _selectedPointType;
        
        if (_selectedPointType == RoutePointType.from) {
          setState(() {
            _selectedPointType = RoutePointType.to;
          });
        } else {
          setState(() {
            _isPointSelectionEnabled = false;
            _routeCompleted = true;
          });
        }
        
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
      onMapLongTapCallback: (map, point) {},
    );
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getSettings();
      setState(() {
        _settings = settings;
      });
    } catch (e) {
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

    try {
      final permPoint = mapkit.Point(latitude: 58.0105, longitude: 56.2502);

      _mapWindow!.map.move(
        mapkit.CameraPosition(
          permPoint,
          zoom: 11.0,
          azimuth: 0,
          tilt: 0,
        ),
      );

      final routePointsCollection = mapWindow.map.mapObjects.addCollection();
      _routesCollection = mapWindow.map.mapObjects.addCollection();
      
      _routePointsManager = RoutePointsManager(
        mapObjects: routePointsCollection,
        onPointsChanged: (points) {
          _onRouteParametersUpdated();
        },
      );
      await _routePointsManager.init();
      
      _drivingRouter = DirectionsFactory.instance.createDrivingRouter(DrivingRouterType.Combined);
      
      mapWindow.map.addInputListener(_inputListener);

      setState(() {
        _isMapReady = true;
      });
    } catch (e, stackTrace) {
      print('❌ Ошибка инициализации карты: $e\n$stackTrace');
    }
  }
  
  void _onRouteParametersUpdated() {
    final fromPoint = _routePointsManager.fromPoint;
    final toPoint = _routePointsManager.toPoint;
    
    if (fromPoint != null && toPoint != null) {
      _requestDrivingRoute();
    } else {
      setState(() {
        _calculation = null;
        _distanceKm = null;
      });
    }
  }
  
  void _requestDrivingRoute() {
    final fromPoint = _routePointsManager.fromPoint;
    final toPoint = _routePointsManager.toPoint;
    if (fromPoint == null || toPoint == null) return;
    
    _drivingSession?.cancel();
    
    const drivingOptions = DrivingOptions(routesCount: 1);
    const vehicleOptions = DrivingVehicleOptions();
    
    final requestPoints = [
      mapkit.RequestPoint(fromPoint, mapkit.RequestPointType.Waypoint, null, null, null),
      mapkit.RequestPoint(toPoint, mapkit.RequestPointType.Waypoint, null, null, null),
    ];
    
    final listener = DrivingSessionRouteListener(
      onDrivingRoutes: (routes) {
        if (routes.isNotEmpty) {
          final route = routes.first;
          final distanceKm = route.metadata.weight.distance.value / 1000;
          
          setState(() {
            _drivingRoutes = routes;
          });
          
          _calculatePriceForDistance(distanceKm);
          _drawRoute(route);
        }
      },
      onDrivingRoutesError: (error) {
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
  
  Future<void> _calculatePriceForDistance(double distanceKm) async {
    try {
      final calculation = await _priceService.calculatePrice(distanceKm);
      
      setState(() {
        _distanceKm = distanceKm;
        _calculation = calculation;
        _errorMessage = null;
      });
    } catch (e) {
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
      final routeInfo = await _mapsService.calculateRoute(from, to);

      if (routeInfo == null) {
        throw Exception('Не удалось построить маршрут');
      }

      final calculation = await _priceService.calculatePrice(
        routeInfo.distance,
      );

      setState(() {
        _calculation = calculation;
        _distanceKm = routeInfo.distance;
        _isCalculating = false;
      });
    } catch (e) {
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
        middle: const Text(
          'Свободный маршрут (OLD)',
          style: TextStyle(color: CupertinoColors.label),
        ),
      ),
      child: Stack(
        children: [
          YandexMap(
            onMapCreated: _onMapCreated,
          ),

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
                          ),
                        ),

                        const SizedBox(height: 12),

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
                          ),
                        ),

                        const SizedBox(height: 16),

                        CupertinoButton.filled(
                          onPressed: _isCalculating ? null : _calculateRoute,
                          child: _isCalculating
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : const Text('Рассчитать стоимость'),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  if (_calculation != null || _errorMessage != null)
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.systemBackground.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _errorMessage != null
                            ? Text(_errorMessage!)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Расстояние: ${_distanceKm!.toStringAsFixed(1)} км'),
                                  Text('Стоимость: ${_calculation!.finalPrice} ₽'),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (!_isMapReady)
            Container(
              color: theme.systemBackground.withOpacity(0.9),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 20),
              ),
            ),
        ],
      ),
    );
  }
}
