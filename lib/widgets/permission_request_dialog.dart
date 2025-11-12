import 'package:flutter/cupertino.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Диалог для запроса разрешений при первом запуске
class PermissionRequestDialog extends StatefulWidget {
  final VoidCallback? onComplete;

  const PermissionRequestDialog({super.key, this.onComplete});

  @override
  State<PermissionRequestDialog> createState() =>
      _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog> {
  int _currentStep = 0;
  bool _isRequesting = false;

  final List<_PermissionStep> _steps = [
    _PermissionStep(
      icon: CupertinoIcons.location_fill,
      title: 'Геолокация',
      description:
          'Для определения вашего местоположения и расчета расстояний до точек отправления',
      color: CupertinoColors.systemBlue,
    ),
    _PermissionStep(
      icon: CupertinoIcons.bell_fill,
      title: 'Уведомления',
      description:
          'Для напоминаний о поездках и важных обновлений, даже когда приложение не открыто',
      color: CupertinoColors.systemPurple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStep];

    return CupertinoAlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(currentStep.icon, color: currentStep.color, size: 28),
          const SizedBox(width: 8),
          Text(currentStep.title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(currentStep.description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          // Индикатор прогресса
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentStep
                      ? currentStep.color
                      : CupertinoColors.systemGrey3,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (_currentStep > 0)
          CupertinoDialogAction(
            onPressed: _isRequesting ? null : _previousStep,
            child: const Text('Назад'),
          ),
        CupertinoDialogAction(
          onPressed: _isRequesting ? null : _skip,
          child: const Text('Пропустить'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _isRequesting ? null : _requestPermission,
          child: _isRequesting
              ? const CupertinoActivityIndicator()
              : Text(_currentStep == _steps.length - 1 ? 'Разрешить' : 'Далее'),
        ),
      ],
    );
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);

    final permissionService = PermissionService.instance;
    bool granted = false;

    if (_currentStep == 0) {
      // Запрос геолокации
      granted = await permissionService.requestLocationPermission();
    } else if (_currentStep == 1) {
      // Запрос уведомлений
      granted = await permissionService.requestNotificationPermission();

      // Инициализация сервиса уведомлений
      if (granted) {
        await NotificationService.instance.initialize();
      }
    }

    setState(() => _isRequesting = false);

    if (granted) {
      _nextStep();
    } else {
      // Показываем диалог с объяснением
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    final currentStep = _steps[_currentStep];

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Разрешение не получено'),
        content: Text(
          'Разрешение на ${currentStep.title.toLowerCase()} важно для работы приложения.\n\n'
          'Вы можете выдать разрешение позже в настройках приложения.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Настройки'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Продолжить'),
            onPressed: () {
              Navigator.of(context).pop();
              _nextStep();
            },
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _complete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _skip() {
    _complete();
  }

  void _complete() {
    Navigator.of(context).pop();
    widget.onComplete?.call();
  }
}

class _PermissionStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _PermissionStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

/// Проверка и показ диалога разрешений при необходимости
Future<void> showPermissionDialogIfNeeded(BuildContext context) async {
  final permissionService = PermissionService.instance;

  // Проверяем, нужно ли показывать диалог
  final shouldShow = await permissionService.shouldShowPermissionRationale();

  if (shouldShow && context.mounted) {
    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionRequestDialog(),
    );
  }
}
