import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/route_stop.dart';
import '../../../models/trip_type.dart';
import '../../../models/booking.dart';
import '../../../models/user.dart';
import '../../../models/trip_settings.dart';
import '../../../models/baggage.dart';
import '../../../models/pet_info_v3.dart';
import '../../../models/passenger_info.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/trip_settings_service.dart';
import '../../../services/route_service.dart';
import '../../../theme/theme_manager.dart';
import '../../admin/screens/admin_panel_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../orders/screens/booking_detail_screen.dart';
import 'baggage_selection_screen_v3.dart';
import 'add_passenger_screen.dart';
import 'individual_booking_screen.dart';
import '../widgets/simple_pet_selection_sheet.dart';

class GroupBookingScreen extends StatefulWidget {
  final RouteStop? fromStop;
  final RouteStop? toStop;

  const GroupBookingScreen({super.key, this.fromStop, this.toStop});

  @override
  State<GroupBookingScreen> createState() => _GroupBookingScreenState();
}

class _GroupBookingScreenState extends State<GroupBookingScreen> {
  Direction _selectedDirection = Direction.donetskToRostov;
  DateTime?
  _selectedDate; // Изменено на nullable - пользователь должен выбрать дату
  String _selectedTime = '';
  String _selectedPickupPoint = '';
  List<PassengerInfo> _passengers = [];
  bool _isLoading = true;
  UserType? _userType;
  TripSettings? _tripSettings;
  final TripSettingsService _settingsService = TripSettingsService();

  // Выбор городов
  RouteStop? _selectedFromStop;
  RouteStop? _selectedToStop;
  List<RouteStop> _availableStops = [];

  // Багаж и животные
  List<BaggageItem> _selectedBaggage = [];
  List<PetInfo> _selectedPets = [];
  bool _hasVKDiscount = false;
  bool _baggageSelectionVisited =
      false; // Флаг: заходил ли пользователь в выбор багажа

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userType = await AuthService.instance.getUserType();
      final settings = await _settingsService.getCurrentSettings();

      // Загружаем доступные остановки
      final routeService = RouteService.instance;
      final stops = routeService.getRouteStops('donetsk_to_rostov');

