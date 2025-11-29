import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/trip_settings.dart';
import '../../../services/trip_settings_service.dart';

class ScheduleSettingsWidget extends StatefulWidget {
  final dynamic theme;
  
  const ScheduleSettingsWidget({super.key, required this.theme});

  @override
  State<ScheduleSettingsWidget> createState() => _ScheduleSettingsWidgetState();
}

class _ScheduleSettingsWidgetState extends State<ScheduleSettingsWidget> {
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
          _buildSectionTitle('Время отправления'),
          const SizedBox(height: 16),
          
          _buildTimesList(),
          
          const SizedBox(height: 24),
          
          CupertinoButton.filled(
            child: const Text('Добавить время'),
            onPressed: _showAddTimeDialog,
          ),
          
          const SizedBox(height: 24),
          
          _buildMaxPassengersSection(),
          
          const SizedBox(height: 24),
          
          _buildSaveButton(),
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

  Widget _buildTimesList() {
    final times = _currentSettings!.departureTimes;
    
    if (times.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: widget.theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.theme.separator.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            'Нет времени отправления',
            style: TextStyle(
              color: widget.theme.secondaryLabel,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.separator.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: times.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          
          return Column(
            children: [
              if (index > 0)
                Divider(height: 1, color: widget.theme.separator.withOpacity(0.2)),
              _buildTimeItem(time, index),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeItem(String time, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.clock,
            color: widget.theme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.theme.label,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _editTime(index, time),
            child: Icon(
              CupertinoIcons.pencil,
              color: widget.theme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _deleteTime(time),
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

  Widget _buildMaxPassengersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.separator.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Максимальное количество пассажиров',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.theme.label,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(CupertinoIcons.person_2, color: widget.theme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Пассажиров: ${_currentSettings!.maxPassengers}',
                  style: TextStyle(color: widget.theme.label, fontSize: 16),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _currentSettings!.maxPassengers > 1
                    ? () => _updateMaxPassengers(_currentSettings!.maxPassengers - 1)
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentSettings!.maxPassengers > 1 
                        ? widget.theme.primary 
                        : widget.theme.separator,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.minus,
                    color: _currentSettings!.maxPassengers > 1
                        ? CupertinoColors.white
                        : widget.theme.secondaryLabel,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _currentSettings!.maxPassengers < 15
                    ? () => _updateMaxPassengers(_currentSettings!.maxPassengers + 1)
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentSettings!.maxPassengers < 15 
                        ? widget.theme.primary 
                        : widget.theme.separator,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.plus,
                    color: _currentSettings!.maxPassengers < 15
                        ? CupertinoColors.white
                        : widget.theme.secondaryLabel,
                    size: 16,
                  ),
                ),
              ),
            ],
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

  void _showAddTimeDialog() {
    final TextEditingController controller = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Добавить время'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            const Text('Введите время в формате ЧЧ:ММ'),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Например: 08:00',
              keyboardType: TextInputType.text,
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
              if (_isValidTime(controller.text)) {
                _addTime(controller.text);
                Navigator.pop(context);
              } else {
                _showError('Неверный формат времени. Используйте ЧЧ:ММ');
              }
            },
          ),
        ],
      ),
    );
  }

  void _editTime(int index, String currentTime) {
    final TextEditingController controller = TextEditingController(text: currentTime);
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Редактировать время'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Например: 08:00',
              keyboardType: TextInputType.text,
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
              if (_isValidTime(controller.text)) {
                _updateTime(index, controller.text);
                Navigator.pop(context);
              } else {
                _showError('Неверный формат времени. Используйте ЧЧ:ММ');
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteTime(String time) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить время'),
        content: Text('Удалить время отправления $time?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () {
              _removeTime(time);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  bool _isValidTime(String time) {
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  void _addTime(String time) {
    final updatedTimes = List<String>.from(_currentSettings!.departureTimes);
    
    if (!updatedTimes.contains(time)) {
      updatedTimes.add(time);
      updatedTimes.sort(); // Сортируем по времени
      
      setState(() {
        _currentSettings = _currentSettings!.copyWith(departureTimes: updatedTimes);
      });
    }
  }

  void _updateTime(int index, String newTime) {
    final updatedTimes = List<String>.from(_currentSettings!.departureTimes);
    updatedTimes[index] = newTime;
    updatedTimes.sort(); // Сортируем по времени
    
    setState(() {
      _currentSettings = _currentSettings!.copyWith(departureTimes: updatedTimes);
    });
  }

  void _removeTime(String time) {
    final updatedTimes = List<String>.from(_currentSettings!.departureTimes);
    updatedTimes.remove(time);
    
    setState(() {
      _currentSettings = _currentSettings!.copyWith(departureTimes: updatedTimes);
    });
  }

  void _updateMaxPassengers(int newMax) {
    setState(() {
      _currentSettings = _currentSettings!.copyWith(maxPassengers: newMax);
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
