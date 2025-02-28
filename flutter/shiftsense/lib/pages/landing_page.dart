import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/patient_repository.dart';
import '../widgets/patient_data_box.dart';
import '../widgets/header_bar.dart';
import '../widgets/footer_bar.dart';
import '../models/pulseira_model.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PatientRepository _repository = PatientRepository();
  List<PatientData> _patients = [];
  late MQTTService _mqttService;
  bool _showDelete = false;
  bool _mqttConnected = false;
  bool _loading = true;
  String? _errorMessage;
  final Map<String, List<String>> _subscriptions = {};

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _repository.init();
      await _loadPatients();
      await _initializeMQTT();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao inicializar: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadPatients() async {
    final patients = await _repository.getAllPatients();
    setState(() {
      _patients = patients;
    });
  }

  Future<void> _initializeMQTT() async {
    _mqttService = MQTTService(
      server: '07356c1b41e34d65a6152a202151c24d.s1.eu.hivemq.cloud',
      clientId: 'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      username: 'hivemq.webclient.1740079881529',
      password: 'h45de%Pb.6O8aBQo>JC!',
      port: 8883,
      onMessageReceived: _handleMQTTMessage,
    );

    try {
      await _mqttService.connect();
      setState(() {
        _mqttConnected = true;
        _loading = false;
      });

      // Inscreve nos tópicos dos pacientes existentes
      for (final patient in _patients) {
        _subscribeToPatientTopics(patient.id);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro na conexão MQTT: $e';
        _loading = false;
      });
    }
  }

  void _handleMQTTMessage(String topic, String message) async {
    try {
      final jsonData = jsonDecode(message);
      final parts = topic.split('/');
      if (parts.length != 2) return;

      final patientId = parts[0];
      final limb = parts[1];

      // Procura o paciente ou cria um novo
      PatientData existingPatient;
      try {
        existingPatient = _patients.firstWhere((p) => p.id == patientId);
      } catch (e) {
        existingPatient = PatientData(
          name: 'Paciente $patientId',
          id: patientId,
          sensorData: {
            'braco': SensorInfo(
              direction: '-',
              duration: '0s',
              icon: Icons.accessibility,
            ),
            'perna': SensorInfo(
              direction: '-',
              duration: '0s',
              icon: Icons.directions_walk,
            ),
          },
        );
        _patients.add(existingPatient);
        _subscribeToPatientTopics(patientId);
      }

      // Atualiza os dados do sensor
      final updatedPatient = PatientData(
        name: existingPatient.name,
        id: existingPatient.id,
        sensorData: Map<String, SensorInfo>.from(existingPatient.sensorData),
      );

      updatedPatient.sensorData[limb] = SensorInfo(
        direction: jsonData['position'],
        duration: '${jsonData['time_in_position']}s',
        icon: limb == 'braco' 
            ? Icons.accessibility 
            : Icons.directions_walk,
      );

      await _repository.savePatient(updatedPatient);

      setState(() {
        _patients = _patients.map((p) => p.id == patientId ? updatedPatient : p).toList();
      });
    } catch (e) {
      print('Erro ao processar mensagem: $e');
    }
  }

  void _subscribeToPatientTopics(String patientId) {
    final topics = ['$patientId/braco', '$patientId/perna'];
    topics.forEach((topic) {
      if (!_subscriptions.containsKey(patientId)) {
        _subscriptions[patientId] = [];
      }
      if (!_subscriptions[patientId]!.contains(topic)) {
        _mqttService.subscribe(topic);
        _subscriptions[patientId]!.add(topic);
      }
    });
  }

  void _toggleDeleteMode() {
    setState(() => _showDelete = !_showDelete);
  }

  void _deletePatient(int index) async {
    final patientId = _patients[index].id;
    await _repository.deletePatient(patientId);
    setState(() => _patients.removeAt(index));
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFade0c1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Conectando ao MQTT...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFade0c1),
        body: Center(
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: HeaderBar(showLogo: true),
      backgroundColor: const Color(0xFFade0c1),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _patients.length,
        itemBuilder: (context, index) => Stack(
          children: [
            PatientDataBox(
              patient: _patients[index],
              scale: 1.0,
            ),
            if (_showDelete)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _deletePatient(index),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: FooterBar(
        onHomePressed: () => Navigator.pushReplacementNamed(context, '/landing'),
        onDeletePressed: _toggleDeleteMode,
        onAddPressed: () => Navigator.pushNamed(context, '/add'),
      ),
    );
  }
}