import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/time_to_travel_logo.dart';
import '../auth/screens/auth_screen.dart';
import '../home/screens/home_screen.dart';

/// Заставка приложения с логотипом Time to Travel
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _backgroundOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Анимация логотипа
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Анимация фона
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Масштаб логотипа
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Прозрачность логотипа
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Прозрачность фона
    _backgroundOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeIn),
    );
  }

  void _startAnimationSequence() async {
    // Запуск анимации фона
    _backgroundController.forward();

    // Задержка перед анимацией логотипа
    await Future.delayed(const Duration(milliseconds: 300));

    // Запуск анимации логотипа
    _logoController.forward();

    // Ожидание завершения анимации + дополнительная задержка
    await Future.delayed(const Duration(milliseconds: 3000));

    // Проверка авторизации и переход на соответствующий экран
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    try {
      final isLoggedIn = await AuthService.instance.isLoggedIn();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => isLoggedIn
                ? HomeScreen() // Убираем const, так как HomeScreen не const
                : const AuthScreen(),
          ),
        );
      }
    } catch (e) {
      // В случае ошибки перенаправляем на экран авторизации
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: TimeToTravelColors.darkBg,
      child: AnimatedBuilder(
        animation: Listenable.merge([_logoController, _backgroundController]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              // Градиентный фон от красного к черному
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(
                    0xFFDC2626,
                  ).withOpacity(_backgroundOpacityAnimation.value), // Красный
                  Color(
                    0xFF000000,
                  ).withOpacity(_backgroundOpacityAnimation.value), // Черный
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Логотип с анимацией
                  Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: TimeToTravelLogo(
                        size: 120,
                        primaryColor: TimeToTravelColors.redPrimary,
                        secondaryColor: TimeToTravelColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Название приложения
                  Opacity(
                    opacity: _logoOpacityAnimation.value,
                    child: Text(
                      'TIME TO TRAVEL',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: TimeToTravelColors.textPrimary,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Подзаголовок
                  Opacity(
                    opacity: _logoOpacityAnimation.value * 0.8,
                    child: Text(
                      'Пассажирские перевозки',
                      style: TextStyle(
                        fontSize: 16,
                        color: TimeToTravelColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