      setState(() {
        _userType = userType;
        _tripSettings = settings;
        _availableStops = stops;

        // Устанавливаем начальные значения из переданных параметров или по умолчанию
        if (widget.fromStop != null && widget.toStop != null) {
          _selectedFromStop = widget.fromStop;
          _selectedToStop = widget.toStop;
        } else {
          // По умолчанию: Донецк → Ростов
          _selectedFromStop = stops.firstWhere((stop) => stop.id == 'donetsk');
          _selectedToStop = stops.firstWhere((stop) => stop.id == 'rostov');
        }

        _passengers = [
          PassengerInfo(
            type: PassengerType.adult,
          ), // Добавляем одного взрослого по умолчанию
        ];
        _isLoading = false;

        // НЕ устанавливаем начальные значения - пользователь должен выбрать сам
        // _selectedTime и _selectedPickupPoint остаются пустыми строками
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Ошибка загрузки настроек: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: theme.systemBackground,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: theme.secondarySystemBackground,
          middle: Text(
            'Групповая поездка',
            style: TextStyle(color: theme.label),
          ),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_tripSettings == null) {
      return CupertinoPageScaffold(
        backgroundColor: theme.systemBackground,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: theme.secondarySystemBackground,
          middle: Text(
            'Групповая поездка',
            style: TextStyle(color: theme.label),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 50,
                color: theme.secondaryLabel,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки настроек',
                style: TextStyle(fontSize: 18, color: theme.label),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: _loadData,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('Групповая поездка', style: TextStyle(color: theme.label)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Маршрут (выбор городов)
              _buildSectionTitle('Маршрут', theme),
              _buildRouteSelection(theme),
              const SizedBox(height: 24),

              // Дата
              _buildSectionTitle('Дата поездки', theme),
              _buildDatePicker(theme),

              const SizedBox(height: 24),

              // Время
              _buildSectionTitle('Время отправления', theme),
              _buildTimePicker(theme),

              const SizedBox(height: 24),

              // Место посадки (для всех направлений)
              _buildSectionTitle('Место посадки', theme),
              _buildPickupPointPicker(theme),

              const SizedBox(height: 24),

              // Количество пассажиров
              _buildSectionTitle('Количество пассажиров', theme),
              _buildPassengerCountPicker(theme),

              const SizedBox(height: 24),

              // Багаж
              _buildSectionTitle('Багаж', theme),
              _buildBaggageSection(theme),

              const SizedBox(height: 24),

              // Животные
              _buildSectionTitle('Животные', theme),
              _buildPetsSection(theme),

              const SizedBox(height: 24),

              // Стоимость
              _buildPricingSummary(theme),

              const SizedBox(height: 24),

              // Кнопка бронирования или сохранения
              CupertinoButton.filled(
                onPressed: _isLoading
                    ? null
                    : (_userType == UserType.dispatcher
                          ? _saveSettings
                          : _bookTrip),
                child: _isLoading
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : Text(
                        _userType == UserType.dispatcher
                            ? 'Сохранить настройки'
                            : 'Забронировать за ${_getTotalPrice().toInt()} ₽',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              // Отступ снизу для системных кнопок навигации
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.label,
        ),
      ),
    );
  }

  // Новый метод выбора маршрута через выпадающие списки
  Widget _buildRouteSelection(theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Откуда
          _buildStopSelector(
            theme: theme,
            label: 'Откуда',
            icon: CupertinoIcons.location,
            selectedStop: _selectedFromStop,
            onTap: () => _showFromStopPicker(theme),
          ),

          const SizedBox(height: 12),

          // Кнопка переключения направления
          Center(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _swapStops,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.arrow_up_arrow_down,
                  color: theme.primary,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Куда
          _buildStopSelector(
            theme: theme,
            label: 'Куда',
            icon: CupertinoIcons.location_solid,
            selectedStop: _selectedToStop,
            onTap: () => _showToStopPicker(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStopSelector({
    required theme,
    required String label,
    required IconData icon,
    required RouteStop? selectedStop,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.systemBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.separator.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: theme.secondaryLabel),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedStop?.name ?? 'Выберите город',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.label,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              color: theme.secondaryLabel,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _swapStops() {
    setState(() {
      final temp = _selectedFromStop;
      _selectedFromStop = _selectedToStop;
      _selectedToStop = temp;

      // Обновляем направление
      if (_selectedFromStop?.id == 'donetsk') {
        _selectedDirection = Direction.donetskToRostov;
      } else if (_selectedFromStop?.id == 'rostov') {
        _selectedDirection = Direction.rostovToDonetsk;
      }

      // Сбрасываем выбранное время и место посадки при смене направления
      _selectedTime = '';
      _selectedPickupPoint = '';
    });
  }

  void _showFromStopPicker(theme) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: theme.systemBackground,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.separator)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Отмена',
                      style: TextStyle(color: theme.primary),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Откуда',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.label,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Готово',
                      style: TextStyle(color: theme.primary),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: theme.systemBackground,
                itemExtent: 44,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedFromStop = _availableStops[index];

                    // Обновляем направление
                    if (_selectedFromStop?.id == 'donetsk') {
                      _selectedDirection = Direction.donetskToRostov;
                    } else if (_selectedFromStop?.id == 'rostov') {
                      _selectedDirection = Direction.rostovToDonetsk;
                    }

                    // Сбрасываем время и место посадки
                    _selectedTime = '';
                    _selectedPickupPoint = '';
                  });
                },
                scrollController: FixedExtentScrollController(
                  initialItem: _selectedFromStop != null
                      ? _availableStops.indexOf(_selectedFromStop!)
                      : 0,
                ),
                children: _availableStops
                    .map(
                      (stop) => Center(
                        child: Text(
                          stop.name,
                          style: TextStyle(fontSize: 18, color: theme.label),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToStopPicker(theme) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: theme.systemBackground,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.separator)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Отмена',
                      style: TextStyle(color: theme.primary),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Куда',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.label,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Готово',
                      style: TextStyle(color: theme.primary),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: theme.systemBackground,
                itemExtent: 44,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedToStop = _availableStops[index];

                    // Сбрасываем время и место посадки при смене направления
                    _selectedTime = '';
                    _selectedPickupPoint = '';
                  });
                },
                scrollController: FixedExtentScrollController(
                  initialItem: _selectedToStop != null
                      ? _availableStops.indexOf(_selectedToStop!)
                      : 1,
                ),
                children: _availableStops
                    .map(
                      (stop) => Center(
                        child: Text(
                          stop.name,
                          style: TextStyle(fontSize: 18, color: theme.label),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedDate != null
              ? theme.systemRed
              : theme.separator.withOpacity(0.2),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: () => _showDatePicker(),
        child: Row(
          children: [
            Icon(CupertinoIcons.calendar, color: theme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Выберите дату поездки'
                    : _formatDate(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null
                      ? theme.tertiaryLabel
                      : theme.label,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: theme.secondaryLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(theme) {
    final departureTimes = _tripSettings?.departureTimes ?? [];

    if (departureTimes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.separator.withOpacity(0.2)),
        ),
        child: Text(
          'Время отправления не настроено',
          style: TextStyle(color: theme.secondaryLabel),
          textAlign: TextAlign.center,
        ),
      );
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showTimePickerModal(theme),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedTime.isNotEmpty
                ? theme.systemRed
                : theme.separator.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.clock, color: theme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTime.isEmpty
                    ? 'Выберите время отправления'
                    : _selectedTime,
                style: TextStyle(
                  color: _selectedTime.isEmpty
                      ? theme.tertiaryLabel
                      : theme.label,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: theme.secondaryLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupPointPicker(theme) {
    // Получаем места посадки для выбранного города отправления
    final fromStopId = _selectedFromStop?.id ?? '';
    final pickupPoints = PickupPoints.getPickupPointsForCity(fromStopId);

    if (pickupPoints.isEmpty || _selectedFromStop == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.separator.withOpacity(0.2)),
        ),
        child: Text(
          'Сначала выберите город отправления',
          style: TextStyle(color: theme.secondaryLabel),
          textAlign: TextAlign.center,
        ),
      );
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showPickupPointModal(theme),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPickupPoint.isNotEmpty
                ? theme.systemRed
                : theme.separator.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.location, color: theme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedPickupPoint.isEmpty
                    ? 'Место посадки'
                    : _selectedPickupPoint,
                style: TextStyle(
                  color: _selectedPickupPoint.isEmpty
                      ? theme.tertiaryLabel
                      : theme.label,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: theme.secondaryLabel),
          ],
        ),
      ),
    );
  }

  void _showTimePickerModal(theme) {
    final departureTimes = _tripSettings?.departureTimes ?? [];

    // Временная переменная для хранения выбранного значения
    String tempSelectedTime = _selectedTime.isNotEmpty
        ? _selectedTime
        : departureTimes.first;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: theme.systemBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.separator)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Время отправления',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.label,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _selectedTime = tempSelectedTime;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Выбрать',
                      style: TextStyle(
                        color: theme.systemRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Список времени
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: _selectedTime.isNotEmpty
                      ? departureTimes.indexOf(_selectedTime)
                      : 0,
                ),
                onSelectedItemChanged: (index) {
                  tempSelectedTime = departureTimes[index];
                },
                children: departureTimes.map((time) {
                  return Center(
                    child: Text(
                      time,
                      style: TextStyle(fontSize: 20, color: theme.label),
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

  void _showPickupPointModal(theme) {
    // Получаем места посадки для выбранного города отправления
    final fromStopId = _selectedFromStop?.id ?? '';
    final pickupPoints = PickupPoints.getPickupPointsForCity(fromStopId);

    if (pickupPoints.isEmpty) {
      _showError('Места посадки не настроены для выбранного города');
      return;
    }

    // Временная переменная для хранения выбранного значения
    String tempSelectedPickupPoint = _selectedPickupPoint.isNotEmpty
        ? _selectedPickupPoint
        : pickupPoints.first;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: theme.systemBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.separator)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Место посадки',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.label,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.fromStop?.name ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _selectedPickupPoint = tempSelectedPickupPoint;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Выбрать',
                      style: TextStyle(
                        color: theme.systemRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Список мест посадки
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem:
                      _selectedPickupPoint.isNotEmpty &&
                          pickupPoints.contains(_selectedPickupPoint)
                      ? pickupPoints.indexOf(_selectedPickupPoint)
                      : 0,
                ),
                onSelectedItemChanged: (index) {
                  tempSelectedPickupPoint = pickupPoints[index];
                },
                children: pickupPoints.map((point) {
                  return Center(
                    child: Text(
                      point,
                      style: TextStyle(fontSize: 20, color: theme.label),
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

  Widget _buildPassengerCountPicker(theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Список пассажиров
          ..._passengers.asMap().entries.map((entry) {
            final index = entry.key;
            final passenger = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Divider(height: 1, color: theme.separator.withOpacity(0.2)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _editPassenger(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          passenger.type == PassengerType.adult
                              ? CupertinoIcons.person
                              : CupertinoIcons.smiley,
                          color: theme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                passenger.displayName,
                                style: TextStyle(
                                  color: theme.label,
                                  fontSize: 16,
                                ),
                              ),
                              if (passenger.seatInfo.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  passenger.seatInfo,
                                  style: TextStyle(
                                    color: theme.secondaryLabel,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _removePassenger(index),
                          child: Icon(
                            CupertinoIcons.trash,
                            color: theme.systemRed,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),

          // Кнопка добавить пассажира
          if (_passengers.length < (_tripSettings?.maxPassengers ?? 8)) ...[
            if (_passengers.isNotEmpty)
              Divider(height: 1, color: theme.separator.withOpacity(0.2)),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onPressed: _addPassenger,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add_circled, color: theme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Добавить пассажира',
                    style: TextStyle(color: theme.primary, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addPassenger() async {
    print('👥 [PASSENGERS] Добавление нового пассажира...');
    print('👥 [PASSENGERS] Текущее количество: ${_passengers.length}');
    final passenger = await Navigator.push<PassengerInfo>(
      context,
      CupertinoPageRoute(builder: (context) => const AddPassengerScreen()),
    );

    if (passenger != null) {
      setState(() {
        _passengers.add(passenger);
        print(
          '👥 [PASSENGERS] ✅ Пассажир добавлен! Новое количество: ${_passengers.length}',
        );
        print(
          '👥 [PASSENGERS] 🔄 Будет пересчитан багаж: ${_passengers.length * 2} бесплатных S',
        );
      });
    } else {
      print('👥 [PASSENGERS] ❌ Добавление отменено');
    }
  }

  Future<void> _editPassenger(int index) async {
    print('👥 [PASSENGERS] Редактирование пассажира #${index + 1}...');
    final passenger = await Navigator.push<PassengerInfo>(
      context,
      CupertinoPageRoute(
        builder: (context) =>
            AddPassengerScreen(initialPassenger: _passengers[index]),
      ),
    );

    if (passenger != null) {
      setState(() {
        _passengers[index] = passenger;
        print('👥 [PASSENGERS] ✅ Пассажир #${index + 1} обновлен');
      });
    } else {
      print('👥 [PASSENGERS] ❌ Редактирование отменено');
    }
  }

  void _removePassenger(int index) {
    print('👥 [PASSENGERS] Попытка удалить пассажира #${index + 1}...');
    print('👥 [PASSENGERS] Текущее количество: ${_passengers.length}');
    // Не позволяем удалить последнего пассажира
    if (_passengers.length <= 1) {
      print('👥 [PASSENGERS] ❌ Нельзя удалить последнего пассажира');
      _showError('Должен быть хотя бы один пассажир');
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить пассажира?'),
        content: Text(
          'Вы уверены, что хотите удалить ${_passengers[index].displayName}?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _passengers.removeAt(index);
                print(
                  '👥 [PASSENGERS] ✅ Пассажир удален! Новое количество: ${_passengers.length}',
                );
                print(
                  '👥 [PASSENGERS] 🔄 Будет пересчитан багаж: ${_passengers.length * 2} бесплатных S',
                );
              });
            },
          ),
        ],
      ),
    );
  }

  double _calculateChildSeatPrice() {
    // Автокресло водителя предоставляется бесплатно
    return 0.0;
  }

  Widget _buildPricingSummary(theme) {
    final groupPrice = _tripSettings?.pricing['groupTripPrice'] ?? 2000;
    final passengerCount = _passengers.length;
    final basePrice = groupPrice * passengerCount;
    final baggagePrice = _calculateBaggagePrice();
    final petPrice = _calculatePetPrice();
    final childSeatPrice = _calculateChildSeatPrice();
    final vkDiscount = _hasVKDiscount ? 30.0 : 0.0;
    final totalPrice =
        basePrice + baggagePrice + petPrice + childSeatPrice - vkDiscount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Итого к оплате:',
            style: TextStyle(fontSize: 16, color: theme.label),
          ),
          const SizedBox(height: 8),

          // Базовая стоимость
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$passengerCount × $groupPrice ₽',
                style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
              ),
              Text(
                '${basePrice.toInt()} ₽',
                style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
              ),
            ],
          ),

          // Багаж (если есть)
          if (baggagePrice > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Багаж',
                  style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                ),
                Text(
                  '+${baggagePrice.toInt()} ₽',
                  style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                ),
              ],
            ),
          ],

          // Животные (если есть)
          if (petPrice > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Животные',
                  style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                ),
                Text(
                  '+${petPrice.toInt()} ₽',
                  style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                ),
              ],
            ),
          ],

          // Детские кресла (если есть)
          if (childSeatPrice > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Детские кресла',
                  style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                ),
                Text(
                  '+${childSeatPrice.toInt()} ₽',
                  style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                ),
              ],
            ),
          ],

          // VK скидка (если есть)
          if (vkDiscount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Скидка VK',
                  style: TextStyle(fontSize: 16, color: theme.systemGreen),
                ),
                Text(
                  '-${vkDiscount.toInt()} ₽',
                  style: TextStyle(fontSize: 16, color: theme.systemGreen),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Итоговая сумма
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Итого:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
              Text(
                '${totalPrice.toInt()} ₽',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Оплата при посадке в автомобиль',
            style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Временная переменная для хранения выбранной даты
    DateTime tempSelectedDate = _selectedDate ?? today;

    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: theme.systemBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.separator)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Дата поездки',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.label,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _selectedDate = tempSelectedDate;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Выбрать',
                      style: TextStyle(
                        color: theme.systemRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempSelectedDate,
                minimumDate: today,
                maximumDate: today.add(const Duration(days: 30)),
                onDateTimeChanged: (date) {
                  tempSelectedDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaggageSection(theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _openBaggageSelection,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(CupertinoIcons.bag, color: theme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedBaggage.isEmpty
                          ? 'Выберите багаж'
                          : '${_getTotalBaggageCount()} ${_getBaggageCountText(_getTotalBaggageCount())}',
                      style: TextStyle(color: theme.label, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedBaggage.isNotEmpty
                          ? '+${_calculateBaggagePrice()} ₽'
                          : 'Размеры S, M, L, Custom',
                      style: TextStyle(
                        color: _selectedBaggage.isNotEmpty
                            ? theme.primary
                            : theme.secondaryLabel,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: theme.secondaryLabel,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetsSection(theme) {
    final bool hasPet = _selectedPets.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Переключатель "Везу животное"
            Row(
              children: [
                Icon(CupertinoIcons.paw, color: theme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Везу животное',
                    style: TextStyle(
                      color: theme.label,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                CupertinoSwitch(
                  value: hasPet,
                  onChanged: (value) {
                    if (value) {
                      // Включаем - открываем окно выбора
                      _openSimplePetSelection();
                    } else {
                      // Выключаем - удаляем животное
                      setState(() {
                        _selectedPets.clear();
                      });
                    }
                  },
                ),
              ],
            ),

            // Если животное выбрано - показываем карточку
            if (hasPet) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPetDisplayText(),
                            style: TextStyle(
                              color: theme.label,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${_calculatePetPrice().toInt()} ₽',
                            style: TextStyle(
                              color: theme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Изменить',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: _openSimplePetSelection,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPetDisplayText() {
    if (_selectedPets.isEmpty) return 'Не выбрано';

    final pet = _selectedPets.first;
    final categoryText = pet.categoryDescription;

    // Описание уже не содержит вес (новая логика)
    return categoryText;
  }

  String _getBaggageCountText(int count) {
    if (count == 1) return 'предмет багажа';
    if (count < 5) return 'предмета багажа';
    return 'предметов багажа';
  }

  int _getTotalBaggageCount() {
    return _selectedBaggage.fold(0, (sum, item) => sum + item.quantity);
  }

  double _calculateBaggagePrice() {
    print('💵 [GROUP] ========== РАСЧЕТ СТОИМОСТИ БАГАЖА ==========');
    print('💵 [GROUP] Количество пассажиров: ${_passengers.length}');
    print(
      '💵 [GROUP] Бесплатных S багажей: ${_passengers.length * 2} (${_passengers.length} × 2)',
    );
    // ФИНАЛЬНАЯ ЛОГИКА v8.0 (с учетом пассажиров):
    // Если ТОЛЬКО S: первые (passengerCount × 2) бесплатно, остальные по 500₽
    // Если есть M/L: ВСЕ S платно + один M/L бесплатно

    if (_selectedBaggage.isEmpty) {
      print('💵 [GROUP] Багаж не выбран, стоимость: 0₽');
      return 0.0;
    }

    // Подсчитываем количество каждого размера
    int sCount = 0, mCount = 0, lCount = 0, customCount = 0;
    double sPrice = 500.0, mPrice = 1000.0, lPrice = 2000.0, customPrice = 0.0;

    for (var item in _selectedBaggage) {
      switch (item.size) {
        case BaggageSize.s:
          sCount = item.quantity;
          sPrice = item.pricePerExtraItem;
          break;
        case BaggageSize.m:
          mCount = item.quantity;
          mPrice = item.pricePerExtraItem;
          break;
        case BaggageSize.l:
          lCount = item.quantity;
          lPrice = item.pricePerExtraItem;
          break;
        case BaggageSize.custom:
          customCount = item.quantity;
          customPrice = item.pricePerExtraItem;
          break;
      }
    }

    print(
      '💵 [GROUP] Состав: S=$sCount, M=$mCount, L=$lCount, Custom=$customCount',
    );

    // НОВАЯ ЛОГИКА v12.0: Каждый пассажир выбирает ОДИН вариант: 2S ИЛИ 1M ИЛИ 1L
    // Алгоритм распределения:
    // 1. Распределяем L (по 1 на пассажира)
    // 2. Распределяем M (по 1 на пассажира)
    // 3. Распределяем S (по 2 на пассажира)
    // 4. Остаток считаем платным

    int availablePassengers = _passengers.length;
    int remainingS = sCount;
    int remainingM = mCount;
    int remainingL = lCount;

    print('💵 [GROUP] --- РАСПРЕДЕЛЕНИЕ БАГАЖА ПО ПАССАЖИРАМ ---');

    // Шаг 1: Распределяем L (приоритет - самый дорогой)
    int passengersWithL = 0;
    if (remainingL > 0) {
      passengersWithL = remainingL <= availablePassengers
          ? remainingL
          : availablePassengers;
      availablePassengers -= passengersWithL;
      remainingL -= passengersWithL;
      print('💵 [GROUP] $passengersWithL пассажиров выбрали 1×L (бесплатно)');
    }

    // Шаг 2: Распределяем M
    int passengersWithM = 0;
    if (remainingM > 0 && availablePassengers > 0) {
      passengersWithM = remainingM <= availablePassengers
          ? remainingM
          : availablePassengers;
      availablePassengers -= passengersWithM;
      remainingM -= passengersWithM;
      print('💵 [GROUP] $passengersWithM пассажиров выбрали 1×M (бесплатно)');
    }

    // Шаг 3: Распределяем S по 2 штуки на пассажира
    int passengersWithS = 0;
    if (remainingS > 0 && availablePassengers > 0) {
      // Сколько пассажиров может выбрать 2×S?
      int maxPassengersForS = remainingS ~/ 2; // Делим нацело
      passengersWithS = maxPassengersForS <= availablePassengers
          ? maxPassengersForS
          : availablePassengers;
      availablePassengers -= passengersWithS;
      remainingS -= (passengersWithS * 2);
      print(
        '💵 [GROUP] $passengersWithS пассажиров выбрали 2×S (бесплатно, итого ${passengersWithS * 2} шт)',
      );
    }

    print('💵 [GROUP] Неиспользованных пассажиров: $availablePassengers');
    print(
      '💵 [GROUP] Остаток платного багажа: S=$remainingS, M=$remainingM, L=$remainingL',
    );

    // Шаг 4: Считаем стоимость платного багажа
    double total = 0.0;

    if (remainingS > 0) {
      double cost = remainingS * sPrice;
      total += cost;
      print(
        '💵 [GROUP] Платные S: $remainingS × ${sPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    if (remainingM > 0) {
      double cost = remainingM * mPrice;
      total += cost;
      print(
        '💵 [GROUP] Платные M: $remainingM × ${mPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    if (remainingL > 0) {
      double cost = remainingL * lPrice;
      total += cost;
      print(
        '💵 [GROUP] Платные L: $remainingL × ${lPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    // Custom всегда платно
    if (customCount > 0) {
      double cost = customCount * customPrice;
      total += cost;
      print(
        '💵 [GROUP] Custom: $customCount × ${customPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    print(
      '💵 [GROUP] ========== ИТОГО: ${total.toStringAsFixed(0)}₽ ==========',
    );
    return total;
  }

  double _calculatePetPrice() {
    return _selectedPets.fold(0.0, (sum, pet) => sum + pet.cost);
  }

  double _getTotalPrice() {
    final groupPrice = _tripSettings?.pricing['groupTripPrice'] ?? 2000;
    final passengerCount = _passengers.length;
    final basePrice = groupPrice * passengerCount;
    final baggagePrice = _calculateBaggagePrice();
    final petPrice = _calculatePetPrice();
    final childSeatPrice = _calculateChildSeatPrice();
    final vkDiscount = _hasVKDiscount ? 30.0 : 0.0;

    return basePrice + baggagePrice + petPrice + childSeatPrice - vkDiscount;
  }

  Future<void> _openBaggageSelection() async {
    print('🔍 _openBaggageSelection() вызван');
    print('🔍 Текущее количество пассажиров: ${_passengers.length}');
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BaggageSelectionScreen(
          initialBaggage: _selectedBaggage,
          passengerCount:
              _passengers.length, // ← Передаем количество пассажиров
          onBaggageSelected: (List<BaggageItem> baggage) {
            print('🔍 onBaggageSelected вызван');
            print('🔍 Получен багаж: ${baggage.length} предметов');
            setState(() {
              _selectedBaggage = baggage;
              final totalCount = _getTotalBaggageCount();
              print('🔍 Общее количество багажа: $totalCount');

              // Устанавливаем флаг ТОЛЬКО если пользователь выбрал хотя бы 1 предмет багажа
              if (totalCount > 0) {
                print('🔍 Устанавливаем _baggageSelectionVisited = true');
                _baggageSelectionVisited = true;
              } else {
                print('🔍 Багаж не выбран, флаг остается false');
              }
              // Если багаж не выбран (0 предметов), флаг остается false
              // и диалог покажется снова при попытке бронирования
            });
            // Navigator.pop будет вызван в самом BaggageSelectionScreen
          },
        ),
      ),
    );
    print('🔍 Вернулись из BaggageSelectionScreen');
    print('🔍 _baggageSelectionVisited = $_baggageSelectionVisited');
  }

  void _showBaggageConfirmationDialog() {
    print('🔍 _showBaggageConfirmationDialog() вызван');
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Наличие багажа'),
        content: const Text(
          'Вы не выбрали наличие багажа.\n\nЕсть ли у вас багаж для перевозки?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Нет багажа'),
            onPressed: () {
              print('🔍 Нажата кнопка "Нет багажа"');
              Navigator.pop(context);
              setState(() {
                _baggageSelectionVisited =
                    true; // Пользователь подтвердил отсутствие багажа
                _selectedBaggage = []; // Очищаем багаж на всякий случай
              });
              // Продолжаем бронирование
              _bookTrip();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'Да, есть багаж',
              style: TextStyle(
                color: theme.systemRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              print('🔍 Нажата кнопка "Да, есть багаж"');
              Navigator.pop(context);
              // Открываем экран выбора багажа
              _openBaggageSelection();
            },
          ),
        ],
      ),
    );
  }

  // СТАРЫЙ метод (закомментирован, используем _openSimplePetSelection)
  /*
  Future<void> _openPetSelection() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => PetSelectionScreen(
          initialPetInfo: _selectedPets.isNotEmpty ? _selectedPets.first : null,
          onPetSelected: (PetInfo? pet) {
            setState(() {
              if (pet != null) {
                _selectedPets = [pet]; // Заменяем список одним животным
                // Проверяем если животное крупное - должна быть индивидуальная поездка
                if (pet.size == PetSize.l) {
                  _showLargePetWarning();
                }
              } else {
                _selectedPets = [];
              }
            });
            // Navigator.pop будет вызван в самом PetSelectionScreen
          },
        ),
      ),
    );
  }
  */

  /// НОВЫЙ метод: упрощённый выбор животного через Bottom Sheet
  Future<void> _openSimplePetSelection() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => SimplePetSelectionSheet(
        initialPet: _selectedPets.isNotEmpty ? _selectedPets.first : null,
        onPetSelected: (PetInfo? pet) {
          setState(() {
            if (pet != null) {
              _selectedPets = [pet]; // Только ОДНО животное
            } else {
              _selectedPets = [];
            }
          });
        },
      ),
    );

    // ВАЖНО: Проверяем после закрытия Bottom Sheet
    if (_selectedPets.isNotEmpty &&
        _selectedPets.first.requiresIndividualTrip) {
      // Небольшая задержка, чтобы Bottom Sheet полностью закрылся
      await Future.delayed(const Duration(milliseconds: 300));
      _showLargePetAutoSwitchDialog();
    }
  }

  void _showLargePetAutoSwitchDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Автоматический переход'),
        content: const Text(
          'Для животных свыше 6 кг доступна только индивидуальная поездка (8000₽).\n\n'
          'Сейчас вы будете перенаправлены на экран индивидуального трансфера.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отменить выбор'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPets.clear();
              });
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Перейти'),
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
              _navigateToIndividualBooking();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToIndividualBooking() {
    // Закрываем текущий экран групповой поездки
    Navigator.pop(context);

    // Открываем экран индивидуальной поездки с выбранными остановками
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => IndividualBookingScreen(
          fromStop: _selectedFromStop,
          toStop: _selectedToStop,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _bookTrip() async {
    print('🔍 _bookTrip() вызван');
    print('🔍 _baggageSelectionVisited = $_baggageSelectionVisited');
    print('🔍 Количество багажа: ${_getTotalBaggageCount()}');

    // Валидация перед бронированием
    if (_selectedFromStop == null || _selectedToStop == null) {
      _showError('Пожалуйста, выберите города отправления и назначения');
      return;
    }

    if (_selectedDate == null) {
      _showError(
        'Пожалуйста, выберите дату поездки',
        onOkPressed: () =>
            _showDatePicker(), // Автоматически открываем календарь
      );
      return;
    }

    if (_selectedTime.isEmpty) {
      final theme = context.themeManager.currentTheme;
      _showError(
        'Пожалуйста, выберите время отправления',
        onOkPressed: () => _showTimePickerModal(
          theme,
        ), // Автоматически открываем выбор времени
      );
      return;
    }

    // Проверка места посадки для всех направлений
    if (_selectedPickupPoint.isEmpty) {
      final theme = context.themeManager.currentTheme;
      _showError(
        'Пожалуйста, выберите место посадки',
        onOkPressed: () =>
            _showPickupPointModal(theme), // Автоматически открываем выбор места
      );
      return;
    }

    // НОВАЯ ПРОВЕРКА: Пользователь должен подтвердить наличие/отсутствие багажа
    if (!_baggageSelectionVisited) {
      print('🔍 Показываем диалог подтверждения багажа');
      _showBaggageConfirmationDialog();
      return;
    }

    print('🔍 Продолжаем бронирование...');

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.getCurrentUser();
      if (user == null) {
        _showError('Ошибка авторизации');
        return;
      }

      final booking = Booking(
        id: '', // Будет установлен при создании
        clientId: user.id,
        tripType: TripType.group,
        direction: _selectedDirection,
        departureDate: _selectedDate!,
        departureTime: _selectedTime,
        passengerCount: _passengers.length,
        pickupPoint: _selectedPickupPoint.isNotEmpty ? _selectedPickupPoint : null,
        fromStop: _selectedFromStop, // Используем выбранные остановки
        toStop: _selectedToStop, // Используем выбранные остановки
        totalPrice: _getTotalPrice().toInt(),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        trackingPoints: const [],
        baggage: _selectedBaggage,
        pets: _selectedPets,
        passengers: _passengers,
      );

      // Отладочный вывод
      print(
        '🚀 Создаем бронирование: fromStop = ${_selectedFromStop?.name}, toStop = ${_selectedToStop?.name}',
      );
      print('🧳 Багаж: ${_selectedBaggage.length} предметов');
      print('🧳 Список багажа: $_selectedBaggage');

      final bookingId = await BookingService().createBooking(booking);

      // Получаем созданное бронирование с ID
      final createdBooking = await BookingService().getBookingById(bookingId);

      if (mounted && createdBooking != null) {
        _showSuccessDialog(createdBooking);
      } else if (mounted) {
        _showError('Не удалось получить данные созданного бронирования');
      }
    } catch (e) {
      _showError('Ошибка при создании бронирования: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    // Для диспетчеров открываем административную панель
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => AdminPanelScreen()),
    );
  }

  void _showError(String message, {VoidCallback? onOkPressed}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              // Если передан callback, выполняем его после закрытия диалога
              if (onOkPressed != null) {
                onOkPressed();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(Booking booking) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно!'),
        content: Text(
          'Ваше бронирование создано.\nНомер заказа: ${booking.id.substring(0, 8)}',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Посмотреть заказ'),
            onPressed: () async {
              Navigator.pop(context); // Закрываем диалог

              // ВАЖНО: Сохраняем вкладку "Бронирование" перед возвратом
              print('💾 Сохраняем /booking перед возвратом на главный экран');
              await AuthService.instance.saveLastScreen('/booking');
              print('✅ Вкладка /booking сохранена');

              // Возвращаемся на главный экран (он останется на вкладке "Бронирование")
              Navigator.popUntil(context, (route) => route.isFirst);

              // Небольшая задержка для корректной навигации
              await Future.delayed(const Duration(milliseconds: 150));

              // Открываем экран деталей заказа
              if (context.mounted) {
                print('🚀 Открываем экран деталей заказа');
                final result = await Navigator.push<String>(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => BookingDetailScreen(booking: booking),
                  ),
                );

                // После возврата из экрана деталей переключаемся на вкладку "Мои заказы"
                if (context.mounted && result == 'switch_to_orders') {
                  print('🔄 Переключаемся на вкладку "Мои заказы"');
                  HomeScreen.homeScreenKey.currentState?.switchToTab(1);
                  await AuthService.instance.saveLastScreen('/orders');
                  print('✅ Вкладка /orders сохранена');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// Модальное окно для выбора города
class _StopPickerModal extends StatefulWidget {
  final String title;
  final List<RouteStop> availableStops;
  final RouteStop? currentStop;
  final Function(RouteStop) onStopSelected;
  final dynamic theme;

  const _StopPickerModal({
    required this.title,
    required this.availableStops,
    required this.currentStop,
    required this.onStopSelected,
    required this.theme,
  });

  @override
  State<_StopPickerModal> createState() => _StopPickerModalState();
}

class _StopPickerModalState extends State<_StopPickerModal> {
  late RouteStop _currentlySelectedStop;

  @override
  void initState() {
    super.initState();
    // Инициализируем выбранный элемент текущим или первым доступным городом
    _currentlySelectedStop = widget.currentStop ?? widget.availableStops.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: widget.theme.systemBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: widget.theme.separator)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.label,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    widget.onStopSelected(_currentlySelectedStop);
                  },
                  child: Text(
                    'Выбрать',
                    style: TextStyle(
                      color: widget.theme.systemRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Список остановок
          Expanded(
            child: CupertinoPicker(
              itemExtent: 44,
              scrollController: FixedExtentScrollController(
                initialItem: widget.availableStops.indexOf(
                  _currentlySelectedStop,
                ),
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  _currentlySelectedStop = widget.availableStops[index];
                });
              },
              children: widget.availableStops.map((stop) {
                return Center(
                  child: Text(
                    stop.name,
                    style: TextStyle(fontSize: 18, color: widget.theme.label),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
