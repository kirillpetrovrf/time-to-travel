import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:yandex_maps_mapkit/init.dart' as init;
import 'core/constants.dart';
import 'features/main_screen.dart';

void main() async {
  print('==========================================');
  print('🚀 TAXI ROUTE CALCULATOR STARTING...');
  print('==========================================');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Yandex MapKit
  print('🗺️ Initializing MapKit with API key: ${kYandexMapKitApiKey.substring(0, 10)}...');
  await init.initMapkit(apiKey: kYandexMapKitApiKey);
  print('✅ MapKit initialized successfully');
  
  // Настройка системного UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  print('🏁 Running app...');
  print('==========================================');
  runApp(const TaxiRouteCalculatorApp());
}

class TaxiRouteCalculatorApp extends StatelessWidget {
  const TaxiRouteCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taxi Route Calculator',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      home: const MainScreen(),
    );
  }
}

