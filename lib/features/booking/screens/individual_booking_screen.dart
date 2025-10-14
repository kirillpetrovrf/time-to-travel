import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/route_stop.dart';
import '../../../models/trip_type.dart';
import '../../../models/booking.dart';
import '../../../models/baggage.dart';
import '../../../models/pet_info_v3.dart';
import '../../../models/passenger_info.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/route_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../home/screens/home_screen.dart';
import '../../orders/screens/booking_detail_screen.dart';
import 'baggage_selection_screen_v3.dart';
import '../widgets/simple_pet_selection_sheet.dart';
import 'vehicle_selection_screen.dart';

class IndividualBookingScreen extends StatefulWidget {
  final RouteStop? fromStop;
  final RouteStop? toStop;

  const IndividualBookingScreen({super.key, this.fromStop, this.toStop});

  @override
  State<IndividualBookingScreen> createState() =>
      _IndividualBookingScreenState();
}

class _IndividualBookingScreenState extends State<IndividualBookingScreen> {
  Direction _selectedDirection = Direction.donetskToRostov;
  DateTime? _selectedDate; // nullable - пользователь должен выбрать
  String _selectedTime = ''; // String вместо TimeOfDay для SQLite
  List<PassengerInfo> _passengers = []; // Изменено с int на List<PassengerInfo>
  bool _isLoading = false;

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  // Для прокрутки и фокусировки на полях адресов
  final ScrollController _scrollController = ScrollController();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _dropoffFocusNode = FocusNode();
  final GlobalKey _addressSectionKey = GlobalKey();

  // Выбор городов (новая логика как в групповой поездке)
  RouteStop? _selectedFromStop;
  RouteStop? _selectedToStop;
  List<RouteStop> _availableStops = [];

  // Багаж и животные
  List<BaggageItem> _selectedBaggage = [];
  List<PetInfo> _selectedPets = [];
  bool _hasVKDiscount = false;

  // НОВОЕ (ТЗ v3.0): Выбор транспорта для индивидуальных поездок
  VehicleClass? _selectedVehicleClass;

  // Переключатель для детей
  bool _hasChildren = false; // Включен ли переключатель "Добавить ребёнка"

  @override
  void initState() {
    super.initState();
    _loadRouteStops();
    // Добавляем одного взрослого по умолчанию
    _passengers = [PassengerInfo(type: PassengerType.adult)];
  }

