import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;
import '../models/taxi_order.dart';
import '../models/passenger_info.dart';
import '../models/baggage.dart';
import '../models/pet_info_v3.dart';
import '../models/trip_type.dart';
import '../theme/theme_manager.dart';
import '../theme/app_theme.dart';
import '../features/booking/screens/baggage_selection_screen_v3.dart';
import '../features/booking/widgets/simple_pet_selection_sheet.dart';
import '../features/booking/screens/vehicle_selection_screen.dart';

/// Модальное окно пошагового бронирования для свободного маршрута
class CustomRouteBookingModal extends StatefulWidget {
  final String fromAddress;
  final String toAddress;
  final mapkit.Point? fromPoint;
  final mapkit.Point? toPoint;
  final double? distanceKm;
  final double basePrice;
  final double baseCost;
  final double costPerKm;

  const CustomRouteBookingModal({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    this.fromPoint,
    this.toPoint,
    this.distanceKm,
    required this.basePrice,
    required this.baseCost,
    required this.costPerKm,
  });

  @override
  State<CustomRouteBookingModal> createState() => _CustomRouteBookingModalState();
}

class _CustomRouteBookingModalState extends State<CustomRouteBookingModal> {
  // Для свободного маршрута всегда считаем это индивидуальной поездкой
  // (весь багаж бесплатный). Выделено сюда, чтобы использовать в нескольких местах.
  bool get _isIndividualTrip => true;
  int _currentStep = 0;
  final int _totalSteps = 9;

