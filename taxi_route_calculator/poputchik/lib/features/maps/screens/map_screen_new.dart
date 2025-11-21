import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;

import 'package:geolocator/geolocator.dart' as geolocator;
import '../../../services/map_search_manager.dart';
import '../../../features/search/state/map_search_state.dart';
import '../../../features/search/state/search_state.dart';
import '../../../features/search/state/suggest_state.dart' as search_suggest;

import '../state/suggest_state.dart';
import '../../../managers/route_points_manager.dart';
import '../../../managers/search_routing_integration.dart';
import '../../../services/reverse_geocoding_service.dart';
import '../../../utils/polyline_extensions.dart';
import '../../../widgets/geolocation_button.dart';
import '../../../widgets/search_fields_panel.dart';
import '../widgets/flutter_map_widget.dart';
// import '../../../widgets/point_type_selector.dart'; // Конфликт с RoutePointType
import 'package:yandex_maps_mapkit/directions.dart';
import 'package:yandex_maps_mapkit/image.dart' as image_provider;
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;



import '../listeners/map_listeners.dart';
import '../utils/extensions.dart';


import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon; // For Point, hide Icon to avoid conflict
import 'package:yandex_maps_mapkit/runtime.dart';

enum ActiveField { none, from, to }

class MapScreenNew extends StatefulWidget {
  const MapScreenNew({super.key});

  @override
  State<MapScreenNew> createState() => _MapScreenNewState();
}

class _MapScreenNewState extends State<MapScreenNew> {
  final _searchResultImageProvider =
      image_provider.ImageProvider.fromImageProvider(
          const AssetImage("assets/search_result.png"));
  TextEditingController _textFieldControllerFrom = TextEditingController();
  TextEditingController _textFieldControllerTo = TextEditingController();

  final _mapManager = MapSearchManager();
  final _reverseGeocodingService = ReverseGeocodingService();
  late final RoutePointsManager _routePointsManager;
  SearchRoutingIntegration? _integration; // 🆕 Координатор интеграции (nullable until map is ready)


  late final mapkit.MapObjectCollection _searchResultPlacemarksCollection;

  late final _mapWindowSizeChangedListener = MapSizeChangedListenerImpl(
      onMapWindowSizeChange: (_, __, ___) => _updateFocusRect());

  late final _cameraListener = CameraPositionListenerImpl(
    (_, __, cameraUpdateReason, ___) {
      // Обновляем видимую область для поиска при любом перемещении камеры
      // (жесты пользователя, программная анимация, установка начальной позиции)
      if (cameraUpdateReason == mapkit.CameraUpdateReason.Gestures ||
          cameraUpdateReason == mapkit.CameraUpdateReason.Application) {
        _mapWindow?.let((it) {
          _mapManager.setVisibleRegion(it.map.visibleRegion);
          print('🗺️ Visible region updated (reason: $cameraUpdateReason)');
        });
      }
    },
  );

  

