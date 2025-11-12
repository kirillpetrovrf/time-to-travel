import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../maps/screens/map_picker_screen.dart';
import '../../../config/map_config.dart';

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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Откуда
              _buildSectionTitle('Откуда'),
              const SizedBox(height: 8),
              _buildDistrictPicker(
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
              _buildSectionTitle('Куда'),
              const SizedBox(height: 8),
              _buildDistrictPicker(
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
              
              // Отступ снизу для системных кнопок навигации
              const SizedBox(height: 60),
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
    return CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      keyboardType: keyboardType ?? TextInputType.text,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: true,
      readOnly: false,
      enabled: true,
      textAlignVertical: TextAlignVertical.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5),
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Icon(icon, color: CupertinoColors.systemGrey),
      ),
      onTap: () {
        print('TextField onTap: $placeholder');
        // Принудительно запрашиваем фокус
        if (focusNode != null && !focusNode.hasFocus) {
          FocusScope.of(context).requestFocus(focusNode);
          // Дополнительная попытка через небольшую задержку
          Future.delayed(const Duration(milliseconds: 50), () {
            if (!focusNode.hasFocus) {
              focusNode.requestFocus();
            }
          });
        }
      },
      onChanged: (value) {
        print('Text changed in $placeholder: $value');
      },
    );
  }

  Widget _buildDistrictPicker({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showDistrictPicker(value, onChanged),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: const TextStyle(color: CupertinoColors.label)),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: CupertinoColors.systemGrey,
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
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Выберите район',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: _districts.map((district) {
          return CupertinoActionSheetAction(
            onPressed: () {
              onChanged(district);
              Navigator.pop(context);
            },
            child: Text(
              district,
              style: const TextStyle(
                color: CupertinoColors.activeBlue,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Отмена',
            style: TextStyle(
              color: CupertinoColors.destructiveRed,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  void _createRide() {
    print('=== _createRide() вызвана ===');

    // Проверяем заполненность обязательных полей
    if (_fromController.text.trim().isEmpty) {
      print('Ошибка: пустое поле отправления');
      _showErrorDialog('Ошибка', 'Пожалуйста, укажите адрес отправления');
      return;
    }

    if (_toController.text.trim().isEmpty) {
      print('Ошибка: пустое поле назначения');
      _showErrorDialog('Ошибка', 'Пожалуйста, укажите адрес назначения');
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      print('Ошибка: пустое поле цены');
      _showErrorDialog('Ошибка', 'Пожалуйста, укажите цену за место');
      return;
    }

    print('Все поля заполнены, показываем диалог подтверждения');

    // Показываем Action Sheet вместо Alert Dialog
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Поездка создана!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        message: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Маршрут: $_selectedFromDistrict → $_selectedToDistrict\n'
            'Откуда: ${_fromController.text}\n'
            'Куда: ${_toController.text}\n'
            'Дата: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}\n'
            'Время: ${_selectedTime.format(context)}\n'
            'Мест: ${_seatsController.text}\n'
            'Цена: ${_priceController.text} ₽\n\n'
            'Поездка будет опубликована после проверки.',
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 14,
            ),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              print('Нажата кнопка OK в диалоге');
              Navigator.pop(context); // Закрываем Action Sheet
              // Остаемся на экране создания поездки для создания новой поездки
              if (mounted) {
                _clearForm(); // Очищаем форму для создания новой поездки
              }
            },
            child: const Text(
              'Создать еще поездку',
              style: TextStyle(
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              print('Нажата кнопка "Вернуться на главную"');
              Navigator.pop(context); // Закрываем Action Sheet
              if (mounted) {
                Navigator.pop(context); // Возвращаемся на главный экран
              }
            },
            child: const Text(
              'Вернуться на главную',
              style: TextStyle(color: CupertinoColors.activeBlue, fontSize: 16),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            print('Нажата кнопка Отмена в диалоге');
            Navigator.pop(context); // Просто закрываем диалог
          },
          child: const Text(
            'Остаться на экране',
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
          ),
        ),
      ),
    );
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
