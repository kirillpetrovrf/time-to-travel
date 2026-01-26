import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, TextStyle, Direction;
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;
import 'package:yandex_maps_mapkit/directions.dart';
import 'package:common/common.dart';
import '../../../services/route_management_service.dart';
import '../../../models/predefined_route.dart';
import '../../../models/route_group.dart';
import '../../../data/route_groups_initializer.dart';
import '../../../widgets/simple_address_field.dart';
import '../screens/route_group_details_screen.dart';
import '../../../managers/route_points_manager.dart';
import '../../../models/route_point.dart'; // ✅ Единый RoutePointType

/// Виджет для управления фиксированными маршрутами в админ-панели
class RouteManagementWidget extends StatefulWidget {
  final dynamic theme;

  const RouteManagementWidget({super.key, required this.theme});

  @override
  State<RouteManagementWidget> createState() => _RouteManagementWidgetState();
}

class _RouteManagementWidgetState extends State<RouteManagementWidget> {
  final RouteManagementService _routeService = RouteManagementService.instance;

  List<PredefinedRoute> _routes = [];
  List<RouteGroup> _groups = [];
  RouteGroup? _selectedGroup; // Для фильтрации списка маршрутов
  RouteGroup? _selectedGroupForNewRoute; // Для добавления нового маршрута
  bool _isLoading = true;
  bool _isSaving = false;

  // Данные для добавления нового маршрута
  String _selectedFromCity = '';
  String _selectedToCity = '';
  final TextEditingController _priceController = TextEditingController();

  // Карта для активации Yandex API автоподсказок
  // ignore: unused_field - используется для поддержания жизни MapKit
  MapWindow? _mapWindow;

  // 🆕 Координаты для отображения на карте
  Point? _fromPoint;
  Point? _toPoint;

  // 🆕 Менеджер точек маршрута и коллекции карты
  RoutePointsManager? _routePointsManager;
  MapObjectCollection? _routesCollection;

