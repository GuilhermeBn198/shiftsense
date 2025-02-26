import 'package:flutter/material.dart';
import '../models/pulseira_model.dart';

class PatientDataBox extends StatelessWidget {
  final PatientData patient;
  final double scale;

  PatientDataBox({required this.patient, this.scale = 1.0});

  Widget _buildSensorCircle(IconData icon, String value, Color color) {
    return Container(
      width: 32 * scale,
      height: 32 * scale,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Icon(icon, size: 16 * scale, color: color),
      ),
    );
  }

  Widget _buildSensorBox(String limb, SensorInfo data) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFFade0c1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF145e52), // Borda principal
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSensorCircle(data.icon, '', Color(0xFF145e52)),
          _buildSensorCircle(_getDirectionIcon(data.direction), '', Color(0xFF7bc5a2)),
          Text(data.duration, style: TextStyle(color: Color(0xFF145e52))),
        ],
      ),
    );
  }

  IconData _getDirectionIcon(String direction) {
    switch (direction.toLowerCase()) {
      case 'up': return Icons.arrow_upward;
      case 'down': return Icons.arrow_downward;
      case 'left': return Icons.arrow_back;
      case 'right': return Icons.arrow_forward;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFF7bc5a2), // Cor interna
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF145e52), width: 2),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Text(patient.name, style: TextStyle(
                  color: Color(0xFF145e52),
                  fontWeight: FontWeight.bold,
                )),
                Text('ID: ${patient.id}', style: TextStyle(
                  color: Color(0xFF145e52).withOpacity(0.7),
                )),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildSensorBox('Braço', 
                    patient.sensorData['braco'] ?? SensorInfo(
                      direction: '-',
                      duration: '0s',
                      icon: Icons.accessibility,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildSensorBox('Perna', 
                    patient.sensorData['perna'] ?? SensorInfo(
                      direction: '-',
                      duration: '0s',
                      icon: Icons.directions_walk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}