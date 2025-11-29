import 'package:collection/collection.dart';
import 'package:common/buttons/simple_button.dart';
import 'package:common/listeners/map_input_listener.dart';
import 'package:common/map/flutter_map_widget.dart';
import 'package:common/resources/theme.dart';
import 'package:common/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:map_routing/data/geometry_provider.dart';
import 'package:map_routing/data/routing_type.dart';
import 'package:map_routing/utils/polyline_extensions.dart';
import 'package:map_routing/widgets/point_type_selector.dart';
import 'package:map_routing/managers/route_points_manager_safe.dart';
import 'package:yandex_maps_mapkit/directions.dart';
import 'package:yandex_maps_mapkit/image.dart' as image_provider;
import 'package:yandex_maps_mapkit/init.dart' as init;
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/runtime.dart';
import 'package:yandex_maps_mapkit/transport.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /**
   * Replace "your_api_key" with a valid developer key.
   */
  await init.initMapkit(apiKey: "2f1d6a75-b751-4077-b305-c6abaea0b542");

  runApp(
    MaterialApp(
      theme: MapkitFlutterTheme.lightTheme,
      darkTheme: MapkitFlutterTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MapkitFlutterApp(),
    ),
  );
}

class MapkitFlutterApp extends StatefulWidget {
  const MapkitFlutterApp({super.key});

  @override
  State<MapkitFlutterApp> createState() => _MapkitFlutterAppState();
}

class _MapkitFlutterAppState extends State<MapkitFlutterApp> {
  MapWindow? _mapWindow;

  var _routePoints = <Point>[];
  var _drivingRoutes = <DrivingRoute>[];
  var _pedestrianRoutes = <MasstransitRoute>[];
  var _publicTransportRoutes = <MasstransitRoute>[];
  var _currentRoutingType = RoutingType.driving;
  
  // Новые переменные для функционала тапов
  RoutePointType _selectedPointType = RoutePointType.from;
  late RoutePointsManager _routePointsManager;
  bool _isPointSelectionEnabled = true; // Флаг для контроля режима выбора точек
  bool _routeCompleted = false; // Флаг завершения выбора маршрута

  List<Point> get routePoints => _routePoints;
  List<DrivingRoute> get drivingRoutes => _drivingRoutes;
  List<MasstransitRoute> get pedestrianRoutes => _pedestrianRoutes;
  List<MasstransitRoute> get publicTransportRoutes => _publicTransportRoutes;
  RoutingType get currentRoutingType => _currentRoutingType;

  set routePoints(List<Point> newValue) {
    _routePoints = newValue;
    _onRouteParametersUpdated();
  }

  set drivingRoutes(List<DrivingRoute> newValue) {
    _drivingRoutes = newValue;
    _onDrivingRoutesUpdated();
  }

  set pedestrianRoutes(List<MasstransitRoute> newValue) {
    _pedestrianRoutes = newValue;
    _onPedestrianRoutesUpdated();
  }

  set publicTransportRoutes(List<MasstransitRoute> newValue) {
    _publicTransportRoutes = newValue;
    _onPublicTransportRoutesUpdated();
  }

  set currentRoutingType(RoutingType newValue) {
    _currentRoutingType = newValue;
    _onRouteParametersUpdated();
  }

  DrivingSession? _drivingSession;
  late final DrivingRouter _drivingRouter;

  MasstransitSession? _pedestrianSession;
  late final PedestrianRouter _pedestrianRouter;

  MasstransitSession? _publicTransportSession;
  late final MasstransitRouter _publicTransportRouter;

  late final MapObjectCollection _placemarksCollection;
  late final MapObjectCollection _routesCollection;

  late final pointImageProvider =
      image_provider.ImageProvider.fromImageProvider(
          const AssetImage("assets/ic_point.png"));

  late final finishPointImageProvider =
      image_provider.ImageProvider.fromImageProvider(
          const AssetImage("assets/ic_finish_point.png"));

