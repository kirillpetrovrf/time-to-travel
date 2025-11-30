import 'package:flutter/cupertino.dart';
import '../../../models/baggage.dart';
import '../../../services/baggage_pricing_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';

/// Экран выбора багажа (ПОЛНОСТЬЮ ПЕРЕДЕЛАН под ТЗ v3.0)
/// НОВЫЕ ПРАВИЛА v13.0:
/// - ГРУППОВАЯ ПОЕЗДКА: квотная система (2×S или 1×M или 1×L на пассажира)
/// - ИНДИВИДУАЛЬНЫЙ ТРАНСФЕР: весь багаж БЕСПЛАТНЫЙ (аренда всей машины)
class BaggageSelectionScreen extends StatefulWidget {
  final List<BaggageItem> initialBaggage;
  final Function(List<BaggageItem>) onBaggageSelected;
  final int passengerCount; // Количество пассажиров
  final bool isIndividualTrip; // Тип поездки (индивидуальная или групповая)

  const BaggageSelectionScreen({
    super.key,
    this.initialBaggage = const [],
    required this.onBaggageSelected,
    required this.passengerCount,
    this.isIndividualTrip = false, // По умолчанию - групповая поездка
  });

  @override
  State<BaggageSelectionScreen> createState() => _BaggageSelectionScreenState();
}

class _BaggageSelectionScreenState extends State<BaggageSelectionScreen> {
  late Map<BaggageSize, int>
  _quantities; // Количество каждого типа багажа (0-10)
  Map<BaggageSize, double> _prices = {}; // Цены от диспетчера
  bool _isLoading = true;

