import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/adapters.dart';
import 'pages/home_page.dart';
import 'pages/landing_page.dart';
import 'pages/add_pulseiras_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Hive
  await Hive.initFlutter();
  Hive.registerAdapter(PatientDataAdapter());
  Hive.registerAdapter(SensorInfoAdapter());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftSense App',
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/landing': (context) => LandingPage(),
        '/add': (context) => AddPulseirasPage(),
      },
      theme: ThemeData(
        primaryColor: Color(0xFF145e52),
        colorScheme: ColorScheme.light(
          secondary: Color(0xFF7bc5a2),
          surface: Color(0xFFade0c1),
        ),
        scaffoldBackgroundColor: Color(0xFFade0c1),
        appBarTheme: AppBarTheme(
          color: Color(0xFF145e52),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
    );
  }
}