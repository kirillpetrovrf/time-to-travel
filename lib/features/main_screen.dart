import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:common/common.dart'; // Нужен для extension методов (let, castOrNull) и Impl классов
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:geolocator/geolocator.dart' as geolocator;
// import 'package:taxi_route_calculator/camera/camera_manager.dart';
import '../dialogs/dialogs_factory.dart';
import 'search/managers/map_search_manager.dart';
import 'search/state/map_search_state.dart';
import 'search/state/search_state.dart';
import 'search/state/suggest_state.dart';
import '../managers/route_points_manager.dart';
import '../managers/search_routing_integration.dart';
import '../permissions/permission_manager.dart';
import '../services/reverse_geocoding_service.dart';
import '../services/auth_service.dart';
import 'home/screens/home_screen.dart';
import '../models/user.dart';
import '../services/price_calculator_service.dart';
import '../models/price_calculation.dart';
import '../models/taxi_order.dart';
import '../models/booking.dart';
import '../models/route_stop.dart';
import '../models/trip_type.dart' as trip_type;
import '../models/passenger_info.dart';
import '../models/baggage.dart';
import '../models/pet_info_v3.dart';
import 'orders/screens/booking_detail_screen.dart';
import '../utils/polyline_extensions.dart';

import '../models/route_point.dart'; // ✅ Единый RoutePointType
import '../widgets_taxi/search_fields_panel.dart';
import '../widgets_taxi/point_type_selector.dart';
import '../widgets/custom_route_booking_modal.dart';
import 'package:yandex_maps_mapkit/directions.dart';
import 'package:yandex_maps_mapkit/image.dart' as image_provider;
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, TextStyle; // Hide Icon and TextStyle to avoid conflict
// import 'package:yandex_maps_mapkit/mapkit_factory.dart';
import 'package:yandex_maps_mapkit/runtime.dart';

// Tutorial imports
import 'tutorial/tutorial_overlay.dart';
import 'tutorial/tutorial_step.dart';
import 'tutorial/tutorial_preferences.dart';

