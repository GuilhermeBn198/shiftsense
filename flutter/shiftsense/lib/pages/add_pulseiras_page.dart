import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/patient_repository.dart';
import '../widgets/header_bar.dart';
import '../widgets/footer_bar.dart';
import '../widgets/patient_data_box.dart';
import '../models/pulseira_model.dart';

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
  final PatientRepository _repository = PatientRepository();
  bool _isSubscribed = false;
  bool _mqttConnected = false;
  bool _connecting = true; // Flag para indicar que está tentando conectar
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _initializeMQTT();
    _repository.init(); // Inicializa a box do Hive
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

    // Inicia a conexão e define um timeout de 30 segundos
    _mqttService.connect().then((_) {
      setState(() {
        _mqttConnected = true;
        _connecting = false;
      });
    }).timeout(Duration(seconds: 30), onTimeout: () {
      setState(() {
        _connecting = false;
        _connectionError = 'Tempo de conexão esgotado (30s). Verifique sua rede e configurações.';
      });
      _mqttService.disconnect();
    }).catchError((e) {
      setState(() {
        _connecting = false;
        _connectionError = 'Erro na conexão MQTT: $e';
      });
    });
  }

  void _handleTestData(String topic, String message) {
    try {
      final jsonData = jsonDecode(message);
      final direction = jsonData['position']?.toString() ?? '-';
      final duration = jsonData['time_in_position']?.toString() ?? '0';

      setState(() {
        final sensorInfo = SensorInfo(
          direction: direction,
          duration: '${duration}s',
          icon: topic.contains('braco')
              ? Icons.accessibility
              : Icons.directions_walk,
        );

        if (topic.contains('braco')) {
          _armData = sensorInfo;
        } else {
          _legData = sensorInfo;
        }
      });
    } catch (e) {
      print('Erro ao processar mensagem: $e');
    }
  }

  void _sendTestSubscription() {
    final patientId = _patientIdController.text;
    if (patientId.isNotEmpty && !_isSubscribed) {
      if (!_mqttConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MQTT não está conectado. Aguarde...')),
        );
        return;
      }
      _mqttService.subscribe('$patientId/braco');
      _mqttService.subscribe('$patientId/perna');
      setState(() => _isSubscribed = true);
    }
  }

  void _confirmAddition() async {
    if (_nameController.text.isEmpty || _patientIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }

    final newPatient = PatientData(
      name: _nameController.text,
      id: _patientIdController.text,
      sensorData: {
        'braco': _armData ??
            SensorInfo(
              direction: '-',
              duration: '0s',
              icon: Icons.accessibility,
            ),
        'perna': _legData ??
            SensorInfo(
              direction: '-',
              duration: '0s',
              icon: Icons.directions_walk,
            ),
      },
    );

    try {
      await _repository.savePatient(newPatient);
      Navigator.pop(context, newPatient);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar paciente: $e')),
      );
    }
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    _nameController.dispose();
    _patientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(showLogo: true),
      backgroundColor: const Color(0xFFade0c1),
      body: _connecting
          ? Center(child: CircularProgressIndicator())
          : _connectionError != null
              ? Center(child: Text(_connectionError!))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInputForm(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: PatientDataBox(
                          patient: PatientData(
                            name: _nameController.text,
                            id: _patientIdController.text,
                            sensorData: {
                              'braco': _armData ??
                                  SensorInfo(
                                    direction: '-',
                                    duration: '0s',
                                    icon: Icons.accessibility,
                                  ),
                              'perna': _legData ??
                                  SensorInfo(
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
        color: const Color(0xFF7bc5a2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF145e52), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do Paciente',
              labelStyle: TextStyle(color: Color(0xFF145e52)),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _patientIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID da Pulseira',
                    labelStyle: TextStyle(color: Color(0xFF145e52)),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: _isSubscribed ? Colors.grey : const Color(0xFF145e52),
                ),
                onPressed: _isSubscribed ? null : _sendTestSubscription,
              ),
            ],
          ),
        ],
      ),
    );
  }
}