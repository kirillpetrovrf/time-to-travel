import 'package:flutter/cupertino.dart';

/// Модель для одного шага туториала
class TutorialStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final List<GlobalKey>? additionalTargetKeys; // 🆕 Дополнительные ключи для выделения нескольких элементов
  final TutorialArrowDirection arrowDirection;
  final Offset? customArrowOffset;
  final VoidCallback? onStepShown; // 🆕 Callback когда шаг показывается - для автоматических действий

  TutorialStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.additionalTargetKeys, // 🆕
    this.arrowDirection = TutorialArrowDirection.bottom,
    this.customArrowOffset,
    this.onStepShown, // 🆕
  });
}

/// Направление стрелки подсказки
enum TutorialArrowDirection {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}
