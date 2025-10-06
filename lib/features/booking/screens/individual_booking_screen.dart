import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/route_stop.dart';
import '../../../models/trip_type.dart';
import '../../../models/booking.dart';
import '../../../models/baggage.dart';
import '../../../models/pet_info.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../theme/theme_manager.dart';
import '../../home/screens/home_screen.dart';
import '../../orders/screens/booking_detail_screen.dart';
import 'baggage_selection_screen_v3.dart';
import 'pet_selection_screen.dart';
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
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _passengerCount = 1;
  bool _isLoading = false;

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  // Багаж и животные
  List<BaggageItem> _selectedBaggage = [];
  List<PetInfo> _selectedPets = [];
  bool _hasVKDiscount = false;

  // НОВОЕ (ТЗ v3.0): Выбор транспорта для индивидуальных поездок
  VehicleClass? _selectedVehicleClass;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Направление
                    _buildSectionTitle('Направление', theme),
                    _buildDirectionPicker(theme),

                    const SizedBox(height: 24),

                    // Адреса
                    _buildSectionTitle('Адреса', theme),
                    _buildAddressFields(theme),

                    const SizedBox(height: 24),

                    // Дата и время
                    _buildSectionTitle('Дата и время', theme),
                    _buildDateTimePicker(theme),

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
              color: value == groupValue
                  ? theme.primary
                  : theme.secondaryLabel.withOpacity(0.3),
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
            placeholder: _selectedDirection == Direction.donetskToRostov
                ? 'Адрес в Донецке'
                : 'Адрес в Ростове-на-Дону',
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

  Widget _buildDateTimePicker(theme) {
    return Column(
      children: [
        // Дата
        Container(
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.separator.withOpacity(0.2)),
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
                    _formatDate(_selectedDate),
                    style: TextStyle(color: theme.label, fontSize: 16),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: theme.secondaryLabel.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Время
        Container(
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.separator.withOpacity(0.2)),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onPressed: () => _showTimePicker(),
            child: Row(
              children: [
                Icon(CupertinoIcons.clock, color: theme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatTime(_selectedTime),
                    style: TextStyle(color: theme.label, fontSize: 16),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: theme.secondaryLabel.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerCountPicker(theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(CupertinoIcons.person_2, color: theme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Пассажиров: $_passengerCount',
                style: TextStyle(color: theme.label, fontSize: 16),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _passengerCount > 1
                  ? () => setState(() => _passengerCount--)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _passengerCount > 1
                      ? theme.primary
                      : theme.secondaryLabel.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.minus,
                  color: _passengerCount > 1
                      ? CupertinoColors.white
                      : theme.secondaryLabel.withOpacity(0.3),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _passengerCount < 8
                  ? () => setState(() => _passengerCount++)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _passengerCount < 8
                      ? theme.primary
                      : theme.secondaryLabel.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.plus,
                  color: _passengerCount < 8
                      ? CupertinoColors.white
                      : theme.secondaryLabel.withOpacity(0.3),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
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
    final baseTimeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final basePrice = TripPricing.getIndividualTripPrice(
      baseTimeString,
      _selectedDirection,
    );
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
    return _selectedTime.hour >= 22;
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
                          ? '+${_calculateBaggagePrice().toInt()} ₽'
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
    // НОВАЯ ЛОГИКА: первый багаж ЛЮБОГО размера бесплатно
    int totalBaggageCount = _getTotalBaggageCount();

    if (totalBaggageCount == 0) return 0.0;
    if (totalBaggageCount == 1) return 0.0; // Первый багаж бесплатно

    // Считаем стоимость всех багажей (без учета бесплатного первого)
    double totalCost = 0.0;
    int processedCount = 0;

    for (var item in _selectedBaggage) {
      for (int i = 0; i < item.quantity; i++) {
        processedCount++;

        // Первый багаж бесплатно
        if (processedCount == 1) continue;

        // Все последующие по полной цене
        totalCost += item.pricePerExtraItem;
      }
    }

    return totalCost;
  }

  double _calculatePetPrice() {
    return _selectedPets.fold(0.0, (sum, pet) => sum + pet.cost);
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

  int _calculatePrice() {
    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final basePrice = TripPricing.getIndividualTripPrice(
      timeString,
      _selectedDirection,
    );
    final baggagePrice = _calculateBaggagePrice();
    final petPrice = _calculatePetPrice();
    final vkDiscount = _hasVKDiscount ? 30.0 : 0.0;

    return (basePrice + baggagePrice + petPrice - vkDiscount).toInt();
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Отмена'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(const Duration(days: 30)),
                onDateTimeChanged: (date) =>
                    setState(() => _selectedDate = date),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Отмена'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  2024,
                  1,
                  1,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                use24hFormat: true,
                onDateTimeChanged: (dateTime) {
                  setState(() {
                    _selectedTime = TimeOfDay(
                      hour: dateTime.hour,
                      minute: dateTime.minute,
                    );
                  });
                },
              ),
            ),
          ],
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

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _bookTrip() async {
    if (_pickupController.text.trim().isEmpty ||
        _dropoffController.text.trim().isEmpty) {
      _showError('Пожалуйста, укажите адреса отправления и назначения');
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
        tripType: TripType.individual,
        direction: _selectedDirection,
        departureDate: _selectedDate,
        departureTime: _formatTime(_selectedTime),
        passengerCount: _passengerCount,
        pickupAddress: _pickupController.text.trim(),
        dropoffAddress: _dropoffController.text.trim(),
        totalPrice: _calculatePrice(),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        trackingPoints: const [],
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
}
