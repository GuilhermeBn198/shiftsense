import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(Duration(seconds: 10), () {
      Navigator.pushReplacementNamed(context, '/landing');
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () {
            _timer.cancel();
            Navigator.pushReplacementNamed(context, '/landing');
          },
          child: Image.asset('assets/logo.png', width: 150), // Apenas a logo
        ),
      ),
    );
  }
}