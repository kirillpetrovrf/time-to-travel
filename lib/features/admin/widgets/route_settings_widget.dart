import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RouteSettingsWidget extends StatefulWidget {
  final dynamic theme;

  const RouteSettingsWidget({super.key, required this.theme});

  @override
  State<RouteSettingsWidget> createState() => _RouteSettingsWidgetState();
}

class _RouteSettingsWidgetState extends State<RouteSettingsWidget> {
  final List<Map<String, dynamic>> _routes = [
    {
      'id': 'donetsk_rostov',
      'name': 'Донецк → Ростов-на-Дону',
      'distance': '180 км',
      'duration': '3 ч 30 мин',
      'isActive': true,
    },
    {
      'id': 'rostov_donetsk',
      'name': 'Ростов-на-Дону → Донецк',
      'distance': '180 км',
      'duration': '3 ч 30 мин',
      'isActive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Доступные маршруты'),
          const SizedBox(height: 16),

          ..._routes.map((route) => _buildRouteCard(route)).toList(),

          const SizedBox(height: 24),

          CupertinoButton.filled(
            child: const Text('Добавить новый маршрут'),
            onPressed: _showAddRouteDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: widget.theme.label,
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  route['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.label,
                  ),
                ),
              ),
              CupertinoSwitch(
                value: route['isActive'],
                onChanged: (value) {
                  setState(() {
                    route['isActive'] = value;
                  });
                  _updateRouteStatus(route['id'], value);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                CupertinoIcons.location,
                size: 16,
                color: widget.theme.secondaryLabel,
              ),
              const SizedBox(width: 4),
              Text(
                route['distance'],
                style: TextStyle(
                  fontSize: 14,
                  color: widget.theme.secondaryLabel,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                CupertinoIcons.clock,
                size: 16,
                color: widget.theme.secondaryLabel,
              ),
              const SizedBox(width: 4),
              Text(
                route['duration'],
                style: TextStyle(
                  fontSize: 14,
                  color: widget.theme.secondaryLabel,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: widget.theme.primary.withOpacity(0.1),
                  onPressed: () => _editRoute(route),
                  child: Text(
                    'Редактировать',
                    style: TextStyle(color: widget.theme.primary, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: CupertinoColors.systemRed.withOpacity(0.1),
                onPressed: () => _deleteRoute(route),
                child: const Text(
                  'Удалить',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateRouteStatus(String routeId, bool isActive) {
    // Здесь будет логика обновления статуса маршрута в базе данных
    print('Обновляем статус маршрута $routeId: $isActive');
  }

  void _editRoute(Map<String, dynamic> route) {
    // Показываем диалог редактирования маршрута
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Редактирование маршрута'),
        content: Text('Редактирование маршрута: ${route['name']}'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Сохранить'),
            onPressed: () {
              Navigator.pop(context);
              // Здесь будет логика сохранения изменений
            },
          ),
        ],
      ),
    );
  }

  void _deleteRoute(Map<String, dynamic> route) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удаление маршрута'),
        content: Text(
          'Вы уверены, что хотите удалить маршрут "${route['name']}"?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _routes.removeWhere((r) => r['id'] == route['id']);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showAddRouteDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Новый маршрут'),
        content: const Text('Добавление нового маршрута'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Добавить'),
            onPressed: () {
              Navigator.pop(context);
              // Здесь будет логика добавления нового маршрута
            },
          ),
        ],
      ),
    );
  }
}