  Future<void> _loadRouteStops() async {
    final routeService = RouteService.instance;
    final stops = routeService.getRouteStops('donetsk_to_rostov');

    setState(() {
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

      // Обновляем направление
      if (_selectedFromStop?.id == 'donetsk') {
        _selectedDirection = Direction.donetskToRostov;
      } else if (_selectedFromStop?.id == 'rostov') {
        _selectedDirection = Direction.rostovToDonetsk;
      }
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _scrollController.dispose();
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    super.dispose();
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
          'Индивидуальный трансфер',
          style: TextStyle(color: theme.label),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Направление
                    _buildSectionTitle('Направление', theme),
                    _buildDirectionPicker(theme),

                    const SizedBox(height: 24),

                    // Адреса
                    Container(
                      key: _addressSectionKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionTitle('Адреса', theme),
                          _buildAddressFields(theme),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Дата поездки
                    _buildSectionTitle('Дата поездки', theme),
                    _buildDatePicker(theme),

                    const SizedBox(height: 24),

                    // Время отправления
                    _buildSectionTitle('Время отправления', theme),
                    _buildTimePicker(theme),

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

                    // НОВОЕ (ТЗ v3.0): Выбор транспорта
                    _buildSectionTitle('Тип транспорта', theme),
                    _buildVehicleSection(theme),

                    const SizedBox(height: 24),

                    // Комендантский час предупреждение
                    if (_isNightTime()) _buildNightTimeWarning(theme),

                    // Стоимость
                    _buildPricingSummary(theme),

                    // Отступ снизу для системных кнопок навигации
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Кнопка бронирования
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton.filled(
                onPressed: _isLoading ? null : _bookTrip,
                child: _isLoading
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : Text(
                        'Забронировать за ${_calculatePrice()} ₽',
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

  Widget _buildDirectionPicker(theme) {
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

      // Сбрасываем адреса при смене направления
      _pickupController.clear();
      _dropoffController.clear();
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

                    // Сбрасываем адреса
                    _pickupController.clear();
                    _dropoffController.clear();
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

                    // Сбрасываем адреса при смене направления
                    _pickupController.clear();
                    _dropoffController.clear();
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

  Widget _buildAddressFields(theme) {
    return Column(
      children: [
        // Откуда
        Container(
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.separator.withOpacity(0.2)),
          ),
          child: CupertinoTextField(
            controller: _pickupController,
            focusNode: _pickupFocusNode,
            placeholder: _selectedFromStop != null
                ? 'Адрес в ${_selectedFromStop!.name}'
                : 'Адрес отправления',
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

        // Куда
        Container(
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.separator.withOpacity(0.2)),
          ),
          child: CupertinoTextField(
            controller: _dropoffController,
            focusNode: _dropoffFocusNode,
            placeholder: _selectedDirection == Direction.donetskToRostov
                ? 'Адрес в Ростове-на-Дону'
                : 'Адрес в Донецке',
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
      ],
    );
  }

  Widget _buildDatePicker(theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedDate != null
              ? theme.separator.withOpacity(0.2)
              : theme.systemRed,
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
                ? theme.separator.withOpacity(0.2)
                : theme.systemRed,
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
                Padding(
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
              ],
            );
          }).toList(),

          // Кнопка добавить пассажира
          if (_passengers.length < 8) ...[
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

          // Разделитель перед переключателем ребёнка
          if (_passengers.length < 8)
            Divider(height: 1, color: theme.separator.withOpacity(0.2)),

          // Переключатель "Добавить ребёнка"
          if (_passengers.length < 8)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(CupertinoIcons.smiley, color: theme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Добавить ребёнка',
                      style: TextStyle(
                        color: theme.label,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: _hasChildren,
                    onChanged: (value) {
                      if (value) {
                        // Включаем - открываем модальное окно для добавления ребёнка
                        _showAddChildModal(theme);
                      } else {
                        // Выключаем - показываем диалог подтверждения
                        _showRemoveAllChildrenDialog();
                      }
                    },
                  ),
                ],
              ),
            ),

          // Кнопка "+ Добавить ребёнка" (показывается только когда переключатель включен)
          if (_hasChildren && _passengers.length < 8) ...[
            Divider(height: 1, color: theme.separator.withOpacity(0.2)),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onPressed: () => _showAddChildModal(theme),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add_circled, color: theme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Добавить ребёнка',
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

  Widget _buildNightTimeWarning(theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemOrange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Комендантский час',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Выезд после 22:00 — доплата +2 000 ₽',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.secondaryLabel.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(theme) {
    final totalPrice = _calculatePrice();

    // Если время не выбрано, показываем базовую цену
    final basePrice = _selectedTime.isEmpty
        ? 8000
        : TripPricing.getIndividualTripPrice(_selectedTime, _selectedDirection);

    final nightSurcharge =
        _isNightTime() && _selectedDirection == Direction.donetskToRostov
        ? 2000
        : 0;
    final baggagePrice = _calculateBaggagePrice();
    final petPrice = _calculatePetPrice();
    final vkDiscount = _hasVKDiscount ? 30.0 : 0.0;

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
                'Базовая стоимость',
                style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
              ),
              Text(
                '${basePrice - nightSurcharge} ₽',
                style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
              ),
            ],
          ),

          // Ночная доплата (если есть)
          if (nightSurcharge > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ночная доплата',
                  style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                ),
                Text(
                  '+$nightSurcharge ₽',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemOrange,
                  ),
                ),
              ],
            ),
          ],

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
                '$totalPrice ₽',
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
            'Оплата при посадке в автомобиль\nВключена подача до адреса',
            style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
          ),
        ],
      ),
    );
  }

  bool _isNightTime() {
    // _selectedTime теперь String формата '22:00'
    if (_selectedTime.isEmpty) return false;

    final parts = _selectedTime.split(':');
    if (parts.length != 2) return false;

    final hour = int.tryParse(parts[0]) ?? 0;
    return hour >= 22;
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
                          ? 'Бесплатно'
                          : 'Размеры S, M, L, Custom',
                      style: TextStyle(
                        color: _selectedBaggage.isNotEmpty
                            ? theme.systemGreen
                            : theme.secondaryLabel,
                        fontSize: 14,
                        fontWeight: _selectedBaggage.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                          ? '+${_calculatePetPrice().toInt()} ₽'
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

  int _getTotalBaggageCount() {
    return _selectedBaggage.fold(0, (sum, item) => sum + item.quantity);
  }

  String _getPetCountText(int count) {
    if (count == 1) return 'животное';
    if (count < 5) return 'животных';
    return 'животных';
  }

  double _calculateBaggagePrice() {
    print('💵 [INDIVIDUAL] ========== РАСЧЕТ СТОИМОСТИ БАГАЖА ==========');
    print('💵 [INDIVIDUAL] 🎁 ВЕСЬ БАГАЖ БЕСПЛАТНЫЙ (аренда всей машины)');

    // НОВАЯ ЛОГИКА v9.0 для ИНДИВИДУАЛЬНОГО ТРАНСФЕРА:
    // Весь багаж БЕСПЛАТНЫЙ, т.к. клиент арендует всю машину целиком

    if (_selectedBaggage.isEmpty) {
      print('💵 [INDIVIDUAL] Багаж не выбран, стоимость: 0₽');
      return 0.0;
    }

    // Подсчитываем количество багажа (для логирования)
    int sCount = 0, mCount = 0, lCount = 0, customCount = 0;

    for (var item in _selectedBaggage) {
      switch (item.size) {
        case BaggageSize.s:
          sCount = item.quantity;
          break;
        case BaggageSize.m:
          mCount = item.quantity;
          break;
        case BaggageSize.l:
          lCount = item.quantity;
          break;
        case BaggageSize.custom:
          customCount = item.quantity;
          break;
      }
    }

    print(
      '💵 [INDIVIDUAL] Выбранный багаж: S=$sCount, M=$mCount, L=$lCount, Custom=$customCount',
    );
    print('💵 [INDIVIDUAL] ✅ Весь багаж БЕСПЛАТНЫЙ (аренда машины)');
    print('💵 [INDIVIDUAL] ========== ИТОГО: 0₽ ==========');

    return 0.0;
  }

  double _calculatePetPrice() {
    return _selectedPets.fold(0.0, (sum, pet) => sum + pet.cost);
  }

  Future<void> _openBaggageSelection() async {
    print('🔍 [INDIVIDUAL] _openBaggageSelection() вызван');
    print(
      '🔍 [INDIVIDUAL] Текущее количество пассажиров: ${_passengers.length}',
    );
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BaggageSelectionScreen(
          initialBaggage: _selectedBaggage,
          passengerCount: _passengers.length,
          isIndividualTrip:
              true, // ← ИНДИВИДУАЛЬНЫЙ ТРАНСФЕР - весь багаж бесплатный
          onBaggageSelected: (List<BaggageItem> baggage) {
            print('🔍 [INDIVIDUAL] onBaggageSelected вызван');
            print('🔍 [INDIVIDUAL] Получен багаж: ${baggage.length} предметов');
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
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => SimplePetSelectionSheet(
        initialPet: _selectedPets.isNotEmpty ? _selectedPets.first : null,
        onPetSelected: (PetInfo? pet) {
          setState(() {
            if (pet != null) {
              _selectedPets = [pet]; // Заменяем список одним животным
            } else {
              _selectedPets = [];
            }
          });
        },
      ),
    );
  }

  int _calculatePrice() {
    // Если время не выбрано, возвращаем базовую цену
    if (_selectedTime.isEmpty) {
      return 8000; // Базовая цена индивидуального трансфера
    }

    // _selectedTime уже строка формата '15:00'
    final basePrice = TripPricing.getIndividualTripPrice(
      _selectedTime,
      _selectedDirection,
    );
    final baggagePrice = _calculateBaggagePrice();
    final petPrice = _calculatePetPrice();
    final vkDiscount = _hasVKDiscount ? 30.0 : 0.0;

    return (basePrice + baggagePrice + petPrice - vkDiscount).toInt();
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

  /// Прокручивает экран к секции адресов и фокусируется на первом пустом поле
  void _scrollToAddressFields() {
    // Получаем контекст секции адресов
    final RenderBox? renderBox =
        _addressSectionKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      // Вычисляем позицию секции адресов
      final position = renderBox.localToGlobal(Offset.zero).dy;
      final scrollPosition =
          _scrollController.offset + position - 100; // -100 для отступа сверху

      // Плавно прокручиваем к секции адресов
      _scrollController.animateTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    // Фокусируемся на первом пустом поле через небольшую задержку
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_pickupController.text.trim().isEmpty) {
        _pickupFocusNode.requestFocus();
      } else if (_dropoffController.text.trim().isEmpty) {
        _dropoffFocusNode.requestFocus();
      }
    });
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
                        color: theme.primary,
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

  void _showTimePickerModal(theme) {
    // Парсим текущее время или используем текущее системное время
    DateTime initialTime = DateTime.now();
    if (_selectedTime.isNotEmpty) {
      try {
        final timeParts = _selectedTime.split(':');
        initialTime = DateTime(
          initialTime.year,
          initialTime.month,
          initialTime.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      } catch (e) {
        // Если не удалось распарсить, используем текущее время
        print('⚠️ Не удалось распарсить время: $_selectedTime');
      }
    }

    // Временная переменная для хранения выбранного времени
    DateTime tempSelectedTime = initialTime;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 260,
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
                      // Форматируем время в строку HH:mm
                      final formattedTime =
                          '${tempSelectedTime.hour.toString().padLeft(2, '0')}:'
                          '${tempSelectedTime.minute.toString().padLeft(2, '0')}';

                      setState(() {
                        _selectedTime = formattedTime;
                      });

                      print('⏰ Выбрано время: $formattedTime');
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Готово',
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Time Picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: initialTime,
                onDateTimeChanged: (DateTime newTime) {
                  tempSelectedTime = newTime;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookTrip() async {
    // Валидация выбора городов
    if (_selectedFromStop == null || _selectedToStop == null) {
      _showError('Пожалуйста, выберите города отправления и назначения');
      return;
    }

    // Валидация даты
    if (_selectedDate == null) {
      _showError(
        'Пожалуйста, выберите дату поездки',
        onOkPressed: () => _showDatePicker(),
      );
      return;
    }

    // Валидация времени
    if (_selectedTime.isEmpty) {
      final theme = context.themeManager.currentTheme;
      _showError(
        'Пожалуйста, выберите время отправления',
        onOkPressed: () => _showTimePickerModal(theme),
      );
      return;
    }

    // Валидация адресов
    if (_pickupController.text.trim().isEmpty ||
        _dropoffController.text.trim().isEmpty) {
      _showError(
        'Пожалуйста, укажите адреса отправления и назначения',
        onOkPressed: () => _scrollToAddressFields(),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.getCurrentUser();
      if (user == null) {
        _showError('Ошибка авторизации');
        return;
      }

      print('📅 [INDIVIDUAL] Создание бронирования:');
      print('📅 [INDIVIDUAL]   Дата: ${_selectedDate!.toIso8601String()}');
      print('📅 [INDIVIDUAL]   Время: $_selectedTime');
      print('📅 [INDIVIDUAL]   От: ${_selectedFromStop!.name}');
      print('📅 [INDIVIDUAL]   До: ${_selectedToStop!.name}');

      final booking = Booking(
        id: '', // Будет установлен при создании
        clientId: user.id,
        tripType: TripType.individual,
        direction: _selectedDirection,
        departureDate: _selectedDate!, // DateTime для SQLite
        departureTime: _selectedTime, // String для SQLite
        passengerCount: _passengers.length,
        pickupAddress: _pickupController.text.trim(),
        dropoffAddress: _dropoffController.text.trim(),
        fromStop: _selectedFromStop, // Добавляем остановку отправления
        toStop: _selectedToStop, // Добавляем остановку назначения
        totalPrice: _calculatePrice(),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        trackingPoints: const [],
        baggage: _selectedBaggage,
        pets: _selectedPets,
        passengers: _passengers, // ← Добавляем пассажиров
      );

      final bookingId = await BookingService().createBooking(booking);

      print('✅ [INDIVIDUAL] Бронирование создано с ID: $bookingId');
      print('✅ [INDIVIDUAL] Данные сохранены в SQLite + Firebase');

      // Получаем созданное бронирование с ID
      final createdBooking = await BookingService().getBookingById(bookingId);

      if (mounted && createdBooking != null) {
        _showSuccessDialog(createdBooking);
      } else if (mounted) {
        _showError('Не удалось получить данные созданного бронирования');
      }
    } catch (e) {
      print('❌ [INDIVIDUAL] Ошибка при создании бронирования: $e');
      _showError('Ошибка при создании бронирования: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

  Widget _buildVehicleSection(theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _openVehicleSelection,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(CupertinoIcons.car, color: theme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedVehicleClass == null
                          ? 'Выберите тип транспорта'
                          : _getVehicleClassName(_selectedVehicleClass!),
                      style: TextStyle(color: theme.label, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedVehicleClass != null
                          ? '+${_getVehiclePrice(_selectedVehicleClass!).toInt()} ₽'
                          : 'Седан, Универсал, Минивэн, Микроавтобус',
                      style: TextStyle(
                        color: _selectedVehicleClass != null
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

  String _getVehicleClassName(VehicleClass vehicleClass) {
    switch (vehicleClass) {
      case VehicleClass.sedan:
        return 'Седан';
      case VehicleClass.wagon:
        return 'Универсал';
      case VehicleClass.minivan:
        return 'Минивэн';
      case VehicleClass.microbus:
        return 'Микроавтобус';
    }
  }

  double _getVehiclePrice(VehicleClass vehicleClass) {
    switch (vehicleClass) {
      case VehicleClass.sedan:
        return 0.0;
      case VehicleClass.wagon:
        return 300.0;
      case VehicleClass.minivan:
        return 800.0;
      case VehicleClass.microbus:
        return 1500.0;
    }
  }

  Future<void> _openVehicleSelection() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => VehicleSelectionScreen(
          initialSelection: _selectedVehicleClass,
          onVehicleSelected: (VehicleClass? vehicle) {
            setState(() {
              _selectedVehicleClass = vehicle;
            });
          },
        ),
      ),
    );
  }

  // ========== МЕТОДЫ ДЛЯ РАБОТЫ С ПАССАЖИРАМИ ==========

  void _addPassenger() {
    print('👥 [INDIVIDUAL] Добавление нового пассажира...');
    print('👥 [INDIVIDUAL] Текущее количество: ${_passengers.length}');

    setState(() {
      // Добавляем взрослого пассажира напрямую
      _passengers.add(PassengerInfo(type: PassengerType.adult));
      print(
        '👥 [INDIVIDUAL] ✅ Пассажир добавлен! Новое количество: ${_passengers.length}',
      );
      print(
        '👥 [INDIVIDUAL] 🔄 Будет пересчитан багаж: ${_passengers.length * 2} бесплатных S',
      );
    });
  }

  void _removePassenger(int index) {
    if (_passengers.length <= 1) {
      _showError('Должен быть хотя бы один пассажир');
      return;
    }

    setState(() {
      final removedPassenger = _passengers[index];
      _passengers.removeAt(index);
      print(
        '👥 [INDIVIDUAL] ✅ Пассажир удалён! Осталось: ${_passengers.length}',
      );

      // Если удалили последнего ребёнка, выключаем переключатель
      if (removedPassenger.isChild && !_passengers.any((p) => p.isChild)) {
        _hasChildren = false;
      }
    });
  }

  // Показать модальное окно для добавления ребёнка
  Future<void> _showAddChildModal(theme) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => _ChildConfigurationModal(
        theme: theme,
        onSave: (int ageMonths, ChildSeatType seatType, bool useOwnSeat) {
          print('👶 [INDIVIDUAL] Добавление ребёнка...');
          print('👶 [INDIVIDUAL] Возраст: $ageMonths месяцев');
          print('👶 [INDIVIDUAL] Тип кресла: $seatType');
          print('👶 [INDIVIDUAL] Своё кресло: $useOwnSeat');

          setState(() {
            _passengers.add(
              PassengerInfo(
                type: PassengerType.child,
                seatType: seatType,
                useOwnSeat: useOwnSeat,
                ageMonths: ageMonths,
              ),
            );
            _hasChildren = true; // Включаем переключатель
            print(
              '👶 [INDIVIDUAL] ✅ Ребёнок добавлен! Всего пассажиров: ${_passengers.length}',
            );
          });
        },
      ),
    );
  }

  // Диалог подтверждения удаления всех детей
  void _showRemoveAllChildrenDialog() {
    final childrenCount = _passengers
        .where((p) => p.type == PassengerType.child)
        .length;

    if (childrenCount == 0) {
      // Если детей нет, просто выключаем переключатель
      setState(() {
        _hasChildren = false;
      });
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить всех детей?'),
        content: Text(
          'Вы уверены, что хотите удалить всех детей из списка пассажиров? ($childrenCount ${_getChildCountWord(childrenCount)})',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _passengers.removeWhere((p) => p.type == PassengerType.child);
                _hasChildren = false;
                print(
                  '👶 [INDIVIDUAL] ✅ Все дети удалены! Осталось пассажиров: ${_passengers.length}',
                );
              });
            },
          ),
        ],
      ),
    );
  }

  String _getChildCountWord(int count) {
    if (count == 1) return 'ребёнок';
    if (count >= 2 && count <= 4) return 'ребёнка';
    return 'детей';
  }

  // ========== КОНЕЦ МЕТОДОВ ДЛЯ ПАССАЖИРОВ ==========
}

// ========== ВИДЖЕТ МОДАЛЬНОГО ОКНА ВЫБОРА ДЕТСКОГО КРЕСЛА ==========

class _ChildConfigurationModal extends StatefulWidget {
  final CustomTheme theme;
  final Function(int ageMonths, ChildSeatType seatType, bool useOwnSeat) onSave;

  const _ChildConfigurationModal({required this.theme, required this.onSave});

  @override
  State<_ChildConfigurationModal> createState() =>
      _ChildConfigurationModalState();
}

class _ChildConfigurationModalState extends State<_ChildConfigurationModal> {
  int? _ageMonths;
  ChildSeatType? _selectedSeatType;
  bool _useOwnSeat = false;

  bool get _canSave => _ageMonths != null && _selectedSeatType != null;

  @override
  void initState() {
    super.initState();
    // Автоматически открываем picker выбора возраста после открытия модального окна
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAgePicker();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: widget.theme.systemBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          children: [
            // Заголовок (фиксированный)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: widget.theme.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Отмена',
                      style: TextStyle(color: widget.theme.primary),
                    ),
                  ),
                  Text(
                    'Добавить ребёнка',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.theme.label,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _canSave
                        ? () {
                            widget.onSave(
                              _ageMonths!,
                              _selectedSeatType!,
                              _useOwnSeat,
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    child: Text(
                      'Готово',
                      style: TextStyle(
                        color: _canSave
                            ? widget.theme.primary
                            : widget.theme.tertiaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Контент (прокручиваемый)
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Блок: Возраст ребёнка
                    _buildAgeSection(),

                    const SizedBox(height: 24),

                    // Блок: Тип автокресла (показывается после выбора возраста)
                    if (_ageMonths != null) _buildSeatTypeSection(),

                    const SizedBox(height: 24),

                    // Блок: Чьё кресло (показывается после выбора типа кресла)
                    if (_selectedSeatType != null &&
                        _selectedSeatType != ChildSeatType.none)
                      _buildOwnSeatSection(),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Возраст ребёнка',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.theme.label,
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAgePicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _ageMonths != null
                    ? widget.theme.primary
                    : widget.theme.separator.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.calendar, color: widget.theme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _ageMonths == null
                        ? 'Укажите возраст'
                        : _formatAge(_ageMonths!),
                    style: TextStyle(
                      color: _ageMonths == null
                          ? widget.theme.tertiaryLabel
                          : widget.theme.label,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: widget.theme.secondaryLabel,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип автокресла',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.theme.label,
          ),
        ),
        const SizedBox(height: 12),
        ...ChildSeatType.values.map((seatType) {
          final isSelected = seatType == _selectedSeatType;
          final isRecommended =
              seatType == ChildSeatTypeExtension.recommendByAge(_ageMonths!);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSeatType = seatType;
                // Если выбрано "без кресла", сбрасываем useOwnSeat
                if (seatType == ChildSeatType.none) {
                  _useOwnSeat = false;
                } else {
                  // Если выбрано кресло - показываем диалог выбора чьё кресло
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _showSeatOwnershipDialog();
                  });
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.theme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? widget.theme.primary
                      : widget.theme.separator.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isRecommended)
                        const Icon(
                          CupertinoIcons.star_fill,
                          color: CupertinoColors.systemYellow,
                          size: 16,
                        ),
                      if (isRecommended) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          seatType.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: widget.theme.label,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: widget.theme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seatType.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.theme.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildOwnSeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Чьё автокресло',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.theme.label,
          ),
        ),
        const SizedBox(height: 12),

        // Кресло водителя
        GestureDetector(
          onTap: () {
            setState(() {
              _useOwnSeat = false;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !_useOwnSeat
                    ? widget.theme.primary
                    : widget.theme.separator.withOpacity(0.2),
                width: !_useOwnSeat ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Кресло водителя',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: !_useOwnSeat
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: widget.theme.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Бесплатно',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_useOwnSeat)
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: widget.theme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),

        // Своё кресло
        GestureDetector(
          onTap: () {
            setState(() {
              _useOwnSeat = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _useOwnSeat
                    ? widget.theme.primary
                    : widget.theme.separator.withOpacity(0.2),
                width: _useOwnSeat ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Своё кресло',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _useOwnSeat
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: widget.theme.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Бесплатно',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_useOwnSeat)
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: widget.theme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAgePicker() {
    int selectedYears = (_ageMonths ?? 0) ~/ 12;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        color: widget.theme.systemBackground,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: widget.theme.separator),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Отмена',
                      style: TextStyle(color: widget.theme.primary),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Возраст ребёнка',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.theme.label,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Готово',
                      style: TextStyle(color: widget.theme.primary),
                    ),
                    onPressed: () {
                      setState(() {
                        _ageMonths = selectedYears * 12;
                        // Автоматически рекомендуем тип кресла
                        _selectedSeatType =
                            ChildSeatTypeExtension.recommendByAge(_ageMonths!);
                      });
                      Navigator.pop(context);

                      // Если автоматически выбрано кресло (не "Без кресла"), показываем диалог выбора
                      if (_selectedSeatType != null &&
                          _selectedSeatType != ChildSeatType.none) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _showSeatOwnershipDialog();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: widget.theme.systemBackground,
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedYears,
                ),
                onSelectedItemChanged: (index) {
                  selectedYears = index;
                },
                children: List.generate(
                  16,
                  (index) => Center(
                    child: Text(
                      '$index ${_yearWord(index)}',
                      style: TextStyle(fontSize: 20, color: widget.theme.label),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeatOwnershipDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false, // Пользователь должен обязательно выбрать
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Чьё автокресло?'),
          content: const Text('Выберите, чьё кресло будет использоваться'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                setState(() {
                  _useOwnSeat = false;
                });
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  const Text(
                    'Кресло водителя',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Бесплатно',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                setState(() {
                  _useOwnSeat = true;
                });
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  const Text(
                    'Своё кресло',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Бесплатно',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _yearWord(int years) {
    if (years == 0) return 'лет';
    if (years == 1) return 'год';
    if (years >= 2 && years <= 4) return 'года';
    return 'лет';
  }

  String _formatAge(int ageMonths) {
    final years = ageMonths ~/ 12;
    return '$years ${_yearWord(years)}';
  }
}
