import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/trip_type.dart';
import '../../../models/booking.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../theme/theme_manager.dart';

class IndividualBookingScreen extends StatefulWidget {
  const IndividualBookingScreen({super.key});

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

                    // Комендантский час предупреждение
                    if (_isNightTime()) _buildNightTimeWarning(theme),

                    // Стоимость
                    _buildPricingSummary(theme),
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
    final basePrice = _selectedDirection == Direction.donetskToRostov
        ? TripPricing.individualTripPrice
        : TripPricing.individualTripPrice;
    final nightSurcharge =
        _isNightTime() && _selectedDirection == Direction.donetskToRostov
        ? 2000
        : 0;

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

          if (nightSurcharge > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Базовая стоимость',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.secondaryLabel.withOpacity(0.7),
                  ),
                ),
                Text(
                  '$basePrice ₽',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.secondaryLabel.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ночная доплата',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.secondaryLabel.withOpacity(0.7),
                  ),
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
            const SizedBox(height: 8),
            Divider(color: theme.separator.withOpacity(0.3)),
            const SizedBox(height: 8),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Общая стоимость',
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
            style: TextStyle(
              fontSize: 14,
              color: theme.secondaryLabel.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  bool _isNightTime() {
    return _selectedTime.hour >= 22;
  }

  int _calculatePrice() {
    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    return TripPricing.getIndividualTripPrice(timeString, _selectedDirection);
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

      if (mounted) {
        _showSuccessDialog(bookingId);
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

  void _showSuccessDialog(String bookingId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно!'),
        content: Text(
          'Ваше бронирование создано.\nНомер заказа: ${bookingId.substring(0, 8)}',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
              Navigator.pop(context); // Возвращаемся на предыдущий экран
            },
          ),
        ],
      ),
    );
  }
}