  late final _inputListener = MapInputListenerImpl(
    onMapTapCallback: (map, point) {
      print("🗺️🗺️🗺️ Map tapped at: ${point.latitude}, ${point.longitude}");
      print("🔍 Current state: isEnabled=$_isPointSelectionEnabled, selectedType=$_selectedPointType, routeCompleted=$_routeCompleted");
      
      // Проверяем, можно ли еще ставить точки
      if (!_isPointSelectionEnabled) {
        print("🚫 Point selection is disabled. Route already completed.");
        return;
      }
      
      _routePointsManager.setPoint(_selectedPointType, point);
      
      // Автоматически переключаемся на следующий тип точки
      print("🔍 Checking selectedType: $_selectedPointType");
      print("🔍 RoutePointType.from == $_selectedPointType: ${_selectedPointType == RoutePointType.from}");
      print("🔍 RoutePointType.to == $_selectedPointType: ${_selectedPointType == RoutePointType.to}");
      
      if (_selectedPointType == RoutePointType.from) {
        print("🔄 Was FROM type, switching to TO and staying enabled");
        setState(() {
          _selectedPointType = RoutePointType.to;
        });
        print("🔄 Auto-switched to TO point type");
      } else if (_selectedPointType == RoutePointType.to) {
        // Достигли TO точки - завершаем выбор точек
        print("🛑 Was TO type, disabling point selection!");
        setState(() {
          _isPointSelectionEnabled = false;
          _routeCompleted = true;
        });
        print("✅ Route completed! Point selection disabled.");
        print("🔍 New state: isEnabled=$_isPointSelectionEnabled, routeCompleted=$_routeCompleted");
      } else {
        print("❌ Unexpected selectedType: $_selectedPointType");
      }
    },
    onMapLongTapCallback: (map, point) {
      routePoints = [...routePoints, point];
      if (routePoints.length == 1) {
        showSnackBar(context, "Added first route point");
      }
    },
  );

