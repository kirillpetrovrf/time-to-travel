import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../maps/screens/map_picker_screen.dart';
import '../../../config/map_config.dart';
import '../../../models/ride.dart';
import '../../../services/database_service.dart';
import '../../../theme/uber_colors.dart';
import 'my_rides_screen.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController(text: '3');

  final _fromFocusNode = FocusNode();
  final _toFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _seatsFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  String _selectedFromDistrict = 'Центр';
  String _selectedToDistrict = 'Спальный район';

  final List<String> _districts = [
    'Центр',
    'Спальный район',
    'Промышленный район',
    'Северный район',
    'Южный район',
    'Восточный район',
    'Западный район',
    'Новый район',
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Создать поездку'),
        backgroundColor: Colors.transparent,
      ),
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Откуда
              _buildDistrictPicker(
                title: 'Откуда',
                value: _selectedFromDistrict,
                onChanged: (value) =>
                    setState(() => _selectedFromDistrict = value!),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _fromController,
                placeholder: 'Уточните адрес или станцию метро',
                icon: CupertinoIcons.location,
                focusNode: _fromFocusNode,
              ),
              const SizedBox(height: 8),
              _buildMapButton(
                text: 'Выбрать на карте',
                icon: CupertinoIcons.map,
                onPressed: () => _openMapPicker(isFromLocation: true),
              ),

              const SizedBox(height: 24),

              // Куда
              _buildDistrictPicker(
                title: 'Куда',
                value: _selectedToDistrict,
                onChanged: (value) =>
                    setState(() => _selectedToDistrict = value!),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _toController,
                placeholder: 'Уточните адрес или станцию метро',
                icon: CupertinoIcons.location_fill,
                focusNode: _toFocusNode,
              ),
              const SizedBox(height: 8),
              _buildMapButton(
                text: 'Выбрать на карте',
                icon: CupertinoIcons.map_fill,
                onPressed: () => _openMapPicker(isFromLocation: false),
              ),

              const SizedBox(height: 24),

              // Дата и время
              _buildSectionTitle('Когда'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: CupertinoColors.systemGrey6,
                      onPressed: _selectDate,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.calendar,
                            color: CupertinoColors.activeBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                            style: const TextStyle(
                              color: CupertinoColors.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: CupertinoColors.systemGrey6,
                      onPressed: _selectTime,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.clock,
                            color: CupertinoColors.activeBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              color: CupertinoColors.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Количество мест и цена
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Мест'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _seatsController,
                          placeholder: '1-4',
                          keyboardType: TextInputType.number,
                          icon: CupertinoIcons.person_2,
                          focusNode: _seatsFocusNode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Цена за место'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _priceController,
                          placeholder: 'Например: 100 ₽',
                          keyboardType: TextInputType.number,
                          icon: CupertinoIcons.money_dollar,
                          focusNode: _priceFocusNode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Кнопка создания
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: CupertinoColors.activeBlue,
                  onPressed: () {
                    print('🔵 Кнопка "Создать поездку" нажата!');
                    _createRide();
                  },
                  child: const Text(
                    'Создать поездку',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Информация
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Поездка будет опубликована после проверки. Пассажиры смогут забронировать места через приложение.',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.label,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType? keyboardType,
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5),
      ),
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: true,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: CupertinoColors.label, fontSize: 16),
        placeholder: placeholder,
        placeholderStyle: const TextStyle(
          color: CupertinoColors.placeholderText,
          fontSize: 16,
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: CupertinoColors.systemGrey, size: 20),
        ),
        decoration: const BoxDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        onTap: () {
          print('CupertinoTextField onTap: $placeholder');
        },
        onChanged: (value) {
          print('Text changed in $placeholder: $value');
        },
      ),
    );
  }

  Widget _buildDistrictPicker({
    required String title,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: UberColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UberColors.lightGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: UberColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        onPressed: () => _showDistrictPicker(value, onChanged),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Показываем название только если район по умолчанию
                  Text(
                    value == _districts.first ? title : value,
                    style: TextStyle(
                      color: value == _districts.first
                          ? UberColors.mediumGray
                          : UberColors.uberBlack,
                      fontSize: value == _districts.first ? 16 : 14,
                      fontWeight: value == _districts.first
                          ? FontWeight.w500
                          : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: UberColors.mediumGray,
            ),
          ],
        ),
      ),
    );
  }

  void _showDistrictPicker(
    String currentValue,
    ValueChanged<String?> onChanged,
  ) {
    showCupertinoModalPopup(
      context: context,
      barrierColor: UberColors.blackOverlay,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: UberColors.whiteOverlay,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: UberColors.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: UberColors.lightGray, width: 1),
                ),
              ),
              child: const Text(
                'Выберите район',
                style: TextStyle(
                  color: UberColors.uberBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: _districts.map((district) {
                    final isSelected = district == currentValue;
                    return Container(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        onPressed: () {
                          onChanged(district);
                          Navigator.pop(context);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                district,
                                style: TextStyle(
                                  color: isSelected
                                      ? UberColors.green
                                      : UberColors.uberBlack,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                CupertinoIcons.checkmark,
                                color: UberColors.green,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                color: UberColors.lightGray,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Отмена',
                  style: TextStyle(
                    color: UberColors.uberBlack,
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

  void _selectDate() async {
    final now = DateTime.now();
    final minDate = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDate.isBefore(minDate)
        ? minDate
        : _selectedDate;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Готово',
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
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
                initialDateTime: initialDate,
                minimumDate: minDate,
                onDateTimeChanged: (date) =>
                    setState(() => _selectedDate = date),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTime() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Готово',
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  2023,
                  1,
                  1,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                onDateTimeChanged: (time) => setState(
                  () => _selectedTime = TimeOfDay.fromDateTime(time),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRide() async {
    print('🔵 [CREATE_RIDE] === _createRide() вызвана ===');

    // Проверяем заполненность обязательных полей
    if (_fromController.text.trim().isEmpty) {
      print('❌ [CREATE_RIDE] Ошибка: пустое поле отправления');
      _showErrorDialog('Ошибка', 'Пожалуйста, укажите адрес отправления');
      return;
    }

    if (_toController.text.trim().isEmpty) {
      print('❌ [CREATE_RIDE] Ошибка: пустое поле назначения');
      _showErrorDialog('Ошибка', 'Пожалуйста, укажите адрес назначения');
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      print('❌ [CREATE_RIDE] Ошибка: пустое поле цены');
      _showErrorDialog('Ошибка', 'Пожалуйста, укажите цену за место');
      return;
    }

    print('✅ [CREATE_RIDE] Все поля заполнены, создаем поездку в базе данных');

    try {
      // Парсим количество мест и цену
      final seats = int.tryParse(_seatsController.text) ?? 3;
      final price =
          double.tryParse(_priceController.text.replaceAll('₽', '').trim()) ??
          0.0;

      print('📊 [CREATE_RIDE] Параметры: seats=$seats, price=$price');

      if (price <= 0) {
        print('❌ [CREATE_RIDE] Ошибка: некорректная цена');
        _showErrorDialog('Ошибка', 'Пожалуйста, укажите корректную цену');
        return;
      }

      // Создаем DateTime для отправления
      final departureDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      print('⏰ [CREATE_RIDE] Дата/время отправления: $departureDateTime');

      // В реальном приложении здесь будут данные текущего пользователя
      const currentDriverId = 'driver_1';
      const currentDriverName = 'Алексей';
      const currentDriverPhone = '+7 (999) 111-22-33';

      // Создаем объект поездки
      final rideId = DatabaseService.instance.generateId();
      print('🆔 [CREATE_RIDE] Сгенерирован ID поездки: $rideId');

      final ride = Ride(
        id: rideId,
        driverId: currentDriverId,
        driverName: currentDriverName,
        driverPhone: currentDriverPhone,
        fromAddress: _fromController.text.trim(),
        toAddress: _toController.text.trim(),
        fromDistrict: _selectedFromDistrict,
        toDistrict: _selectedToDistrict,
        fromDetails: _fromController.text.trim(),
        toDetails: _toController.text.trim(),
        departureTime: departureDateTime,
        availableSeats: seats,
        totalSeats: seats,
        pricePerSeat: price,
        status: RideStatus.active,
        description: 'Поездка создана через приложение',
        createdAt: DateTime.now(),
      );

      print('📦 [CREATE_RIDE] Объект Ride создан: ${ride.id}');
      print('   От: ${ride.fromAddress}');
      print('   До: ${ride.toAddress}');
      print('   Статус: ${ride.status}');

      // Сохраняем поездку в базу данных
      print('💾 [CREATE_RIDE] Вызываем DatabaseService.createRide()...');
      final savedId = await DatabaseService.instance.createRide(ride);
      print('✅ [CREATE_RIDE] DatabaseService.createRide() вернул ID: $savedId');

      print('✅ [CREATE_RIDE] Поездка успешно создана и сохранена в БД!');

      // Показываем диалог успеха
      print('📝 [CREATE_RIDE] Вызываем _showSuccessDialog...');
      if (mounted) {
        _showSuccessDialog(ride);
      } else {
        print('❌ [CREATE_RIDE] Виджет не смонтирован, не показываем диалог');
      }
    } catch (e, stackTrace) {
      print('❌❌❌ [CREATE_RIDE] КРИТИЧЕСКАЯ ОШИБКА при создании поездки: $e');
      print('Stack trace: $stackTrace');
      _showErrorDialog(
        'Ошибка создания поездки',
        'Не удалось создать поездку: $e',
      );
    }
  }

  void _showSuccessDialog(Ride ride) {
    print('🎉 Показываем диалог успеха для поездки: ${ride.id}');

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Поездка создана!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            'Маршрут: ${ride.fromDistrict} → ${ride.toDistrict}\n'
            'Откуда: ${ride.fromAddress}\n'
            'Куда: ${ride.toAddress}\n'
            'Время: ${_formatDateTime(ride.departureTime)}\n'
            'Мест: ${ride.totalSeats}\n'
            'Цена: ${ride.pricePerSeat.toInt()} ₽ за место\n\n'
            'Поездка успешно опубликована! Пассажиры могут найти её в поиске и забронировать места.\n\n'
            'Переключитесь на вкладку "Главная" чтобы увидеть созданную поездку.',
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 14,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              print('👍 Пользователь выбрал "Создать еще поездку"');
              Navigator.pop(context); // Закрываем диалог
              if (mounted) {
                _clearForm(); // Очищаем форму для создания новой поездки
              }
            },
            child: const Text(
              'Создать еще',
              style: TextStyle(
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              print(
                '✅ Пользователь выбрал "Готово" - переходим к Моим поездкам',
              );
              Navigator.pop(context); // Закрываем диалог
              if (mounted) {
                _clearForm(); // Очищаем форму

                // Переходим на экран "Мои поездки"
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const MyRidesScreen(),
                  ),
                );
              }
            },
            child: const Text(
              'Готово',
              style: TextStyle(
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (date == today) {
      dateStr = 'Сегодня';
    } else if (date == tomorrow) {
      dateStr = 'Завтра';
    } else {
      dateStr = '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }

    return '$dateStr в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            color: CupertinoColors.destructiveRed,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            message,
            style: const TextStyle(color: CupertinoColors.secondaryLabel),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка для выбора на карте
  Widget _buildMapButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: CupertinoColors.systemGrey6,
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: CupertinoColors.systemBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: CupertinoColors.systemBlue,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Открытие экрана выбора на карте
  void _openMapPicker({required bool isFromLocation}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
        builder: (context) => MapPickerScreen(
          pointType: isFromLocation
              ? MapPointType.pickup
              : MapPointType.dropoff,
          title: isFromLocation
              ? 'Выберите место посадки'
              : 'Выберите место высадки',
        ),
      ),
    );

    if (result != null && mounted) {
      final address = result['address'] as String?;
      if (address != null) {
        if (isFromLocation) {
          _fromController.text = address;
        } else {
          _toController.text = address;
        }
      }
    }
  }

  /// Очистка формы после создания поездки
  void _clearForm() {
    _fromController.clear();
    _toController.clear();
    _priceController.clear();
    _seatsController.text = '3'; // Сбрасываем к значению по умолчанию

    setState(() {
      _selectedFromDistrict = 'Центр';
      _selectedToDistrict = 'Спальный район';
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });

    print('Форма очищена для создания новой поездки');
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _priceController.dispose();
    _seatsController.dispose();

    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    _priceFocusNode.dispose();
    _seatsFocusNode.dispose();

    super.dispose();
  }
}
