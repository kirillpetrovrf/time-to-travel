import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/trip_type.dart';
import '../../../models/booking.dart';
import '../../../models/user.dart';
import '../../../models/trip_settings.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/trip_settings_service.dart';
import '../../../theme/theme_manager.dart';
import '../../admin/screens/admin_panel_screen.dart';

class GroupBookingScreen extends StatefulWidget {
  const GroupBookingScreen({super.key});

  @override
  State<GroupBookingScreen> createState() => _GroupBookingScreenState();
}

class _GroupBookingScreenState extends State<GroupBookingScreen> {
  Direction _selectedDirection = Direction.donetskToRostov;
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '';
  String _selectedPickupPoint = '';
  int _passengerCount = 1;
  bool _isLoading = true;
  UserType? _userType;
  TripSettings? _tripSettings;
  final TripSettingsService _settingsService = TripSettingsService();

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
        _passengerCount = 1;
        _isLoading = false;

        // Устанавливаем начальные значения из настроек
        if (settings.departureTimes.isNotEmpty) {
          _selectedTime = settings.departureTimes.first;
        }
        if (settings.donetskPickupPoints.isNotEmpty) {
          _selectedPickupPoint = settings.donetskPickupPoints.first;
        }
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
                    // Направление
                    _buildSectionTitle('Направление', theme),
                    _buildDirectionPicker(theme),

                    const SizedBox(height: 24),

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
                            : 'Забронировать за ${(_tripSettings?.pricing['groupTripPrice'] ?? 2000) * _passengerCount} ₽',
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

    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        children: departureTimes.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          return Column(
            children: [
              if (index > 0)
                Divider(height: 1, color: theme.separator.withOpacity(0.2)),
              _buildRadioTile(
                theme: theme,
                title: time,
                value: time,
                groupValue: _selectedTime,
                onChanged: (value) => setState(() => _selectedTime = value!),
              ),
            ],
          );
        }).toList(),
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

    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        children: pickupPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return Column(
            children: [
              if (index > 0)
                Divider(height: 1, color: theme.separator.withOpacity(0.2)),
              _buildRadioTile(
                theme: theme,
                title: point,
                value: point,
                groupValue: _selectedPickupPoint,
                onChanged: (value) =>
                    setState(() => _selectedPickupPoint = value!),
              ),
            ],
          );
        }).toList(),
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
                  color: _passengerCount > 1 ? theme.primary : theme.separator,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.minus,
                  color: _passengerCount > 1
                      ? CupertinoColors.white
                      : theme.secondaryLabel,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _passengerCount < (_tripSettings?.maxPassengers ?? 8)
                  ? () => setState(() => _passengerCount++)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _passengerCount < (_tripSettings?.maxPassengers ?? 8)
                      ? theme.primary
                      : theme.separator,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.plus,
                  color: _passengerCount < (_tripSettings?.maxPassengers ?? 8)
                      ? CupertinoColors.white
                      : theme.secondaryLabel,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSummary(theme) {
    final groupPrice = _tripSettings?.pricing['groupTripPrice'] ?? 2000;
    final totalPrice = groupPrice * _passengerCount;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_passengerCount × $groupPrice ₽',
                style: TextStyle(fontSize: 18, color: theme.secondaryLabel),
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
            'Оплата при посадке в автомобиль',
            style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
          ),
        ],
      ),
    );
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
                initialDateTime: _selectedDate.isBefore(DateTime.now())
                    ? DateTime.now()
                    : _selectedDate,
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(const Duration(days: 30)),
                onDateTimeChanged: (date) {
                  setState(() => _selectedDate = date);
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

  Future<void> _bookTrip() async {
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
        departureDate: _selectedDate,
        departureTime: _selectedTime,
        passengerCount: _passengerCount,
        pickupPoint: _selectedDirection == Direction.donetskToRostov
            ? _selectedPickupPoint
            : null,
        totalPrice:
            (_tripSettings?.pricing['groupTripPrice'] ?? 2000) *
            _passengerCount,
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

  Future<void> _saveSettings() async {
    // Для диспетчеров открываем административную панель
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const AdminPanelScreen()),
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
