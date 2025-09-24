import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/trip_type.dart';

class PickupPointsWidget extends StatefulWidget {
  final dynamic theme;

  const PickupPointsWidget({super.key, required this.theme});

  @override
  State<PickupPointsWidget> createState() => _PickupPointsWidgetState();
}

class _PickupPointsWidgetState extends State<PickupPointsWidget> {
  List<String> _donetskPoints = List.from(TripPricing.donetskPickupPoints);
  List<String> _rostovPoints = [
    'Центральный автовокзал',
    'ТЦ Горизонт',
    'Площадь Ленина',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPointsSection(
            'Остановки в Донецке',
            _donetskPoints,
            CupertinoIcons.location_solid,
            true,
          ),

          const SizedBox(height: 24),

          _buildPointsSection(
            'Остановки в Ростове-на-Дону',
            _rostovPoints,
            CupertinoIcons.location,
            false,
          ),

          const SizedBox(height: 24),

          _buildMapIntegrationSection(),
        ],
      ),
    );
  }

  Widget _buildPointsSection(
    String title,
    List<String> points,
    IconData icon,
    bool isDonetsk,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: widget.theme.primary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.label,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showAddPointDialog(isDonetsk),
              child: Icon(
                CupertinoIcons.plus_circle_fill,
                color: widget.theme.primary,
                size: 24,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: widget.theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.theme.separator.withOpacity(0.2)),
          ),
          child: Column(
            children: points.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;

              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      color: widget.theme.separator.withOpacity(0.2),
                    ),
                  _buildPointItem(point, index, isDonetsk),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPointItem(String point, int index, bool isDonetsk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.primary,
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
                  point,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.theme.label,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Активная остановка',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
              ],
            ),
          ),

          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showPointOptions(point, index, isDonetsk),
            child: Icon(
              CupertinoIcons.ellipsis,
              color: widget.theme.secondaryLabel,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapIntegrationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.map, color: widget.theme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Интеграция с картами',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.label,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Настройте точные координаты остановок для отображения на карте и навигации',
            style: TextStyle(fontSize: 14, color: widget.theme.secondaryLabel),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: widget.theme.primary,
                  child: const Text('Открыть карту'),
                  onPressed: _openMapEditor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  color: widget.theme.secondarySystemBackground,
                  child: Text(
                    'Импорт координат',
                    style: TextStyle(color: widget.theme.label),
                  ),
                  onPressed: _importCoordinates,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPointDialog(bool isDonetsk) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          isDonetsk ? 'Новая остановка в Донецке' : 'Новая остановка в Ростове',
        ),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: nameController,
              placeholder: 'Название остановки',
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: addressController,
              placeholder: 'Адрес (необязательно)',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Добавить'),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  if (isDonetsk) {
                    _donetskPoints.add(nameController.text);
                  } else {
                    _rostovPoints.add(nameController.text);
                  }
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPointOptions(String point, int index, bool isDonetsk) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(point),
        message: const Text('Выберите действие'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editPoint(point, index, isDonetsk);
            },
            child: const Text('Редактировать'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showPointOnMap(point);
            },
            child: const Text('Показать на карте'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _togglePointStatus(point, index, isDonetsk);
            },
            child: const Text('Деактивировать'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deletePoint(point, index, isDonetsk);
            },
            child: const Text('Удалить'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  void _editPoint(String point, int index, bool isDonetsk) {
    final TextEditingController controller = TextEditingController(text: point);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Редактировать остановку'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Название остановки',
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
              if (controller.text.isNotEmpty) {
                setState(() {
                  if (isDonetsk) {
                    _donetskPoints[index] = controller.text;
                  } else {
                    _rostovPoints[index] = controller.text;
                  }
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _deletePoint(String point, int index, bool isDonetsk) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить остановку'),
        content: Text('Удалить остановку "$point"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () {
              setState(() {
                if (isDonetsk) {
                  _donetskPoints.removeAt(index);
                } else {
                  _rostovPoints.removeAt(index);
                }
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPointOnMap(String point) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(point),
        content: const Text(
          'Функция отображения на карте будет доступна в следующем обновлении',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _togglePointStatus(String point, int index, bool isDonetsk) {
    // Логика активации/деактивации остановки
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Статус изменен'),
        content: Text('Остановка "$point" деактивирована'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _openMapEditor() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Редактор карты'),
        content: const Text(
          'Функция редактирования карты будет доступна в следующем обновлении',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _importCoordinates() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Импорт координат'),
        content: const Text(
          'Функция импорта координат будет доступна в следующем обновлении',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
