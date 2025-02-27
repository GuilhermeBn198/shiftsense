import 'package:flutter/material.dart';
import '../models/pulseira_model.dart';

class PatientDataBox extends StatelessWidget {
  final PatientData patient;
  final double scale;
  final bool showLabels;

  const PatientDataBox({
    required this.patient,
    this.scale = 1.0,
    this.showLabels = true,
  });

  Widget _buildSensorCircle(IconData icon, String value, Color color) {
    return Container(
      width: 32 * scale,
      height: 32 * scale,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5 * scale),
      ),
      child: Center(
        child: icon != Icons.help_outline 
            ? Icon(icon, size: 16 * scale, color: color)
            : Text(
                value.substring(0, 1),
                style: TextStyle(
                  fontSize: 16 * scale,
                  color: color,
                ),
              ),
      ),
    );
  }

  Widget _buildLimbSection(String limb, SensorInfo data) {
    return Container(
      margin: EdgeInsets.all(4 * scale),
      padding: EdgeInsets.all(8 * scale),
      decoration: BoxDecoration(
        color: Color(0xFFade0c1),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(
          color: Color(0xFF145e52),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (showLabels)
            Text(
              limb.toUpperCase(),
              style: TextStyle(
                  color: Color(0xFF145e52),
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.bold),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSensorCircle(data.icon, '', Color(0xFF145e52)),
              _buildSensorCircle(
                  _getDirectionIcon(data.direction),
                  data.direction,
                  Color(0xFF7bc5a2)),
              _buildSensorCircle(
                  Icons.access_time, data.duration, Color(0xFF145e52)),
            ],
          ),
        ],
      ),
    );
  }

IconData _getDirectionIcon(String direction) {
  final dir = direction.toLowerCase();
  if (dir.contains('pra cima')) return Icons.arrow_upward;
  if (dir.contains('pra baixo')) return Icons.arrow_downward;
  if (dir.contains('pra esquerda')) return Icons.arrow_back;
  if (dir.contains('pra direita')) return Icons.arrow_forward;
  if (dir.contains('pra cima / pra esquerda')) return Icons.arrow_back;
  if (dir.contains('pra cima / pra direita')) return Icons.arrow_forward;
  if (dir.contains('pra baixo / pra direita')) return Icons.arrow_back;
  if (dir.contains('pra baixo / pra esquerda')) return Icons.arrow_forward;
  return Icons.help_outline; //nao identificou posicao
}

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF7bc5a2),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: Color(0xFF145e52),
          width: 2 * scale,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8 * scale),
            child: Column(
              children: [
                Text(
                  patient.name,
                  style: TextStyle(
                      color: Color(0xFF145e52),
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'ID: ${patient.id}',
                  style: TextStyle(
                      color: Color(0xFF145e52).withOpacity(0.7),
                      fontSize: 12 * scale),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildLimbSection('Braço', patient.sensorData['braco']!),
                ),
                Expanded(
                  child: _buildLimbSection('Perna', patient.sensorData['perna']!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