  late final _searchResultPlacemarkTapListener = MapObjectTapListenerImpl(
    onMapObjectTapped: (mapObject, point) {
      print('🎯 Search result placemark tapped at: ${point.latitude}, ${point.longitude}');
      return false;
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

  // Тип точки, выбранный пользователем для установки на карту
  RoutePointType _selectedPointType = RoutePointType.from;

  // Variables for tap-to-place functionality from map_routing
  bool _isPointSelectionEnabled = true; // Flag to control point selection mode

  // Показывать ли текст "Стираем все маршруты"
  bool _showDeleteMessage = false;

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

  // MapInputListener as class variable to prevent garbage collection
  late final _inputListener = MapInputListenerImpl(
    onMapTapCallback: (map, point) {
      print("🗺️🗺️🗺️ Map tapped at: ${point.latitude}, ${point.longitude}");
      print("🔍 Current state: isEnabled=$_isPointSelectionEnabled, selectedType=$_selectedPointType");
      
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
        });
        print("✅ Route completed! Point selection disabled.");
        print("🔍 New state: isEnabled=$_isPointSelectionEnabled");
      }
      
      // Reverse geocoding для отображения адреса (не влияет на координаты точки)
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
      print("� Map long tap at: ${point.latitude}, ${point.longitude}");
    },
  );

  // Route listeners from map_routing (lines 154-218)
  late final _drivingRouteListener = DrivingSessionRouteListener(
    onDrivingRoutes: (newRoutes) {
      print('🎉🎉🎉 onDrivingRoutes FIRED! Got ${newRoutes.length} routes');
      if (newRoutes.isEmpty) {
        showSnackBar(context, "Can't build a route");
      }
      setState(() {
        _drivingRoutes = newRoutes;
        _onDrivingRoutesUpdated();
      });
    },
    onDrivingRoutesError: (Error error) {
      print('❌❌❌ onDrivingRoutesError FIRED! Error: $error');
      switch (error) {
        case final NetworkError _:
          showSnackBar(
            context,
            "Driving routes request error due network issue",
          );
        default:
          showSnackBar(context, "Driving routes request unknown error");
      }
    },
  );

  @override
  void initState() {
    super.initState();
    
    print('🎯 MainScreen initState() called');
    print('📝 INIT - FROM field: "${_textFieldControllerFrom.text}"');
    print('📝 INIT - TO field: "${_textFieldControllerTo.text}"');
    print('🔍 INIT - Active field: $_activeField');
    print('📌 INIT - Last search field type: $_lastSearchFieldType');
    print('✅ RoutePointsManager will be initialized when map is created');
  }

  @override
  void dispose() {
    _mapSearchSubscription?.cancel();
    _searchSubscription?.cancel();
    _suggestSubscription?.cancel();
    _mapManager.dispose();
    _reverseGeocodingService.dispose();
    _integration?.dispose();
    super.dispose();
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
    final requestPoints = [
      mapkit.RequestPoint(routePoints.first, mapkit.RequestPointType.Waypoint, null, null, null),
      ...(routePoints.sublist(1, routePoints.length - 1).map(
          (it) => mapkit.RequestPoint(it, mapkit.RequestPointType.Viapoint, null, null, null))),
      mapkit.RequestPoint(routePoints.last, mapkit.RequestPointType.Waypoint, null, null, null)
    ];

    print('🚗 Requesting driving route with ${requestPoints.length} request points');
    _requestDrivingRoutes(requestPoints);
  }

  // Routing request methods from map_routing (lines 538-576)
  void _requestDrivingRoutes(List<mapkit.RequestPoint> points) {
    print('🚗🚗 _requestDrivingRoutes called with ${points.length} points');
    print('🎧 Listener: ${_drivingRouteListener.hashCode}');
    const drivingOptions = DrivingOptions(routesCount: 3);
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
      // Route reset
      
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
          // Карта на весь экран
          FlutterMapWidget(
            onMapCreated: _setupMap,
            onMapDispose: () {
              print('🗑️ Map disposing - cleaning up listeners');
              _mapWindow?.removeSizeChangedListener(_mapWindowSizeChangedListener);
              _mapWindow?.map.removeCameraListener(_cameraListener);
              _mapSearchSubscription?.cancel();
              _searchSubscription?.cancel();
              _suggestSubscription?.cancel();
            },
          ),
          // Панель с полями поиска поверх карты
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: StreamBuilder<MapSearchState>(
                stream: _mapManager.mapSearchState,
                builder: (context, snapshot) {
                  // 🎯 Извлекаем suggestions из stream (как в taxi_route_calculator)
                  final mapSearchState = snapshot.data;
                  final suggestState = mapSearchState?.suggestState;
                  final suggestions = (suggestState is search_suggest.SuggestSuccess) 
                      ? suggestState.suggestItems 
                      : <search_suggest.SuggestItem>[];

                  return SearchFieldsPanel(
                    fromController: _textFieldControllerFrom,
                    toController: _textFieldControllerTo,
                    fromSuggestions: _activeField == ActiveField.from ? suggestions : const <search_suggest.SuggestItem>[],
                    toSuggestions: _activeField == ActiveField.to ? suggestions : const <search_suggest.SuggestItem>[],
                    isFromFieldActive: _activeField == ActiveField.from,
                    isToFieldActive: _activeField == ActiveField.to,
                    showFromSuggestions: _activeField == ActiveField.from && suggestions.isNotEmpty,
                    showToSuggestions: _activeField == ActiveField.to && suggestions.isNotEmpty,
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
                      if (_activeField == ActiveField.from) {
                        // 🆕 Убеждаемся что тип поля правильный при вводе текста
                        _lastSearchFieldType = RoutePointType.from;
                        _mapManager.setQueryText(text);
                      }
                    },
                    onToTextChanged: (text) {
                      if (_activeField == ActiveField.to) {
                        // 🆕 Убеждаемся что тип поля правильный при вводе текста
                        _lastSearchFieldType = RoutePointType.to;
                        _mapManager.setQueryText(text);
                      }
                    },
                    onFromSuggestionSelected: (address) {
                      // 📍 Этот callback вызывается ПОСЛЕ suggestion.onTap()
                      // suggestion.onTap() уже запустил поиск через URI/searchText
                      // Нам нужно только установить флаги для обработки результата
                      
                      print('📍 FROM suggestion selected: $address');
                      
                      _lastSearchFieldType = RoutePointType.from;
                      _waitingForSuggestionResult = true;
                      
                      setState(() {
                        _textFieldControllerFrom.text = address; // Обновляем UI
                        _activeField = ActiveField.none;
                      });
                    },
                    onToSuggestionSelected: (address) {
                      // 📍 Этот callback вызывается ПОСЛЕ suggestion.onTap()
                      // suggestion.onTap() уже запустил поиск через URI/searchText
                      // Нам нужно только установить флаги для обработки результата
                      
                      print('� TO suggestion selected: $address');
                      
                      _lastSearchFieldType = RoutePointType.to;
                      _waitingForSuggestionResult = true;
                      
                      setState(() {
                        _textFieldControllerTo.text = address; // Обновляем UI
                        _activeField = ActiveField.none;
                      });
                      print('✅ TO state updated');
                    },
                    // Новые callback'и для кнопок карты
                    onFromMapButtonTapped: () {
                      print('🗺️ FROM map button tapped - enabling point selection');
                      setState(() {
                        _selectedPointType = RoutePointType.from;
                        _isPointSelectionEnabled = true;
                        _activeField = ActiveField.none; // Закрываем поиск
                      });
                      showSnackBar(context, "Выберите точку ОТКУДА на карте 🟢");
                    },
                    onToMapButtonTapped: () {
                      print('🗺️ TO map button tapped - enabling point selection');
                      setState(() {
                        _selectedPointType = RoutePointType.to;
                        _isPointSelectionEnabled = true;
                        _activeField = ActiveField.none; // Закрываем поиск
                      });
                      showSnackBar(context, "Выберите точку КУДА на карте 🔴");
                    },
                  );
                },
              ),
            ),
          ),
          // Кнопка сброса маршрута под полями поиска с текстом
          Positioned(
            top: 140, // Близко под полями "От" и "До"
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  FloatingActionButton(
                    heroTag: "reset_route_button",
                    mini: true,
                    backgroundColor: CupertinoColors.white,
                    onPressed: () async {
                      // Показываем текст
                      setState(() {
                        _showDeleteMessage = true;
                      });
                      
                      // Выполняем оба сброса сразу
                      _forceResetAllFields();
                      _routePointsManager.forceTripleClear();
                      print("📱 Маршрут полностью удалён! 🗑️");
                      
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
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  // Анимированный текст справа от кнопки (только fade)
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _showDeleteMessage ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _showDeleteMessage
                          ? Container(
                              margin: const EdgeInsets.only(left: 8),
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
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
                                  'Стираем все маршруты',
                                  style: widgets.TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 16,
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
          ),
          // Кнопка геолокации
          Positioned(
            bottom: 16,
            right: 16,
            child: GeolocationButton(
              onPressed: _moveToUserLocation,
            ),
          ),
          // Кнопки зума - вертикально справа по центру экрана
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
                ],
              ),
            ),
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
    _routePointsManager.init();
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
      print('🎯🎯🎯 CALLBACK INVOKED! Address selected from search: $address at ${point.latitude}, ${point.longitude}');
      print('🔧 Last search field type: $_lastSearchFieldType');
      print('🔧 Waiting for suggestion result: $_waitingForSuggestionResult');
      
      // Обрабатываем результат только если ждем результат от саджеста
      if (_waitingForSuggestionResult) {
        print('✅ Flag is TRUE - processing result');
        _waitingForSuggestionResult = false; // Сбрасываем флаг
        
        // Устанавливаем точку на карте в зависимости от типа поля
        if (_lastSearchFieldType == RoutePointType.from) {
          print('🔧 Setting FROM point from search result');
          _routePointsManager.setPoint(RoutePointType.from, point);
        } else if (_lastSearchFieldType == RoutePointType.to) {
          print('🔧 Setting TO point from search result');
          _routePointsManager.setPoint(RoutePointType.to, point);
        }
        
        // Перемещаем камеру к выбранной точке
        if (_mapWindow?.map != null) {
          print('📍 Moving camera to selected address: ${point.latitude}, ${point.longitude}');
          final newCameraPosition = CameraPosition(
            point,
            zoom: 15.0,
            azimuth: 0.0,
            tilt: 0.0,
          );
          _mapWindow!.map.moveWithAnimation(
            newCameraPosition,
            const mapkit.Animation(mapkit.AnimationType.Smooth, duration: 1.0),
          );
        }
        
        print('✅ Point set from search result successfully!');
      } else {
        print('⚠️⚠️⚠️ IGNORING search result - flag is FALSE (not waiting for suggestion result)');
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
    
    // Сначала добавляем слушатель камеры (заглушка)
    // mapWindow.map.addCameraListener(_cameraListener);
    
    // Пытаемся получить геолокацию пользователя для начального положения
    await _initializeUserLocation(mapWindow);

    print('📡 Subscribing to search and suggest streams...');
    _mapManager.mapSearchState.listen((uiState) {
      if (uiState.suggestState is SuggestError) {
        showSnackBar(context, "Ошибка предложений, проверьте подключение к интернету");
      }

      final searchState = uiState.searchState;

      if (searchState is SearchSuccess) {
        final searchItems = searchState.items;
        print('✅ Search response: ${searchItems.length} items');

        _updateSearchResponsePlacemarks(searchItems);

        // ОТКЛЮЧЕНО: auto-selection из stream subscription
        // Теперь все результаты обрабатываются только через callback onAddressSelected
        // который вызывается из MapSearchManager после фильтрации по городу
        
        // Показываем результаты поиска на карте без автовыбора
        if (searchState.shouldZoomToItems && !_waitingForSuggestionResult) {
          _focusCamera(
            searchItems.map((it) => it.point),
            searchState.itemsBoundingBox,
          );
        }
      } else if (searchState is SearchOff) {
        _searchResultPlacemarksCollection.clear();
      } else if (searchState is SearchError) {
        showSnackBar(context, "Ошибка поиска, проверьте подключение к интернету");
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
          showSnackBar(context, 'Необходимо разрешение на использование геолокации');
          return;
        }
      }

      if (permission == geolocator.LocationPermission.deniedForever) {
        print('❌ Геолокация: Разрешение отклонено навсегда');
        showSnackBar(context, 'Разрешение на геолокацию заблокировано. Включите в настройках.');
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
        showSnackBar(context, 'Получены некорректные координаты');
        return;
      }
      
      // 📍 Устанавливаем позицию пользователя для приоритета саджестов
      final point = Point(latitude: position.latitude, longitude: position.longitude);
      _mapManager.setUserPosition(point);

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
          
          // Visible region обновится автоматически через CameraListener
          
          print('✅ Камера перемещена успешно');
          showSnackBar(context, 'Перемещено к вашему местоположению');
        } else {
          print('❌ MapWindow не инициализирован');
          showSnackBar(context, 'Карта не готова');
        }
      } catch (cameraError) {
        print('❌ Ошибка перемещения камеры: $cameraError');
        showSnackBar(context, 'Ошибка перемещения камеры: $cameraError');
      }
      
    } catch (e) {
      print('❌ Ошибка геолокации: $e');
      showSnackBar(context, 'Не удалось получить местоположение: $e');
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
      
      // Создаем иконку для маркера пользователя
      final userLocationIcon = image_provider.ImageProvider.fromImageProvider(
        const AssetImage("assets/png-location.png")
      );
      
      // Добавляем новый маркер
      _userLocationPlacemark = _userLocationCollection.addPlacemark()
        ..geometry = point
        ..setIcon(userLocationIcon)
        ..setIconStyle(const mapkit.IconStyle(scale: 1.0));
      
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
      
      // 📍 Устанавливаем позицию для приоритета саджестов
      _mapManager.setUserPosition(userPoint);
      
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

  void showSnackBar(BuildContext context, String message) {
    // Используем простой print вместо ScaffoldMessenger для Cupertino app
    print('📢 SnackBar: $message');
  }
}
