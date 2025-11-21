import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Добавлено для SystemChrome
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;
import 'package:yandex_maps_mapkit/mapkit_factory.dart' as mapkit_factory;
import 'package:yandex_maps_mapkit/yandex_map.dart';
import '../../../theme/theme_manager.dart';
import '../../../services/yandex_maps_service.dart';
import '../../../services/price_calculator_service.dart';
import '../../../services/database_service.dart'; // Добавлено для работы с БД
import '../../../models/price_calculation.dart';
import '../../../models/ride.dart'; // Добавлено для модели Ride
import '../../rides/screens/ride_detail_screen.dart'; // Добавлено для перехода на детали поездки

/// Экран создания поездки с картой и расчетом стоимости
class CreateRideWithMapScreen extends StatefulWidget {
  const CreateRideWithMapScreen({super.key});

  @override
  State<CreateRideWithMapScreen> createState() =>
      _CreateRideWithMapScreenState();
}

class _CreateRideWithMapScreenState extends State<CreateRideWithMapScreen>
    with WidgetsBindingObserver {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  final YandexMapsService _mapsService = YandexMapsService.instance;
  final PriceCalculatorService _priceService = PriceCalculatorService.instance;

  bool _isCalculating = false;
  PriceCalculation? _calculation;
  double? _distanceKm;
  String? _errorMessage;

  mapkit.MapWindow? _mapWindow;
  bool _isMapReady = false;
  bool _isMapStarted = false; // Флаг для предотвращения двойного старта

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isMapStarted) {
      mapkit_factory.mapkit.onStop();
      _isMapStarted = false;
    }
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isMapStarted) {
      mapkit_factory.mapkit.onStart();
    } else if (state == AppLifecycleState.paused && _isMapStarted) {
      mapkit_factory.mapkit.onStop();
    }
  }

  void _onMapCreated(mapkit.MapWindow mapWindow) async {
    _mapWindow = mapWindow;

    print('🗺️ [CREATE_RIDE] MapWindow создан');

    try {
      // Запускаем отрисовку карты ТОЛЬКО ОДИН РАЗ
      if (!_isMapStarted) {
        mapkit_factory.mapkit.onStart();
        _isMapStarted = true;
        print('✅ [CREATE_RIDE] MapKit запущен');
      }

      // Задержка для инициализации рендера
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Устанавливаем начальную позицию на Пермь
      final permPoint = mapkit.Point(latitude: 58.0105, longitude: 56.2502);

      _mapWindow!.map.move(
        mapkit.CameraPosition(permPoint, zoom: 11.0, azimuth: 0.0, tilt: 0.0),
      );

      // Небольшая задержка перед показом UI
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      setState(() {
        _isMapReady = true;
      });

      print('✅ [CREATE_RIDE] Карта готова');
    } catch (e, stackTrace) {
      print('❌ [CREATE_RIDE] Ошибка инициализации карты: $e');
      print('StackTrace: $stackTrace');
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
      print('🗺️ [CREATE_RIDE] Начинаем расчет маршрута...');
      print('🗺️ [CREATE_RIDE] Откуда: $from');
      print('🗺️ [CREATE_RIDE] Куда: $to');

      // 1. Получаем маршрут через Yandex API
      final routeInfo = await _mapsService.calculateRoute(from, to);

      if (routeInfo == null) {
        throw Exception('Не удалось построить маршрут');
      }

      print('✅ [CREATE_RIDE] Маршрут получен: ${routeInfo.distance} км');

      // 2. Рассчитываем стоимость
      final calculation = await _priceService.calculatePrice(
        routeInfo.distance,
      );

      print('💰 [CREATE_RIDE] Стоимость: ${calculation.finalPrice}₽');

      // Небольшая задержка перед обновлением UI
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      setState(() {
        _calculation = calculation;
        _distanceKm = routeInfo.distance;
        _isCalculating = false;
      });
    } catch (e) {
      print('❌ [CREATE_RIDE] Ошибка: $e');
      setState(() {
        _errorMessage = 'Не удалось построить маршрут: ${e.toString()}';
        _isCalculating = false;
      });
    }
  }

  void _bookTrip() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Создание поездки'),
        content: Text(
          'Создать поездку?\n\n'
          'Откуда: ${_fromController.text}\n'
          'Куда: ${_toController.text}\n'
          'Расстояние: ${_distanceKm?.toStringAsFixed(1)} км\n'
          'Стоимость: ${_calculation?.finalPrice}₽',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Создать'),
            onPressed: () async {
              Navigator.pop(context); // Закрываем диалог
              await _createRideInDatabase(); // Создаем поездку в БД
            },
          ),
        ],
      ),
    );
  }

  /// Создание поездки в базе данных
  Future<void> _createRideInDatabase() async {
    if (_calculation == null || _distanceKm == null) {
      _showErrorDialog('Ошибка', 'Сначала рассчитайте маршрут');
      return;
    }

    try {
      setState(() => _isCalculating = true);

      print('🚀 [CREATE_RIDE] Создаем поездку в базе данных...');

      // В реальном приложении здесь данные текущего водителя
      const currentDriverId = 'driver_1';
      const currentDriverName = 'Алексей';
      const currentDriverPhone = '+7 (999) 111-22-33';

      // Создаем поездку
      final ride = Ride(
        id: DatabaseService.instance.generateId(),
        driverId: currentDriverId,
        driverName: currentDriverName,
        driverPhone: currentDriverPhone,
        fromAddress: _fromController.text.trim(),
        toAddress: _toController.text.trim(),
        fromDistrict: 'Центр', // TODO: определять автоматически
        toDistrict: 'Центр',
        fromDetails: _fromController.text.trim(),
        toDetails: _toController.text.trim(),
        departureTime: DateTime.now().add(
          const Duration(hours: 1),
        ), // TODO: выбор даты
        availableSeats: 3,
        totalSeats: 3,
        pricePerSeat: _calculation!.finalPrice,
        status: RideStatus.active,
        description: 'Поездка создана через карту',
        createdAt: DateTime.now(),
      );

      // Сохраняем в БД
      await DatabaseService.instance.createRide(ride);

      print('✅ [CREATE_RIDE] Поездка успешно создана!');

      setState(() => _isCalculating = false);

      // Показываем успех и переходим на экран деталей
      _showSuccessDialog(ride);
    } catch (e) {
      print('❌ [CREATE_RIDE] Ошибка создания поездки: $e');
      setState(() => _isCalculating = false);
      _showErrorDialog('Ошибка', 'Не удалось создать поездку: $e');
    }
  }

  void _showSuccessDialog(Ride createdRide) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Theme(
        data: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.light,
          ),
        ),
        child: CupertinoAlertDialog(
          title: const Text('Успешно!'),
          content: Text(
            'Поездка создана!\n\n'
            '${createdRide.fromAddress} → ${createdRide.toAddress}\n'
            'Стоимость: ${createdRide.pricePerSeat.toInt()} ₽',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Посмотреть'),
              onPressed: () async {
                print('🛑 [CREATE_RIDE] Останавливаем MapKit перед закрытием');

                // КРИТИЧНО: останавливаем карту ПЕРЕД Navigator.pop()
                if (_isMapStarted) {
                  mapkit_factory.mapkit.onStop();
                  _isMapStarted = false;
                  print('✅ [CREATE_RIDE] MapKit остановлен');
                }

                // Даем время на остановку рендера
                await Future.delayed(const Duration(milliseconds: 150));

                if (!mounted) return;

                // Закрываем диалог
                Navigator.pop(context);

                // Небольшая задержка
                await Future.delayed(const Duration(milliseconds: 50));

                if (!mounted) return;

                // Закрываем экран CreateRide (возвращаемся на главную с нижней навигацией)
                Navigator.pop(context);

                // Небольшая задержка перед открытием деталей
                await Future.delayed(const Duration(milliseconds: 150));

                if (!mounted) return;

                // Переходим на экран деталей поездки (внутри текущего таба, нижнее меню останется видимым)
                Navigator.of(context, rootNavigator: false).push(
                  CupertinoPageRoute(
                    builder: (context) => RideDetailScreen(ride: createdRide),
                  ),
                );

                print('✅ [CREATE_RIDE] Перешли на экран деталей поездки');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
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

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: const Text('Создать поездку'),
      ),
      child: Stack(
        children: [
          // Карта на весь экран
          YandexMap(onMapCreated: _onMapCreated),

          // Оверлей с UI - используем SingleChildScrollView
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          color: Colors.black.withOpacity(0.1),
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
                                  color: Colors.white,
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

                  // Отступ вместо Spacer
                  const SizedBox(height: 16),

                  // Нижняя панель с результатом
                  if (_calculation != null || _errorMessage != null)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.systemBackground.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: _errorMessage != null
                          ? _buildErrorContent(theme)
                          : _buildResultContent(theme),
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

  Widget _buildErrorContent(theme) {
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

  Widget _buildResultContent(theme) {
    final calc = _calculation!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Расстояние и стоимость
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
                  '${calc.finalPrice.toInt()} ₽',
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

        const SizedBox(height: 16),

        // Кнопка создания поездки
        CupertinoButton.filled(
          onPressed: _bookTrip,
          child: const Text(
            'Создать поездку',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
