import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PickupPointsWidget extends StatefulWidget {
  final dynamic theme;

  const PickupPointsWidget({super.key, required this.theme});

  @override
  State<PickupPointsWidget> createState() => _PickupPointsWidgetState();
}

class _PickupPointsWidgetState extends State<PickupPointsWidget> {
  // Все 11 городов с местами посадки
  final Map<String, List<String>> _cityPoints = {
    'Донецк': ['Центральный автовокзал'],
    'Макеевка': ['пл. Ленина'],
    'Харцызск': ['Автостанция'],
    'Иловайск': ['Центральная площадь'],
    'Кутейниково': ['Остановка у магазина'],
    'Амвросиевка': ['Автостанция'],
    'КПП УСПЕНКА': ['Граница ДНР-РФ'],
    'Матвеев-Курган': ['Центральная площадь'],
    'Покровское': ['Автобусная остановка'],
    'Таганрог': ['Автовокзал'],
    'Ростов-на-Дону': ['Главный автовокзал'],
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Места посадки на маршруте',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.theme.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Все остановки на маршруте Донецк → Ростов-на-Дону',
            style: TextStyle(fontSize: 14, color: widget.theme.secondaryLabel),
          ),
          const SizedBox(height: 24),

          // Все 11 городов
          ..._cityPoints.entries.map((entry) {
            final cityName = entry.key;
            final points = entry.value;
            final index = _cityPoints.keys.toList().indexOf(cityName);

            return Column(
              children: [
                _buildPointsSection(
                  cityName,
                  points,
                  CupertinoIcons.location_solid,
                  cityName,
                  index + 1,
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),

          const SizedBox(height: 8),

          _buildMapIntegrationSection(),
        ],
      ),
    );
  }

  Widget _buildPointsSection(
    String cityName,
    List<String> points,
    IconData icon,
    String cityId,
    int orderNumber,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                  '$orderNumber',
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
              child: Text(
                cityName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.label,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showAddPointDialog(cityId),
              child: Icon(
                CupertinoIcons.plus_circle_fill,
                color: widget.theme.primary,
                size: 24,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

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
                  _buildPointItem(point, index, cityId),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPointItem(String point, int index, String cityId) {
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
              child: Icon(
                CupertinoIcons.location_solid,
                size: 16,
                color: widget.theme.primary,
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
            onPressed: () => _showPointOptions(point, index, cityId),
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

  void _showAddPointDialog(String cityId) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Новая остановка в городе $cityId'),
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
                  _cityPoints[cityId]?.add(nameController.text);
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPointOptions(String point, int index, String cityId) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(point),
        message: const Text('Выберите действие'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editPoint(point, index, cityId);
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
              _togglePointStatus(point, index, cityId);
            },
            child: const Text('Деактивировать'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deletePoint(point, index, cityId);
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

  void _editPoint(String point, int index, String cityId) {
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
                  _cityPoints[cityId]?[index] = controller.text;
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _deletePoint(String point, int index, String cityId) {
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
                _cityPoints[cityId]?.removeAt(index);
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

  void _togglePointStatus(String point, int index, String cityId) {
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
