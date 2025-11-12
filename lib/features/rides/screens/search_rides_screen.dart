import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchRidesScreen extends StatefulWidget {
  const SearchRidesScreen({super.key});

  @override
  State<SearchRidesScreen> createState() => _SearchRidesScreenState();
}

class _SearchRidesScreenState extends State<SearchRidesScreen> {
  final _searchController = TextEditingController();

  String _selectedFromDistrict = 'Любой';
  String _selectedToDistrict = 'Любой';
  DateTime _selectedDate = DateTime.now();

  final List<String> _districts = [
    'Любой',
    'Центр',
    'Спальный район',
    'Промышленный район',
    'Северный район',
    'Южный район',
    'Восточный район',
    'Западный район',
    'Новый район',
  ];

  // Моковые данные поездок
  final List<Map<String, dynamic>> _mockRides = [
    {
      'id': '1',
      'driver': 'Алексей',
      'rating': 4.8,
      'from': 'Центр',
      'to': 'Спальный район',
      'fromDetails': 'м. Тверская',
      'toDetails': 'ТЦ Мега',
      'time': '14:30',
      'date': 'Сегодня',
      'price': 120,
      'seatsAvailable': 2,
      'carModel': 'Toyota Camry',
      'carColor': 'Серебристый',
      'features': ['Некурящий', 'Кондиционер'],
    },
    {
      'id': '2',
      'driver': 'Мария',
      'rating': 4.9,
      'from': 'Северный район',
      'to': 'Центр',
      'fromDetails': 'м. Сокольники',
      'toDetails': 'м. Красные ворота',
      'time': '16:00',
      'date': 'Сегодня',
      'price': 100,
      'seatsAvailable': 3,
      'carModel': 'Hyundai Solaris',
      'carColor': 'Белый',
      'features': ['Детское кресло', 'Музыка'],
    },
    {
      'id': '3',
      'driver': 'Дмитрий',
      'rating': 4.7,
      'from': 'Западный район',
      'to': 'Восточный район',
      'fromDetails': 'м. Парк Победы',
      'toDetails': 'м. Измайловская',
      'time': '18:15',
      'date': 'Завтра',
      'price': 150,
      'seatsAvailable': 1,
      'carModel': 'BMW 3 Series',
      'carColor': 'Черный',
      'features': ['Премиум', 'Wi-Fi'],
    },
  ];

  List<Map<String, dynamic>> get _filteredRides {
    return _mockRides.where((ride) {
      final fromMatch =
          _selectedFromDistrict == 'Любой' ||
          ride['from'] == _selectedFromDistrict;
      final toMatch =
          _selectedToDistrict == 'Любой' || ride['to'] == _selectedToDistrict;

      return fromMatch && toMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Поиск поездок'),
        backgroundColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Фильтры
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: CupertinoColors.systemGrey6,
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Маршрут
                  Row(
                    children: [
                      Expanded(
                        child: _buildDistrictFilter(
                          'Откуда',
                          _selectedFromDistrict,
                          (value) =>
                              setState(() => _selectedFromDistrict = value!),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(CupertinoIcons.arrow_right, size: 16),
                      ),
                      Expanded(
                        child: _buildDistrictFilter(
                          'Куда',
                          _selectedToDistrict,
                          (value) =>
                              setState(() => _selectedToDistrict = value!),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Дата
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: CupertinoColors.white,
                    onPressed: _selectDate,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.calendar,
                          color: CupertinoColors.activeBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getDateString(_selectedDate),
                          style: const TextStyle(color: CupertinoColors.label),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Список поездок
            Expanded(
              child: _filteredRides.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.car_detailed,
                            size: 64,
                            color: CupertinoColors.systemGrey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Поездки не найдены',
                            style: TextStyle(
                              fontSize: 18,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Попробуйте изменить фильтры',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey2,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredRides.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final ride = _filteredRides[index];
                        return _buildRideCard(ride);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictFilter(
    String title,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: CupertinoColors.white,
          onPressed: () => _showDistrictPicker(value, onChanged),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(color: CupertinoColors.label),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.chevron_down,
                size: 12,
                color: CupertinoColors.systemGrey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showRideDetails(ride),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с водителем
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: CupertinoColors.activeBlue,
                    child: Text(
                      ride['driver'][0],
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['driver'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.star_fill,
                              size: 12,
                              color: CupertinoColors.systemYellow,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ride['rating'].toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${ride['price']} ₽',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      Text(
                        'за место',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Маршрут
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.location,
                    size: 16,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${ride['from']} • ${ride['fromDetails']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.location_fill,
                    size: 16,
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${ride['to']} • ${ride['toDetails']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Время и места
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.clock,
                    size: 16,
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${ride['date']} в ${ride['time']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    CupertinoIcons.person_2,
                    size: 16,
                    color: CupertinoColors.systemOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride['seatsAvailable']} мест',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ),

              // Особенности
              if (ride['features'] != null && ride['features'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: (ride['features'] as List<String>).map((feature) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
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
        title: const Text('Выберите район'),
        actions: _districts.map((district) {
          return CupertinoActionSheetAction(
            onPressed: () {
              onChanged(district);
              Navigator.pop(context);
            },
            child: Text(district),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
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
        height: 200,
        color: CupertinoColors.systemBackground,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: initialDate,
          minimumDate: minDate,
          onDateTimeChanged: (date) => setState(() => _selectedDate = date),
        ),
      ),
    );
  }

  String _getDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) return 'Сегодня';
    if (selected == tomorrow) return 'Завтра';
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showRideDetails(Map<String, dynamic> ride) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Поездка ${ride['driver']}'),
        message: Column(
          children: [
            Text('${ride['carModel']} (${ride['carColor']})'),
            const SizedBox(height: 8),
            Text('${ride['from']} → ${ride['to']}'),
            Text('${ride['date']} в ${ride['time']}'),
            Text('${ride['price']} ₽ за место'),
            Text('Свободных мест: ${ride['seatsAvailable']}'),
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _bookRide(ride);
            },
            child: const Text('Забронировать место'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _contactDriver(ride);
            },
            child: const Text('Связаться с водителем'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  void _bookRide(Map<String, dynamic> ride) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Бронирование'),
        content: Text(
          'Забронировать место в поездке ${ride['driver']}?\n'
          '${ride['from']} → ${ride['to']}\n'
          '${ride['date']} в ${ride['time']}\n'
          'Стоимость: ${ride['price']} ₽',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              // Здесь будет логика бронирования
              _showBookingSuccess(ride);
            },
            child: const Text('Забронировать'),
          ),
        ],
      ),
    );
  }

  void _showBookingSuccess(Map<String, dynamic> ride) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно!'),
        content: Text(
          'Место забронировано!\n'
          'Водитель получил уведомление.\n'
          'Ожидайте подтверждения от ${ride['driver']}.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _contactDriver(Map<String, dynamic> ride) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Связаться с ${ride['driver']}'),
        content: const Text(
          'Функция чата будет доступна после бронирования места.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
