import 'package:flutter/cupertino.dart';
import '../../../models/passenger_info.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';

/// Экран добавления/редактирования пассажира
class AddPassengerScreen extends StatefulWidget {
  final PassengerInfo? initialPassenger;

  const AddPassengerScreen({super.key, this.initialPassenger});

  @override
  State<AddPassengerScreen> createState() => _AddPassengerScreenState();
}

class _AddPassengerScreenState extends State<AddPassengerScreen> {
  PassengerType _selectedType = PassengerType.adult;
  ChildSeatType? _selectedSeatType;
  bool _useOwnSeat = false;
  int? _ageMonths;

  @override
  void initState() {
    super.initState();
    if (widget.initialPassenger != null) {
      _selectedType = widget.initialPassenger!.type;
      _selectedSeatType = widget.initialPassenger!.seatType;
      _useOwnSeat = widget.initialPassenger!.useOwnSeat;
      _ageMonths = widget.initialPassenger!.ageMonths;
    }
  }

  bool get _canSave {
    if (_selectedType == PassengerType.adult) return true;
    // Для ребенка нужно выбрать возраст и тип кресла
    return _ageMonths != null && _selectedSeatType != null;
  }

  void _savePassenger() {
    final passenger = PassengerInfo(
      type: _selectedType,
      seatType: _selectedType == PassengerType.child ? _selectedSeatType : null,
      useOwnSeat: _selectedType == PassengerType.child ? _useOwnSeat : false,
      ageMonths: _selectedType == PassengerType.child ? _ageMonths : null,
    );
    Navigator.of(context).pop(passenger);
  }

  void _showAgePickerDialog() {
    int selectedYears = (_ageMonths ?? 0) ~/ 12;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('Укажите возраст ребенка'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedYears,
                ),
                onSelectedItemChanged: (index) {
                  selectedYears = index;
                },
                children: List.generate(
                  16,
                  (index) => Center(child: Text('$index ${_yearWord(index)}')),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Готово'),
            onPressed: () {
              setState(() {
                _ageMonths = selectedYears * 12;
                // Автоматически рекомендуем тип кресла
                final recommendedSeat = ChildSeatTypeExtension.recommendByAge(
                  _ageMonths!,
                );
                _selectedSeatType = recommendedSeat;
              });
              Navigator.pop(dialogContext);
              // Показываем диалог выбора автокресла
              _showSeatTypePickerDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showSeatTypePickerDialog() {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;
    ChildSeatType? tempSelectedSeatType = _selectedSeatType;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('Выберите тип автокресла'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Рекомендуется: ${_selectedSeatType?.displayName ?? ""}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              const SizedBox(height: 16),
              ...ChildSeatType.values.map((seatType) {
                final isSelected = seatType == tempSelectedSeatType;
                final isRecommended = seatType == _selectedSeatType;
                return GestureDetector(
                  onTap: () {
                    setDialogState(() {
                      tempSelectedSeatType = seatType;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.secondarySystemBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : theme.separator,
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
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: theme.label,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: CupertinoColors.activeBlue,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seatType.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Выбрать'),
              onPressed: () {
                if (tempSelectedSeatType != null) {
                  setState(() {
                    _selectedSeatType = tempSelectedSeatType;
                  });
                  Navigator.pop(dialogContext);
                  // Если выбрано кресло (не "без кресла"), показываем выбор своё/водителя
                  if (tempSelectedSeatType != ChildSeatType.none) {
                    _showOwnSeatDialog();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOwnSeatDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('Автокресло'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Вы привезёте своё автокресло или воспользуетесь креслом водителя?',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Кресло водителя'),
            onPressed: () {
              Navigator.pop(dialogContext);
              // Показываем предупреждение о стоимости
              _showDriverSeatCostWarning();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Своё кресло'),
            onPressed: () {
              setState(() {
                _useOwnSeat = true;
              });
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  void _showDriverSeatCostWarning() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('Автокресло водителя'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Автокресло водителя предоставляется бесплатно'),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () {
              Navigator.pop(dialogContext);
              // Возвращаем обратно к выбору кресла
              _showOwnSeatDialog();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Подтвердить'),
            onPressed: () {
              setState(() {
                _useOwnSeat = false;
              });
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          widget.initialPassenger == null
              ? 'Добавить пассажира'
              : 'Редактировать',
          style: TextStyle(color: theme.label),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Отмена', style: TextStyle(color: theme.quaternaryLabel)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Готово',
            style: TextStyle(
              color: _canSave
                  ? CupertinoColors.activeBlue
                  : theme.quaternaryLabel,
            ),
          ),
          onPressed: _canSave ? _savePassenger : null,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Выбор типа пассажира
              Text(
                'Тип пассажира',
                style: TextStyle(
                  color: theme.label,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Взрослый
              _buildTypeCard(
                type: PassengerType.adult,
                icon: CupertinoIcons.person_fill,
                title: 'Взрослый',
                subtitle: 'Пассажир от 18 лет',
                theme: theme,
              ),

              const SizedBox(height: 12),

              // Ребенок
              _buildTypeCard(
                type: PassengerType.child,
                icon: CupertinoIcons.smiley,
                title: 'Ребенок',
                subtitle: 'Пассажир до 18 лет',
                theme: theme,
              ),

              // Если выбран ребенок - показываем дополнительные поля
              if (_selectedType == PassengerType.child) ...[
                const SizedBox(height: 24),

                // Возраст ребенка
                Text(
                  'Возраст ребенка',
                  style: TextStyle(
                    color: theme.label,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showAgePickerDialog,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.secondarySystemBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          color: theme.label,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _ageMonths == null
                                    ? 'Укажите возраст'
                                    : _formatAge(_ageMonths!),
                                style: TextStyle(
                                  color: _ageMonths == null
                                      ? theme.secondaryLabel
                                      : theme.label,
                                  fontSize: 16,
                                ),
                              ),
                              if (_selectedSeatType != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _selectedSeatType == ChildSeatType.none
                                      ? _selectedSeatType!.displayName
                                      : _useOwnSeat
                                      ? '${_selectedSeatType!.displayName} • Своё кресло'
                                      : '${_selectedSeatType!.displayName} • Кресло водителя',
                                  style: TextStyle(
                                    color: theme.secondaryLabel,
                                    fontSize: 14,
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
              ],

              // Кнопка "Добавить ребёнка" внизу экрана
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _canSave ? _savePassenger : null,
                  child: Text(
                    _selectedType == PassengerType.adult
                        ? 'Добавить взрослого'
                        : 'Добавить ребёнка',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required PassengerType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required CustomTheme theme,
  }) {
    final isSelected = _selectedType == type;

    return Container(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() {
            _selectedType = type;
            if (type == PassengerType.adult) {
              _selectedSeatType = null;
              _useOwnSeat = false;
              _ageMonths = null;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: CupertinoColors.activeBlue, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : theme.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? CupertinoColors.white : theme.label,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.label,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.secondaryLabel,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