  // 🆕 Для построения маршрута
  DrivingRouter? _drivingRouter;
  DrivingSession? _drivingSession;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadRoutes();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _drivingSession?.cancel();
  // demo timers cancelled via async flow; nothing extra to cancel here
    _mapWindow = null;
    super.dispose();
  }

  // Колбэк создания карты для активации Yandex MapKit API
  void _onMapCreated(MapWindow mapWindow) async {
    _mapWindow = mapWindow;
    debugPrint(
      '🗺️ [ROUTE_MANAGEMENT] Карта создана для активации Yandex API автоподсказок',
    );

    try {
      // Центрируем карту на Ростовской области
      final rostovPoint = Point(latitude: 47.2357, longitude: 39.7015);
      _mapWindow!.map.move(
        CameraPosition(rostovPoint, zoom: 7.0, azimuth: 0, tilt: 0),
      );

      // Инициализируем коллекцию для маркеров
      final routePointsCollection = mapWindow.map.mapObjects.addCollection();
      _routesCollection = mapWindow.map.mapObjects.addCollection();

      // Инициализируем RoutePointsManager для управления маркерами
      _routePointsManager = RoutePointsManager(
        mapObjects: routePointsCollection,
        onPointsChanged: (points) {
          debugPrint('� [ROUTE_MANAGEMENT] Точки изменились: ${points.length}');
          _onRouteParametersUpdated();
        },
      );
      await _routePointsManager!.init();

      // Инициализируем DrivingRouter для построения маршрутов
      _drivingRouter = DirectionsFactory.instance.createDrivingRouter(
        DrivingRouterType.Combined,
      );

      debugPrint('✅ [ROUTE_MANAGEMENT] MapKit полностью инициализирован');
    } catch (e) {
      debugPrint('❌ [ROUTE_MANAGEMENT] Ошибка инициализации карты: $e');
    }
  }

  // 🆕 Обновление маршрута когда меняются точки
  void _onRouteParametersUpdated() {
    if (_fromPoint != null && _toPoint != null) {
      debugPrint('✅ [ROUTE_MANAGEMENT] Обе точки установлены, строим маршрут');
      _requestDrivingRoute();
    } else {
      debugPrint(
        '⚠️ [ROUTE_MANAGEMENT] Не все точки: from=${_fromPoint != null}, to=${_toPoint != null}',
      );
    }
  }

  // 🆕 Запрос построения маршрута
  void _requestDrivingRoute() {
    if (_fromPoint == null || _toPoint == null || _drivingRouter == null) {
      debugPrint(
        '⚠️ [ROUTE_MANAGEMENT] Невозможно построить маршрут: отсутствуют данные',
      );
      return;
    }

    debugPrint(
      '🚗 [ROUTE_MANAGEMENT] Запрос маршрута: $_fromPoint → $_toPoint',
    );

    _drivingSession?.cancel();

    const drivingOptions = DrivingOptions(routesCount: 1);
    const vehicleOptions = DrivingVehicleOptions();

    final requestPoints = [
      RequestPoint(_fromPoint!, RequestPointType.Waypoint, null, null, null),
      RequestPoint(_toPoint!, RequestPointType.Waypoint, null, null, null),
    ];

    try {
      _drivingSession = _drivingRouter!.requestRoutes(
        drivingOptions,
        vehicleOptions,
        DrivingSessionRouteListener(
          onDrivingRoutes: (routes) {
            if (routes.isNotEmpty) {
              _drawRoute(routes.first);
              debugPrint('✅ [ROUTE_MANAGEMENT] Маршрут построен');
            }
          },
          onDrivingRoutesError: (error) {
            debugPrint(
              '❌ [ROUTE_MANAGEMENT] Ошибка построения маршрута: $error',
            );
          },
        ),
        points: requestPoints,
      );
    } catch (e) {
      debugPrint('❌ [ROUTE_MANAGEMENT] Exception при requestRoutes: $e');
    }
  }

  // 🆕 Отрисовка маршрута на карте
  void _drawRoute(DrivingRoute route) {
    _routesCollection?.clear();

    final polyline = _routesCollection?.addPolylineWithGeometry(route.geometry);
    if (polyline != null) {
      polyline.setStrokeColor(const Color.fromARGB(255, 0, 122, 255));
      polyline.strokeWidth = 5.0;
      polyline.outlineColor = const Color.fromARGB(128, 255, 255, 255);
      polyline.outlineWidth = 1.0;
    }

    // Подгоняем камеру под маршрут
    _fitCameraToRoute();

    debugPrint('✅ [ROUTE_MANAGEMENT] Маршрут отрисован');
  }

  // 🆕 Подгонка камеры под маршрут (как в IndividualBookingScreen)
  void _fitCameraToRoute() {
    if (_fromPoint == null || _toPoint == null || _mapWindow == null) return;

    final minLat = _fromPoint!.latitude < _toPoint!.latitude
        ? _fromPoint!.latitude
        : _toPoint!.latitude;
    final maxLat = _fromPoint!.latitude > _toPoint!.latitude
        ? _fromPoint!.latitude
        : _toPoint!.latitude;
    final minLon = _fromPoint!.longitude < _toPoint!.longitude
        ? _fromPoint!.longitude
        : _toPoint!.longitude;
    final maxLon = _fromPoint!.longitude > _toPoint!.longitude
        ? _fromPoint!.longitude
        : _toPoint!.longitude;

    // Добавляем отступ 10% от размера области (как в IndividualBookingScreen)
    final latDelta = (maxLat - minLat) * 0.1;
    final lonDelta = (maxLon - minLon) * 0.1;

    final boundingBox = BoundingBox(
      Point(latitude: minLat - latDelta, longitude: minLon - lonDelta),
      Point(latitude: maxLat + latDelta, longitude: maxLon + lonDelta),
    );

    try {
      final cameraPosition = _mapWindow!.map.cameraPositionForGeometry(
        Geometry.fromBoundingBox(boundingBox),
      );
      // Используем анимацию как в IndividualBookingScreen
      _mapWindow!.map.moveWithAnimation(
        cameraPosition,
        const mapkit.Animation(mapkit.AnimationType.Smooth, duration: 0.5),
      );
    } catch (e) {
      debugPrint('⚠️ [ROUTE_MANAGEMENT] Ошибка подгонки камеры: $e');
    }
  }

  // 🆕 Обновление точки "Откуда" на карте
  void _updateFromPoint(Point? point) {
    _fromPoint = point;
    if (point != null && _routePointsManager != null) {
      _routePointsManager!.setPoint(RoutePointType.from, point);
      debugPrint(
        '📍 [ROUTE_MANAGEMENT] FROM точка установлена: ${point.latitude}, ${point.longitude}',
      );
    }
  }

  // 🆕 Очистить форму и карту (кнопка "корзина")
  void _clearForm() {
    setState(() {
      _selectedFromCity = '';
      _selectedToCity = '';
      _fromPoint = null;
      _toPoint = null;
      _priceController.clear();
      _selectedGroupForNewRoute = null;
    });
    _routePointsManager?.removePoint(RoutePointType.from);
    _routePointsManager?.removePoint(RoutePointType.to);
    _routesCollection?.clear();
    debugPrint('🗑️ Форма и карта очищены');
  }

  // 🆕 Обновление точки "Куда" на карте
  void _updateToPoint(Point? point) {
    _toPoint = point;
    if (point != null && _routePointsManager != null) {
      _routePointsManager!.setPoint(RoutePointType.to, point);
      debugPrint(
        '📍 [ROUTE_MANAGEMENT] TO точка установлена: ${point.latitude}, ${point.longitude}',
      );
    }
  }

  Future<void> _loadGroups() async {
    final groups = RouteGroupsInitializer.initialGroups;
    setState(() {
      _groups = groups;
    });
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routes = await _routeService.getAllRoutes(forceRefresh: true);
      if (mounted) {
        setState(() {
          _routes = routes;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Показываем менее пугающее сообщение и все равно пытаемся загрузить локальные данные
      print('⚠️ Ошибка загрузки из Firebase, используем локальные данные: $e');
      try {
        final routes = await _routeService.getAllRoutes(forceRefresh: false);
        if (mounted) {
          setState(() {
            _routes = routes;
            _isLoading = false;
          });
        }
      } catch (localError) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showError('Ошибка загрузки маршрутов: $localError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Фильтрация маршрутов по выбранной группе
    final displayedRoutes = _selectedGroup == null
        ? _routes
        : _routes.where((route) {
            // НОВАЯ ЛОГИКА: Сначала проверяем, назначен ли маршрут явно к этой группе
            if (route.groupId != null && route.groupId == _selectedGroup!.id) {
              return true;
            }

            // СУЩЕСТВУЮЩАЯ ЛОГИКА: Проверяем соответствие городов
            // (для групп с заполненными списками городов, например "Ростовская область")
            // Если у группы нет городов (как у "Любые маршруты"), пропускаем эту проверку
            if (_selectedGroup!.originCities.isEmpty ||
                _selectedGroup!.destinationCities.isEmpty) {
              // Группа без городов - только по groupId
              return false;
            }

            // Проверяем соответствие городов отправления
            final fromMatch = _selectedGroup!.originCities.any(
              (city) =>
                  route.fromCity.toLowerCase().contains(city.toLowerCase()),
            );
            // Проверяем соответствие городов назначения
            final toMatch = _selectedGroup!.destinationCities.any(
              (city) => route.toCity.toLowerCase().contains(city.toLowerCase()),
            );

            // Если включено автореверсирование, проверяем и обратное направление
            if (_selectedGroup!.autoGenerateReverse) {
              final reverseFromMatch = _selectedGroup!.destinationCities.any(
                (city) =>
                    route.fromCity.toLowerCase().contains(city.toLowerCase()),
              );
              final reverseToMatch = _selectedGroup!.originCities.any(
                (city) =>
                    route.toCity.toLowerCase().contains(city.toLowerCase()),
              );
              return (fromMatch && toMatch) ||
                  (reverseFromMatch && reverseToMatch);
            }

            return fromMatch && toMatch;
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildGroupsSection(displayedRoutes.length),
          const SizedBox(height: 24),
          _buildAddRouteSection(),
          const SizedBox(height: 32),
          _buildRoutesListSection(displayedRoutes),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Управление маршрутами',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: widget.theme.label,
      ),
    );
  }

  Widget _buildGroupsSection(int filteredCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статистика
          Row(
            children: [
              _StatItem(
                icon: CupertinoIcons.square_grid_2x2,
                label: 'Групп',
                value: '${_groups.length}',
                theme: widget.theme,
              ),
              const SizedBox(width: 16),
              _StatItem(
                icon: CupertinoIcons.arrow_right_circle,
                label: _selectedGroup == null
                    ? 'Всего маршрутов'
                    : 'Отфильтровано',
                value: '$filteredCount',
                theme: widget.theme,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Кнопка "Все маршруты"
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedGroup = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedGroup == null
                    ? widget.theme.primary.withOpacity(0.1)
                    : widget.theme.systemBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedGroup == null
                      ? widget.theme.primary
                      : widget.theme.separator,
                  width: _selectedGroup == null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.list_bullet,
                    color: _selectedGroup == null
                        ? widget.theme.primary
                        : widget.theme.label,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Все маршруты',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _selectedGroup == null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedGroup == null
                            ? widget.theme.primary
                            : widget.theme.label,
                      ),
                    ),
                  ),
                  Text(
                    '${_routes.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedGroup == null
                          ? widget.theme.primary
                          : widget.theme.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Список групп
          ...List.generate(_groups.length, (index) {
            final group = _groups[index];
            final isSelected = _selectedGroup?.name == group.name;
            final groupRoutesCount = _routes.where((route) {
              // ВАЖНО: Сначала проверяем, назначен ли маршрут явно к этой группе по groupId
              if (route.groupId != null && route.groupId == group.id) {
                return true;
              }

              // Если у группы нет городов — маршруты попадают только по groupId
              if (group.originCities.isEmpty ||
                  group.destinationCities.isEmpty) {
                return false;
              }

              // Строгая проверка: маршрут принадлежит группе, если
              // fromCity соответствует originCities И toCity соответствует destinationCities
              // ИЛИ (если autoGenerateReverse) обратное направление
              final fromMatch = group.originCities.any(
                (city) =>
                    route.fromCity.toLowerCase().contains(city.toLowerCase()),
              );
              final toMatch = group.destinationCities.any(
                (city) =>
                    route.toCity.toLowerCase().contains(city.toLowerCase()),
              );

              if (group.autoGenerateReverse) {
                final reverseFromMatch = group.destinationCities.any(
                  (city) =>
                      route.fromCity.toLowerCase().contains(city.toLowerCase()),
                );
                final reverseToMatch = group.originCities.any(
                  (city) =>
                      route.toCity.toLowerCase().contains(city.toLowerCase()),
                );
                return (fromMatch && toMatch) ||
                    (reverseFromMatch && reverseToMatch);
              }

              return fromMatch && toMatch;
            }).length;

            return Padding(
              padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    // Переключение: если группа уже выбрана, снимаем выбор
                    _selectedGroup = isSelected ? null : group;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.theme.primary.withOpacity(0.1)
                        : widget.theme.systemBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? widget.theme.primary
                          : widget.theme.separator,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? widget.theme.primary
                                    : widget.theme.label,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$groupRoutesCount маршрут${_getRoutesSuffix(groupRoutesCount)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.theme.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          color: widget.theme.secondaryLabel,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) =>
                                  RouteGroupDetailsScreen(group: group),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getRoutesSuffix(int count) {
    if (count % 10 == 1 && count % 100 != 11) return '';
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20))
      return 'а';
    return 'ов';
  }

  Widget _buildAddRouteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.add_circled,
                color: widget.theme.systemGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Добавить новый маршрут',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🔧 РАБОЧИЙ SimpleAddressField для "Откуда"
          SimpleAddressField(
            label: 'Откуда',
            initialValue: _selectedFromCity,
            onAddressSelected: (address) {
              setState(() {
                _selectedFromCity = address;
              });
              print('✅ Выбран адрес "Откуда": $address');
            },
            // 🆕 Callback с координатами для отображения на карте
            onAddressWithCoordinatesSelected: (address, coordinates) {
              setState(() {
                _selectedFromCity = address;
              });
              _updateFromPoint(coordinates);
              print(
                '📍 Выбран адрес "Откуда" с координатами: $address -> ${coordinates?.latitude}, ${coordinates?.longitude}',
              );
            },
          ),
          const SizedBox(height: 12),

          // 🗺️ Карта с маркерами и маршрутом (как в IndividualBookingScreen)
          // Показываем только когда есть хотя бы одна координата
          Visibility(
            visible: _fromPoint != null || _toPoint != null,
            maintainState: true, // Карта остается в памяти даже когда невидима
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.theme.separator.withOpacity(0.3),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 1.2, // Пропорции как в IndividualBookingScreen
                child: FlutterMapWidget(
                  onMapCreated: _onMapCreated,
                  onMapDispose: () {
                    _mapWindow = null;
                    _routePointsManager = null;
                    _routesCollection = null;
                  },
                ),
              ),
            ),
          ),

          // 🔧 РАБОЧИЙ SimpleAddressField для "Куда"
          SimpleAddressField(
            label: 'Куда',
            initialValue: _selectedToCity,
            onAddressSelected: (address) {
              setState(() {
                _selectedToCity = address;
              });
              print('✅ Выбран адрес "Куда": $address');
            },
            // 🆕 Callback с координатами для отображения на карте
            onAddressWithCoordinatesSelected: (address, coordinates) {
              setState(() {
                _selectedToCity = address;
              });
              _updateToPoint(coordinates);
              print(
                '📍 Выбран адрес "Куда" с координатами: $address -> ${coordinates?.latitude}, ${coordinates?.longitude}',
              );
            },
          ),
          const SizedBox(height: 12),

          // Выбор группы маршрута
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Группа маршрута',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.theme.label,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showGroupPicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.theme.systemBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.separator),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.folder,
                        color: widget.theme.secondaryLabel,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedGroupForNewRoute?.name ?? 'Выберите группу',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedGroupForNewRoute != null
                                ? widget.theme.label
                                : widget.theme.secondaryLabel,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_down,
                        color: widget.theme.secondaryLabel,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildInputField(
            'Цена (₽)',
            _priceController,
            'Например: 50000',
            CupertinoIcons.money_dollar_circle,
            isNumeric: true,
          ),
          const SizedBox(height: 20),

          // Кнопки: Очистить + Добавить маршрут
          Row(
            children: [
              // Кнопка "Очистить" (корзина)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: widget.theme.systemRed.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                onPressed: _clearForm,
                child: const Icon(
                  CupertinoIcons.trash,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Кнопка "Добавить маршрут"
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: _isSaving ? null : _addRoute,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CupertinoActivityIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Добавить маршрут',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String placeholder,
    IconData icon, {
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: widget.theme.label,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.theme.systemBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.theme.separator),
          ),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(icon, color: widget.theme.secondaryLabel, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutesListSection(List<PredefinedRoute> displayedRoutes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedGroup == null
                  ? 'Все маршруты (${displayedRoutes.length})'
                  : '${_selectedGroup!.name} (${displayedRoutes.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.theme.label,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: widget.theme.systemGreen,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.refresh, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Обновить', style: TextStyle(color: Colors.white)),
                ],
              ),
              onPressed: _loadRoutes,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CupertinoActivityIndicator(),
            ),
          )
        else if (displayedRoutes.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: widget.theme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.arrow_right_circle,
                  size: 48,
                  color: widget.theme.secondaryLabel,
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedGroup == null
                      ? 'Маршруты не найдены'
                      : 'Нет маршрутов в группе "${_selectedGroup!.name}"',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.theme.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedGroup == null
                      ? 'Добавьте первый маршрут с помощью формы выше'
                      : 'Добавьте маршруты соответствующие этой группе',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.theme.tertiaryLabel,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedRoutes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildRouteCard(displayedRoutes[index]),
          ),
      ],
    );
  }

  Widget _buildRouteCard(PredefinedRoute route) {
    // Находим группу маршрута
    final routeGroup = route.groupId != null
        ? _groups.firstWhere(
            (g) => g.id == route.groupId,
            orElse: () => RouteGroup(
              id: 'unknown',
              name: 'Без группы',
              description: '',
              originCities: [],
              destinationCities: [],
              basePrice: 0,
              autoGenerateReverse: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.separator),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.theme.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.arrow_right,
              color: widget.theme.systemBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route.fromCity} → ${route.toCity}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.label,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${route.price.toStringAsFixed(0)}₽',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.systemGreen,
                      ),
                    ),
                    if (routeGroup != null) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.theme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.theme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.folder_fill,
                                size: 12,
                                color: widget.theme.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  routeGroup.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: widget.theme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Создан: ${_formatDate(route.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.theme.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),

          CupertinoButton(
            padding: const EdgeInsets.all(8),
            child: Icon(
              CupertinoIcons.pencil_circle,
              color: widget.theme.warning,
            ),
            onPressed: () => _editRoute(route),
          ),

          CupertinoButton(
            padding: const EdgeInsets.all(8),
            child: Icon(CupertinoIcons.delete, color: widget.theme.danger),
            onPressed: () => _confirmDeleteRoute(route),
          ),
        ],
      ),
    );
  }

  /// Показать выбор группы для нового маршрута
  void _showGroupPicker() {
    // Если группа не выбрана, устанавливаем первую группу по умолчанию
    final initialIndex = _selectedGroupForNewRoute != null
        ? _groups.indexOf(_selectedGroupForNewRoute!)
        : 0;
    RouteGroup? tempSelectedGroup = _groups.isNotEmpty
        ? _groups[initialIndex >= 0 ? initialIndex : 0]
        : null;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Шапка с кнопкой "Выбрать"
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Отмена',
                        style: TextStyle(color: CupertinoColors.systemRed),
                      ),
                    ),
                    const Text(
                      'Выберите группу',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _selectedGroupForNewRoute = tempSelectedGroup;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Выбрать',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              // Пикер
              Expanded(
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex >= 0 ? initialIndex : 0,
                  ),
                  onSelectedItemChanged: (int selectedItem) {
                    tempSelectedGroup = _groups[selectedItem];
                  },
                  children: List<Widget>.generate(_groups.length, (int index) {
                    return Center(
                      child: Text(
                        _groups[index].name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addRoute() async {
    final fromCity = _selectedFromCity.trim();
    final toCity = _selectedToCity.trim();
    final priceText = _priceController.text.trim();

    if (fromCity.isEmpty || toCity.isEmpty || priceText.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    if (_selectedGroupForNewRoute == null) {
      _showError('Выберите группу маршрута');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError('Введите корректную цену');
      return;
    }

    print('🔍 [DEBUG] RouteManagementWidget._addRoute():');
    print('   fromCity: $fromCity');
    print('   toCity: $toCity');
    print('   price: $price');
    print('   _selectedGroupForNewRoute: ${_selectedGroupForNewRoute?.name}');
    print('   groupId to pass: ${_selectedGroupForNewRoute?.id}');

    setState(() {
      _isSaving = true;
    });

    try {
      await _routeService.addRoute(
        fromCity: fromCity,
        toCity: toCity,
        routeGroupId: _selectedGroupForNewRoute!.id,
        stopsData: [], // ⚠️ TODO: передавать остановки из UI
        basePrice: price,
      );

      // Очищаем форму
      setState(() {
        _selectedFromCity = '';
        _selectedToCity = '';
        _selectedGroupForNewRoute = null; // Сбрасываем выбранную группу
        // 🆕 Очищаем точки и маршрут на карте
        _fromPoint = null;
        _toPoint = null;
      });
      _priceController.clear();
      // 🆕 Очищаем маркеры и маршрут на карте
      _routePointsManager?.removePoint(RoutePointType.from);
      _routePointsManager?.removePoint(RoutePointType.to);
      _routesCollection?.clear();

      // Перезагружаем список
      await _loadRoutes();

      _showSuccess('Маршрут "$fromCity → $toCity" добавлен');
    } catch (e) {
      _showError('Маршрут добавлен локально. Firebase недоступен: $e');
      // Все равно очищаем форму и перезагружаем, так как данные могут быть сохранены локально
      setState(() {
        _selectedFromCity = '';
        _selectedToCity = '';
        // 🆕 Очищаем точки карты
        _fromPoint = null;
        _toPoint = null;
      });
      _priceController.clear();
      // 🆕 Очищаем маркеры и маршрут на карте
      _routePointsManager?.removePoint(RoutePointType.from);
      _routePointsManager?.removePoint(RoutePointType.to);
      _routesCollection?.clear();
      await _loadRoutes();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _editRoute(PredefinedRoute route) async {
    // Показываем диалог редактирования
    final result = await showCupertinoDialog(
      context: context,
      builder: (context) =>
          _EditRouteDialog(route: route, theme: widget.theme, groups: _groups),
    );

    if (result != null) {
      try {
        final updatedRoute = route.copyWith(
          fromCity: result['fromCity'],
          toCity: result['toCity'],
          price: result['price'],
          groupId: result['groupId'],
        );

        await _routeService.updateRoute(updatedRoute);

        await _loadRoutes();
        _showSuccess('Маршрут обновлён');
      } catch (e) {
        _showError('Ошибка обновления маршрута: $e');
      }
    }
  }

  Future<void> _confirmDeleteRoute(PredefinedRoute route) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить маршрут'),
        content: Text(
          'Вы уверены, что хотите удалить маршрут "${route.fromCity} → ${route.toCity}"?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _routeService.deleteRoute(route.id);
        await _loadRoutes();
        _showSuccess('Маршрут удалён');
      } catch (e) {
        _showError('Ошибка удаления маршрута: $e');
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Диалог для редактирования маршрута
class _EditRouteDialog extends StatefulWidget {
  final PredefinedRoute route;
  final dynamic theme;
  final List<RouteGroup> groups;

  const _EditRouteDialog({
    required this.route,
    required this.theme,
    required this.groups,
  });

  @override
  State<_EditRouteDialog> createState() => _EditRouteDialogState();
}

class _EditRouteDialogState extends State<_EditRouteDialog> {
  late String _selectedFromCity;
  late String _selectedToCity;
  late final TextEditingController _priceController;
  RouteGroup? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _selectedFromCity = widget.route.fromCity;
    _selectedToCity = widget.route.toCity;
    _priceController = TextEditingController(
      text: widget.route.price.toInt().toString(),
    );

    // Найти текущую группу маршрута
    if (widget.route.groupId != null && widget.groups.isNotEmpty) {
      _selectedGroup = widget.groups.cast<RouteGroup?>().firstWhere(
        (g) => g?.id == widget.route.groupId,
        orElse: () => null,
      );
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _showGroupPicker() {
    if (widget.groups.isEmpty) return;

    // Вычисляем начальный индекс
    final initialIndex = _selectedGroup != null
        ? widget.groups.indexWhere((g) => g.id == _selectedGroup!.id)
        : 0;

    // Инициализируем временную выбранную группу
    RouteGroup tempSelectedGroup =
        widget.groups[initialIndex >= 0 ? initialIndex : 0];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // Шапка с кнопками
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Отмена'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Готово'),
                    onPressed: () {
                      setState(() {
                        _selectedGroup = tempSelectedGroup;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // Picker
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex >= 0 ? initialIndex : 0,
                ),
                onSelectedItemChanged: (index) {
                  tempSelectedGroup = widget.groups[index];
                },
                children: widget.groups.map((group) {
                  return Center(
                    child: Text(
                      group.name,
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Редактировать маршрут',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),

            // Содержимое с полями ввода
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔧 SimpleAddressField для "Откуда" с подсказками от Яндекс API
                  SimpleAddressField(
                    label: 'Откуда',
                    initialValue: _selectedFromCity,
                    onAddressSelected: (address) {
                      setState(() {
                        _selectedFromCity = address;
                      });
                      print('✅ [EDIT] Выбран адрес "Откуда": $address');
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🔧 SimpleAddressField для "Куда" с подсказками от Яндекс API
                  SimpleAddressField(
                    label: 'Куда',
                    initialValue: _selectedToCity,
                    onAddressSelected: (address) {
                      setState(() {
                        _selectedToCity = address;
                      });
                      print('✅ [EDIT] Выбран адрес "Куда": $address');
                    },
                  ),
                  const SizedBox(height: 12),

                  CupertinoTextField(
                    controller: _priceController,
                    placeholder: 'Цена (₽)',
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Выбор группы маршрута
                  if (widget.groups.isNotEmpty)
                    GestureDetector(
                      onTap: _showGroupPicker,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.folder,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedGroup?.name ?? 'Выберите группу',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedGroup != null
                                      ? CupertinoColors.label.resolveFrom(
                                          context,
                                        )
                                      : CupertinoColors.placeholderText
                                            .resolveFrom(context),
                                ),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_down,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Разделитель
            Container(
              height: 0.5,
              color: CupertinoColors.separator.resolveFrom(context),
            ),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Отмена',
                      style: TextStyle(
                        color: CupertinoColors.systemBlue.resolveFrom(context),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 50,
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Сохранить',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemBlue.resolveFrom(context),
                      ),
                    ),
                    onPressed: () {
                      final fromCity = _selectedFromCity.trim();
                      final toCity = _selectedToCity.trim();
                      final price = double.tryParse(
                        _priceController.text.trim(),
                      );

                      if (fromCity.isEmpty ||
                          toCity.isEmpty ||
                          price == null ||
                          price <= 0) {
                        return;
                      }

                      Navigator.pop(context, {
                        'fromCity': fromCity,
                        'toCity': toCity,
                        'price': price,
                        'groupId': _selectedGroup?.id,
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет для отображения статистики
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final dynamic theme;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.systemBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.separator),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.label,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: theme.secondaryLabel),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
