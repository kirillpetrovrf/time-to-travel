import 'package:flutter/cupertino.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' hide TextStyle, Icon;
import 'package:yandex_maps_mapkit/yandex_map.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../../services/yandex_maps_service.dart';
import '../../../services/price_calculator_service.dart';
import '../../../services/calculator_settings_service.dart';
import '../../../models/calculator_settings.dart';
import '../../../models/price_calculation.dart';

/// Экран "Свободный маршрут" с картой как в Яндекс.Такси
class CustomRouteWithMapScreen extends StatefulWidget {
  const CustomRouteWithMapScreen({super.key});

  @override
  State<CustomRouteWithMapScreen> createState() =>
      _CustomRouteWithMapScreenState();
}

// Реализация MapCameraListener
class _CameraListenerImpl implements MapCameraListener {
  final Function(VisibleRegion) onRegionChanged;

  _CameraListenerImpl(this.onRegionChanged);

  @override
  void onCameraPositionChanged(
    Map map,
    CameraPosition cameraPosition,
    CameraUpdateReason cameraUpdateReason,
    bool finished,
  ) {
    if (finished) {
      onRegionChanged(map.visibleRegion);
    }
  }
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

  // Карта
  MapWindow? _mapWindow;
  VisibleRegion? _visibleRegion;

  // UI состояние
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
    super.dispose();
  }

  void _onMapCreated(MapWindow mapWindow) {
    _mapWindow = mapWindow;

    print('🗺️ [MAP] ========== ИНИЦИАЛИЗАЦИЯ КАРТЫ ==========');
    print('🗺️ [MAP] MapWindow создан: ${_mapWindow != null}');
    print('🗺️ [MAP] Map объект: ${_mapWindow?.map != null}');

    try {
      // Проверяем доступность карты
      final map = _mapWindow!.map;
      print('🗺️ [MAP] ✅ Map объект доступен');

      // 🔧 ЭКСПЕРИМЕНТ: Попробуем переключить на растровую карту (может помочь с тайлами)
      try {
        map.mapType = MapType.Map;
        print('🗺️ [MAP] 🔧 Переключено на MapType.Map (растровая карта)');
      } catch (e) {
        print('🗺️ [MAP] ⚠️ Не удалось переключить тип карты: $e');
      }

      // Устанавливаем начальную позицию на Пермь
      final permPoint = const Point(latitude: 58.0105, longitude: 56.2502);
      print('🗺️ [MAP] Перемещаем камеру на: $permPoint');

      map.move(CameraPosition(permPoint, zoom: 11.0, azimuth: 0.0, tilt: 0.0));
      print('🗺️ [MAP] ✅ Камера перемещена');

      // Проверяем доступность logo
      print('🗺️ [MAP] Проверяем настройки карты...');
      print('🗺️ [MAP] Logo доступен: ${map.logo != null}');

      // 🔍 ДИАГНОСТИКА: Проверяем состояние карты
      print('🗺️ [MAP] 🔍 ДИАГНОСТИКА КАРТЫ:');
      print('🗺️ [MAP] 🔍 MapType: ${map.mapType}');
      print('🗺️ [MAP] 🔍 Камера: ${map.cameraPosition}');
      print('🗺️ [MAP] 🔍 Видимая область: ${map.visibleRegion}');

      // 🔍 Проверяем тайлы и кеш
      print('🗺️ [MAP] ⚠️ ВНИМАНИЕ: Если тайлы не загружаются:');
      print('🗺️ [MAP] ⚠️ 1. Проверьте интернет-соединение');
      print('🗺️ [MAP] ⚠️ 2. Проверьте API-ключ Yandex Maps');
      print('🗺️ [MAP] ⚠️ 3. Проверьте сетевые разрешения Android');
      print('🗺️ [MAP] ⚠️ 4. Поищите в логах "No available cache for request"');

      // Подписываемся на изменения видимой области
      final cameraListener = _CameraListenerImpl((region) {
        if (mounted) {
          setState(() {
            _visibleRegion = region;
            print(
              '🗺️ [MAP] 📍 Видимая область обновлена: ${region.bottomLeft} - ${region.topRight}',
            );
          });
        }
      });
      map.addCameraListener(cameraListener);
      print('🗺️ [MAP] ✅ CameraListener добавлен');

      // Сохраняем начальную видимую область
      final initialRegion = map.visibleRegion;
      print(
        '🗺️ [MAP] Начальная видимая область: ${initialRegion.bottomLeft} - ${initialRegion.topRight}',
      );

      setState(() {
        _visibleRegion = initialRegion;
        _isMapReady = true;
      });

      print('🗺️ [MAP] ========== ✅ КАРТА ГОТОВА К РАБОТЕ ==========');

      // Ждём 3 секунды и проверяем, загрузились ли тайлы
      Future.delayed(const Duration(seconds: 3), () {
        print('🗺️ [MAP] 🔍 ПРОВЕРКА ПОСЛЕ 3 СЕКУНД:');
        print('🗺️ [MAP] 🔍 Если вы видите только сетку без изображения:');
        print('🗺️ [MAP] 🔍 ❌ Тайлы НЕ ЗАГРУЗИЛИСЬ от Yandex API');
        print('🗺️ [MAP] 🔍 Проверьте логи на наличие ошибок:');
        print('🗺️ [MAP] 🔍 - "No available cache for request"');
        print('🗺️ [MAP] 🔍 - "HTTP" или "SSL" ошибки');
        print('🗺️ [MAP] 🔍 - "Connection" ошибки');
      });
    } catch (e, stackTrace) {
      print('🗺️ [MAP] ❌ ОШИБКА при инициализации карты:');
      print('🗺️ [MAP] Ошибка: $e');
      print('🗺️ [MAP] StackTrace: $stackTrace');
    }
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
          // Карта на весь экран
          YandexMap(onMapCreated: _onMapCreated),

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
