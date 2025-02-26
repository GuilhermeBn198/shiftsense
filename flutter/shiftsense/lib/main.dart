import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/landing_page.dart';
import 'pages/add_pulseiras_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulseira App',
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/landing': (context) => LandingPage(),
        '/add': (context) => AddPulseirasPage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}