  // Контроллеры для custom багажа
  final TextEditingController _customDescriptionController =
      TextEditingController();
  final TextEditingController _customDimensionsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeQuantities();
    _loadPrices();
  }

  void _initializeQuantities() {
    print('🧳 [БАГАЖ] ============ ИНИЦИАЛИЗАЦИЯ БАГАЖА ============');
    print(
      '🧳 [БАГАЖ] ТИП ПОЕЗДКИ: ${widget.isIndividualTrip ? "ИНДИВИДУАЛЬНЫЙ ТРАНСФЕР" : "ГРУППОВАЯ ПОЕЗДКА"}',
    );
    print('🧳 [БАГАЖ] Количество пассажиров: ${widget.passengerCount}');
    print(
      '🧳 [БАГАЖ] Бесплатных S багажей: ${widget.passengerCount * 2} (${widget.passengerCount} × 2)',
    );
    print(
      '🧳 [БАГАЖ] Бесплатных M багажей: ${widget.passengerCount * 1} (${widget.passengerCount} × 1)',
    );
    print(
      '🧳 [БАГАЖ] Бесплатных L багажей: ${widget.passengerCount * 1} (${widget.passengerCount} × 1)',
    );
    print(
      '🧳 [БАГАЖ] Начальный багаж: ${widget.initialBaggage.length} предметов',
    );

    // Инициализируем количества из существующего багажа или нулями
    _quantities = {
      BaggageSize.s: 0,
      BaggageSize.m: 0,
      BaggageSize.l: 0,
      BaggageSize.custom: 0,
    };

    // Заполняем из начальных данных
    for (final item in widget.initialBaggage) {
      _quantities[item.size] = item.quantity;
      print(
        '🧳 [БАГАЖ] Загружен ${item.size.name.toUpperCase()}: ${item.quantity} шт, цена: ${item.pricePerExtraItem}₽/шт',
      );
      if (item.size == BaggageSize.custom) {
        _customDescriptionController.text = item.customDescription ?? '';
        _customDimensionsController.text = item.customDimensions ?? '';
      }
    }

    print(
      '🧳 [БАГАЖ] Итоговые количества: S=${_quantities[BaggageSize.s]}, M=${_quantities[BaggageSize.m]}, L=${_quantities[BaggageSize.l]}, Custom=${_quantities[BaggageSize.custom]}',
    );
  }

  Future<void> _loadPrices() async {
    print('💰 [БАГАЖ] Загрузка цен багажа...');
    try {
      final prices = await BaggagePricingService.getExtraBaggagePrices();
      print('💰 [БАГАЖ] Цены загружены успешно:');
      print('💰 [БАГАЖ]   S: ${prices[BaggageSize.s]}₽/шт');
      print('💰 [БАГАЖ]   M: ${prices[BaggageSize.m]}₽/шт');
      print('💰 [БАГАЖ]   L: ${prices[BaggageSize.l]}₽/шт');
      print('💰 [БАГАЖ]   Custom: ${prices[BaggageSize.custom]}₽/шт');
      if (mounted) {
        setState(() {
          _prices = prices;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [БАГАЖ] Ошибка загрузки цен: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _customDescriptionController.dispose();
    _customDimensionsController.dispose();
    super.dispose();
  }

  void _updateQuantity(BaggageSize size, int newQuantity) {
    if (newQuantity >= 0 && newQuantity <= 10) {
      final oldQuantity = _quantities[size] ?? 0;
      print(
        '➕➖ [БАГАЖ] Изменение количества ${size.name.toUpperCase()}: $oldQuantity → $newQuantity',
      );
      setState(() {
        _quantities[size] = newQuantity;
      });
      print(
        '📊 [БАГАЖ] Текущее состояние: S=${_quantities[BaggageSize.s]}, M=${_quantities[BaggageSize.m]}, L=${_quantities[BaggageSize.l]}, Custom=${_quantities[BaggageSize.custom]}',
      );
      print(
        '📊 [БАГАЖ] Общее количество: ${_getTotalBaggageCount()} предметов',
      );
      print(
        '💵 [БАГАЖ] Общая стоимость: ${_calculateTotalCost().toStringAsFixed(0)}₽',
      );
    }
  }

  int _getTotalBaggageCount() {
    return _quantities.values.fold(0, (sum, quantity) => sum + quantity);
  }

  // Определяет количество бесплатных багажей для данного размера (для UI)
  int _getFreeBaggageCount(BaggageSize size) {
    final quantity = _quantities[size] ?? 0;
    if (quantity == 0) return 0;

    // ИНДИВИДУАЛЬНЫЙ ТРАНСФЕР: весь багаж бесплатный
    if (widget.isIndividualTrip) {
      return quantity; // Все багажи бесплатные
    }

    final sCount = _quantities[BaggageSize.s] ?? 0;
    final mCount = _quantities[BaggageSize.m] ?? 0;
    final lCount = _quantities[BaggageSize.l] ?? 0;

    // НОВАЯ УПРОЩЁННАЯ ЛОГИКА v13.0: Используем тот же алгоритм что и в _calculateTotalCost
    int availablePassengers = widget.passengerCount;
    int remainingS = sCount;
    int remainingM = mCount;
    int remainingL = lCount;

    // Шаг 1: Распределяем L (по 1 на пассажира)
    if (remainingL > 0) {
      int passengersWithL = remainingL <= availablePassengers
          ? remainingL
          : availablePassengers;
      availablePassengers -= passengersWithL;
      remainingL -= passengersWithL;
    }

    // Шаг 2: Распределяем M (по 1 на пассажира)
    if (remainingM > 0 && availablePassengers > 0) {
      int passengersWithM = remainingM <= availablePassengers
          ? remainingM
          : availablePassengers;
      availablePassengers -= passengersWithM;
      remainingM -= passengersWithM;
    }

    // Шаг 3: Распределяем S - ЛЮБОЕ количество до лимита бесплатно
    if (remainingS > 0 && availablePassengers > 0) {
      int maxFreeS =
          availablePassengers *
          2; // Каждому оставшемуся пассажиру - 2 бесплатных S
      int freeS = remainingS <= maxFreeS ? remainingS : maxFreeS;
      remainingS -= freeS;
    }

    // Возвращаем количество бесплатных для данного размера
    if (size == BaggageSize.s) {
      return sCount - remainingS; // Бесплатных S
    } else if (size == BaggageSize.m) {
      return mCount - remainingM; // Бесплатных M
    } else if (size == BaggageSize.l) {
      return lCount - remainingL; // Бесплатных L
    } else if (size == BaggageSize.custom) {
      return 0; // Custom всегда платно
    }

    return 0;
  }

  double _calculateTotalCost() {
    // ЛОГИКА v13.0: Проверяем тип поездки
    if (widget.isIndividualTrip) {
      // ИНДИВИДУАЛЬНЫЙ ТРАНСФЕР: весь багаж БЕСПЛАТНЫЙ
      print(
        '💵 [БАГАЖ] ========== РАСЧЕТ СТОИМОСТИ (ИНДИВИДУАЛЬНЫЙ) ==========',
      );
      print('💵 [БАГАЖ] 🎁 ВЕСЬ БАГАЖ БЕСПЛАТНЫЙ (аренда всей машины)');

      int totalBaggageCount = _getTotalBaggageCount();
      if (totalBaggageCount == 0) {
        print('💵 [БАГАЖ] Багаж не выбран, стоимость: 0₽');
        return 0.0;
      }

      final sCount = _quantities[BaggageSize.s] ?? 0;
      final mCount = _quantities[BaggageSize.m] ?? 0;
      final lCount = _quantities[BaggageSize.l] ?? 0;
      final customCount = _quantities[BaggageSize.custom] ?? 0;

      print(
        '💵 [БАГАЖ] Выбранный багаж: S=$sCount, M=$mCount, L=$lCount, Custom=$customCount',
      );
      print('💵 [БАГАЖ] ✅ Весь багаж БЕСПЛАТНЫЙ (аренда всей машины)');
      print('💵 [БАГАЖ] ========== ИТОГО: 0₽ ==========');

      return 0.0;
    }

    // ГРУППОВАЯ ПОЕЗДКА: квотная система
    print(
      '💵 [БАГАЖ] ========== РАСЧЕТ СТОИМОСТИ v12.0 (ГРУППОВАЯ) ==========',
    );
    print('💵 [БАГАЖ] Количество пассажиров: ${widget.passengerCount}');

    int totalBaggageCount = _getTotalBaggageCount();
    print('💵 [БАГАЖ] Общее количество багажа: $totalBaggageCount предметов');

    if (totalBaggageCount == 0) {
      print('💵 [БАГАЖ] Багаж не выбран, стоимость: 0₽');
      return 0.0;
    }

    final sCount = _quantities[BaggageSize.s] ?? 0;
    final mCount = _quantities[BaggageSize.m] ?? 0;
    final lCount = _quantities[BaggageSize.l] ?? 0;
    final customCount = _quantities[BaggageSize.custom] ?? 0;

    final sPrice = _prices[BaggageSize.s] ?? 500.0;
    final mPrice = _prices[BaggageSize.m] ?? 1000.0;
    final lPrice = _prices[BaggageSize.l] ?? 2000.0;
    final customPrice = _prices[BaggageSize.custom] ?? 0.0;

    print(
      '💵 [БАГАЖ] Состав: S=$sCount, M=$mCount, L=$lCount, Custom=$customCount',
    );

    // НОВАЯ ЛОГИКА v12.0: Каждый пассажир выбирает ОДИН вариант: 2S ИЛИ 1M ИЛИ 1L
    // Алгоритм распределения:
    // 1. Распределяем L (по 1 на пассажира)
    // 2. Распределяем M (по 1 на пассажира)
    // 3. Распределяем S (по 2 на пассажира)
    // 4. Остаток считаем платным

    int availablePassengers = widget.passengerCount;
    int remainingS = sCount;
    int remainingM = mCount;
    int remainingL = lCount;

    print('💵 [БАГАЖ] --- РАСПРЕДЕЛЕНИЕ БАГАЖА ПО ПАССАЖИРАМ ---');

    // Шаг 1: Распределяем L (приоритет - самый дорогой)
    int passengersWithL = 0;
    if (remainingL > 0) {
      passengersWithL = remainingL <= availablePassengers
          ? remainingL
          : availablePassengers;
      availablePassengers -= passengersWithL;
      remainingL -= passengersWithL;
      print('💵 [БАГАЖ] $passengersWithL пассажиров выбрали 1×L (бесплатно)');
    }

    // Шаг 2: Распределяем M
    int passengersWithM = 0;
    if (remainingM > 0 && availablePassengers > 0) {
      passengersWithM = remainingM <= availablePassengers
          ? remainingM
          : availablePassengers;
      availablePassengers -= passengersWithM;
      remainingM -= passengersWithM;
      print('💵 [БАГАЖ] $passengersWithM пассажиров выбрали 1×M (бесплатно)');
    }

    // Шаг 3: Распределяем S - ЛЮБОЕ количество до лимита (availablePassengers × 2)
    int freeS = 0;
    if (remainingS > 0 && availablePassengers > 0) {
      int maxFreeS = availablePassengers * 2; // Лимит бесплатных S
      freeS = remainingS <= maxFreeS ? remainingS : maxFreeS;

      // Считаем сколько пассажиров использовали бесплатные S
      int usedPassengers = (freeS / 2).ceil(); // Округляем вверх

      remainingS -= freeS;
      print(
        '💵 [БАГАЖ] Бесплатных S: $freeS шт (лимит: $maxFreeS), использовано $usedPassengers пассажиров',
      );
      availablePassengers -= usedPassengers;
    }

    print('💵 [БАГАЖ] Неиспользованных пассажиров: $availablePassengers');
    print(
      '💵 [БАГАЖ] Остаток платного багажа: S=$remainingS, M=$remainingM, L=$remainingL',
    );

    // Шаг 4: Считаем стоимость платного багажа
    double total = 0.0;

    if (remainingS > 0) {
      double cost = remainingS * sPrice;
      total += cost;
      print(
        '💵 [БАГАЖ] Платные S: $remainingS × ${sPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    if (remainingM > 0) {
      double cost = remainingM * mPrice;
      total += cost;
      print(
        '💵 [БАГАЖ] Платные M: $remainingM × ${mPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    if (remainingL > 0) {
      double cost = remainingL * lPrice;
      total += cost;
      print(
        '💵 [БАГАЖ] Платные L: $remainingL × ${lPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    // Custom всегда платно
    if (customCount > 0) {
      double cost = customCount * customPrice;
      total += cost;
      print(
        '💵 [БАГАЖ] Custom: $customCount × ${customPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    print(
      '💵 [БАГАЖ] ========== ИТОГО: ${total.toStringAsFixed(0)}₽ ==========',
    );

    return total;
  }

  List<BaggageItem> _buildBaggageList() {
    final List<BaggageItem> result = [];

    for (final size in BaggageSize.values) {
      final quantity = _quantities[size] ?? 0;
      if (quantity > 0) {
        final pricePerExtra = _prices[size] ?? 0.0;
        result.add(
          BaggageItem(
            size: size,
            quantity: quantity,
            customDescription: size == BaggageSize.custom
                ? _customDescriptionController.text
                : null,
            customDimensions: size == BaggageSize.custom
                ? _customDimensionsController.text
                : null,
            pricePerExtraItem: pricePerExtra,
          ),
        );
      }
    }

    return result;
  }

  void _showCustomBaggageDialog() {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Индивидуальный багаж'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Информационное сообщение о цене
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.info_circle_fill,
                    color: CupertinoColors.systemOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Цена уточняется диспетчером после оформления заказа',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.secondaryLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _customDescriptionController,
              placeholder: 'Что везете? (необязательно)',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _customDimensionsController,
              placeholder: 'Габариты (Д×Ш×В см)',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Сохранить'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
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
          middle: Text('Выбор багажа', style: TextStyle(color: theme.label)),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('Выбор багажа', style: TextStyle(color: theme.label)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Отмена', style: TextStyle(color: theme.quaternaryLabel)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Готово',
            style: TextStyle(color: CupertinoColors.activeBlue),
          ),
          onPressed: () {
            final baggageList = _buildBaggageList();
            print('');
            print('✅ [БАГАЖ] ========== ПОДТВЕРЖДЕНИЕ ВЫБОРА ==========');
            print('✅ [БАГАЖ] Пользователь нажал "Готово"');
            print('✅ [БАГАЖ] Выбрано предметов: ${_getTotalBaggageCount()}');
            for (var item in baggageList) {
              print(
                '✅ [БАГАЖ]   • ${item.size.name.toUpperCase()}: ${item.quantity} шт, цена за доп: ${item.pricePerExtraItem.toStringAsFixed(0)}₽',
              );
            }
            print(
              '✅ [БАГАЖ] Итоговая стоимость: ${_calculateTotalCost().toStringAsFixed(0)}₽',
            );
            print('✅ [БАГАЖ] ==========================================');
            print('');
            // Callback сам вызовет Navigator.pop с правильным типом
            widget.onBaggageSelected(baggageList);
          },
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Итоговая стоимость (перемещен в начало)
              _buildTotalCostCard(theme),

              const SizedBox(height: 24),

              // Карточки размеров багажа
              ..._buildBaggageCards(theme),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBaggageCards(CustomTheme theme) {
    final List<Widget> cards = [];

    for (final size in [
      BaggageSize.s,
      BaggageSize.m,
      BaggageSize.l,
      BaggageSize.custom,
    ]) {
      cards.add(_buildBaggageCard(size, theme));
      cards.add(const SizedBox(height: 16));
    }

    return cards;
  }

  Widget _buildBaggageCard(BaggageSize size, CustomTheme theme) {
    final quantity = _quantities[size] ?? 0;
    final pricePerExtra = _prices[size] ?? 0.0;

    // Определяем количество бесплатных багажей для этого размера
    int freeCount = _getFreeBaggageCount(size);
    int paidCount = quantity - freeCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: quantity > 0
            ? Border.all(color: CupertinoColors.activeBlue, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Иконка размера
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getSizeColor(size),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSizeIcon(size),
                  color: CupertinoColors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Информация о размере
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSizeTitle(size),
                      style: TextStyle(
                        color: theme.label,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getSizeDimensions(size),
                      style: TextStyle(
                        color: theme.secondaryLabel,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _getSizeExamples(size),
                      style: TextStyle(
                        color: theme.secondaryLabel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Цена и статус
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quantity == 0)
                      Text(
                        'Не выбрано',
                        style: TextStyle(
                          color: theme.placeholderText,
                          fontSize: 14,
                        ),
                      )
                    // ИНДИВИДУАЛЬНЫЙ ТРАНСФЕР - весь багаж БЕСПЛАТНЫЙ
                    else if (widget.isIndividualTrip)
                      Text(
                        'БЕСПЛАТНО',
                        style: TextStyle(
                          color: CupertinoColors.activeGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    // Для индивидуального (custom) багажа - особая логика
                    else if (size == BaggageSize.custom)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Цена уточняется диспетчером',
                            style: TextStyle(
                              color: CupertinoColors.systemOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'После оформления заказа с Вами свяжется диспетчер',
                            style: TextStyle(
                              color: theme.secondaryLabel,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    // Все багажи бесплатные (S багажи в пределах 2-х)
                    else if (freeCount > 0 && paidCount == 0)
                      Text(
                        freeCount == 1
                            ? 'БЕСПЛАТНО'
                            : 'БЕСПЛАТНО (${freeCount} шт)',
                        style: TextStyle(
                          color: CupertinoColors.activeGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    // Есть и бесплатные, и платные (например, 2 бесплатных S + 3 платных S)
                    else if (freeCount > 0 && paidCount > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'БЕСПЛАТНО (${freeCount}) + ${paidCount} доп.',
                            style: TextStyle(
                              color: theme.label,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (pricePerExtra > 0)
                            Text(
                              'Доп. багаж: ${(paidCount * pricePerExtra).toStringAsFixed(0)}₽',
                              style: TextStyle(
                                color: theme.secondaryLabel,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      )
                    // Все багажи платные (не S, или S больше 2-х)
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pricePerExtra.toStringAsFixed(0)}₽',
                            style: TextStyle(
                              color: theme.label,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (quantity > 1)
                            Text(
                              'Всего: ${(quantity * pricePerExtra).toStringAsFixed(0)}₽',
                              style: TextStyle(
                                color: theme.secondaryLabel,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // Кнопки управления количеством
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: quantity > 0
                        ? () => _updateQuantity(size, quantity - 1)
                        : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: quantity > 0
                            ? CupertinoColors.systemRed
                            : theme.quaternaryLabel,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.minus,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                  ),

                  Container(
                    width: 40,
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        color: theme.label,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: quantity < 10
                        ? () {
                            if (size == BaggageSize.custom && quantity == 0) {
                              _showCustomBaggageDialog();
                            }
                            _updateQuantity(size, quantity + 1);
                          }
                        : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: quantity < 10
                            ? CupertinoColors.activeBlue
                            : theme.quaternaryLabel,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.plus,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Кнопка настройки для custom багажа
          if (size == BaggageSize.custom && quantity > 0) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showCustomBaggageDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Указать габариты и описание',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCostCard(CustomTheme theme) {
    final totalCost = _calculateTotalCost();
    final hasFreeBaggage = _quantities.values.any((q) => q > 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ИНДИВИДУАЛЬНЫЙ ТРАНСФЕР - специальное сообщение
          if (widget.isIndividualTrip) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.gift,
                    color: CupertinoColors.systemGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Весь багаж БЕСПЛАТНО\n(аренда всей машины)',
                      style: TextStyle(
                        color: CupertinoColors.systemGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
          // ГРУППОВАЯ ПОЕЗДКА - обычная логика
          else ...[
            // Бесплатный багаж
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Бесплатный багаж:',
                  style: TextStyle(color: theme.label, fontSize: 16),
                ),
                Text(
                  hasFreeBaggage ? 'Включен' : 'Не выбран',
                  style: TextStyle(
                    color: hasFreeBaggage
                        ? CupertinoColors.activeGreen
                        : theme.placeholderText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Правила бесплатного багажа
            const SizedBox(height: 8),
            Text(
              'Только на 1 пассажира : S : 2 или M / L : 1',
              style: TextStyle(color: theme.secondaryLabel, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            // Дополнительный багаж (если есть)
            if (totalCost > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Дополнительный багаж:',
                    style: TextStyle(color: theme.label, fontSize: 16),
                  ),
                  Text(
                    '${totalCost.toStringAsFixed(0)}₽',
                    style: TextStyle(
                      color: theme.label,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Вспомогательные методы для отображения информации о размерах
  String _getSizeTitle(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return 'Размер S (Малый)';
      case BaggageSize.m:
        return 'Размер M (Средний)';
      case BaggageSize.l:
        return 'Размер L (Большой)';
      case BaggageSize.custom:
        return 'Индивидуальный';
    }
  }

  String _getSizeDimensions(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return '30×40×20 см (до 10 кг)';
      case BaggageSize.m:
        return '50×60×25 см (до 20 кг)';
      case BaggageSize.l:
        return '70×80×30 см (до 32 кг)';
      case BaggageSize.custom:
        return 'Любые габариты';
    }
  }

  String _getSizeExamples(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return 'Рюкзак, небольшая сумка';
      case BaggageSize.m:
        return 'Спортивная сумка, средний чемодан';
      case BaggageSize.l:
        return 'Большой чемодан, коробка';
      case BaggageSize.custom:
        return 'Гитара, микроволновка, нестандартные предметы';
    }
  }

  IconData _getSizeIcon(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return CupertinoIcons.bag;
      case BaggageSize.m:
        return CupertinoIcons.bag_fill;
      case BaggageSize.l:
        return CupertinoIcons.cube_box;
      case BaggageSize.custom:
        return CupertinoIcons.cube;
    }
  }

  Color _getSizeColor(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return CupertinoColors.activeGreen;
      case BaggageSize.m:
        return CupertinoColors.activeBlue;
      case BaggageSize.l:
        return CupertinoColors.systemOrange;
      case BaggageSize.custom:
        return CupertinoColors.systemPurple;
    }
  }
}
