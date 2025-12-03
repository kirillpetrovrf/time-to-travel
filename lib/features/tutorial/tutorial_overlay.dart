import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'tutorial_step.dart';

/// Оверлей для показа туториала с подсветкой элементов
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const TutorialOverlay({
    Key? key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // 🆕 Вызываем callback первого шага
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.steps.isNotEmpty) {
        widget.steps[0].onStepShown?.call();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _animationController.reset();
      setState(() {
        _currentStep++;
      });
      _animationController.forward();
      
      // 🆕 Вызываем callback нового шага после короткой задержки
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _currentStep < widget.steps.length) {
          widget.steps[_currentStep].onStepShown?.call();
        }
      });
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      setState(() {
        _currentStep--;
      });
      _animationController.forward();
    }
  }

  Rect? _getTargetRect() {
    final step = widget.steps[_currentStep];
    final RenderBox? renderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return null;

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    // Отрицательный padding - уменьшаем рамку на 10px с каждой стороны
    const padding = -10.0;
    return Rect.fromLTWH(
      position.dx - padding,
      position.dy - padding,
      size.width + padding * 2,
      size.height + padding * 2,
    );
  }

  // 🆕 Получаем список всех прямоугольников для выделения (включая дополнительные)
  List<Rect> _getAllTargetRects() {
    final step = widget.steps[_currentStep];
    final rects = <Rect>[];
    
    // Главный элемент (первый флаг) - используем 0 padding для полного размера кнопки
    final RenderBox? mainRenderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (mainRenderBox != null) {
      final size = mainRenderBox.size;
      final position = mainRenderBox.localToGlobal(Offset.zero);
      const padding = 0.0; // 🔧 Изменено: такой же размер как у второго флага
      rects.add(Rect.fromLTWH(
        position.dx - padding,
        position.dy - padding,
        size.width + padding * 2,
        size.height + padding * 2,
      ));
    }
    
    // Дополнительные элементы (второй флаг, корзина, геолокация)
    if (step.additionalTargetKeys != null) {
      for (final key in step.additionalTargetKeys!) {
        final RenderBox? renderBox =
            key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          final position = renderBox.localToGlobal(Offset.zero);
          const padding = 0.0; // Полный размер кнопки
          rects.add(Rect.fromLTWH(
            position.dx - padding,
            position.dy - padding,
            size.width + padding * 2,
            size.height + padding * 2,
          ));
        }
      }
    }
    
    return rects;
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = _getTargetRect();
    final allTargetRects = _getAllTargetRects(); // 🆕 Получаем все прямоугольники

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {}, // Блокируем клики по затемненной области
        child: Stack(
          children: [
            // Затемнение с вырезом
            FadeTransition(
              opacity: _fadeAnimation,
              child: CustomPaint(
                painter: _HolePainter(
                  holeRects: allTargetRects, // 🆕 Передаём все прямоугольники
                  holeRadius: 8.0,
                ),
                child: Container(),
              ),
            ),

            // Подсветка границ всех целевых элементов с анимацией пульсации
            ...allTargetRects.map((rect) => Positioned(
              left: rect.left,
              top: rect.top,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _PulsingBorder(
                  width: rect.width,
                  height: rect.height,
                  color: const Color(0xFFE31E24),
                ),
              ),
            )),

            // Текст подсказки и элементы управления
            Positioned(
              left: 0,
              right: 0,
              top: _currentStep == widget.steps.length - 1 ? 0 : null, // 🔧 Для последнего шага - вверху
              bottom: _currentStep == widget.steps.length - 1 ? null : 0, // 🔧 Для остальных - внизу
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildHintBox(context, targetRect),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintBox(BuildContext context, Rect? targetRect) {
    final step = widget.steps[_currentStep];
    
    // 🆕 Для кнопки "Заказать" всегда показываем окно вверху
    final isOrderButton = _currentStep == widget.steps.length - 1;

    return SafeArea( // 🔧 Добавлен SafeArea для безопасного отступа от краёв экрана
      child: Align(
        alignment: isOrderButton ? Alignment.topCenter : Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.only(
            top: isOrderButton ? 20 : 0, // 🔧 Уменьшен отступ для лучшей видимости
            bottom: isOrderButton ? 0 : 40,
            left: 20,
            right: 20,
          ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              step.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),

            // Описание
            Text(
              step.description,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 20),

            // Индикатор прогресса
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentStep
                        ? const Color(0xFFE31E24) // Фирменный красный
                        : CupertinoColors.systemGrey4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Кнопки управления
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Кнопка "Назад"
                if (_currentStep > 0)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: _previousStep,
                    child: const Text(
                      'Назад',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),

                // Кнопка "Далее" / "Готово"
                CupertinoButton(
                  color: const Color(0xFFE31E24), // Фирменный красный
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    _currentStep == widget.steps.length - 1
                        ? 'Готово'
                        : 'Далее',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CupertinoColors.white, // Белый цвет текста
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ), // 🔧 Закрывающая скобка для SafeArea
    );
  }
}

/// CustomPainter для рисования затемнения с вырезом
class _HolePainter extends CustomPainter {
  final List<Rect> holeRects; // 🆕 Изменено на список прямоугольников
  final double holeRadius;

  _HolePainter({
    required this.holeRects, // 🆕
    required this.holeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Создаем путь для всего экрана
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Создаём общий путь для всех вырезов
    Path allHolesPath = Path();
    for (final holeRect in holeRects) {
      allHolesPath.addRRect(
        RRect.fromRectAndRadius(
          holeRect,
          Radius.circular(holeRadius),
        ),
      );
    }

    // Используем Path.combine с разностью для создания "дырок"
    final overlayPath = Path.combine(
      PathOperation.difference,
      outerPath,
      allHolesPath,
    );

    // Рисуем затемнение с вырезами
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.75)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) {
    return oldDelegate.holeRects != holeRects ||
        oldDelegate.holeRadius != holeRadius;
  }
}

/// Виджет с анимацией пульсации для подсветки кнопок
class _PulsingBorder extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const _PulsingBorder({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  State<_PulsingBorder> createState() => _PulsingBorderState();
}

class _PulsingBorderState extends State<_PulsingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.color,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
