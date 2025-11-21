import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/ride.dart';
import '../../../models/booking.dart';
import '../../../services/database_service.dart';
import '../../../services/chat_service.dart';
import '../../../theme/uber_colors.dart';
import '../../chat/screens/chat_screen.dart';

class SearchRidesScreen extends StatefulWidget {
  const SearchRidesScreen({super.key});

  @override
  State<SearchRidesScreen> createState() => _SearchRidesScreenState();
}

class _SearchRidesScreenState extends State<SearchRidesScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final _searchController = TextEditingController();

  String _selectedFromDistrict = 'Любой';
  String _selectedToDistrict = 'Любой';
  DateTime _selectedDate = DateTime.now();
  List<Ride> _rides = [];
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() => _isLoading = true);

    try {
      print(
        '🔍 Загружаем поездки. Фильтры: from=$_selectedFromDistrict, to=$_selectedToDistrict, date=$_selectedDate',
      );

      final rides = await _databaseService.searchRides(
        fromDistrict: _selectedFromDistrict == 'Любой'
            ? null
            : _selectedFromDistrict,
        toDistrict: _selectedToDistrict == 'Любой' ? null : _selectedToDistrict,
      );

      print('📊 Найдено поездок в БД: ${rides.length}');
      for (final ride in rides) {
        print(
          '   - ${ride.id}: ${ride.fromDistrict} → ${ride.toDistrict}, дата: ${ride.departureTime}, статус: ${ride.status}',
        );
      }

      // Фильтруем по дате (показываем поездки начиная со вчерашнего дня)
      final filteredRides = rides.where((ride) {
        final rideDate = DateTime(
          ride.departureTime.year,
          ride.departureTime.month,
          ride.departureTime.day,
        );
        final selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        final yesterday = selectedDate.subtract(const Duration(days: 1));
        final matches =
            rideDate.isAtSameMomentAs(selectedDate) ||
            rideDate.isAfter(yesterday); // Показываем от вчера и позже
        print(
          '   - Поездка ${ride.id}: дата поездки $rideDate vs выбранная дата $selectedDate (от $yesterday) = $matches',
        );
        return matches;
      }).toList();

      print(
        '✅ После фильтрации по дате остается поездок: ${filteredRides.length}',
      );

      setState(() {
        _rides = filteredRides;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка при загрузке поездок: $e');
      setState(() => _isLoading = false);
      _showErrorDialog('Ошибка загрузки', 'Не удалось загрузить поездки');
    }
  }

  List<Ride> get _filteredRides {
    return _rides.where((ride) {
      final fromMatch =
          _selectedFromDistrict == 'Любой' ||
          ride.fromDistrict == _selectedFromDistrict;
      final toMatch =
          _selectedToDistrict == 'Любой' ||
          ride.toDistrict == _selectedToDistrict;

      return fromMatch && toMatch && ride.status == RideStatus.active;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: UberColors.backgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Найти поездку',
          style: TextStyle(
            color: UberColors.uberBlack,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: UberColors.whiteOverlay,
        border: null,
        trailing: Container(
          decoration: BoxDecoration(
            color: UberColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: UberColors.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onPressed: _selectDate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.calendar,
                  color: UberColors.uberBlack,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _getDateString(_selectedDate),
                  style: const TextStyle(
                    color: UberColors.uberBlack,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Фильтры в стиле Uber
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: UberColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: UberColors.cardShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: UberColors.backgroundGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.arrow_right,
                          size: 16,
                          color: UberColors.mediumGray,
                        ),
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
                ],
              ),
            ),

            // Список поездок
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        color: UberColors.uberBlack,
                      ),
                    )
                  : _filteredRides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: UberColors.backgroundGray,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              CupertinoIcons.car_detailed,
                              size: 48,
                              color: UberColors.mediumGray,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Поездки не найдены',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: UberColors.uberBlack,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Попробуйте изменить фильтры поиска',
                            style: TextStyle(
                              fontSize: 16,
                              color: UberColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        CupertinoSliverRefreshControl(
                          onRefresh: _loadRides,
                          builder:
                              (
                                context,
                                refreshState,
                                pulledExtent,
                                refreshTriggerPullDistance,
                                refreshIndicatorExtent,
                              ) {
                                return Container(
                                  padding: const EdgeInsets.only(top: 16),
                                  alignment: Alignment.center,
                                  child: const CupertinoActivityIndicator(
                                    color: UberColors.uberBlack,
                                  ),
                                );
                              },
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final ride = _filteredRides[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildRideCard(ride),
                              );
                            }, childCount: _filteredRides.length),
                          ),
                        ),
                      ],
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
    final bool isSelected = value != 'Любой';

    return Container(
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
                  if (!isSelected) ...[
                    // Показываем "Откуда" или "Куда" только если район не выбран
                    Text(
                      title,
                      style: const TextStyle(
                        color: UberColors.mediumGray,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    // Показываем выбранный район
                    Text(
                      value,
                      style: const TextStyle(
                        color: UberColors.uberBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
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

  Widget _buildRideCard(Ride ride) {
    return Container(
      decoration: BoxDecoration(
        color: UberColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: UberColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showRideDetails(ride),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с водителем в стиле Uber
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [UberColors.blue, UberColors.green],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        ride.driverName.isNotEmpty ? ride.driverName[0] : 'В',
                        style: const TextStyle(
                          color: UberColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: UberColors.uberBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: UberColors.yellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.star_fill,
                                    size: 10,
                                    color: UberColors.yellow,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '4.8',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: UberColors.uberBlack,
                                    ),
                                  ),
                                ],
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
                        '${ride.pricePerSeat.toInt()} ₽',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: UberColors.uberBlack,
                        ),
                      ),
                      const Text(
                        'за место',
                        style: TextStyle(
                          fontSize: 12,
                          color: UberColors.mediumGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Маршрут в стиле Uber
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: UberColors.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: UberColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.fromDistrict,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: UberColors.uberBlack,
                                ),
                              ),
                              if (ride.fromDetails != null &&
                                  ride.fromDetails!.isNotEmpty)
                                Text(
                                  ride.fromDetails!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: UberColors.mediumGray,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: UberColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.toDistrict,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: UberColors.uberBlack,
                                ),
                              ),
                              if (ride.toDetails != null &&
                                  ride.toDetails!.isNotEmpty)
                                Text(
                                  ride.toDetails!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: UberColors.mediumGray,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Время и места в стиле Uber
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: UberColors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.clock,
                          size: 12,
                          color: UberColors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(ride.departureTime),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: UberColors.uberBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: UberColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.person_2,
                          size: 12,
                          color: UberColors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.availableSeats} мест',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: UberColors.uberBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Описание поездки
              if (ride.description != null && ride.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UberColors.lightOverlay,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ride.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: UberColors.mediumGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: UberColors.uberBlack,
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
                      decoration: BoxDecoration(
                        color: isSelected
                            ? UberColors.green.withOpacity(0.1)
                            : UberColors.white,
                      ),
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
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? UberColors.green
                                      : UberColors.uberBlack,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                CupertinoIcons.checkmark,
                                color: UberColors.green,
                                size: 18,
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
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: UberColors.lightGray, width: 1),
                ),
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.all(16),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Отмена',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: UberColors.mediumGray,
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

  void _showRideDetails(Ride ride) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Поездка ${ride.driverName}'),
        message: Column(
          children: [
            Text('${ride.fromDistrict} → ${ride.toDistrict}'),
            const SizedBox(height: 8),
            Text('Откуда: ${ride.fromAddress}'),
            Text('Куда: ${ride.toAddress}'),
            Text(_formatDateTime(ride.departureTime)),
            Text('${ride.pricePerSeat.toInt()} ₽ за место'),
            Text('Свободных мест: ${ride.availableSeats}'),
            if (ride.description != null && ride.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Описание: ${ride.description}'),
            ],
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

  void _bookRide(Ride ride) {
    int seatsToBook = 1;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Бронирование'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Забронировать место в поездке ${ride.driverName}?\n'
              '${ride.fromDistrict} → ${ride.toDistrict}\n'
              '${_formatDateTime(ride.departureTime)}\n'
              'Стоимость: ${ride.pricePerSeat.toInt()} ₽ за место',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Количество мест: '),
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  onPressed: seatsToBook > 1
                      ? () {
                          // В реальном приложении здесь будет setState
                        }
                      : null,
                  child: const Icon(CupertinoIcons.minus),
                ),
                Text(' $seatsToBook '),
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  onPressed: seatsToBook < ride.availableSeats
                      ? () {
                          // В реальном приложении здесь будет setState
                        }
                      : null,
                  child: const Icon(CupertinoIcons.plus),
                ),
              ],
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              await _createBooking(ride, seatsToBook);
            },
            child: const Text('Забронировать'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBooking(Ride ride, int seatsToBook) async {
    try {
      // В реальном приложении здесь будет ID текущего пользователя
      const currentUserId = 'passenger_1';
      const currentUserName = 'Анна';
      const currentUserPhone = '+7 (999) 123-45-67';

      final booking = Booking(
        id: _databaseService.generateId(),
        rideId: ride.id,
        passengerId: currentUserId,
        passengerName: currentUserName,
        passengerPhone: currentUserPhone,
        seatsBooked: seatsToBook,
        totalPrice: ride.pricePerSeat * seatsToBook,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        rideFrom: ride.fromAddress,
        rideTo: ride.toAddress,
        rideDriverName: ride.driverName,
        rideDepartureTime: ride.departureTime,
      );

      await _databaseService.createBooking(booking);

      // Создаем чат с водителем после успешного бронирования
      final chatService = ChatService.instance;
      await chatService.createChatForBooking(
        rideId: ride.id,
        driverName: ride.driverName,
        route: '${ride.fromDistrict} → ${ride.toDistrict}',
      );

      _showBookingSuccess(ride);

      // Обновляем список поездок
      await _loadRides();
    } catch (e) {
      _showErrorDialog(
        'Ошибка бронирования',
        'Не удалось забронировать место: $e',
      );
    }
  }

  void _showBookingSuccess(Ride ride) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно!'),
        content: Text(
          'Место забронировано!\n'
          'Водитель получил уведомление.\n'
          'Ожидайте подтверждения от ${ride.driverName}.',
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

  void _contactDriver(Ride ride) async {
    try {
      // Создаем чат с водителем
      final chatService = ChatService.instance;

      // Проверяем, существует ли уже чат для этой поездки
      var conversation = await chatService.findByRideId(ride.id);

      if (conversation == null) {
        // Создаем новый чат
        conversation = await chatService.createChatForBooking(
          rideId: ride.id,
          driverName: ride.driverName,
          route: '${ride.fromDistrict} → ${ride.toDistrict}',
        );

        // Добавляем системное сообщение о начале чата
        await chatService.updateLastMessage(
          conversationId: conversation.id,
          message: 'Чат создан. Теперь вы можете общаться с водителем!',
          isFromUser: false,
        );
      }

      // Открываем чат
      if (mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => ChatScreen(ride: ride)),
        );
      }
    } catch (e) {
      _showErrorDialog('Ошибка', 'Не удалось создать чат с водителем: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
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
