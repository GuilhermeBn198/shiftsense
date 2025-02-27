import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/header_bar.dart';
import '../widgets/footer_bar.dart';
import '../widgets/patient_data_box.dart';
import '../models/pulseira_model.dart';
import '../services/mqtt_service.dart';

class AddPulseirasPage extends StatefulWidget {
  @override
  _AddPulseirasPageState createState() => _AddPulseirasPageState();
}

class _AddPulseirasPageState extends State<AddPulseirasPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();
  late MQTTService _mqttService;
  SensorInfo? _armData;
  SensorInfo? _legData;

  @override
  void initState() {
    super.initState();
    _initializeMQTT();
  }

  void _initializeMQTT() {
    _mqttService = MQTTService(
      server: '07356c1b41e34d65a6152a202151c24d.s1.eu.hivemq.cloud',
      clientId: 'flutter_add_${DateTime.now().millisecondsSinceEpoch}',
      username: 'hivemq.webclient.1740079881529',
      password: 'h45de%Pb.6O8aBQo>JC!',
      port: 8883,
      onMessageReceived: _handleTestData,
    );
    _mqttService.connect();
  }

  void _handleTestData(String topic, String message) {
    setState(() {
      try {
        final jsonData = jsonDecode(message);
        final direction = jsonData['position'];
        final timeInPosition = jsonData['time_in_position'];

        final sensorInfo = SensorInfo(
          direction: direction,
          duration: '${timeInPosition}s',
          icon: topic.contains('braco') ? Icons.accessibility : Icons.directions_walk,
        );

        if (topic.contains('braco')) {
          _armData = sensorInfo;
        } else {
          _legData = sensorInfo;
        }
      } catch (e) {
        print('Erro ao decodificar JSON: $e');
      }
    });
  }

  void _sendTestSubscription() {
    final patientId = _patientIdController.text;
    if (patientId.isNotEmpty) {
      _mqttService.subscribe('$patientId/braco');
      _mqttService.subscribe('$patientId/perna');
    }
  }

  void _confirmAddition() {
    final newPatient = PatientData(
      name: _nameController.text,
      id: _patientIdController.text,
      sensorData: {
        'braco': _armData ?? SensorInfo(
          direction: '-', 
          duration: '0s',
          icon: Icons.accessibility,
        ),
        'perna': _legData ?? SensorInfo(
          direction: '-',
          duration: '0s',
          icon: Icons.directions_walk,
        ),
      },
    );
    
    Navigator.pop(context, newPatient);
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(showLogo: true),
      backgroundColor: Color(0xFFade0c1),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputForm(),
            SizedBox(height: 20),
            Expanded(
              child: PatientDataBox(
                patient: PatientData(
                  name: _nameController.text,
                  id: _patientIdController.text,
                  sensorData: {
                    'braco': _armData ?? SensorInfo(
                      direction: '-', 
                      duration: '0s',
                      icon: Icons.accessibility,
                    ),
                    'perna': _legData ?? SensorInfo(
                      direction: '-',
                      duration: '0s',
                      icon: Icons.directions_walk,
                    ),
                  },
                ),
                scale: 1.4,
                showLabels: false,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FooterBar(
        onHomePressed: () => Navigator.pop(context),
        onDeletePressed: () => Navigator.pop(context),
        onAddPressed: _confirmAddition,
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF7bc5a2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF145e52), width: 2),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nome do Paciente',
              labelStyle: TextStyle(color: Color(0xFF145e52)),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _patientIdController,
                  decoration: InputDecoration(
                    labelText: 'ID da Pulseira',
                    labelStyle: TextStyle(color: Color(0xFF145e52)),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Color(0xFF145e52)),
                onPressed: _sendTestSubscription,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
