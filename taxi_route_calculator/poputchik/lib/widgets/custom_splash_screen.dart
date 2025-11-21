import 'package:flutter/cupertino.dart';

class CustomSplashScreen extends StatelessWidget {
  const CustomSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              24,
            ), // Такое же как на экране авторизации
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
