import 'package:flutter/cupertino.dart';
import '../../../models/trip_type.dart';
import '../../../theme/theme_manager.dart';

/// Экран выбора транспорта для индивидуальных поездок (ТЗ v3.0)
class VehicleSelectionScreen extends StatefulWidget {
  final VehicleClass? initialSelection;
  final Function(VehicleClass?) onVehicleSelected;

  const VehicleSelectionScreen({
    super.key,
    this.initialSelection,
    required this.onVehicleSelected,
  });

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  VehicleClass? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Выбор транспорта'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            widget.onVehicleSelected(_selectedVehicle);
          },
          child: const Text('Готово'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildVehicleOption(
              theme: theme,
              vehicle: VehicleClass.sedan,
              title: 'Седан',
              description: '1-3 пассажира\nЭкономичный вариант',
              price: '+0 ₽',
              icon: CupertinoIcons.car,
            ),
            const SizedBox(height: 12),
            _buildVehicleOption(
              theme: theme,
              vehicle: VehicleClass.wagon,
              title: 'Универсал',
              description: '1-4 пассажира\nБольше места для багажа',
              price: '+300 ₽',
              icon: CupertinoIcons.car_detailed,
            ),
            const SizedBox(height: 12),
            _buildVehicleOption(
              theme: theme,
              vehicle: VehicleClass.minivan,
              title: 'Минивэн',
              description: '1-6 пассажиров\nКомфорт и простор',
              price: '+800 ₽',
              icon: CupertinoIcons.bus,
            ),
            const SizedBox(height: 12),
            _buildVehicleOption(
              theme: theme,
              vehicle: VehicleClass.microbus,
              title: 'Микроавтобус',
              description: '1-8 пассажиров\nДля больших групп',
              price: '+1500 ₽',
              icon: CupertinoIcons.bus,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Важно знать:',
                    style: TextStyle(
                      color: theme.label,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Цены указаны как доплата к базовому тарифу\n'
                    '• Выбор транспорта влияет на итоговую стоимость\n'
                    '• Для животных M/L размера рекомендуется универсал+\n'
                    '• Время подачи может увеличиться для спецтранспорта',
                    style: TextStyle(color: theme.secondaryLabel, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleOption({
    required dynamic theme,
    required VehicleClass vehicle,
    required String title,
    required String description,
    required String price,
    required IconData icon,
  }) {
    final isSelected = _selectedVehicle == vehicle;

    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = vehicle),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.systemBlue
                : theme.separator.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.systemBlue
                    : theme.tertiarySystemBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? CupertinoColors.white : theme.label,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.label,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: theme.secondaryLabel, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    color: theme.systemBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: theme.systemBlue,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
