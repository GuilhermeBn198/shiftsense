import 'package:flutter/material.dart';

class PatientData {
  final String name;
  final String id;
  final Map<String, dynamic> sensorData;

  PatientData({
    required this.name,
    required this.id,
    required this.sensorData,
  });
}

class SensorInfo {
  final String direction;
  final String duration;
  final IconData icon;

  SensorInfo({
    required this.direction,
    required this.duration,
    required this.icon,
  });
}