enum ActiveField { none, from, to }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _searchResultImageProvider =
      image_provider.ImageProvider.fromImageProvider(
          const AssetImage("assets/search_result.png"));
  TextEditingController _textFieldControllerFrom = TextEditingController();
  TextEditingController _textFieldControllerTo = TextEditingController();

  final _mapManager = MapSearchManager();
  final _reverseGeocodingService = ReverseGeocodingService();
  final _priceService = PriceCalculatorService.instance; // 🆕 Сервис расчёта цены
  late final RoutePointsManager _routePointsManager;
  SearchRoutingIntegration? _integration; // 🆕 Координатор интеграции (nullable until map is ready)

  // 🆕 Состояние калькулятора
  PriceCalculation? _calculation; // Результат расчёта
  double? _distanceKm;            // Расстояние в км

  // Tutorial GlobalKeys
  final GlobalKey _geolocationButtonKey = GlobalKey();
  final GlobalKey _searchPanelKey = GlobalKey();
  final GlobalKey _orderButtonKey = GlobalKey();
  final GlobalKey _fromFlagButtonKey = GlobalKey(); // Кнопка "ОТ"
  final GlobalKey _toFlagButtonKey = GlobalKey();   // Кнопка "ДО"
  final GlobalKey _clearButtonKey = GlobalKey();     // Кнопка корзины
  
  // Tutorial state
  bool _showTutorial = false;

  late final mapkit.MapObjectCollection _searchResultPlacemarksCollection;

  late final _mapWindowSizeChangedListener = MapSizeChangedListenerImpl(
      onMapWindowSizeChange: (_, __, ___) => _updateFocusRect());

  late final _cameraListener = CameraPositionListenerImpl(
    (_, __, cameraUpdateReason, ___) {
      // Updating current visible region to apply new search on map moved by user gestures.
      if (cameraUpdateReason == mapkit.CameraUpdateReason.Gestures) {
        _mapWindow
            ?.let((it) => _mapManager.setVisibleRegion(it.map.visibleRegion));
      }
    },
  );

  late final _searchResultPlacemarkTapListener = MapObjectTapListenerImpl(
    onMapObjectTapped: (mapObject, _) {
      final successSearchState = _mapManager
          .mapSearchState.valueOrNull?.searchState
          .castOrNull<SearchSuccess>();

      final point = mapObject.castOrNull<mapkit.PlacemarkMapObject>()?.geometry;
      final tappedGeoObject =
          successSearchState?.placemarkPointToGeoObject[point];

      if (tappedGeoObject != null && point != null) {
        print('🎯 Search result tapped: ${tappedGeoObject.name ?? 'Unknown'}');
        print('📍 Coordinates: ${point.latitude}, ${point.longitude}');
        
        // Устанавливаем точку в зависимости от активного поля
        if (_lastSearchFieldType != null && _isPointSelectionEnabled) {
          print('🔧 Setting ${_lastSearchFieldType} point from search result');
          _routePointsManager.setPoint(_lastSearchFieldType!, point);
          
          // Обновляем текст в соответствующем поле
          final address = tappedGeoObject.name ?? 'Unknown location';
          if (_lastSearchFieldType == RoutePointType.from) {
            _textFieldControllerFrom.text = address;
          } else {
            _textFieldControllerTo.text = address;
          }
          
          // Управляем состоянием после установки точки
          if (_lastSearchFieldType == RoutePointType.from) {
            setState(() {
              _selectedPointType = RoutePointType.to;
            });
            print('🔄 Auto-switched to TO point type after FROM selection');
          } else {
            setState(() {
              _isPointSelectionEnabled = false;
              _routeCompleted = true;
            });
            print('✅ Route completed! Point selection disabled.');
          }
          
          print("📱 Установлено: ${address}");
        } else {
          print("📱 Выбрано: ${tappedGeoObject.name ?? 'Неизвестно'}");
        }
      }
      return true;
    },
  );

  mapkit.MapWindow? _mapWindow;

  StreamSubscription<MapSearchState>? _mapSearchSubscription;
  StreamSubscription<void>? _searchSubscription;
  StreamSubscription<void>? _suggestSubscription;

  // Состояние активного поля
  ActiveField _activeField = ActiveField.none;
  
  // Запоминаем тип поля для которого был запущен последний поиск
  // Это нужно т.к. _activeField сбрасывается перед получением результата поиска
  RoutePointType? _lastSearchFieldType;
  
  // Флаг того, что пользователь выбрал адрес из саджеста (не просто печатает)
  bool _waitingForSuggestionResult = false;
  
  // Флаг программной установки текста (чтобы не триггерить suggest)
  bool _isSettingTextProgrammatically = false;

  // Тип точки, выбранный пользователем для установки на карту
  RoutePointType _selectedPointType = RoutePointType.from;

  // Variables for tap-to-place functionality from map_routing
  bool _isPointSelectionEnabled = true; // Flag to control point selection mode
  bool _routeCompleted = false; // Flag for route completion
  bool _showDeleteMessage = false; // Flag for animated delete message

  // Routing variables from map_routing (lines 49-52, 92-99)
  var _drivingRoutes = <DrivingRoute>[];
  // REMOVED: _pedestrianRoutes, _publicTransportRoutes, and _currentRoutingType - taxi app only needs driving routes

  // Router and session variables from map_routing
  DrivingSession? _drivingSession;
  late final DrivingRouter _drivingRouter;

  // REMOVED: PedestrianRouter and MasstransitRouter - taxi app only needs driving routes

  late final mapkit.MapObjectCollection _routesCollection;

  // User location placemark
  mapkit.PlacemarkMapObject? _userLocationPlacemark;
  late final mapkit.MapObjectCollection _userLocationCollection;

  // Geolocation variables
  late final DialogsFactory _dialogsFactory;
  late final PermissionManager _permissionManager;
  // late final mapkit.LocationManager _locationManager;
  // late final CameraManager _cameraManager;
  // late final mapkit.UserLocationLayer _userLocationLayer;
  late final AppLifecycleListener _lifecycleListener;

  // MapInputListener as class variable to prevent garbage collection
  late final _inputListener = MapInputListenerImpl(
    onMapTapCallback: (map, point) {
      print("🗺️🗺️🗺️ Map tapped at: ${point.latitude}, ${point.longitude}");
      print("🔍 Current state: isEnabled=$_isPointSelectionEnabled, selectedType=$_selectedPointType, routeCompleted=$_routeCompleted");
      
      // Check if we can still place points
      if (!_isPointSelectionEnabled) {
        print("🚫 Point selection is disabled. Route already completed.");
        return;
      }
      
      // ПРЯМАЯ установка точки без дополнительной обработки (как в map_routing)
      _routePointsManager.setPoint(_selectedPointType, point);
      print("✅ Point set directly: $_selectedPointType → ${point.latitude}, ${point.longitude}");
      
      // Сохраняем тип точки для reverse geocoding
      final pointTypeForThisTap = _selectedPointType;
      
      // Automatically switch to next point type
      print("🔍 Checking selectedType: $_selectedPointType");
      
      if (_selectedPointType == RoutePointType.from) {
        print("🔄 Was FROM type, switching to TO and staying enabled");
        setState(() {
          _selectedPointType = RoutePointType.to;
        });
        print("🔄 Auto-switched to TO point type");
      } else if (_selectedPointType == RoutePointType.to) {
        print("🛑 Was TO type, disabling point selection!");
        setState(() {
          _isPointSelectionEnabled = false;
          _routeCompleted = true;
        });
        print("✅ Route completed! Point selection disabled.");
        print("🔍 New state: isEnabled=$_isPointSelectionEnabled, routeCompleted=$_routeCompleted");
      }
      
      // Только reverse geocoding для отображения адреса (не влияет на координаты точки)
      print("🌐 Starting reverse geocoding for point: ${point.latitude}, ${point.longitude}");
      _reverseGeocodingService.getAddressFromPoint(point).then((address) {
        print("✅ Reverse geocoding completed. Address: $address");
        final displayText = address ?? "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
        print("📝 Display text will be: $displayText");
        setState(() {
          if (pointTypeForThisTap == RoutePointType.from) {
            _textFieldControllerFrom.text = displayText;
            print("📝 Updated FROM field with: $displayText");
          } else {
            _textFieldControllerTo.text = displayText;
            print("📝 Updated TO field with: $displayText");
          }
        });
      }).catchError((e) {
        print("❌ Reverse geocoding error: $e");
        // Fallback to coordinates on error
        final coordsText = "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
        setState(() {
          if (pointTypeForThisTap == RoutePointType.from) {
            _textFieldControllerFrom.text = coordsText;
          } else {
            _textFieldControllerTo.text = coordsText;
          }
        });
      });
    },
    onMapLongTapCallback: (map, point) {
      print("📍 MapInputListener: onMapLongTap called");
      // Can add long tap logic if needed
    },
  );

  // Route listeners from map_routing (lines 154-218)
  late final _drivingRouteListener = DrivingSessionRouteListener(
    onDrivingRoutes: (newRoutes) {
      print('🎉🎉🎉 onDrivingRoutes FIRED! Got ${newRoutes.length} routes');
      
      // Используем все найденные маршруты (блокировка КПП убрана)
      final routesToUse = newRoutes;
      
      if (routesToUse.isEmpty) {
        // Показываем диалог вместо SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Маршрут не найден'),
              content: const Text('Не удалось построить маршрут по выбранным точкам'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        });
      }
      setState(() {
        _drivingRoutes = routesToUse;
        _onDrivingRoutesUpdated();
      });
      
      // 🆕 Расчёт цены для первого маршрута
      if (routesToUse.isNotEmpty) {
        final route = routesToUse.first;
        final distanceKm = route.metadata.weight.distance.value / 1000;
        print('📏 [ROUTE] Расстояние маршрута: $distanceKm км');
        _calculatePriceForDistance(distanceKm);
      }
    },
    onDrivingRoutesError: (Error error) {
      print('❌❌❌ onDrivingRoutesError FIRED! Error: $error');
      // Показываем диалог вместо SnackBar (совместимость с CupertinoApp)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        String errorMessage;
        switch (error) {
          case final NetworkError _:
            errorMessage = "Ошибка сети при построении маршрута.\nПроверьте интернет-соединение.";
          default:
            errorMessage = "Не удалось построить маршрут.\nПопробуйте уменьшить расстояние.";
        }
        
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Ошибка маршрута'),
            content: Text(errorMessage),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      });
    },
  );

  // REMOVED: _pedestrianRouteListener and _publicTransportRouteListener - taxi app only needs driving routes

  @override
  void initState() {
    super.initState();
    
    print('🎯 MainScreen initState() called');
    print('📝 INIT - FROM field: "${_textFieldControllerFrom.text}"');
    print('📝 INIT - TO field: "${_textFieldControllerTo.text}"');
    print('🔍 INIT - Active field: $_activeField');
    print('📌 INIT - Last search field type: $_lastSearchFieldType');
    print('✅ RoutePointsManager will be initialized when map is created');
    
    // Initialize geolocation components
    _dialogsFactory = DialogsFactory(_showDialog);
    _permissionManager = PermissionManager(_dialogsFactory);
    // TODO: Найти правильный способ создания LocationManager
    // _locationManager = mapkit.createLocationManager();
    
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _requestPermissionsIfNeeded();
      },
    );

    _requestPermissionsIfNeeded();
    _checkAndShowTutorial(); // Check if need to show tutorial
  }

  // Tutorial methods
  Future<void> _checkAndShowTutorial() async {
    print('🎓 [TUTORIAL] Проверка, нужно ли показывать туториал...');
    final completed = await TutorialPreferences.isTutorialCompleted();
    print('🎓 [TUTORIAL] Статус завершения: $completed');
    if (!completed && mounted) {
      print('🎓 [TUTORIAL] Туториал НЕ завершен, запускаем через 1 секунду...');
      // Show tutorial after a short delay to ensure UI is ready
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          print('🎓 [TUTORIAL] Запуск туториала!');
          _startTutorial();
        } else {
          print('🎓 [TUTORIAL] ❌ Widget не mounted, пропускаем туториал');
        }
      });
    } else if (completed) {
      print('🎓 [TUTORIAL] ✅ Туториал уже был завершен ранее');
    } else {
      print('🎓 [TUTORIAL] ❌ Widget не mounted');
    }
  }

  void _startTutorial() {
    print('🎓 [TUTORIAL] 🚀 _startTutorial() вызван');
    setState(() {
      _showTutorial = true;
      print('🎓 [TUTORIAL] ✅ _showTutorial установлен в true');
    });
  }

  void _completeTutorial() async {
    print('🎓 [TUTORIAL] ✅ Туториал завершен, сохраняем статус...');
    await TutorialPreferences.setTutorialCompleted();
    setState(() {
      _showTutorial = false;
      print('🎓 [TUTORIAL] 🔴 _showTutorial установлен в false');
    });
  }

  void _skipTutorial() async {
    await TutorialPreferences.setTutorialCompleted();
    setState(() {
      _showTutorial = false;
    });
  }

  // 🆕 Метод для автоматической установки тестовых точек маршрута
  void _setDemoRoute() {
    print('🎬 Tutorial: Устанавливаем демо-маршрут');
    
    // Получаем видимую область карты
    final visibleRegion = _mapWindow?.map.visibleRegion;
    if (visibleRegion == null) {
      print('⚠️ Tutorial: Карта ещё не готова');
      return;
    }
    
    // Вычисляем центр видимой области
    final centerLat = (visibleRegion.bottomLeft.latitude + visibleRegion.topRight.latitude) / 2;
    final centerLon = (visibleRegion.bottomLeft.longitude + visibleRegion.topRight.longitude) / 2;
    
    // Вычисляем размер видимой области
    final latDelta = visibleRegion.topRight.latitude - visibleRegion.bottomLeft.latitude;
    final lonDelta = visibleRegion.topRight.longitude - visibleRegion.bottomLeft.longitude;
    
    // Создаём две точки на расстоянии ~30% от центра влево-вверх и вправо-вниз
    final fromPoint = mapkit.Point(
      latitude: centerLat - latDelta * 0.15, 
      longitude: centerLon - lonDelta * 0.15
    );
    final toPoint = mapkit.Point(
      latitude: centerLat + latDelta * 0.15, 
      longitude: centerLon + lonDelta * 0.15
    );
    
    print('📍 Tutorial: Демо точки в видимой области');
    print('   FROM: ${fromPoint.latitude}, ${fromPoint.longitude}');
    print('   TO: ${toPoint.latitude}, ${toPoint.longitude}');
    
    // Устанавливаем точки
    _routePointsManager.setPoint(RoutePointType.from, fromPoint);
    _routePointsManager.setPoint(RoutePointType.to, toPoint);
    
    // Обновляем текстовые поля
    setState(() {
      _isSettingTextProgrammatically = true;
      _textFieldControllerFrom.text = 'Точка А';
      _textFieldControllerTo.text = 'Точка Б';
      _isSettingTextProgrammatically = false;
      _selectedPointType = RoutePointType.to;
      _routeCompleted = true;
    });
    
    print('✅ Tutorial: Демо-маршрут установлен');
  }

  // 🆕 Метод для автоматической очистки маршрута (для туториала)
  void _clearDemoRoute() {
    print('🎬 Tutorial: Очищаем демо-маршрут (шаг корзины)');
    
    // Небольшая задержка чтобы пользователь увидел подсветку кнопки
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Показываем анимированный текст
        setState(() {
          _showDeleteMessage = true;
        });
        
        // Выполняем сброс
        _forceResetAllFields();
        _routePointsManager.forceTripleClear();
        print("🗑️ Tutorial: Маршрут очищен кнопкой корзины");
        
        // Скрываем текст через 2 секунды
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showDeleteMessage = false;
            });
          }
        });
      }
    });
  }

  List<TutorialStep> _getTutorialSteps() {
    return [
      // ШАГ 1: Приветствие
      TutorialStep(
        title: 'Добро пожаловать!',
        description: 'Вводи адреса вручную, чтобы заказать машину.',
        targetKey: _searchPanelKey,
        arrowDirection: TutorialArrowDirection.top,
      ),
      // ШАГ 2: Флаги + автоматическая установка маршрута
      TutorialStep(
        title: 'Выбор точек на карте',
        description: 'Сейчас мы автоматически установим маршрут для демонстрации. '
            'Нажимай на кнопки флагов 🚩🏁, чтобы указать адрес подачи и назначения.',
        targetKey: _fromFlagButtonKey,
        additionalTargetKeys: [_toFlagButtonKey],
        arrowDirection: TutorialArrowDirection.top,
        onStepShown: _setDemoRoute, // Автоматически создаём маршрут
      ),
      // ШАГ 3: Геолокация
      TutorialStep(
        title: 'Моя геолокация',
        description: 'Нажми эту кнопку, чтобы быстро определить твоё текущее местоположение на карте.',
        targetKey: _geolocationButtonKey,
        arrowDirection: TutorialArrowDirection.bottom,
      ),
      // ШАГ 4: Заказать поездку
      TutorialStep(
        title: 'Заказать поездку',
        description: 'После построения маршрута нажми эту кнопку для оформления заказа. '
            'Ты увидишь стоимость поездки и сможешь выбрать дополнительные услуги.',
        targetKey: _orderButtonKey,
        arrowDirection: TutorialArrowDirection.bottom, // Карточка ВВЕРХУ экрана
      ),
      // ШАГ 5 (ПОСЛЕДНИЙ): Корзина + автоматическая очистка
      TutorialStep(
        title: 'Сброс маршрута',
        description: 'Нажми на корзину, чтобы удалить построенный маршрут и начать заново. '
            'Сейчас мы автоматически очистим демо-маршрут.',
        targetKey: _clearButtonKey,
        arrowDirection: TutorialArrowDirection.top, // Карточка ВНИЗУ экрана
        onStepShown: _clearDemoRoute, // 🆕 Автоматически очищаем маршрут
      ),
    ];
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    // _cameraManager.dispose();
    _mapManager.dispose();
    _reverseGeocodingService.dispose();
    _integration?.dispose();
    // RoutePointsManagerSafe не имеет dispose метода - очистка происходит автоматически
    super.dispose();
  }

  // Геолокационные методы
  void _showDialog(
    String descriptionText,
    ButtonTextsWithActions buttonTextsWithActions,
  ) {
    final actionButtons = buttonTextsWithActions.map((button) {
      return TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          button.$2();
        },
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
        child: Text(button.$1),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(descriptionText),
          contentTextStyle: Theme.of(context).textTheme.labelLarge,
          backgroundColor: Theme.of(context).colorScheme.surface,
          actions: actionButtons,
        );
      },
    );
  }

  void _requestPermissionsIfNeeded() {
    final permissions = [PermissionType.accessLocation];
    _permissionManager.tryToRequest(permissions);
    _permissionManager.showRequestDialog(permissions);
  }

  // Visualization methods from map_routing (lines 498-536)
  void _onDrivingRoutesUpdated() {
    _routesCollection.clear();
    if (_drivingRoutes.isEmpty) {
      return;
    }

    _drivingRoutes.asMap().forEach((index, route) {
      _createPolylineWithStyle(index, route.geometry);
    });
  }

  // 🆕 Расчёт стоимости поездки
  Future<void> _calculatePriceForDistance(double distanceKm) async {
    try {
      print('💰 [PRICE] Расчёт цены для расстояния: $distanceKm км');
      
      // Получаем города из текстовых полей
      String fromCity = _textFieldControllerFrom.text.trim();
      String toCity = _textFieldControllerTo.text.trim();
      String departureTime = DateFormat('HH:mm').format(DateTime.now());
      
      // 🎯 Извлекаем промежуточные города из всех точек маршрута
      List<String> intermediateCities = [];
      final allPoints = _routePointsManager.points;
      
      // 🌍 Получаем координаты начальной и конечной точки
      final fromPoint = _routePointsManager.fromPoint;
      final toPoint = _routePointsManager.toPoint;
      
      double? fromLat, fromLng, toLat, toLng;
      
      if (fromPoint != null) {
        fromLat = fromPoint.latitude;
        fromLng = fromPoint.longitude;
      }
      
      if (toPoint != null) {
        toLat = toPoint.latitude;
        toLng = toPoint.longitude;
      }
      
      if (allPoints.length > 2) {
        // Если есть промежуточные точки
        for (int i = 1; i < allPoints.length - 1; i++) {
          intermediateCities.add('Промежуточная_точка_${i}');
        }
      }
      
      print('💰 [PRICE] Маршрут: $fromCity -> $toCity, время: $departureTime');
      print('💰 [PRICE] 📍 Координаты: ($fromLat, $fromLng) → ($toLat, $toLng)');
      print('💰 [PRICE] Промежуточные города: ${intermediateCities.join(", ")}');
      
      final calculation = await _priceService.calculatePrice(
        distanceKm,
        fromCity: fromCity,
        toCity: toCity,
        departureTime: departureTime,
        intermediateCities: intermediateCities,
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
      
      if (!mounted) return;
      
      setState(() {
        _distanceKm = distanceKm;
        _calculation = calculation;
      });
      
      print('💰 [PRICE] Стоимость: ${calculation.finalPrice}₽ ${calculation.isSpecialRoute ? "(спец. маршрут)" : ""}');
    } catch (e) {
      print('❌ [PRICE] Ошибка расчета: $e');
    }
  }

  // 🆕 Обработчик нажатия кнопки "Заказать"
  Future<void> _onOrderButtonPressed() async {
    print('🚕 [ORDER] Кнопка "Заказать такси" нажата');
    
    // Проверяем наличие всех данных
    if (_calculation == null || _distanceKm == null) {
      print('❌ [ORDER] Нет данных для заказа');
      _showOrderDialog('Ошибка', 'Нет данных для заказа', isError: true);
      return;
    }
    
    final fromPoint = _routePointsManager.fromPoint;
    final toPoint = _routePointsManager.toPoint;
    
    if (fromPoint == null || toPoint == null) {
      print('❌ [ORDER] Нет точек маршрута');
      _showOrderDialog('Ошибка', 'Не выбраны точки маршрута', isError: true);
      return;
    }
    
    print('✅ [ORDER] Все данные есть, получаем адреса...');
    print('   FROM: $fromPoint');
    print('   TO: $toPoint');
    print('   Distance: $_distanceKm км');
    print('   Price: ${_calculation!.finalPrice}₽');
    
    // Получаем адреса точек маршрута
    String fromAddress = _textFieldControllerFrom.text.isNotEmpty 
        ? _textFieldControllerFrom.text 
        : 'Адрес не определен';
    String toAddress = _textFieldControllerTo.text.isNotEmpty
        ? _textFieldControllerTo.text
        : 'Адрес не определен';
    
    // Если адреса пустые, пробуем получить через reverse geocoding
    if (fromAddress == 'Адрес не определен' || toAddress == 'Адрес не определен') {
      try {
        final reverseGeoService = ReverseGeocodingService();
        
        if (fromAddress == 'Адрес не определен') {
          print('📍 [ORDER] Получение адреса точки отправления...');
          fromAddress = await reverseGeoService.getAddressFromPoint(fromPoint) ?? 'Адрес не определен';
          print('   FROM Address: $fromAddress');
        }
        
        if (toAddress == 'Адрес не определен') {
          print('📍 [ORDER] Получение адреса точки назначения...');
          toAddress = await reverseGeoService.getAddressFromPoint(toPoint) ?? 'Адрес не определен';
          print('   TO Address: $toAddress');
        }
      } catch (e) {
        print('⚠️ [ORDER] Ошибка получения адресов: $e');
      }
    }
    
    print('🎯 [ORDER] Открываем модальное окно бронирования...');
    
    // Открываем модальное окно бронирования
    final order = await showCupertinoModalPopup<TaxiOrder>(
      context: context,
      builder: (context) => CustomRouteBookingModal(
        fromAddress: fromAddress,
        toAddress: toAddress,
        fromPoint: fromPoint,
        toPoint: toPoint,
        distanceKm: _distanceKm,
        basePrice: _calculation!.finalPrice,
        baseCost: _calculation!.baseCost,
        costPerKm: _calculation!.costPerKm,
      ),
    );
    
    if (order == null) {
      print('❌ [ORDER] Пользователь отменил бронирование');
      return;
    }
    
    print('✅ [ORDER] Заказ создан через модальное окно: ${order.orderId}');
    
    // ✅ SQLite удалён - заказы идут напрямую в PostgreSQL через OrdersService
    print('🎉 [ORDER] Заказ будет синхронизирован с PostgreSQL автоматически!');
    print('⚙️ [ORDER] BookingService уже отправил заказ на backend через OrdersService');
    
    // Открываем экран деталей заказа напрямую (без success dialog)
    print('📱 [ORDER] Прямой переход к экрану деталей заказа...');
    await _openTaxiOrderDetails(order.orderId);
  }

  // Переключение на вкладку "Мои заказы"
  // DEPRECATED: метод _navigateToOrders удален - больше не используется

  /// ⚠️ DEPRECATED: SQLite удалён, заказы такси теперь в PostgreSQL через OrdersService
  /// Открывает экран деталей taxi order (конвертируя TaxiOrder → Booking)
  Future<void> _openTaxiOrderDetails(String orderId) async {
    try {
      print('⚠️ [TAXI] SQLite удалён - используйте BookingService для просмотра заказов');
      print('💡 [TAXI] Заказ ID: $orderId - загружайте через BookingService.getBookingById()');
      
      // ✅ TODO: Заменить на вызов OrdersService.getOrderById() после рефакторинга UI
      // final orderResult = await OrdersService().getOrderById(orderId);
      // if (!orderResult.isSuccess) {
      //   print('❌ [TAXI] Заказ не найден: $orderId');
      //   return;
      // }
      // final order = orderResult.order!;
      // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)));
      
    } catch (e) {
      print('❌ [TAXI] Ошибка: $e');
    }
  }

  // Показать диалог успешного создания заказа
  // Показать диалог с результатом заказа (Cupertino-стиль)
  void _showOrderDialog(String title, String message, {required bool isError}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // REMOVED: _onPedestrianRoutesUpdated and _onPublicTransportRoutesUpdated - taxi app only needs driving routes

  void _createPolylineWithStyle(int routeIndex, mapkit.Polyline routeGeometry) {
    final polyline = _routesCollection.addPolylineWithGeometry(routeGeometry);
    routeIndex == 0
        ? polyline.applyMainRouteStyle()
        : polyline.applyAlternativeRouteStyle();
  }

    // Route update orchestration from map_routing (lines 445-495)
  void _onRouteParametersUpdated() {
    print('🛣️ _onRouteParametersUpdated() called');
    final routePoints = _routePointsManager.points;
    print('🛣️ Route points count: ${routePoints.length}');

    if (routePoints.isEmpty) {
      print('⚠️ No route points, cancelling sessions');
      _drivingSession?.cancel();
      _drivingRoutes = [];
      return;
    }

    if (routePoints.length < 2) {
      print('⚠️ Need at least 2 points for routing, currently have: ${routePoints.length}');
      return;
    }

    print('✅ Have ${routePoints.length} points, building driving route...');
    
    // ✅ Исключаем запрещенные КПП (но не добавляем автоматически новые точки)
    final modifiedRoutePoints = _excludeForbiddenCheckpoints(routePoints);
    
    // Проверяем, что после фильтрации осталось минимум 2 точки
    if (modifiedRoutePoints.length < 2) {
      print('⚠️ После исключения запрещённых КПП осталось меньше 2 точек (${modifiedRoutePoints.length})');
      print('❌ Невозможно построить маршрут. Выберите другие точки, не попадающие в запрещённые зоны.');
      
      // Показываем предупреждение пользователю через Cupertino диалог
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('⚠️ Запрещённая зона'),
            content: const Text('Выбранная точка находится в запрещённой зоне (КПП). Выберите другую точку.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 🛣️ ПРИНУДИТЕЛЬНОЕ ДОБАВЛЕНИЕ КПП УСПЕНКА для маршрутов из Донецка в Ростов
    final fromCity = _textFieldControllerFrom.text.trim();
    final toCity = _textFieldControllerTo.text.trim();
    final routeWithCheckpoints = _addUspenkaCheckpointIfNeeded(modifiedRoutePoints, fromCity, toCity);
    
    // 🛣️ ПРИНУДИТЕЛЬНОЕ ДОБАВЛЕНИЕ ПРОМЕЖУТОЧНЫХ ГОРОДОВ для маршрута Донецк-Луганск
    final finalRoutePoints = _addLuhanskWaypointsIfNeeded(routeWithCheckpoints);
    
    // Блокировка КПП убрана - строим маршруты без ограничений
    
    // NOTE: historically we used Waypoint for all intermediate mandatory
    // checkpoints to force the router to pass exactly through these points.
    // A recent change used Viapoint for intermediates which let the
    // routing engine select nearby roads and resulted in unexpected paths.
    // Revert to Waypoint for intermediates to restore previous, correct
    // routing behavior (user expectation: exact passage through КПП).
    final requestPoints = [
      mapkit.RequestPoint(finalRoutePoints.first, mapkit.RequestPointType.Waypoint, null, null, null),
      ...(finalRoutePoints.sublist(1, finalRoutePoints.length - 1).map(
          (it) => mapkit.RequestPoint(it, mapkit.RequestPointType.Waypoint, null, null, null))),
      mapkit.RequestPoint(finalRoutePoints.last, mapkit.RequestPointType.Waypoint, null, null, null)
    ];

    print('🚗 Requesting driving route with ${requestPoints.length} request points');
    _requestDrivingRoutes(requestPoints);
  }

  // Routing request methods from map_routing (lines 538-576)
  void _requestDrivingRoutes(List<mapkit.RequestPoint> points) {
    print('🚗🚗 _requestDrivingRoutes called with ${points.length} points');
    
    // 🔍 ПОДРОБНЫЙ ЛОГ ВСЕХ ТОЧЕК ЗАПРОСА
    print('📍📍📍 ДЕТАЛЬНЫЙ ЛОГ ТОЧЕК ЗАПРОСА:');
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final typeStr = point.type == mapkit.RequestPointType.Waypoint ? 'Waypoint' : 'Viapoint';
      print('   [$i] $typeStr → ${point.point.latitude}, ${point.point.longitude}');
    }
    print('📍📍📍 КОНЕЦ ЛОГА ТОЧЕК');
    
    print('🎧 Listener: ${_drivingRouteListener.hashCode}');
    
    // Используем стандартные настройки маршрутизации с максимальной точностью
    // 🚫 NOTE: Yandex MapKit в данной версии не поддерживает avoidAreas
    // Вместо этого полагаемся на точные waypoint'ы и фильтрацию результатов
    const drivingOptions = DrivingOptions(
      routesCount: 1, // Только один маршрут для точного прохождения
    );
    
    const vehicleOptions = DrivingVehicleOptions();

    _drivingSession = _drivingRouter.requestRoutes(
      drivingOptions,
      vehicleOptions,
      _drivingRouteListener,
      points: points,
    );
    print('✅ requestRoutes() call completed, session: ${_drivingSession.hashCode}');
  }

  // REMOVED: _requestPedestrianRoutes and _requestPublicTransportRoutes - taxi app only needs driving routes

  // Test method with known working coordinates - ОТКЛЮЧЕН, перенесен в меню
  // void _testRouteWithKnownPoints() {
  //   print('🧪 Testing route with known Moscow points...');
  //   
  //   // Clear existing routes first
  //   _clearRoutes();
  //   
  //   // Red Square to Gorky Park (guaranteed to be on road network)
  //   final fromPoint = Point(latitude: 55.753544, longitude: 37.621202); // Red Square
  //   final toPoint = Point(latitude: 55.731093, longitude: 37.601374);   // Gorky Park
  //   
  //   print('🧪 Setting FROM point: Red Square');
  //   _routePointsManager.setPoint(RoutePointType.from, fromPoint);
  //   
  //   print('🧪 Setting TO point: Gorky Park');
  //   _routePointsManager.setPoint(RoutePointType.to, toPoint);
  //   
  //   setState(() {
  //     _selectedPointType = RoutePointType.to;
  //     _isPointSelectionEnabled = false;
  //     _routeCompleted = true;
  //   });
  //   
  //   print('✅ Test points set, route should be requested automatically');
  // }

  // Clear routes method - resets all routing state - ОТКЛЮЧЕН, заменен полным сбросом
  // void _clearRoutes() {
  //   print('🧹 Clearing all routes...');
  //   print('📝 BEFORE clearing - FROM field: "${_textFieldControllerFrom.text}"');
  //   print('📝 BEFORE clearing - TO field: "${_textFieldControllerTo.text}"');
  //   print('🔍 BEFORE clearing - Active field: $_activeField');
  //   print('📌 BEFORE clearing - Last search field type: $_lastSearchFieldType');
  //   
  //   // Cancel any active sessions
  //   _drivingSession?.cancel();
  //   
  //   // Clear route collections
  //   setState(() {
  //     _drivingRoutes = [];
  //     _routesCollection.clear();
  //     
  //     // Reset point selection state
  //     _selectedPointType = RoutePointType.from;
  //     _isPointSelectionEnabled = true;
  //     _routeCompleted = false;
  //     
  //     // 🆕 КРИТИЧНО: Сбрасываем сохраненный тип поля для поиска
  //     _lastSearchFieldType = null;
  //     
  //     // 🆕 Сбрасываем активное поле
  //     _activeField = ActiveField.none;
  //     
  //     // Clear points from RoutePointsManager
  //     _routePointsManager.clearAllPoints();
  //   });
  //   
  //   // 🆕 Принудительно очищаем текстовые поля
  //   _textFieldControllerFrom.clear();
  //   _textFieldControllerTo.clear();
  //   
  //   // 🆕 Дополнительная проверка очистки
  //   Future.delayed(Duration.zero, () {
  //     if (_textFieldControllerFrom.text.isNotEmpty) {
  //       _textFieldControllerFrom.text = '';
  //       print('🔧 Force cleared FROM field');
  //     }
  //     if (_textFieldControllerTo.text.isNotEmpty) {
  //       _textFieldControllerTo.text = '';
  //       print('🔧 Force cleared TO field');
  //     }
  //   });
  //   
  //   print('✅ Routes cleared, ready for new selection');
  //   print('🔄 Search field type reset to null');
  //   print('🔄 Active field reset to none');
  // }

  // Принудительный сброс всех полей и состояния
  void _forceResetAllFields() {
    print('🔥 FORCE RESET - Resetting all fields and state...');
    
    // 🆕 Останавливаем все активные поисковые операции
    print('🛑 Stopping all search operations...');
    _mapManager.reset(); // Полный сброс поисковой системы
    _searchResultPlacemarksCollection.clear(); // Очистка результатов поиска
    
    setState(() {
      // Создаем новые контроллеры
      _textFieldControllerFrom.dispose();
      _textFieldControllerTo.dispose();
      _textFieldControllerFrom = TextEditingController();
      _textFieldControllerTo = TextEditingController();
      
      // Сбрасываем все состояние
      _activeField = ActiveField.none;
      _lastSearchFieldType = null;
      _selectedPointType = RoutePointType.from;
      _isPointSelectionEnabled = true;
      _routeCompleted = false;
      
      // 🆕 Закрываем окно стоимости (чтобы не мешало при построении нового маршрута)
      _calculation = null;
      _distanceKm = null;
      
      // Очищаем маршруты
      _drivingRoutes = [];
      _routesCollection.clear();
      
      // Очищаем точки с тройным сбросом
      _routePointsManager.forceTripleClear();
    });
    
    print('🔥 FORCE RESET - All fields and state reset');
    print('📝 AFTER FORCE RESET - FROM field: "${_textFieldControllerFrom.text}"');
    print('📝 AFTER FORCE RESET - TO field: "${_textFieldControllerTo.text}"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ 1. КАРТА НА ВЕСЬ ЭКРАН (базовый слой)
          FlutterMapWidget(
            onMapCreated: _setupMap,
            onMapDispose: () {
              _mapWindow
                  ?.removeSizeChangedListener(_mapWindowSizeChangedListener);
              _mapWindow?.map.removeCameraListener(_cameraListener);
              _mapSearchSubscription?.cancel();
              _searchSubscription?.cancel();
              _suggestSubscription?.cancel();
            },
          ),
          
          // 🔍 2. ПАНЕЛЬ ПОИСКА "ОТКУДА/КУДА" (поверх карты)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: StreamBuilder<MapSearchState>(
                stream: _mapManager.mapSearchState,
                builder: (context, snapshot) {
              final mapSearchState = snapshot.data;
              final suggestState = mapSearchState?.suggestState;
              final suggestions = suggestState is SuggestSuccess ? suggestState.suggestItems : <SuggestItem>[];
              
              print('🔍 [UI_STREAM] StreamBuilder rebuild: activeField=$_activeField, suggestions=${suggestions.length}, suggestState=${suggestState.runtimeType}');
              if (suggestions.isNotEmpty) {
                print('   📋 First 3 suggestions:');
                for (int i = 0; i < suggestions.length && i < 3; i++) {
                  print('      [${i+1}] ${suggestions[i].title.text}');
                }
              }

                  return SearchFieldsPanel(
                    key: _searchPanelKey,
                    fromController: _textFieldControllerFrom,
                    toController: _textFieldControllerTo,
                    fromSuggestions: _activeField == ActiveField.from ? suggestions : [],
                    toSuggestions: _activeField == ActiveField.to ? suggestions : [],
                    isFromFieldActive: _activeField == ActiveField.from,
                    isToFieldActive: _activeField == ActiveField.to,
                    showFromSuggestions: _activeField == ActiveField.from && suggestions.isNotEmpty,
                    showToSuggestions: _activeField == ActiveField.to && suggestions.isNotEmpty,
                    fromFlagButtonKey: _fromFlagButtonKey, // 🆕 GlobalKey для tutorial
                    toFlagButtonKey: _toFlagButtonKey,     // 🆕 GlobalKey для tutorial
                    onFromFieldTapped: () {
                      setState(() {
                        _activeField = ActiveField.from;
                        // 🆕 Обновляем тип поля для последующих поисков
                        _lastSearchFieldType = RoutePointType.from;
                      });
                      print('🔍 FROM field activated, search type set to FROM');
                      print('📝 Current FROM field text: "${_textFieldControllerFrom.text}"');
                      print('📝 Current TO field text: "${_textFieldControllerTo.text}"');
                    },
                    onToFieldTapped: () {
                      setState(() {
                        _activeField = ActiveField.to;
                        // 🆕 Обновляем тип поля для последующих поисков
                        _lastSearchFieldType = RoutePointType.to;
                      });
                      print('🔍 TO field activated, search type set to TO');
                      print('📝 Current FROM field text: "${_textFieldControllerFrom.text}"');
                      print('📝 Current TO field text: "${_textFieldControllerTo.text}"');
                    },
                    onFromTextChanged: (text) {
                      // Игнорируем изменения при программной установке текста
                      if (_isSettingTextProgrammatically) return;
                      
                      if (_activeField == ActiveField.from) {
                        // 🆕 Убеждаемся что тип поля правильный при вводе текста
                        _lastSearchFieldType = RoutePointType.from;
                        _mapManager.setQueryText(text);
                      }
                    },
                    onToTextChanged: (text) {
                      // Игнорируем изменения при программной установке текста
                      if (_isSettingTextProgrammatically) return;
                      
                      if (_activeField == ActiveField.to) {
                        // 🆕 Убеждаемся что тип поля правильный при вводе текста
                        _lastSearchFieldType = RoutePointType.to;
                        _mapManager.setQueryText(text);
                      }
                    },
                    // 🆕 Обработчики для кнопки "Найти" на клавиатуре
                    onFromSubmitted: (text) {
                      print('⌨️ FROM field submitted with text: "$text"');
                      if (text.isNotEmpty) {
                        _lastSearchFieldType = RoutePointType.from;
                        _waitingForSuggestionResult = true;  // Ждем результат поиска
                        print('🔍 Starting search via keyboard for FROM: $text');
                        _mapManager.startSearch(text);
                      }
                    },
                    onToSubmitted: (text) {
                      print('⌨️ TO field submitted with text: "$text"');
                      if (text.isNotEmpty) {
                        _lastSearchFieldType = RoutePointType.to;
                        _waitingForSuggestionResult = true;  // Ждем результат поиска
                        print('🔍 Starting search via keyboard for TO: $text');
                        _mapManager.startSearch(text);
                      }
                    },
                    onFromSuggestionSelected: (suggestion) {
                      print('📍 Selected FROM suggestion: ${suggestion.displayText}');
                      print('🔧 Setting FROM controller text to: ${suggestion.displayText}');
                      
                      // Запоминаем что это FROM поле перед поиском
                      _lastSearchFieldType = RoutePointType.from;
                      _waitingForSuggestionResult = true; // Ждем результат выбора из саджеста
                      
                      setState(() {
                        // Устанавливаем флаг перед программной установкой текста
                        _isSettingTextProgrammatically = true;
                        _textFieldControllerFrom.text = suggestion.displayText; // ✅ Красивое название
                        _isSettingTextProgrammatically = false;
                        _activeField = ActiveField.none;
                      });
                      print('✅ FROM controller text is now: ${_textFieldControllerFrom.text}');
                      
                      // Запускаем поиск - результат будет обработан через onAddressSelected callback
                      print('🔗 Starting search for FROM address using searchText: ${suggestion.searchText}');
                      _mapManager.startSearch(suggestion.searchText); // ✅ Поиск по JSON
                    },
                    onToSuggestionSelected: (suggestion) {
                      print('📍 Selected TO suggestion: ${suggestion.displayText}');
                      print('🔧 Setting TO controller text to: ${suggestion.displayText}');
                      
                      // Запоминаем что это TO поле перед поиском
                      _lastSearchFieldType = RoutePointType.to;
                      _waitingForSuggestionResult = true; // Ждем результат выбора из саджеста
                      
                      setState(() {
                        // Устанавливаем флаг перед программной установкой текста
                        _isSettingTextProgrammatically = true;
                        _textFieldControllerTo.text = suggestion.displayText; // ✅ Красивое название
                        _isSettingTextProgrammatically = false;
                        _activeField = ActiveField.none;
                      });
                      print('✅ TO controller text is now: ${_textFieldControllerTo.text}');
                      
                      // Запускаем поиск - результат будет обработан через onAddressSelected callback
                      print('🔗 Starting search for TO address using searchText: ${suggestion.searchText}');
                      _mapManager.startSearch(suggestion.searchText); // ✅ Поиск по JSON
                    },
                    // Новые callback'и для кнопок карты
                    onFromMapButtonTapped: () {
                      print('🗺️ FROM map button tapped - enabling point selection');
                      setState(() {
                        _selectedPointType = RoutePointType.from;
                        _isPointSelectionEnabled = true;
                        _activeField = ActiveField.none; // Закрываем поиск
                      });
                      print("📱 Выберите точку ОТКУДА на карте 🟢");
                    },
                    onToMapButtonTapped: () {
                      print('🗺️ TO map button tapped - enabling point selection');
                      setState(() {
                        _selectedPointType = RoutePointType.to;
                        _isPointSelectionEnabled = true;
                        _activeField = ActiveField.none; // Закрываем поиск
                      });
                      print("📱 Выберите точку КУДА на карте 🔴");
                    },
                  );
                },
              ),
            ),
          ),
          
          // 🗑️ 3. КНОПКА СБРОСА МАРШРУТА (под панелью поиска)
          Positioned(
            top: 140,
            left: 12,
            right: 16,
            child: Row(
              children: [
                  // Кнопка "корзины"
                  FloatingActionButton(
                    key: _clearButtonKey, // 🆕 GlobalKey для tutorial
                    heroTag: "reset_route_button",
                    mini: true,
                    backgroundColor: CupertinoColors.white,
                    onPressed: () async {
                      // Показываем анимированный текст
                      setState(() {
                        _showDeleteMessage = true;
                      });
                      
                      // Выполняем оба сброса сразу
                      _forceResetAllFields();
                      _routePointsManager.forceTripleClear();
                      print("🔥 Все поля и маршруты сброшены");
                      
                      // Скрываем текст через 2 секунды
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) {
                        setState(() {
                          _showDeleteMessage = false;
                        });
                      }
                    },
                    child: const Icon(
                      Icons.delete_outline,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                  
                  // 📝 Анимированный текст справа от кнопки
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _showDeleteMessage ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _showDeleteMessage
                          ? Container(
                              margin: const EdgeInsets.only(left: 12),
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemGrey.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Все поля и маршруты сброшены',
                                  style: TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          
          // 💰 4. ПАНЕЛЬ С ЦЕНОЙ И РАССТОЯНИЕМ (внизу экрана)
          if (_calculation != null && _distanceKm != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90, // Над кнопкой геолокации
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Расстояние и Цена
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Расстояние
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Расстояние',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_distanceKm!.toStringAsFixed(1)} км',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Цена
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Стоимость',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_calculation!.finalPrice.toInt()} ₽',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 🆕 Кнопка "Заказать"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: _orderButtonKey,
                        onPressed: _onOrderButtonPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CupertinoColors.systemRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Заказать такси',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          

          
          // 🔍 6. КНОПКИ МАСШТАБИРОВАНИЯ (правая сторона, по центру)
          Positioned(
            top: 0,
            bottom: 0,
            right: 16,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: "zoom_in",
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _zoomIn,
                    child: const Icon(
                      Icons.add,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: "zoom_out",
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _zoomOut,
                    child: const Icon(
                      Icons.remove,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    key: _geolocationButtonKey,
                    heroTag: "geolocation",
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _moveToUserLocation,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🎓 7. TUTORIAL OVERLAY (если активен)
          if (_showTutorial)
            TutorialOverlay(
              steps: _getTutorialSteps(),
              onComplete: _completeTutorial,
              onSkip: _skipTutorial,
            ),
        ],
      ),
    );
  }

  Future<void> _setupMap(mapkit.MapWindow mapWindow) async {
    print('🗺️ Map widget created, initializing...');
    _mapWindow = mapWindow;
    _searchResultPlacemarksCollection =
        mapWindow.map.mapObjects.addCollection();

    print('🔧 Creating route points collection...');
    // Инициализируем RoutePointsManager с отдельной коллекцией для точек маршрута
    final routePointsCollection = mapWindow.map.mapObjects.addCollection();
    
    // Create routes collection for drawing routes (from map_routing)
    _routesCollection = mapWindow.map.mapObjects.addCollection();
    
    // Create user location collection for user location marker
    _userLocationCollection = mapWindow.map.mapObjects.addCollection();
    
    print('🔧 Route points collection created, initializing RoutePointsManager...');
    _routePointsManager = RoutePointsManager(
      mapObjects: routePointsCollection,
      onPointsChanged: (points) {
        print('📍 Route points changed: ${points.length} points');
        // Trigger route building when points change
        _onRouteParametersUpdated();
      },
    );
    // Инициализируем иконки
    await _routePointsManager.init();
    print('✅ RoutePointsManager initialized');

    // 🚫 ВРЕМЕННО ОТКЛЮЧЕНО для тестирования точности тапов
    // SearchRoutingIntegration может смещать координаты точек
    print('🔗 SearchRoutingIntegration DISABLED for accurate tap testing');
    
    // _integration = SearchRoutingIntegration(
    //   searchManager: _mapManager,
    //   routeManager: _routePointsManager,
    // );
    
    // _integration?.setFieldControllers(
    //   fromController: _textFieldControllerFrom,
    //   toController: _textFieldControllerTo,
    // );
    
    _mapManager.onAddressSelected = (point, address) {
      print('🎯 Address selected from search: $address at ${point.latitude}, ${point.longitude}');
      print('🔧 Last search field type: $_lastSearchFieldType');
      print('🔧 Waiting for suggestion result: $_waitingForSuggestionResult');
      
      // Обрабатываем результат только если ждем результат от саджеста
      if (_waitingForSuggestionResult) {
        _waitingForSuggestionResult = false; // Сбрасываем флаг
        
        // Устанавливаем точку на карте в зависимости от типа поля
        if (_lastSearchFieldType == RoutePointType.from) {
          print('🔧 Setting FROM point from search result');
          _routePointsManager.setPoint(RoutePointType.from, point);
        } else if (_lastSearchFieldType == RoutePointType.to) {
          print('🔧 Setting TO point from search result');
          _routePointsManager.setPoint(RoutePointType.to, point);
        }
        
        print('✅ Point set from search result successfully!');
      } else {
        print('⚠️ Ignoring search result - not waiting for suggestion result');
      }
    };
    
    // _integration?.initialize();
    print('✅ SearchRoutingIntegration DISABLED - pure tap mode enabled');

    // Initialize geolocation components - временно отключено
    // _cameraManager = CameraManager(mapWindow, _locationManager)
    //   ..start();

    // _userLocationLayer = createUserLocationLayer(mapWindow)
    //   ..headingModeActive = true
    //   ..setVisible(true)
    //   ..setObjectListener(this);

    print('✅ Geolocation components will be initialized');

    // Initialize routers from map_routing (lines 436-441)
    _drivingRouter = DirectionsFactory.instance
        .createDrivingRouter(DrivingRouterType.Combined);
    print('✅ Driving router initialized (taxi app only uses driving routes)');

    print('🎯 Adding MapInputListener to map...');
    mapWindow.map.addInputListener(_inputListener);
    print('✅ MapInputListener added successfully!');

    mapWindow.addSizeChangedListener(_mapWindowSizeChangedListener);

    print('✅ Map initialized! Setting initial camera position...');
    
    // Сначала добавляем слушатель камеры
    mapWindow.map.addCameraListener(_cameraListener);
    
    // Пытаемся получить геолокацию пользователя для начального положения
    await _initializeUserLocation(mapWindow);

    print('📡 Subscribing to search and suggest streams...');
    _mapSearchSubscription = _mapManager.mapSearchState.listen((uiState) {
      if (uiState.suggestState is SuggestError) {
        print("📱 Ошибка предложений, проверьте подключение к интернету");
      }

      final searchState = uiState.searchState;

      if (searchState is SearchSuccess) {
        final searchItems = searchState.items;
        print('✅ Search response: ${searchItems.length} items');

        _updateSearchResponsePlacemarks(searchItems);

        // ❌ УДАЛЕНО: автоматическая установка точки из результатов поиска
        // Теперь точка устанавливается ТОЛЬКО через onAddressSelected callback
        // который вызывается в MapSearchManager после успешного поиска
        
        // Старый код (УДАЛЁН, так как дублировал onAddressSelected):
        // if (_waitingForSuggestionResult && searchItems.isNotEmpty && _lastSearchFieldType != null && _isPointSelectionEnabled) {
        //   final firstItem = searchItems.first;
        //   _routePointsManager.setPoint(_lastSearchFieldType!, firstItem.point);
        //   ... переключение типа точки ...
        //   _waitingForSuggestionResult = false;
        //   _searchResultPlacemarksCollection.clear();
        // }
        
        // Показываем результаты поиска на карте
        if (searchState.shouldZoomToItems) {
          _focusCamera(
            searchItems.map((it) => it.point),
            searchState.itemsBoundingBox,
          );
        }
      } else if (searchState is SearchOff) {
        _searchResultPlacemarksCollection.clear();
      } else if (searchState is SearchError) {
        print("📱 Ошибка поиска, проверьте подключение к интернету");
      }
    });

    _searchSubscription = _mapManager.subscribeForSearch().listen((_) {});
    _suggestSubscription = _mapManager.subscribeForSuggest().listen((_) {});
    print('✅ Map initialization completed, search manager initialized');
  }

  void _updateFocusRect() {
    // Временно отключено из-за краша при повороте экрана
    print('🔧 _updateFocusRect() temporarily disabled to prevent crash');
    return;
  }

  void _updateSearchResponsePlacemarks(List<SearchResponseItem> items) {
    _mapWindow?.map.let((map) {
      _searchResultPlacemarksCollection.clear();

      items.forEach((item) {
        _searchResultPlacemarksCollection.addPlacemark()
          ..geometry = item.point
          ..setIcon(_searchResultImageProvider)
          ..setIconStyle(const mapkit.IconStyle(scale: 1.5))
          ..addTapListener(_searchResultPlacemarkTapListener);
      });
    });
  }

  void _focusCamera(Iterable<mapkit.Point> points, mapkit.BoundingBox boundingBox) {
    if (points.isEmpty) {
      return;
    }

    _mapWindow?.map.let((map) {
      final cameraPosition = points.length == 1
          ? mapkit.CameraPosition(
              points.first,
              zoom: map.cameraPosition.zoom,
              azimuth: map.cameraPosition.azimuth,
              tilt: map.cameraPosition.tilt,
            )
          : map
              .cameraPositionForGeometry(mapkit.Geometry.fromBoundingBox(boundingBox));

      map.moveWithAnimation(
        cameraPosition,
        CameraAnimationProvider.defaultCameraAnimation,
      );
    });
  }

  // Обработчик изменения типа выбранной точки - ОТКЛЮЧЕН, используем кнопки в полях
  // void _onPointTypeChanged(RoutePointType type) {
  //   setState(() {
  //     _selectedPointType = type;
  //   });
  //   print('🎯 Выбран тип точки: $type');
  // }

  // Показать меню с опциями сброса

  // Метод для перемещения к местоположению пользователя
  Future<void> _moveToUserLocation() async {
    try {
      print('🔍 Геолокация: Получение местоположения пользователя...');
      
      // Проверяем разрешения на геолокацию
      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
        if (permission == geolocator.LocationPermission.denied) {
          print('❌ Геолокация: Разрешение отклонено');
          print('📱 Необходимо разрешение на использование геолокации');
          return;
        }
      }

      if (permission == geolocator.LocationPermission.deniedForever) {
        print('❌ Геолокация: Разрешение отклонено навсегда');
        print('📱 Разрешение на геолокацию заблокировано. Включите в настройках.');
        return;
      }

      // Получаем текущее местоположение
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );

      print('📍 Геолокация: Получены координаты ${position.latitude}, ${position.longitude}');

      // Проверяем валидность координат
      if (position.latitude < -90 || position.latitude > 90 || 
          position.longitude < -180 || position.longitude > 180) {
        print('❌ Некорректные координаты: ${position.latitude}, ${position.longitude}');
        print('📱 Получены некорректные координаты');
        return;
      }

      // 📍 КЛЮЧЕВОЙ МОМЕНТ: Устанавливаем позицию пользователя для приоритета саджестов
      final point = Point(latitude: position.latitude, longitude: position.longitude);
      print('🔥🔥🔥 CALLING setUserPosition from _moveToUserLocation');
      print('   Position: ${position.latitude}, ${position.longitude}');
      print('   MapManager: $_mapManager');
      _mapManager.setUserPosition(point);
      print('✅ GPS-позиция установлена в MapSearchManager для приоритета саджестов');

      // Перемещаем камеру к местоположению пользователя
      try {
        final newCameraPosition = CameraPosition(
          point, 
          zoom: 15.0,
          azimuth: 0.0,
          tilt: 0.0,
        );

        print('📍 Перемещение камеры к точке: ${point.latitude}, ${point.longitude}');
        
        if (_mapWindow?.map != null) {
          _mapWindow!.map.moveWithAnimation(
            newCameraPosition,
            const mapkit.Animation(mapkit.AnimationType.Smooth, duration: 1.0),
          );
          
          // Добавляем маркер пользователя на карту
          await _addUserLocationMarker(point);
          
          print('✅ Камера перемещена успешно');
          print('📱 Перемещено к вашему местоположению');
        } else {
          print('❌ MapWindow не инициализирован');
          print('📱 Карта не готова');
        }
      } catch (cameraError) {
        print('❌ Ошибка перемещения камеры: $cameraError');
        // showSnackBar не работает с CupertinoApp
      }
      
    } catch (e) {
      print('❌ Ошибка геолокации: $e');
      // showSnackBar не работает с CupertinoApp
    }
  }

  // Методы для управления зумом карты
  void _zoomIn() {
    if (_mapWindow != null) {
      final map = _mapWindow!.map;
      final currentPosition = map.cameraPosition;
      
      final newCameraPosition = mapkit.CameraPosition(
        currentPosition.target,
        zoom: currentPosition.zoom + 1.0,
        azimuth: currentPosition.azimuth,
        tilt: currentPosition.tilt,
      );

      map.moveWithAnimation(
        newCameraPosition,
        const mapkit.Animation(mapkit.AnimationType.Smooth, duration: 0.3),
      );
      
      print('🔍 Zoom IN: ${currentPosition.zoom} -> ${newCameraPosition.zoom}');
    }
  }

  void _zoomOut() {
    if (_mapWindow != null) {
      final map = _mapWindow!.map;
      final currentPosition = map.cameraPosition;
      
      final newZoom = (currentPosition.zoom - 1.0).clamp(1.0, 23.0);
      final newCameraPosition = mapkit.CameraPosition(
        currentPosition.target,
        zoom: newZoom,
        azimuth: currentPosition.azimuth,
        tilt: currentPosition.tilt,
      );

      map.moveWithAnimation(
        newCameraPosition,
        const mapkit.Animation(mapkit.AnimationType.Smooth, duration: 0.3),
      );
      
      print('🔍 Zoom OUT: ${currentPosition.zoom} -> ${newCameraPosition.zoom}');
    }
  }

  // Метод для добавления маркера местоположения пользователя
  Future<void> _addUserLocationMarker(Point point) async {
    try {
      print('📍 Добавление маркера пользователя на точку: ${point.latitude}, ${point.longitude}');
      
      // Удаляем предыдущий маркер, если он есть
      if (_userLocationPlacemark != null) {
        _userLocationCollection.remove(_userLocationPlacemark!);
        _userLocationPlacemark = null;
      }
      
      // Создаем иконку для маркера пользователя (выбранная пользователем иконка)
      final userLocationIcon = image_provider.ImageProvider.fromImageProvider(
        const AssetImage("assets/png-location.png")
      );
      
      // Добавляем новый маркер
      _userLocationPlacemark = _userLocationCollection.addPlacemark()
        ..geometry = point
        ..setIcon(userLocationIcon)
        ..setIconStyle(const mapkit.IconStyle(scale: 0.75)); // Уменьшаем размер в 2 раза
      
      print('✅ Маркер пользователя добавлен успешно');
    } catch (e) {
      print('❌ Ошибка добавления маркера пользователя: $e');
    }
  }

  // Метод для инициализации пользовательского местоположения при запуске
  Future<void> _initializeUserLocation(mapkit.MapWindow mapWindow) async {
    print('🌍 Инициализация геолокации при запуске...');
    
    try {
      // Проверяем разрешения на геолокацию
      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
      
      if (permission == geolocator.LocationPermission.denied) {
        // Не запрашиваем разрешения сразу, используем fallback
        print('⚠️ Разрешение на геолокацию не предоставлено, использую Москву как fallback');
        _setFallbackLocation(mapWindow);
        // Автоматически запускаем геолокацию через 2 секунды
        Future.delayed(const Duration(seconds: 2), () {
          print('🎯 Автоматический запуск геолокации через 2 секунды...');
          _moveToUserLocation();
        });
        return;
      }

      if (permission == geolocator.LocationPermission.deniedForever) {
        print('⚠️ Разрешение на геолокацию заблокировано навсегда, использую Москву как fallback');
        _setFallbackLocation(mapWindow);
        return;
      }

      // Пытаемся получить текущее местоположение с таймаутом
      print('📍 Получение текущего местоположения...');
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10), // Таймаут 10 секунд
      );

      print('✅ Получено местоположение: ${position.latitude}, ${position.longitude}');

      // Проверяем валидность координат
      if (position.latitude < -90 || position.latitude > 90 || 
          position.longitude < -180 || position.longitude > 180) {
        print('❌ Некорректные координаты, использую fallback');
        _setFallbackLocation(mapWindow);
        return;
      }

      // Устанавливаем позицию пользователя
      final userPoint = Point(latitude: position.latitude, longitude: position.longitude);
      
      // 📍 КЛЮЧЕВОЙ МОМЕНТ: Устанавливаем GPS-позицию в MapSearchManager для приоритета саджестов
      print('🔥🔥🔥 CALLING setUserPosition from _initializeUserLocation');
      print('   Position: ${position.latitude}, ${position.longitude}');
      print('   MapManager: $_mapManager');
      _mapManager.setUserPosition(userPoint);
      print('✅ GPS-позиция установлена в MapSearchManager при инициализации');
      
      final userCameraPosition = CameraPosition(
        userPoint, 
        zoom: 13.0,
        azimuth: 0.0,
        tilt: 0.0,
      );

      mapWindow.map.move(userCameraPosition);
      
      // Добавляем маркер пользователя
      await _addUserLocationMarker(userPoint);
      
      // Обновляем видимую область для поиска
      _mapManager.setVisibleRegion(mapWindow.map.visibleRegion);
      
      print('✅ Карта инициализирована на местоположении пользователя');
      
    } catch (e) {
      print('❌ Ошибка получения геолокации при запуске: $e');
      _setFallbackLocation(mapWindow);
      // Автоматически запускаем геолокацию через 2 секунды даже при ошибке
      Future.delayed(const Duration(seconds: 2), () {
        print('🎯 Автоматический запуск геолокации после ошибки через 2 секунды...');
        _moveToUserLocation();
      });
    }
  }

  // Установка fallback позиции (Москва)
  void _setFallbackLocation(mapkit.MapWindow mapWindow) {
    print('🗺️ Установка fallback позиции (Москва)');
    
    const fallbackPosition = CameraPosition(
      Point(latitude: 55.753284, longitude: 37.622034),
      zoom: 10.0,
      azimuth: 0.0,
      tilt: 0.0,
    );
    
    mapWindow.map.move(fallbackPosition);
    _mapManager.setVisibleRegion(mapWindow.map.visibleRegion);
    
    print('✅ Fallback позиция установлена');
  }



  /// 🚫 Исключает запрещённые КПП из маршрута
  /// КПП Куйбышевский и другие запрещённые КПП для грузового транспорта
  /// + Запрещенные города для маршрута Донецк-Луганск
  List<Point> _excludeForbiddenCheckpoints(List<Point> routePoints) {
    print('🔍 Проверяем ${routePoints.length} точек на предмет запрещённых КПП');

    const double exclusionRadius = 0.05; // 5км радиус исключения (увеличен для большей надежности)

    // Запрещённые КПП и населенные пункты с их координатами
    const kuybyshevskiyLat = 47.337126;
    const kuybyshevskiyLng = 39.944856;
    const kalinovayaLat = 47.740000;
    const kalinovayaLng = 38.820000;
    
    // ❌ СТАРАЯ НЕРАБОЧАЯ КПП УСПЕНКА (закрыта, шлагбаум, тупик) - ЗАПРЕЩЕНА!
    const oldUspenkaLat = 47.697816;
    const oldUspenkaLng = 38.666213;

    // 🚫 КРИТИЧЕСКИ ОПАСНАЯ ЗОНА - ЗАПРЕЩЕН ПРОЕЗД!
    const dangerousZoneLat = 47.908989;
    const dangerousZoneLng = 38.943275;
    
    // 🚫 ЗАПРЕЩЕННЫЕ ГОРОДА ДЛЯ МАРШРУТА ДОНЕЦК-ЛУГАНСК
    // Ясиноватая - не ездим
    const yasinovatayaLat = 48.137611;
    const yasinovatayaLng = 38.056556;
    
    // Пантелемоновка - не ездим
    const pantelemonivkaLat = 48.270833;
    const pantelemonivkaLng = 38.416667;
    
    List<Point> cleanedPoints = [];
    int excludedCount = 0;

    for (final point in routePoints) {
      bool shouldExclude = false;

      // Проверяем КПП Куйбышевский
      double latDiff = (point.latitude - kuybyshevskiyLat).abs();
      double lngDiff = (point.longitude - kuybyshevskiyLng).abs();
      if (latDiff < exclusionRadius && lngDiff < exclusionRadius) {
        print('🚫 Исключаем точку рядом с КПП Куйбышевский: ${point.latitude}, ${point.longitude}');
        shouldExclude = true;
      }
      
      // Проверяем село Калиновая
      if (!shouldExclude) {
        latDiff = (point.latitude - kalinovayaLat).abs();
        lngDiff = (point.longitude - kalinovayaLng).abs();
        if (latDiff < exclusionRadius && lngDiff < exclusionRadius) {
          print('🚫 Исключаем точку рядом с село Калиновая: ${point.latitude}, ${point.longitude}');
          shouldExclude = true;
        }
      }
      
      // Проверяем старую нерабочую КПП Успенка (закрыта, шлагбаум) - ТОЧЕЧНАЯ ПРОВЕРКА
      if (!shouldExclude) {
        // Сначала проверяем, не находится ли точка рядом с РАБОЧЕЙ КПП Авило-Успенка
        const workingKppLat = 47.698500;
        const workingKppLng = 38.678000;
        double workingLatDiff = (point.latitude - workingKppLat).abs();
        double workingLngDiff = (point.longitude - workingKppLng).abs();
        
        // Если точка рядом с рабочей КПП - НЕ исключаем её
        bool isNearWorkingKpp = (workingLatDiff < 0.01 && workingLngDiff < 0.01); // 1км радиус
        
        if (!isNearWorkingKpp) {
          latDiff = (point.latitude - oldUspenkaLat).abs();
          lngDiff = (point.longitude - oldUspenkaLng).abs();
          // Уменьшаем радиус для старой КПП, чтобы не захватывать рабочую
          if (latDiff < (exclusionRadius * 0.5) && lngDiff < (exclusionRadius * 0.5)) {
            print('🚫 ⚠️ КРИТИЧНО! Исключаем точку рядом со СТАРОЙ КПП Успенка (47.697816, 38.666213 - ЗАКРЫТА!): ${point.latitude}, ${point.longitude}');
            shouldExclude = true;
          }
        } else {
          print('✅ Точка рядом с РАБОЧЕЙ КПП Авило-Успенка - НЕ исключаем: ${point.latitude}, ${point.longitude}');
        }
      }
      
      // 🚨 Проверяем КРИТИЧЕСКИ ОПАСНУЮ ЗОНУ - ПОЛНЫЙ ЗАПРЕТ!
      if (!shouldExclude) {
        latDiff = (point.latitude - dangerousZoneLat).abs();
        lngDiff = (point.longitude - dangerousZoneLng).abs();
        if (latDiff < exclusionRadius && lngDiff < exclusionRadius) {
          print('🚨 КРИТИЧЕСКАЯ ОПАСНОСТЬ! Исключаем точку рядом с запрещенной зоной: ${point.latitude}, ${point.longitude}');
          shouldExclude = true;
        }
      }
      
      // 🚫 Проверяем Ясиноватую (запрещенный город для маршрута Донецк-Луганск)
      if (!shouldExclude) {
        latDiff = (point.latitude - yasinovatayaLat).abs();
        lngDiff = (point.longitude - yasinovatayaLng).abs();
        if (latDiff < exclusionRadius && lngDiff < exclusionRadius) {
          print('🚫 Исключаем точку в Ясиноватой (запрещено для маршрута Донецк-Луганск): ${point.latitude}, ${point.longitude}');
          shouldExclude = true;
        }
      }
      
      // 🚫 Проверяем Пантелемоновку (запрещенный город для маршрута Донецк-Луганск)
      if (!shouldExclude) {
        latDiff = (point.latitude - pantelemonivkaLat).abs();
        lngDiff = (point.longitude - pantelemonivkaLng).abs();
        if (latDiff < exclusionRadius && lngDiff < exclusionRadius) {
          print('🚫 Исключаем точку в Пантелемоновке (запрещено для маршрута Донецк-Луганск): ${point.latitude}, ${point.longitude}');
          shouldExclude = true;
        }
      }
      
      if (!shouldExclude) {
        cleanedPoints.add(point);
      } else {
        excludedCount++;
      }
    }
    
    print('✅ Исключено $excludedCount точек из ${routePoints.length}. Осталось: ${cleanedPoints.length}');

    return cleanedPoints;
  }

  /// 🛣️ Автоматически добавляет промежуточные КПП для маршрутов связанных с Донецком
  /// Добавляет КПП Авелон-Успенка для поездок из Донецка в Россию или в Донецк из России
  List<Point> _addUspenkaCheckpointIfNeeded(List<Point> routePoints, String fromCity, String toCity) {
    // 🚫 ПРИОРИТЕТ 1: ПРОВЕРКА ЛОКАЛЬНЫХ МАРШРУТОВ
    if (trip_type.TripPricing.isLocalRoute(fromCity, toCity)) {
      print('🏠 [LOCAL] ЛОКАЛЬНЫЙ МАРШРУТ обнаружен: $fromCity → $toCity');
      print('🏠 [LOCAL] ❌ КПП Авелон-Успенка НЕ добавляется для локальных маршрутов');
      return routePoints; // Возвращаем исходный маршрут БЕЗ КПП
    }

    // 🚫 ПРИОРИТЕТ 2: ПРОВЕРКА ДОНЕЦК-РОСТОВ БЕЗ ХАРЦЫЗСКА
    if (trip_type.TripPricing.isDonetskRostovRoute(fromCity, toCity)) {
      final passesKhartsyzsk = _routePassesThroughKhartsyzsk(routePoints);
      if (!passesKhartsyzsk) {
        print('🚗 [DONETSK-ROSTOV] Прямой маршрут Донецк → Ростов БЕЗ Харцызска');
        print('🚗 [DONETSK-ROSTOV] ❌ КПП Авелон-Успенка НЕ добавляется (только через Харцызск)');
        return routePoints; // Возвращаем исходный маршрут БЕЗ КПП
      } else {
        print('🚗 [DONETSK-ROSTOV] Маршрут Донецк → Ростов ЧЕРЕЗ Харцызск');
        print('🚗 [DONETSK-ROSTOV] ✅ КПП Авелон-Успенка будет добавлено');
      }
    }

    if (routePoints.length < 2) {
      print('🛣️ [DEBUG] Недостаточно точек для анализа: ${routePoints.length}');
      return routePoints;
    }

    final startPoint = routePoints.first;
    final endPoint = routePoints.last;

    // Проверяем связь маршрута с Донецком (радиус 20км от центра)
    const donetskLat = 48.015884;
    const donetskLng = 37.80285;
    
    final startDistanceFromDonetsk = _calculateDistanceBetweenPoints(
      startPoint.latitude, startPoint.longitude,
      donetskLat, donetskLng,
    );

    final endDistanceFromDonetsk = _calculateDistanceBetweenPoints(
      endPoint.latitude, endPoint.longitude,
      donetskLat, donetskLng,
    );

    // Проверяем, что маршрут связан с Донецком (либо начинается из Донецка, либо заканчивается в Донецке)
    final isFromDonetsk = startDistanceFromDonetsk <= 20.0;
    final isToDonetsk = endDistanceFromDonetsk <= 20.0;

    if (!isFromDonetsk && !isToDonetsk) {
      print('🛣️ [DEBUG] Маршрут НЕ связан с Донецком: старт ${startDistanceFromDonetsk.toStringAsFixed(2)}км, финиш ${endDistanceFromDonetsk.toStringAsFixed(2)}км');
      return routePoints;
    }

    // Проверяем направление движения
    if (isFromDonetsk) {
      // Маршрут ИЗ Донецка - проверяем направление
      final isMovingWest = endPoint.longitude < donetskLng && endPoint.latitude < (donetskLat + 2.0);
      
      // 🆕 ПРОВЕРКА на направление в Луганск (северо-восток) - НЕ добавляем КПП
      final isMovingToLuhansk = endPoint.longitude > donetskLng && 
                                endPoint.latitude > donetskLat &&
                                _calculateDistanceBetweenPoints(
                                  endPoint.latitude, endPoint.longitude,
                                  48.5742, 39.3078  // координаты Луганска
                                ) < 100; // в радиусе 100км от Луганска

      // 🆕 ПРОВЕРКА на маршрут в Авило-Успенку - НЕ добавляем КПП (прямой маршрут без крюка)
      final isMovingToAviloUspenka = _calculateDistanceBetweenPoints(
        endPoint.latitude, endPoint.longitude,
        47.698500, 38.678000  // координаты рабочей КПП Авило-Успенка
      ) < 10; // в радиусе 10км от Авило-Успенки

      // 🆕 ПРОВЕРКА на маршрут в Матвеев Курган - НЕ добавляем КПП (прямой маршрут без крюка)
      final isMovingToMatveevKurgan = _calculateDistanceBetweenPoints(
        endPoint.latitude, endPoint.longitude,
        47.567712, 38.861757  // координаты Матвеев Курган
      ) < 10; // в радиусе 10км от Матвеев Кургана
      
      // 🆕 ПРОВЕРКА на маршрут в Покровское - НЕ добавляем КПП (прямой маршрут без крюка)
      final isMovingToPokrovskoe = _calculateDistanceBetweenPoints(
        endPoint.latitude, endPoint.longitude,
        47.415266, 38.896567  // координаты Покровское (Неклиновский р-н)
      ) < 10; // в радиусе 10км от Покровского
      
      if (isMovingWest || isMovingToLuhansk || isMovingToAviloUspenka || isMovingToMatveevKurgan || isMovingToPokrovskoe) {
        if (isMovingToAviloUspenka) {
          print('🛣️ [DEBUG] Маршрут в АВИЛО-УСПЕНКУ - не добавляем КПП (прямой маршрут без крюка)');
        } else if (isMovingToMatveevKurgan) {
          print('🛣️ [DEBUG] Маршрут в МАТВЕЕВ КУРГАН - не добавляем КПП (прямой маршрут без крюка)');
        } else if (isMovingToPokrovskoe) {
          print('🛣️ [DEBUG] Маршрут в ПОКРОВСКОЕ - не добавляем КПП (прямой маршрут без крюка)');
        } else {
          print('🛣️ [DEBUG] Маршрут на ЗАПАД или в ЛУГАНСК - не добавляем КПП (гражданский маршрут)');
        }
        return routePoints;
      }
      
      print('🛣️ [DEBUG] Маршрут на ЮГ в РОСТОВ - добавляем КПП (военный маршрут)');
    } else if (isToDonetsk) {
      // Маршрут В Донецк - проверяем откуда
      final isFromWest = startPoint.longitude < donetskLng && startPoint.latitude < (donetskLat + 2.0);
      
      // 🆕 ПРОВЕРКА на маршрут ИЗ Луганска (северо-восток) - НЕ добавляем КПП
      final isFromLuhansk = startPoint.longitude > donetskLng && 
                            startPoint.latitude > donetskLat &&
                            _calculateDistanceBetweenPoints(
                              startPoint.latitude, startPoint.longitude,
                              48.5742, 39.3078  // координаты Луганска
                            ) < 100; // в радиусе 100км от Луганска

      // 🆕 ПРОВЕРКА на маршрут ИЗ Авило-Успенки - НЕ добавляем КПП (прямой маршрут без крюка)
      final isFromAviloUspenka = _calculateDistanceBetweenPoints(
        startPoint.latitude, startPoint.longitude,
        47.698500, 38.678000  // координаты рабочей КПП Авило-Успенка
      ) < 10; // в радиусе 10км от Авило-Успенки

      // 🆕 ПРОВЕРКА на маршрут ИЗ Матвеев Кургана - НЕ добавляем КПП (прямой маршрут без крюка)
      final isFromMatveevKurgan = _calculateDistanceBetweenPoints(
        startPoint.latitude, startPoint.longitude,
        47.567712, 38.861757  // координаты Матвеев Курган
      ) < 10; // в радиусе 10км от Матвеев Кургана
      
      // 🆕 ПРОВЕРКА на маршрут ИЗ Покровского - НЕ добавляем КПП (прямой маршрут без крюка)
      final isFromPokrovskoe = _calculateDistanceBetweenPoints(
        startPoint.latitude, startPoint.longitude,
        47.415266, 38.896567  // координаты Покровское (Неклиновский р-н)
      ) < 10; // в радиусе 10км от Покровского
      
      if (isFromWest || isFromLuhansk || isFromAviloUspenka || isFromMatveevKurgan || isFromPokrovskoe) {
        if (isFromAviloUspenka) {
          print('🛣️ [DEBUG] Маршрут ИЗ АВИЛО-УСПЕНКИ - не добавляем КПП (прямой маршрут без крюка)');
        } else if (isFromMatveevKurgan) {
          print('🛣️ [DEBUG] Маршрут ИЗ МАТВЕЕВ КУРГАНА - не добавляем КПП (прямой маршрут без крюка)');
        } else if (isFromPokrovskoe) {
          print('🛣️ [DEBUG] Маршрут ИЗ ПОКРОВСКОГО - не добавляем КПП (прямой маршрут без крюка)');
        } else {
          print('🛣️ [DEBUG] Маршрут в Донецк с ЗАПАДА или ИЗ ЛУГАНСКА - не добавляем КПП (гражданский маршрут)');
        }
        return routePoints;
      }
      
      print('🛣️ [DEBUG] Маршрут в Донецк с ЮГА из РОСТОВА - добавляем КПП (военный маршрут)');
    }

    // ✅ ОБЯЗАТЕЛЬНЫЕ ТОЧКИ для военного маршрута из/в Донецк
    const avelon = Point(latitude: 47.698500, longitude: 38.678000);  // КПП Авило-Успенка (на развязке М4)
    const militaryCheckpoint = Point(latitude: 47.318238, longitude: 39.009139);  // Обязательная военная контрольная точка
    
    // ⚠️ КРИТИЧЕСКАЯ ПРОВЕРКА: убеждаемся что не используем старые НЕРАБОТАЮЩИЕ координаты!
    const oldBadKpp = Point(latitude: 47.697816, longitude: 38.666213);  // ЗАПРЕЩЕННЫЕ координаты!
    if ((avelon.latitude - oldBadKpp.latitude).abs() < 0.01 && (avelon.longitude - oldBadKpp.longitude).abs() < 0.01) {
      print('🚨🚨🚨 КРИТИЧЕСКАЯ ОШИБКА! Используются СТАРЫЕ неработающие координаты КПП! Исправите код!');
      return routePoints; // Возвращаем без изменений, чтобы не сломать маршрут
    }

    // Создаем новый список с промежуточной точкой
    List<Point> enhancedRoute;
    
    if (isFromDonetsk) {
      // Маршрут ИЗ Донецка: добавляем КПП и военную контрольную точку
      enhancedRoute = [
        routePoints.first,   // Начальная точка (Донецк)
        avelon,             // Авелон (КПП)
        militaryCheckpoint, // Военная контрольная точка
      ];
      enhancedRoute.addAll(routePoints.skip(1)); // Остальные точки
      
      print('🛣️ ✅ Добавлены обязательные точки для военного маршрута ИЗ Донецка:');
    } else if (isToDonetsk) {
      // Маршрут В Донецк: добавляем военную точку и КПП (в обратном порядке)
      enhancedRoute = [
        routePoints.first,   // Начальная точка (Россия)
        militaryCheckpoint, // Военная контрольная точка
        avelon,             // Авелон (КПП) 
      ];
      enhancedRoute.addAll(routePoints.skip(1)); // Остальные точки включая Донецк
      
      print('🛣️ ✅ Добавлены обязательные точки для военного маршрута В Донецк:');
    } else {
      enhancedRoute = routePoints; // Не должно происходить, но на всякий случай
      print('🛣️ ⚠️ Неопределенный тип маршрута - возвращаем исходный:');
    };
    if (isFromDonetsk) {
      print('   📍 КПП Авило-Успенка: 47.698500, 38.678000');
      print('   🔒 Военная контрольная точка: 47.318238, 39.009139');
      print('   🎯 Всего точек: ${routePoints.length} → ${enhancedRoute.length}');
      print('   🛡️ ВОЕННЫЙ МАРШРУТ: Донецк → КПП → Контрольная точка → Россия');
    } else {
      print('   📍 КПП Авило-Успенка: 47.698500, 38.678000');
      print('   🎯 Всего точек: ${routePoints.length} → ${enhancedRoute.length}');
      print('   🛡️ ВОЕННЫЙ МАРШРУТ: Россия → КПП → Донецк');
    }

    // Финальная проверка КПП убрана - используем все маршруты

    return enhancedRoute;
  }

  /// 🛣️ Добавляет принудительные промежуточные города для маршрутов коридора Донецк-Луганск
  /// Принуждает маршрут проходить через безопасный коридор: Макеевка → Харцызск → Енакиево → Дебальцево
  /// Применяется к маршрутам: Донецк → Луганск, Донецк → Енакиево, Донецк → Дебальцево
  List<Point> _addLuhanskWaypointsIfNeeded(List<Point> routePoints) {
    if (routePoints.length < 2) {
      print('🛣️ [CORRIDOR] Недостаточно точек для анализа: ${routePoints.length}');
      return routePoints;
    }

    final startPoint = routePoints.first;
    final endPoint = routePoints.last;

    // Координаты ключевых городов коридора
    const donetskLat = 48.015884;
    const donetskLng = 37.80285;
    const luhanskLat = 48.5742;
    const luhanskLng = 39.3078;
    const yenakievoLat = 48.233333;
    const yenakievoLng = 38.216667;
    const debaltsevoLat = 48.340900;
    const debaltsevoLng = 38.406600;
    
    // Проверяем расстояния от начальной точки до Донецка
    final startDistanceFromDonetsk = _calculateDistanceBetweenPoints(
      startPoint.latitude, startPoint.longitude,
      donetskLat, donetskLng,
    );
    
    // Проверяем расстояния от конечной точки до городов коридора
    final endDistanceFromLuhansk = _calculateDistanceBetweenPoints(
      endPoint.latitude, endPoint.longitude,
      luhanskLat, luhanskLng,
    );
    final endDistanceFromYenakievo = _calculateDistanceBetweenPoints(
      endPoint.latitude, endPoint.longitude,
      yenakievoLat, yenakievoLng,
    );
    final endDistanceFromDebaltsevo = _calculateDistanceBetweenPoints(
      endPoint.latitude, endPoint.longitude,
      debaltsevoLat, debaltsevoLng,
    );

    // Проверяем, что это маршрут из Донецка (в радиусе 20км)
    final isFromDonetsk = startDistanceFromDonetsk <= 20.0;
    
    // Проверяем, что это маршрут к одному из городов коридора (в радиусе 20км)
    final isToLuhansk = endDistanceFromLuhansk <= 20.0;
    final isToYenakievo = endDistanceFromYenakievo <= 20.0;
    final isToDebaltsevo = endDistanceFromDebaltsevo <= 20.0;
    final isToCorridorCity = isToLuhansk || isToYenakievo || isToDebaltsevo;

    if (!isFromDonetsk || !isToCorridorCity) {
      String targetCity = 'неизвестен';
      if (isToLuhansk) targetCity = 'Луганск';
      if (isToYenakievo) targetCity = 'Енакиево'; 
      if (isToDebaltsevo) targetCity = 'Дебальцево';
      
      print('🛣️ [CORRIDOR] НЕ маршрут коридора Донецк-Луганск: от Донецка ${startDistanceFromDonetsk.toStringAsFixed(2)}км, цель: $targetCity');
      return routePoints;
    }

    String targetCity = 'Луганск';
    if (isToYenakievo) targetCity = 'Енакиево';
    if (isToDebaltsevo) targetCity = 'Дебальцево';
    
    print('🛣️ [CORRIDOR] ✅ Обнаружен маршрут коридора Донецк → $targetCity, добавляем принудительные waypoints');

    // Обязательные промежуточные города с их координатами
    const makeevka = Point(latitude: 48.044444, longitude: 37.926389);    // Макеевка
    const khartsyzsk = Point(latitude: 48.049722, longitude: 38.156111);  // Харцызск  
    const yenakievo = Point(latitude: 48.233333, longitude: 38.216667);   // Енакиево
    const nizhnyayaKrynka = Point(latitude: 48.300000, longitude: 38.350000); // Нижняя Крынка
    const debaltsevo = Point(latitude: 48.340900, longitude: 38.406600);  // Дебальцево

    // Создаем маршрут с принудительными промежуточными точками в зависимости от цели
    late List<Point> enhancedRoute;
    
    if (isToYenakievo) {
      // Маршрут до Енакиево: Донецк → Макеевка → Харцызск → Енакиево
      enhancedRoute = [
        routePoints.first,  // Донецк (начальная точка)
        makeevka,          // Макеевка (обязательная)
        khartsyzsk,        // Харцызск (обязательная) 
        routePoints.last,  // Енакиево (конечная точка)
      ];
    } else if (isToDebaltsevo) {
      // Маршрут до Дебальцево: Донецк → Макеевка → Харцызск → Енакиево → Нижняя Крынка → Дебальцево
      enhancedRoute = [
        routePoints.first,  // Донецк (начальная точка)
        makeevka,          // Макеевка (обязательная)
        khartsyzsk,        // Харцызск (обязательная)
        yenakievo,         // Енакиево (обязательная)
        nizhnyayaKrynka,   // Нижняя Крынка (обязательная для Дебальцево)
        routePoints.last,  // Дебальцево (конечная точка)
      ];
    } else {
      // Маршрут до Луганска: полный коридор
      enhancedRoute = [
        routePoints.first,  // Донецк (начальная точка)
        makeevka,          // Макеевка (обязательная)
        khartsyzsk,        // Харцызск (обязательная)
        yenakievo,         // Енакиево (обязательная)
        debaltsevo,        // Дебальцево (обязательная)
        routePoints.last,  // Луганск (конечная точка)
      ];
    }

    print('🛣️ [CORRIDOR] ✅ Добавлены обязательные промежуточные города для $targetCity:');
    
    if (isToYenakievo) {
      print('   📍 Макеевка: 48.044444, 37.926389');
      print('   📍 Харцызск: 48.049722, 38.156111');
      print('   🎯 Всего точек: ${routePoints.length} → ${enhancedRoute.length}');
      print('   🛣️ БЕЗОПАСНЫЙ МАРШРУТ: Донецк → Макеевка → Харцызск → Енакиево');
    } else if (isToDebaltsevo) {
      print('   📍 Макеевка: 48.044444, 37.926389');
      print('   📍 Харцызск: 48.049722, 38.156111');
      print('   📍 Енакиево: 48.233333, 38.216667');
      print('   📍 Нижняя Крынка: 48.300000, 38.350000');
      print('   🎯 Всего точек: ${routePoints.length} → ${enhancedRoute.length}');
      print('   🛣️ БЕЗОПАСНЫЙ МАРШРУТ: Донецк → Макеевка → Харцызск → Енакиево → Нижняя Крынка → Дебальцево');
    } else {
      print('   📍 Макеевка: 48.044444, 37.926389');
      print('   📍 Харцызск: 48.049722, 38.156111');
      print('   📍 Енакиево: 48.233333, 38.216667');
      print('   📍 Дебальцево: 48.340900, 38.406600');
      print('   🎯 Всего точек: ${routePoints.length} → ${enhancedRoute.length}');
      print('   🛣️ БЕЗОПАСНЫЙ МАРШРУТ: Донецк → Макеевка → Харцызск → Енакиево → Дебальцево → Луганск');
    }

    return enhancedRoute;
  }

  /// Вычисляет расстояние между двумя точками в км (формула гаверсинусов)
  double _calculateDistanceBetweenPoints(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371.0; // км
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLng = (lng2 - lng1) * (math.pi / 180);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// 🔍 Проверяет, проходит ли маршрут через Харцызск (в радиусе 10км)
  bool _routePassesThroughKhartsyzsk(List<Point> routePoints) {
    // Координаты Харцызска
    const double khartsyzskLat = 48.049722;
    const double khartsyzskLng = 38.156111;
    const double radiusKm = 10.0; // Радиус поиска в км
    
    // Проверяем все промежуточные точки маршрута
    for (final point in routePoints) {
      final distance = _calculateDistanceBetweenPoints(
        point.latitude, point.longitude,
        khartsyzskLat, khartsyzskLng,
      );
      
      if (distance <= radiusKm) {
        print('🎯 [KHARTSYZSK] Найдена точка в радиусе ${distance.toStringAsFixed(2)}км от Харцызска');
        return true;
      }
    }
    
    print('❌ [KHARTSYZSK] Маршрут НЕ проходит через Харцызск (ближайшая точка > ${radiusKm}км)');
    return false;
  }
}