  late final _drivingRouteListener = DrivingSessionRouteListener(
    onDrivingRoutes: (newRoutes) {
      if (newRoutes.isEmpty) {
        showSnackBar(context, "Can't build a route");
      }
      drivingRoutes = newRoutes;
    },
    onDrivingRoutesError: (Error error) {
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

  late final _pedestrianRouteListener = RouteHandler(
    onMasstransitRoutes: (newRoutes) {
      if (newRoutes.isEmpty) {
        showSnackBar(context, "Can't build a route");
      }
      pedestrianRoutes = newRoutes;
    },
    onMasstransitRoutesError: (error) {
      switch (error) {
        case final NetworkError _:
          showSnackBar(
            context,
            "Pedestrian routes request error due network issue",
          );
        default:
          showSnackBar(context, "Pedestrian routes request unknown error");
      }
    },
  );

  late final _publicTransportRouteListener = RouteHandler(
    onMasstransitRoutes: (newRoutes) {
      if (newRoutes.isEmpty) {
        showSnackBar(context, "Can't build a route");
      }
      publicTransportRoutes = newRoutes;
    },
    onMasstransitRoutesError: (error) {
      switch (error) {
        case final NetworkError _:
          showSnackBar(
            context,
            "Public transport routes request error due network issue",
          );
        default:
          showSnackBar(
            context,
            "Public transport routes request unknown error",
          );
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    print("🎯 Tap to Place: Building UI with selector");
    
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            FlutterMapWidget(
              onMapCreated: _createMapObjects,
              onMapDispose: () {
                _mapWindow?.map.removeInputListener(_inputListener);
              },
            ),
            // Показываем селектор точек или кнопку сброса
            if (_isPointSelectionEnabled) 
              Positioned(
                top: 60, // Отступ от верха экрана
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PointTypeSelector(
                    selectedType: _selectedPointType,
                    onTypeChanged: (type) {
                      setState(() {
                        _selectedPointType = type;
                      });
                      print("🎯 Выбран тип точки: ${type == RoutePointType.from ? 'FROM' : 'TO'}");
                    },
                  ),
                ),
              )
            else
              Positioned(
                top: 60,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "✅ Маршрут готов!",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isPointSelectionEnabled = true;
                              _routeCompleted = false;
                              _selectedPointType = RoutePointType.from;
                            });
                            _routePointsManager.clearAllPoints();
                            print("🔄 Point selection reset. Ready for new route.");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text("🔄 Выбрать новый маршрут"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0.0,
              left: 0.0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    direction: Axis.vertical,
                    spacing: 10.0,
                    children: [
                      SimpleButton(
                        text: "Построить маршрут",
                        onPressed: () {
                          print("🔘 ПОСТРОИТЬ МАРШРУТ button pressed");
                          if (_routePointsManager.points.length >= 2) {
                            // Используем точки из нашего менеджера
                            routePoints = _routePointsManager.points;
                            showSnackBar(context, "Маршрут построен!");
                            print("✅ Route built successfully with manager points");
                          } else if (routePoints.length >= 2) {
                            // Обратная совместимость с долгими тапами
                            setState(() {});
                            showSnackBar(context, "Маршрут построен!");
                            print("✅ Route built successfully");
                          } else {
                            showSnackBar(context, "Нужно минимум 2 точки. Выберите тип точки сверху и тапните на карту.");
                            print("❌ Not enough points: ${routePoints.length}");
                          }
                        },
                      ),
                      SimpleButton(
                        text: "Быстрый демо-маршрут",
                        onPressed: () {
                          print("🔘 БЫСТРЫЙ ДЕМО-МАРШРУТ button pressed");
                          // Добавляем готовый демо-маршрут
                          routePoints = [
                            Point(latitude: 59.954093, longitude: 30.305770), // Начальная точка
                            Point(latitude: 59.929576, longitude: 30.291737), // Конечная точка
                          ];
                          showSnackBar(context, "Демо-маршрут добавлен! Проверьте карту.");
                          print("✅ Demo route points added: ${routePoints.length}");
                        },
                      ),
                      SimpleButton(
                        text: "Информация о маршруте",
                        onPressed: () {
                          if (drivingRoutes.isNotEmpty) {
                            final route = drivingRoutes.first;
                            final distance = route.metadata.weight.distance.text;
                            final duration = route.metadata.weight.time.text;
                            showSnackBar(context, "Расстояние: $distance, Время: $duration");
                          } else {
                            showSnackBar(context, "Маршрут еще не построен");
                          }
                        },
                      ),
                      SimpleButton(
                        text: "Очистить маршруты",
                        onPressed: () {
                          routePoints = [];
                          _routePointsManager.clearAllPoints();
                          showSnackBar(context, "Все точки маршрута очищены");
                        },
                      ),
                      SimpleButton(
                        text:
                            "Тип маршрута: ${_getRoutingTypeRussianName(currentRoutingType)}",
                        onPressed: () {
                          setState(() {
                            switch (currentRoutingType) {
                              case RoutingType.driving:
                                currentRoutingType = RoutingType.pedestrian;
                              case RoutingType.pedestrian:
                                currentRoutingType =
                                    RoutingType.publicTransport;
                              case RoutingType.publicTransport:
                                currentRoutingType = RoutingType.driving;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createMapObjects(MapWindow mapWindow) {
    _mapWindow = mapWindow;

    mapWindow.map.move(GeometryProvider.startPosition);
    
    print("🎯 Adding MapInputListener to map...");
    mapWindow.map.addInputListener(_inputListener);
    print("✅ MapInputListener added successfully!");

    _placemarksCollection = mapWindow.map.mapObjects.addCollection();
    _routesCollection = mapWindow.map.mapObjects.addCollection();
    
    // Инициализируем менеджер точек маршрута
    _routePointsManager = RoutePointsManager(
      mapObjects: _placemarksCollection,
      onPointsChanged: (points) {
        // Обновляем routePoints только если есть изменения из менеджера
        if (points.isNotEmpty) {
          routePoints = points;
        }
      },
    );
    print("✅ RoutePointsManager initialized");

    _drivingRouter = DirectionsFactory.instance
        .createDrivingRouter(DrivingRouterType.Combined);
    _pedestrianRouter = TransportFactory.instance.createPedestrianRouter();
    _publicTransportRouter =
        TransportFactory.instance.createMasstransitRouter();

    routePoints = GeometryProvider.defaultPoints;
  }

  void _onRouteParametersUpdated() {
    _placemarksCollection.clear();

    if (routePoints.isEmpty) {
      switch (currentRoutingType) {
        case RoutingType.driving:
          _drivingSession?.cancel();
          drivingRoutes = [];
        case RoutingType.pedestrian:
          _pedestrianSession?.cancel();
          pedestrianRoutes = [];
        case RoutingType.publicTransport:
          _publicTransportSession?.cancel();
          publicTransportRoutes = [];
      }
      return;
    }

    routePoints.forEachIndexed((index, point) {
      final placemark = _placemarksCollection.addPlacemark()..geometry = point;

      if (index != routePoints.length - 1) {
        placemark
          ..setIcon(pointImageProvider)
          ..setIconStyle(const IconStyle(scale: 2.5, zIndex: 20.0));
      } else {
        placemark
          ..setIcon(finishPointImageProvider)
          ..setIconStyle(const IconStyle(scale: 1.5, zIndex: 20.0));
      }
    });

    if (routePoints.length < 2) {
      return;
    }

    final requestPoints = [
      RequestPoint(routePoints.first, RequestPointType.Waypoint, null, null, null),
      ...(routePoints.sublist(1, routePoints.length - 1).map(
          (it) => RequestPoint(it, RequestPointType.Viapoint, null, null, null))),
      RequestPoint(routePoints.last, RequestPointType.Waypoint, null, null, null)
    ];

    switch (currentRoutingType) {
      case RoutingType.driving:
        _requestDrivingRoutes(requestPoints);
      case RoutingType.pedestrian:
        _requestPedestrianRoutes(requestPoints);
      case RoutingType.publicTransport:
        _requestPublicTransportRoutes(requestPoints);
    }
  }

  void _onDrivingRoutesUpdated() {
    _routesCollection.clear();
    if (drivingRoutes.isEmpty) {
      return;
    }

    drivingRoutes.forEachIndexed((index, route) {
      _createPolylineWithStyle(index, route.geometry);
    });
  }

  void _onPedestrianRoutesUpdated() {
    _routesCollection.clear();
    if (pedestrianRoutes.isEmpty) {
      return;
    }

    pedestrianRoutes.forEachIndexed((index, route) {
      _createPolylineWithStyle(index, route.geometry);
    });
  }

  void _onPublicTransportRoutesUpdated() {
    _routesCollection.clear();
    if (publicTransportRoutes.isEmpty) {
      return;
    }

    publicTransportRoutes.forEachIndexed((index, route) {
      _createPolylineWithStyle(index, route.geometry);
    });
  }

  void _createPolylineWithStyle(int routeIndex, Polyline routeGeometry) {
    final polyline = _routesCollection.addPolylineWithGeometry(routeGeometry);
    routeIndex == 0
        ? polyline.applyMainRouteStyle()
        : polyline.applyAlternativeRouteStyle();
  }

  void _requestDrivingRoutes(List<RequestPoint> points) {
    const drivingOptions = DrivingOptions(routesCount: 3);
    const vehicleOptions = DrivingVehicleOptions();

    _drivingSession = _drivingRouter.requestRoutes(
      drivingOptions,
      vehicleOptions,
      _drivingRouteListener,
      points: points,
    );
  }

  void _requestPedestrianRoutes(List<RequestPoint> points) {
    const timeOptions = TimeOptions();
    const routeOptions = RouteOptions(FitnessOptions(avoidSteep: false));

    _pedestrianSession = _pedestrianRouter.requestRoutes(
      timeOptions,
      routeOptions,
      _pedestrianRouteListener,
      points: points,
    );
  }

  void _requestPublicTransportRoutes(List<RequestPoint> points) {
    const timeOptions = TimeOptions();
    const transitOptions = TransitOptions(timeOptions);
    const routeOptions = RouteOptions(FitnessOptions(avoidSteep: false));

    _publicTransportSession = _publicTransportRouter.requestRoutes(
      transitOptions,
      routeOptions,
      _publicTransportRouteListener,
      points: points,
    );
  }

  String _getRoutingTypeRussianName(RoutingType type) {
    switch (type) {
      case RoutingType.driving:
        return "автомобиль";
      case RoutingType.pedestrian:
        return "пешком";
      case RoutingType.publicTransport:
        return "общественный транспорт";
    }
  }
}
