import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../services/mqtt_service.dart';
import '../widgets/patient_data_box.dart';
import '../widgets/header_bar.dart';
import '../widgets/footer_bar.dart';
import '../models/pulseira_model.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final List<PatientData> _patients = [];
  late MQTTService _mqttService;
  bool _showDelete = false;
  final Map<String, List<String>> _subscriptions = {};

  @override
  void initState() {
    super.initState();
    _initializeMQTT();
  }

  void _initializeMQTT() {
    _mqttService = MQTTService(
      server: 'broker.hivemq.com',
      clientId: 'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      onMessageReceived: _handleMQTTMessage,
    );
    _mqttService.connect();
  }

  void _handleMQTTMessage(String topic, String message) {
    setState(() {
      final parts = topic.split('/');
      if (parts.length != 2) return;

      final patientId = parts[0];
      final limb = parts[1];
      final data = message.split(',');

      final existingPatient = _patients.firstWhere(
        (p) => p.id == patientId,
        orElse: () => PatientData(
          name: 'Paciente $patientId',
          id: patientId,
          sensorData: {},
        ),
      );

      existingPatient.sensorData[limb] = SensorInfo(
        direction: data[0],
        duration: '${data[1]}s',
        icon: limb == 'braco' ? Icons.accessibility : Icons.directions_walk,
      );

      if (!_patients.contains(existingPatient)) {
        _patients.add(existingPatient);
        _subscribeToPatientTopics(patientId);
      }
    });
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
    setState(() {
      _showDelete = !_showDelete;
    });
  }

  void _deletePatient(int index) {
    final patientId = _patients[index].id;
    _subscriptions[patientId]?.forEach((topic) {
      _mqttService.unsubscribe(topic);
    });
    _subscriptions.remove(patientId);
    
    setState(() {
      _patients.removeAt(index);
    });
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
      backgroundColor: Color(0xFFade0c1), // Cor de fundo externa
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(4),
                    child: Icon(
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