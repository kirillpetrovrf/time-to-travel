import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/trip_settings.dart';
import '../../../services/trip_settings_service.dart';

class PickupDropoffWidget extends StatefulWidget {
  final dynamic theme;

  const PickupDropoffWidget({super.key, required this.theme});

  @override
  State<PickupDropoffWidget> createState() => _PickupDropoffWidgetState();
}

class _PickupDropoffWidgetState extends State<PickupDropoffWidget> {
  final TripSettingsService _settingsService = TripSettingsService();
  TripSettings? _currentSettings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getCurrentSettings();
      setState(() {
        _currentSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Ошибка загрузки настроек: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_currentSettings == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ошибка загрузки настроек',
              style: TextStyle(color: widget.theme.label),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              child: const Text('Повторить'),
              onPressed: _loadSettings,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPointsSection(
            'Места посадки в Донецке',
            _currentSettings!.donetskPickupPoints,
            CupertinoIcons.location_solid,
            true,
            true, // isPickup
          ),

          const SizedBox(height: 24),

          _buildPointsSection(
            'Места посадки в Ростове-на-Дону',
            _currentSettings!.rostovPickupPoints,
            CupertinoIcons.location,
            false,
            true, // isPickup
          ),

          const SizedBox(height: 24),

          _buildPointsSection(
            'Места высадки в Донецке',
            _currentSettings!.donetskDropoffPoints,
            CupertinoIcons.flag,
            true,
            false, // isPickup
          ),

          const SizedBox(height: 24),

          _buildPointsSection(
            'Места высадки в Ростове-на-Дону',
            _currentSettings!.rostovDropoffPoints,
            CupertinoIcons.flag_fill,
            false,
            false, // isPickup
          ),

          const SizedBox(height: 24),

          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildPointsSection(
    String title,
    List<String> points,
    IconData icon,
    bool isDonetsk,
    bool isPickup,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.label,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showAddPointDialog(isDonetsk, isPickup),
              child: Icon(
                CupertinoIcons.plus_circle_fill,
                color: widget.theme.primary,
                size: 24,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (points.isEmpty)
          _buildEmptyState(isPickup ? 'Нет мест посадки' : 'Нет мест высадки')
        else
          _buildPointsList(points, isDonetsk, isPickup),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: widget.theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.separator.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: widget.theme.secondaryLabel, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildPointsList(List<String> points, bool isDonetsk, bool isPickup) {
    return Container(
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
              _buildPointItem(point, index, isDonetsk, isPickup),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPointItem(
    String point,
    int index,
    bool isDonetsk,
    bool isPickup,
  ) {
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
                  'Активная точка',
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
            onPressed: () => _editPoint(point, index, isDonetsk, isPickup),
            child: Icon(
              CupertinoIcons.pencil,
              color: widget.theme.primary,
              size: 18,
            ),
          ),

          const SizedBox(width: 8),

          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _deletePoint(point, isDonetsk, isPickup),
            child: const Icon(
              CupertinoIcons.trash,
              color: CupertinoColors.systemRed,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return CupertinoButton.filled(
      onPressed: _isSaving ? null : _saveSettings,
      child: _isSaving
          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
          : const Text('Сохранить изменения'),
    );
  }

  void _showAddPointDialog(bool isDonetsk, bool isPickup) {
    final TextEditingController nameController = TextEditingController();
    final String cityName = isDonetsk ? 'Донецке' : 'Ростове-на-Дону';
    final String pointType = isPickup ? 'посадки' : 'высадки';

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Новое место $pointType в $cityName'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: nameController,
              placeholder: 'Название места',
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
              if (nameController.text.trim().isNotEmpty) {
                _addPoint(nameController.text.trim(), isDonetsk, isPickup);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _editPoint(String point, int index, bool isDonetsk, bool isPickup) {
    final TextEditingController controller = TextEditingController(text: point);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Редактировать место'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Название места',
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
              if (controller.text.trim().isNotEmpty) {
                _updatePoint(
                  index,
                  controller.text.trim(),
                  isDonetsk,
                  isPickup,
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _deletePoint(String point, bool isDonetsk, bool isPickup) {
    final String pointType = isPickup ? 'посадки' : 'высадки';

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить место'),
        content: Text('Удалить место $pointType "$point"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () {
              _removePoint(point, isDonetsk, isPickup);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _addPoint(String point, bool isDonetsk, bool isPickup) {
    setState(() {
      if (isPickup) {
        if (isDonetsk) {
          final updatedPoints = List<String>.from(
            _currentSettings!.donetskPickupPoints,
          );
          if (!updatedPoints.contains(point)) {
            updatedPoints.add(point);
            _currentSettings = _currentSettings!.copyWith(
              donetskPickupPoints: updatedPoints,
            );
          }
        } else {
          final updatedPoints = List<String>.from(
            _currentSettings!.rostovPickupPoints,
          );
          if (!updatedPoints.contains(point)) {
            updatedPoints.add(point);
            _currentSettings = _currentSettings!.copyWith(
              rostovPickupPoints: updatedPoints,
            );
          }
        }
      } else {
        if (isDonetsk) {
          final updatedPoints = List<String>.from(
            _currentSettings!.donetskDropoffPoints,
          );
          if (!updatedPoints.contains(point)) {
            updatedPoints.add(point);
            _currentSettings = _currentSettings!.copyWith(
              donetskDropoffPoints: updatedPoints,
            );
          }
        } else {
          final updatedPoints = List<String>.from(
            _currentSettings!.rostovDropoffPoints,
          );
          if (!updatedPoints.contains(point)) {
            updatedPoints.add(point);
            _currentSettings = _currentSettings!.copyWith(
              rostovDropoffPoints: updatedPoints,
            );
          }
        }
      }
    });
  }

  void _updatePoint(int index, String newPoint, bool isDonetsk, bool isPickup) {
    setState(() {
      if (isPickup) {
        if (isDonetsk) {
          final updatedPoints = List<String>.from(
            _currentSettings!.donetskPickupPoints,
          );
          updatedPoints[index] = newPoint;
          _currentSettings = _currentSettings!.copyWith(
            donetskPickupPoints: updatedPoints,
          );
        } else {
          final updatedPoints = List<String>.from(
            _currentSettings!.rostovPickupPoints,
          );
          updatedPoints[index] = newPoint;
          _currentSettings = _currentSettings!.copyWith(
            rostovPickupPoints: updatedPoints,
          );
        }
      } else {
        if (isDonetsk) {
          final updatedPoints = List<String>.from(
            _currentSettings!.donetskDropoffPoints,
          );
          updatedPoints[index] = newPoint;
          _currentSettings = _currentSettings!.copyWith(
            donetskDropoffPoints: updatedPoints,
          );
        } else {
          final updatedPoints = List<String>.from(
            _currentSettings!.rostovDropoffPoints,
          );
          updatedPoints[index] = newPoint;
          _currentSettings = _currentSettings!.copyWith(
            rostovDropoffPoints: updatedPoints,
          );
        }
      }
    });
  }

  void _removePoint(String point, bool isDonetsk, bool isPickup) {
    setState(() {
      if (isPickup) {
        if (isDonetsk) {
          final updatedPoints = List<String>.from(
            _currentSettings!.donetskPickupPoints,
          );
          updatedPoints.remove(point);
          _currentSettings = _currentSettings!.copyWith(
            donetskPickupPoints: updatedPoints,
          );
        } else {
          final updatedPoints = List<String>.from(
            _currentSettings!.rostovPickupPoints,
          );
          updatedPoints.remove(point);
          _currentSettings = _currentSettings!.copyWith(
            rostovPickupPoints: updatedPoints,
          );
        }
      } else {
        if (isDonetsk) {
          final updatedPoints = List<String>.from(
            _currentSettings!.donetskDropoffPoints,
          );
          updatedPoints.remove(point);
          _currentSettings = _currentSettings!.copyWith(
            donetskDropoffPoints: updatedPoints,
          );
        } else {
          final updatedPoints = List<String>.from(
            _currentSettings!.rostovDropoffPoints,
          );
          updatedPoints.remove(point);
          _currentSettings = _currentSettings!.copyWith(
            rostovDropoffPoints: updatedPoints,
          );
        }
      }
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _settingsService.saveSettings(_currentSettings!);
      _showSuccess('Настройки успешно сохранены');
    } catch (e) {
      _showError('Ошибка сохранения: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно'),
        content: Text(message),
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