  // Данные бронирования
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<PassengerInfo> _passengers = [PassengerInfo(type: PassengerType.adult)];
  List<BaggageItem> _baggage = [];
  List<PetInfo> _pets = [];
  String _notes = '';
  // Если не выбран - сохранится null, в деталях заказа покажется Седан (0₽)
  VehicleClass? _selectedVehicleClass;

  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Переход к следующему шагу
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeBooking();
    }
  }

  /// Возврат к предыдущему шагу
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  /// Проверяет, является ли маршрут до/от КПП Успенки
  /// Для таких маршрутов ночная доплата 1000₽ вместо 2000₽
  bool _isUspenkaRoute() {
    final from = widget.fromAddress.toLowerCase();
    final to = widget.toAddress.toLowerCase();
    return from.contains('успенка') || to.contains('успенка') ||
           from.contains('кпп') || to.contains('кпп');
  }
  
  /// Возвращает ночную доплату в зависимости от маршрута
  int _getNightSurcharge() {
    return _isUspenkaRoute() ? 1000 : 2000;
  }
  
  /// Проверяет, является ли время ночным (22:00 - 03:59)
  bool _isNightTimeHour() {
    return _selectedTime.hour >= 22 || _selectedTime.hour < 4;
  }

  /// Расчёт итоговой цены
  double _calculateTotalPrice() {
    double total = widget.basePrice;

    // Ночная доплата (22:00 - 03:59)
    // Для маршрутов до КПП Успенка: +1000₽
    // Для остальных маршрутов: +2000₽
    if (_isNightTimeHour()) {
      total += _getNightSurcharge();
    }

    // Животные
    for (final pet in _pets) {
      total += pet.cost;
    }

    // Транспорт (доплата за класс)
    if (_selectedVehicleClass != null) {
      total += _selectedVehicleClass!.extraPrice;
    }

    return total;
  }

  /// Завершение бронирования
  void _completeBooking() {
    // Проверка обязательных полей
    if (_passengers.isEmpty) {
      _showError('Добавьте хотя бы одного пассажира');
      return;
    }

    print('🎯 [BOOKING] Начало создания заказа...');
    
    // Подготовка данных для отладки
    final passengersJson = jsonEncode(_passengers.map((p) => p.toJson()).toList());
    final baggageJson = _baggage.isNotEmpty ? jsonEncode(_baggage.map((b) => b.toJson()).toList()) : null;
    final petsJson = _pets.isNotEmpty ? jsonEncode(_pets.map((p) => p.toJson()).toList()) : null;
    
    // Детальное логирование данных
    print('📊 [BOOKING] Данные заказа:');
    print('  👥 Пассажиры (${_passengers.length}): $passengersJson');
    print('  🎒 Багаж (${_baggage.where((b) => b.quantity > 0).length} типов): $baggageJson');
    print('  🐕 Животные (${_pets.length}): $petsJson');
    print('  🚗 Транспорт: ${_selectedVehicleClass?.name ?? "не выбран"}');
    print('  💬 Комментарии: ${_notes.isNotEmpty ? _notes : "отсутствуют"}');
    print('  💰 Итоговая цена: ${_calculateTotalPrice()}₽');

    // Создание заказа
    final order = TaxiOrder(
      orderId: const Uuid().v4(),
      timestamp: DateTime.now(),
      fromPoint: widget.fromPoint!,
      toPoint: widget.toPoint!,
      fromAddress: widget.fromAddress,
      toAddress: widget.toAddress,
      distanceKm: widget.distanceKm ?? 0,
      rawPrice: widget.basePrice,
      finalPrice: _calculateTotalPrice(),
      baseCost: widget.baseCost,
      costPerKm: widget.costPerKm,
      status: 'pending',
      isSynced: false,
      departureDate: _selectedDate,
      departureTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      passengersJson: passengersJson,
      baggageJson: baggageJson,
      petsJson: petsJson,
      notes: _notes.isNotEmpty ? _notes : null,
      vehicleClass: _selectedVehicleClass?.toString().split('.').last,
    );

    print('✅ [BOOKING] TaxiOrder создан с ID: ${order.orderId}');
    print('📤 [BOOKING] Возвращаем заказ в main_screen...');

    Navigator.of(context).pop(order);
  }

  /// Показать ошибку
  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: _buildStepContent(),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Заголовок модального окна
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Бронирование',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(CupertinoIcons.xmark_circle_fill),
          ),
        ],
      ),
    );
  }

  /// Индикатор прогресса
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'Шаг ${_currentStep + 1} из $_totalSteps',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isCompleted
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey4,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Содержимое текущего шага
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDateStep();
      case 1:
        return _buildTimeStep();
      case 2:
        return _buildPassengersStep();
      case 3:
        return _buildChildrenStep();
      case 4:
        return _buildBaggageStep();
      case 5:
        return _buildPetsStep();
      case 6:
        return _buildNotesStep();
      case 7:
        return _buildVehicleStep();
      case 8:
        return _buildConfirmationStep();
      default:
        return const SizedBox();
    }
  }

  /// Шаг 1: Дата поездки
  Widget _buildDateStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Дата поездки',
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите дату отправления',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 250,
            child: CupertinoDatePicker(
              key: const ValueKey('date_picker'), // ✅ Уникальный ключ для пикера даты
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _selectedDate,
              minimumDate: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
              maximumDate: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ).add(const Duration(days: 30)),
              onDateTimeChanged: (DateTime newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Шаг 2: Время отправления
  Widget _buildTimeStep() {
    final isNightTime = _isNightTimeHour();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Время отправления',
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите время поездки',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          if (isNightTime) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.moon_stars,
                    color: CupertinoColors.systemYellow,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ночная доплата: +${_getNightSurcharge()} ₽',
                      style: TextStyle(
                        color: CupertinoColors.label.resolveFrom(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            height: 250,
            child: CupertinoDatePicker(
              key: const ValueKey('time_picker'), // ✅ Уникальный ключ для пикера времени
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: DateTime(
                2024,
                1,
                1,
                _selectedTime.hour,
                _selectedTime.minute,
              ),
              onDateTimeChanged: (DateTime newTime) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: newTime.hour,
                    minute: newTime.minute,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Шаг 3: Пассажиры
  Widget _buildPassengersStep() {
    final theme = context.themeManager.currentTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Пассажиры',
          textAlign: TextAlign.center,
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
            color: theme.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Добавьте пассажиров (минимум 1, максимум 8)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            child: Text(
                              passenger.displayName,
                              style: TextStyle(
                                color: theme.label,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_passengers.length > 1)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  _passengers.removeAt(index);
                                });
                              },
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
                  onPressed: () {
                    setState(() {
                      _passengers.add(PassengerInfo(type: PassengerType.adult));
                    });
                  },
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
        ),
      ],
    );
  }

  /// Шаг 4: Дети
  Widget _buildChildrenStep() {
    final theme = context.themeManager.currentTheme;
    final childrenCount = _passengers.where((p) => p.type == PassengerType.child).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Дети',
          textAlign: TextAlign.center,
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
            color: theme.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Добавьте детей с автокреслами (опционально)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        
        // Показываем детей, если они есть
        if (childrenCount > 0) ...[
          Container(
            decoration: BoxDecoration(
              color: theme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.separator.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // Список детей
                ..._passengers
                    .asMap()
                    .entries
                    .where((e) => e.value.type == PassengerType.child)
                    .map((entry) {
                  final index = _passengers.indexOf(entry.value);
                  final child = entry.value;
                  
                  return Column(
                    children: [
                      if (entry.key > 0)
                        Divider(height: 1, color: theme.separator.withOpacity(0.2)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.smiley, color: theme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child.displayName,
                                    style: TextStyle(color: theme.label, fontSize: 16),
                                  ),
                                  if (child.seatInfo.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      child.seatInfo,
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
                              onPressed: () {
                                setState(() {
                                  _passengers.removeAt(index);
                                });
                              },
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
                
                // Кнопка добавить ребёнка
                if (_passengers.length < 8) ...[
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
          ),
          const SizedBox(height: 16),
        ],
        
        // Кнопка "Добавить ребёнка" если детей нет
        if (childrenCount == 0 && _passengers.length < 8)
          Container(
            decoration: BoxDecoration(
              color: theme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.separator.withOpacity(0.2)),
            ),
            child: CupertinoButton(
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
          ),
          
        // Информационное сообщение
        if (childrenCount == 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  color: theme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Детские автокресла предоставляются бесплатно',
                    style: TextStyle(
                      color: theme.secondaryLabel,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  /// Показать модальное окно добавления ребёнка
  Future<void> _showAddChildModal(CustomTheme theme) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => _ChildConfigurationModal(
        theme: theme,
        onSave: (int ageMonths, ChildSeatType seatType, bool useOwnSeat) {
          setState(() {
            _passengers.add(
              PassengerInfo(
                type: PassengerType.child,
                seatType: seatType,
                useOwnSeat: useOwnSeat,
                ageMonths: ageMonths,
              ),
            );
          });
        },
      ),
    );
  }

  /// Шаг 5: Багаж
  Widget _buildBaggageStep() {
    final theme = context.themeManager.currentTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Багаж',
          textAlign: TextAlign.center,
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
            color: theme.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Багаж бесплатный для индивидуальных поездок',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.separator.withOpacity(0.2)),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              await Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => BaggageSelectionScreen(
                    passengerCount: _passengers.length,
                    isIndividualTrip: true, // ← СВОБОДНЫЙ МАРШРУТ - весь багаж бесплатный
                    onBaggageSelected: (baggage) {
                      // Navigator.pop теперь вызывается внутри BaggageSelectionScreen
                      setState(() {
                        _baggage = baggage;
                      });
                    },
                  ),
                ),
              );
            },
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
                          _baggage.isEmpty
                              ? 'Выберите багаж'
                              : '${_getTotalBaggageCount()} ${_getBaggageCountText(_getTotalBaggageCount())}',
                          style: TextStyle(color: theme.label, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _baggage.isNotEmpty
                              ? 'Бесплатно'
                              : 'Размеры S, M, L, Custom',
                          style: TextStyle(
                            color: _baggage.isNotEmpty
                                ? theme.systemGreen
                                : theme.secondaryLabel,
                            fontSize: 14,
                            fontWeight: _baggage.isNotEmpty
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
        ),
      ],
    );
  }

  int _getTotalBaggageCount() {
    return _baggage.fold(0, (sum, item) => sum + item.quantity);
  }

  String _getBaggageCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'место';
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'места';
    }
    return 'мест';
  }

  /// Шаг 6: Животные
  Widget _buildPetsStep() {
    final theme = context.themeManager.currentTheme;
    final hasPet = _pets.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Животные',
          textAlign: TextAlign.center,
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
            color: theme.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Везете животных?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Container(
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
                      onChanged: (value) async {
                        if (value) {
                          // Включаем - открываем окно выбора
                          await showCupertinoModalPopup(
                            context: context,
                            builder: (context) => SimplePetSelectionSheet(
                              onPetSelected: (pet) {
                                // Navigator.pop теперь вызывается внутри SimplePetSelectionSheet
                                if (pet != null) {
                                  setState(() {
                                    _pets = [pet];
                                  });
                                }
                              },
                            ),
                          );
                        } else {
                          // Выключаем - удаляем животное
                          setState(() {
                            _pets.clear();
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
                            style: TextStyle(color: theme.primary),
                          ),
                          onPressed: () async {
                            await showCupertinoModalPopup(
                              context: context,
                              builder: (context) => SimplePetSelectionSheet(
                                onPetSelected: (pet) {
                                  // Navigator.pop теперь вызывается внутри SimplePetSelectionSheet
                                  if (pet != null) {
                                    setState(() {
                                      _pets = [pet];
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getPetDisplayText() {
    if (_pets.isEmpty) return '';
    if (_pets.length == 1) {
      final pet = _pets.first;
      return pet.breed;
    }
    return '${_pets.length} животных';
  }

  double _calculatePetPrice() {
    return _pets.fold(0.0, (sum, pet) => sum + pet.cost);
  }

  /// Шаг 7: Комментарии
  Widget _buildNotesStep() {
    final theme = context.themeManager.currentTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Комментарии',
          textAlign: TextAlign.center,
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
            color: theme.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Укажите особые пожелания или важную информацию',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        CupertinoTextField(
          controller: _notesController,
          placeholder: 'Укажите особые пожелания, контактные данные или другую важную информацию...',
          placeholderStyle: TextStyle(
            color: theme.tertiaryLabel,
            fontSize: 16,
          ),
          style: TextStyle(
            color: theme.label,
            fontSize: 16,
          ),
          decoration: BoxDecoration(
            color: theme.systemBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.separator.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(12),
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            _notes = value;
          },
        ),
      ],
    );
  }

  /// Шаг 8: Транспорт
  Widget _buildVehicleStep() {
    final theme = context.themeManager.currentTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Вид транспорта',
          textAlign: TextAlign.center,
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
            color: theme.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите класс автомобиля',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.separator.withOpacity(0.2)),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              final result = await Navigator.push<VehicleClass>(
                context,
                CupertinoPageRoute(
                  builder: (context) => VehicleSelectionScreen(
                    onVehicleSelected: (vehicle) {
                      // Child теперь сам вызывает Navigator.pop с результатом
                      // Родитель получает result через await Navigator.push
                    },
                  ),
                ),
              );
              if (result != null) {
                setState(() {
                  _selectedVehicleClass = result;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(CupertinoIcons.car_detailed, color: theme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVehicleClass == null
                              ? 'Выберите транспорт'
                              : _selectedVehicleClass!.name,
                          style: TextStyle(color: theme.label, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedVehicleClass == null
                              ? 'Седан, Универсал, Минивэн, Микроавтобус'
                              : _selectedVehicleClass!.description,
                          style: TextStyle(
                            color: theme.secondaryLabel,
                            fontSize: 14,
                          ),
                        ),
                        if (_selectedVehicleClass != null && _selectedVehicleClass!.extraPrice > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Доплата: ${_selectedVehicleClass!.extraPrice.toInt()}₽',
                            style: TextStyle(
                              color: theme.systemGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
        ),
      ],
    );
  }

  /// Шаг 9: Подтверждение
  Widget _buildConfirmationStep() {
    final totalPrice = _calculateTotalPrice();
    final theme = context.themeManager.currentTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Подтверждение',
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Проверьте данные заказа',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 24),
          
          // Маршрут
          _buildSummaryRow('Маршрут', '${widget.fromAddress} → ${widget.toAddress}'),
          
          // Дата и время
          _buildSummaryRow('Дата', '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}'),
          _buildSummaryRow('Время', '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
          
          const SizedBox(height: 16),
          
          // Пассажиры (с разделением на взрослых и детей)
          _buildPassengersSummary(),
          
          // Дети (детальная информация)
          if (_passengers.where((p) => p.isChild).isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildChildrenSummary(),
          ],
          
          // Транспорт
          if (_selectedVehicleClass != null) ...[
            const SizedBox(height: 16),
            _buildVehicleSummary(),
          ],
          
          // Багаж
          if (_baggage.any((item) => item.quantity > 0)) ...[
            const SizedBox(height: 16),
            _buildBaggageSummary(),
          ],
          
          // Животные
          if (_pets.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPetsSummary(),
          ],
          
          // Комментарии
          if (_notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSummaryRow('Комментарии', _notes),
          ],
          
          const Divider(height: 32),
          
          // Итоговая цена (большими буквами)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.systemGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Итого:',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${totalPrice.toInt()} ₽',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.systemGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Сводка по пассажирам
  Widget _buildPassengersSummary() {
    final adults = _passengers.where((p) => p.isAdult).length;
    final children = _passengers.where((p) => p.isChild).length;

    String summary = '';
    if (adults > 0) {
      summary += '$adults ${_pluralizePassengers(adults, adult: true)}';
    }
    if (children > 0) {
      if (summary.isNotEmpty) summary += ', ';
      summary += '$children ${_pluralizePassengers(children, adult: false)}';
    }

    return _buildSummaryRow('Пассажиры', summary);
  }

  /// Детальная информация о детях
  Widget _buildChildrenSummary() {
    final children = _passengers.where((p) => p.isChild).toList();
    final theme = context.themeManager.currentTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Дети',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          ...children.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            
            // Форматируем возраст
            String ageStr = 'Возраст не указан';
            if (child.ageMonths != null) {
              final years = child.ageMonths! ~/ 12;
              final months = child.ageMonths! % 12;
              ageStr = '$years ${_pluralizeYears(years)}';
              if (months > 0) {
                ageStr += ' $months ${_pluralizeMonths(months)}';
              }
            }
            
            // Тип кресла
            String seatStr = child.seatType?.displayName ?? 'Без кресла';
            if (child.seatType != null) {
              seatStr += child.useOwnSeat ? ' (своё)' : ' (водителя)';
            }
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < children.length - 1 ? 8 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ребёнок ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• $ageStr',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• $seatStr',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Информация о транспорте
  Widget _buildVehicleSummary() {
    if (_selectedVehicleClass == null) return const SizedBox.shrink();
    
    final vehicle = _selectedVehicleClass!;
    final theme = context.themeManager.currentTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Транспорт',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vehicle.name,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            vehicle.description,
            style: const TextStyle(fontSize: 14),
          ),
          if (vehicle.extraPrice > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Доплата: ${vehicle.extraPrice.toInt()}₽',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.systemGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Детальная информация о багаже
  Widget _buildBaggageSummary() {
    final nonEmptyBaggage = _baggage.where((item) => item.quantity > 0).toList();
    if (nonEmptyBaggage.isEmpty) return const SizedBox.shrink();
    
    final theme = context.themeManager.currentTheme;
    // Для свободного маршрута (индивидуальная поездка) весь багаж бесплатный.
    final totalCost = _isIndividualTrip
        ? 0.0
        : BaggageUtils.calculateTotalBaggageCost(_baggage);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Багаж',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              if (!_isIndividualTrip && totalCost > 0)
                Text(
                  '+${totalCost.toInt()}₽',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.systemGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...nonEmptyBaggage.map((item) {
            // Для индивидуальной поездки багаж отображается как бесплатный
            final cost = _isIndividualTrip ? 0.0 : item.calculateCost();
            final costStr = cost == 0 ? ' (бесплатно)' : ' (+${cost.toInt()}₽)';

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${item.quantity} × ${item.sizeDescription}$costStr',
                style: const TextStyle(fontSize: 14),
              ),
            );
          }),
          if (!_isIndividualTrip && totalCost == 0)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Первое место бесплатно',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Детальная информация о животных
  Widget _buildPetsSummary() {
    if (_pets.isEmpty) return const SizedBox.shrink();
    
    final theme = context.themeManager.currentTheme;
    final totalCost = _pets.fold<double>(0.0, (sum, pet) => sum + pet.cost);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Животные',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              if (totalCost > 0)
                Text(
                  '+${totalCost.toInt()}₽',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.systemGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._pets.asMap().entries.map((entry) {
            final index = entry.key;
            final pet = entry.value;
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < _pets.length - 1 ? 8 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Животное ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• ${pet.breed}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• ${pet.categoryDescription}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• Стоимость: ${pet.cost.toInt()}₽',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Вспомогательные методы для склонения слов
  String _pluralizePassengers(int count, {required bool adult}) {
    if (adult) {
      if (count % 10 == 1 && count % 100 != 11) return 'взрослый';
      if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) return 'взрослых';
      return 'взрослых';
    } else {
      if (count % 10 == 1 && count % 100 != 11) return 'ребёнок';
      if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) return 'ребёнка';
      return 'детей';
    }
  }

  String _pluralizeYears(int years) {
    if (years % 10 == 1 && years % 100 != 11) return 'год';
    if ([2, 3, 4].contains(years % 10) && ![12, 13, 14].contains(years % 100)) return 'года';
    return 'лет';
  }

  String _pluralizeMonths(int months) {
    if (months % 10 == 1 && months % 100 != 11) return 'месяц';
    if ([2, 3, 4].contains(months % 10) && ![12, 13, 14].contains(months % 100)) return 'месяца';
    return 'месяцев';
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопки навигации
  Widget _buildNavigationButtons() {
    final theme = context.themeManager.currentTheme;
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.systemBackground,
        border: Border(
          top: BorderSide(
            color: theme.separator.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isFirstStep)
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.all(16),
                color: theme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
                onPressed: _previousStep,
                child: Text(
                  'Назад',
                  style: TextStyle(
                    color: theme.label,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 12),
          Expanded(
            flex: isFirstStep ? 1 : 1,
            child: CupertinoButton(
              padding: const EdgeInsets.all(16),
              color: theme.systemRed,
              borderRadius: BorderRadius.circular(12),
              onPressed: _nextStep,
              child: Text(
                isLastStep ? 'Забронировать' : 'Далее',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    // Автоматически открываем picker выбора возраста
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
            // Заголовок
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
                    child: Text('Отмена', style: TextStyle(color: widget.theme.primary)),
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
                            widget.onSave(_ageMonths!, _selectedSeatType!, _useOwnSeat);
                            Navigator.pop(context);
                          }
                        : null,
                    child: Text(
                      'Готово',
                      style: TextStyle(
                        color: _canSave ? widget.theme.primary : widget.theme.tertiaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Контент
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAgeSection(),
                    const SizedBox(height: 24),
                    if (_ageMonths != null) _buildSeatTypeSection(),
                    const SizedBox(height: 24),
                    if (_selectedSeatType != null && _selectedSeatType != ChildSeatType.none)
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
                    _ageMonths == null ? 'Укажите возраст' : _formatAge(_ageMonths!),
                    style: TextStyle(
                      color: _ageMonths == null
                          ? widget.theme.tertiaryLabel
                          : widget.theme.label,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, color: widget.theme.secondaryLabel),
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
          final isRecommended = seatType == ChildSeatTypeExtension.recommendByAge(_ageMonths!);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSeatType = seatType;
                if (seatType == ChildSeatType.none) {
                  _useOwnSeat = false;
                } else {
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
                        const Icon(CupertinoIcons.star_fill,
                            color: CupertinoColors.systemYellow, size: 16),
                      if (isRecommended) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          seatType.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: widget.theme.label,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(CupertinoIcons.checkmark_circle_fill,
                            color: widget.theme.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seatType.description,
                    style: TextStyle(fontSize: 14, color: widget.theme.secondaryLabel),
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
          onTap: () => setState(() => _useOwnSeat = false),
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
                          fontWeight: !_useOwnSeat ? FontWeight.w600 : FontWeight.w500,
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
                  Icon(CupertinoIcons.checkmark_circle_fill,
                      color: widget.theme.primary, size: 20),
              ],
            ),
          ),
        ),
        // Своё кресло
        GestureDetector(
          onTap: () => setState(() => _useOwnSeat = true),
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
                          fontWeight: _useOwnSeat ? FontWeight.w600 : FontWeight.w500,
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
                  Icon(CupertinoIcons.checkmark_circle_fill,
                      color: widget.theme.primary, size: 20),
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
                border: Border(bottom: BorderSide(color: widget.theme.separator)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('Отмена', style: TextStyle(color: widget.theme.primary)),
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
                    child: Text('Готово', style: TextStyle(color: widget.theme.primary)),
                    onPressed: () {
                      setState(() {
                        _ageMonths = selectedYears * 12;
                        _selectedSeatType =
                            ChildSeatTypeExtension.recommendByAge(_ageMonths!);
                      });
                      Navigator.pop(context);

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
                scrollController: FixedExtentScrollController(initialItem: selectedYears),
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Чьё автокресло?'),
          content: const Text('Выберите, чьё кресло будет использоваться'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                setState(() => _useOwnSeat = false);
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  const Text('Кресло водителя', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'Бесплатно',
                    style: TextStyle(fontSize: 12, color: CupertinoColors.systemGreen),
                  ),
                ],
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                setState(() => _useOwnSeat = true);
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  const Text('Своё кресло', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'Бесплатно',
                    style: TextStyle(fontSize: 12, color: CupertinoColors.systemGreen),
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
