import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/route_stop.dart';
import '../../../models/trip_type.dart';
import '../../../models/booking.dart';
import '../../../models/user.dart';
import '../../../models/trip_settings.dart';
import '../../../models/baggage.dart';
import '../../../models/pet_info.dart';
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
import 'pet_selection_screen.dart';
import 'add_passenger_screen.dart';

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

  // Багаж и животные
  List<BaggageItem> _selectedBaggage = [];
  List<PetInfo> _selectedPets = [];
  bool _hasVKDiscount = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userType = await AuthService.instance.getUserType();
      final settings = await _settingsService.getCurrentSettings();

      setState(() {
        _userType = userType;
        _tripSettings = settings;
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Маршрут (если выбраны конкретные города)
                    if (widget.fromStop != null && widget.toStop != null) ...[
                      _buildSectionTitle('Маршрут', theme),
                      _buildRouteInfo(theme),
                      const SizedBox(height: 24),
                    ],

                    // Направление (если не выбраны конкретные города)
                    if (widget.fromStop == null || widget.toStop == null) ...[
                      _buildSectionTitle('Направление', theme),
                      _buildDirectionPicker(theme),
                      const SizedBox(height: 24),
                    ],

                    // Дата
                    _buildSectionTitle('Дата поездки', theme),
                    _buildDatePicker(theme),

                    const SizedBox(height: 24),

                    // Время
                    _buildSectionTitle('Время отправления', theme),
                    _buildTimePicker(theme),

                    const SizedBox(height: 24),

                    // Место посадки (только для Донецк → Ростов)
                    if (_selectedDirection == Direction.donetskToRostov) ...[
                      _buildSectionTitle('Место посадки', theme),
                      _buildPickupPointPicker(theme),
                      const SizedBox(height: 24),
                    ],

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
                  ],
                ),
              ),
            ),

            // Кнопка бронирования или сохранения
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton.filled(
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
            ),
          ],
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

  Widget _buildRouteInfo(theme) {
    if (widget.fromStop == null || widget.toStop == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Откуда - кликабельный
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showRouteStopPicker(true, theme),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.location_solid,
                      color: theme.systemRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Откуда',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.fromStop!.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.label,
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

          Divider(height: 1, color: theme.separator.withOpacity(0.2)),

          // Куда - кликабельный
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showRouteStopPicker(false, theme),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.location_solid,
                      color: theme.systemRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Куда',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.toStop!.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.label,
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
        ],
      ),
    );
  }

  Widget _buildDirectionPicker(theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildRadioTile(
            theme: theme,
            title: 'Донецк → Ростов-на-Дону',
            value: Direction.donetskToRostov,
            groupValue: _selectedDirection,
            onChanged: (value) => setState(() => _selectedDirection = value!),
          ),
          Divider(height: 1, color: theme.separator.withOpacity(0.2)),
          _buildRadioTile(
            theme: theme,
            title: 'Ростов-на-Дону → Донецк',
            value: Direction.rostovToDonetsk,
            groupValue: _selectedDirection,
            onChanged: (value) => setState(() => _selectedDirection = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required theme,
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              value == groupValue
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: value == groupValue ? theme.primary : theme.secondaryLabel,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: theme.label, fontSize: 16),
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
    final pickupPoints = _tripSettings?.donetskPickupPoints ?? [];

    if (pickupPoints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.separator.withOpacity(0.2)),
        ),
        child: Text(
          'Места посадки не настроены',
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
                    ? 'Выберите место посадки'
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
    final pickupPoints = _tripSettings?.donetskPickupPoints ?? [];

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
                  Text(
                    'Место посадки',
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
                  initialItem: _selectedPickupPoint.isNotEmpty
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
    final passenger = await Navigator.push<PassengerInfo>(
      context,
      CupertinoPageRoute(builder: (context) => const AddPassengerScreen()),
    );

    if (passenger != null) {
      setState(() {
        _passengers.add(passenger);
      });
    }
  }

  Future<void> _editPassenger(int index) async {
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
      });
    }
  }

  void _removePassenger(int index) {
    // Не позволяем удалить последнего пассажира
    if (_passengers.length <= 1) {
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
                          : '${_selectedBaggage.length} ${_getBaggageCountText(_selectedBaggage.length)}',
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
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _openPetSelection,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(CupertinoIcons.paw, color: theme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPets.isEmpty
                          ? 'Добавить животных'
                          : '${_selectedPets.length} ${_getPetCountText(_selectedPets.length)}',
                      style: TextStyle(color: theme.label, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedPets.isNotEmpty
                          ? '+${_calculatePetPrice()} ₽'
                          : 'S, M, L размеры',
                      style: TextStyle(
                        color: _selectedPets.isNotEmpty
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

  String _getBaggageCountText(int count) {
    if (count == 1) return 'предмет багажа';
    if (count < 5) return 'предмета багажа';
    return 'предметов багажа';
  }

  String _getPetCountText(int count) {
    if (count == 1) return 'животное';
    if (count < 5) return 'животных';
    return 'животных';
  }

  double _calculateBaggagePrice() {
    return _selectedBaggage.fold(0.0, (sum, item) {
      // ОБНОВЛЕНО под ТЗ v3.0: используем новый метод расчета стоимости
      return sum + item.calculateCost();
    });
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
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BaggageSelectionScreen(
          initialBaggage: _selectedBaggage,
          onBaggageSelected: (List<BaggageItem> baggage) {
            setState(() {
              _selectedBaggage = baggage;
            });
            // Navigator.pop будет вызван в самом BaggageSelectionScreen
          },
        ),
      ),
    );
  }

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

  void _showLargePetWarning() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Требуется индивидуальная поездка'),
        content: const Text(
          'Для крупных животных доступна только индивидуальная поездка. '
          'Это обеспечит комфорт и безопасность вашего питомца.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отменить'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPets.removeWhere((pet) => pet.size == PetSize.l);
              });
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Перейти к индивидуальной'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Возврат к выбору типа поездки
              // Здесь можно добавить навигацию к индивидуальной поездке
            },
          ),
        ],
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
    // Валидация перед бронированием
    if (_selectedDate == null) {
      _showError('Пожалуйста, выберите дату поездки');
      return;
    }

    if (_selectedTime.isEmpty) {
      _showError('Пожалуйста, выберите время отправления');
      return;
    }

    if (_selectedDirection == Direction.donetskToRostov &&
        _selectedPickupPoint.isEmpty) {
      _showError('Пожалуйста, выберите место посадки');
      return;
    }

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
        pickupPoint: _selectedDirection == Direction.donetskToRostov
            ? _selectedPickupPoint
            : null,
        fromStop: widget.fromStop,
        toStop: widget.toStop,
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
        '🚀 Создаем бронирование: fromStop = ${widget.fromStop?.name}, toStop = ${widget.toStop?.name}',
      );

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

  void _showRouteStopPicker(bool isFromStop, theme) {
    final routeService = RouteService.instance;
    // Определяем направление на основе текущих остановок
    final direction = widget.fromStop!.order < widget.toStop!.order
        ? 'donetsk_to_rostov'
        : 'rostov_to_donetsk';

    final availableStops = routeService.getRouteStops(direction);

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => _StopPickerModal(
        title: isFromStop ? 'Откуда' : 'Куда',
        availableStops: availableStops,
        currentStop: isFromStop ? widget.fromStop : widget.toStop,
        onStopSelected: (RouteStop stop) {
          setState(() {
            if (isFromStop) {
              // Обновляем fromStop через создание нового widget не получится,
              // поэтому используем локальную переменную
              // Но так как widget.fromStop - final, нам нужно передать это обратно
              Navigator.of(context).pop();
              // Переходим на новый экран с обновленными параметрами
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (context) =>
                      GroupBookingScreen(fromStop: stop, toStop: widget.toStop),
                ),
              );
            } else {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (context) => GroupBookingScreen(
                    fromStop: widget.fromStop,
                    toStop: stop,
                  ),
                ),
              );
            }
          });
        },
        theme: theme,
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
