import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pulseira_model.dart';

class PatientDataBox extends StatefulWidget {
  final PatientData patient;
  final double scale;
  final bool showLabels;

  const PatientDataBox({
    required this.patient,
    this.scale = 1.0,
    this.showLabels = true,
    Key? key,
  }) : super(key: key);

  @override
  _PatientDataBoxState createState() => _PatientDataBoxState();
}

class _PatientDataBoxState extends State<PatientDataBox> {
  bool _blinkOn = false;
  Timer? _blinkTimer;
  Timer? _notificationTimer;

  // 4 horas = 14400 segundos
  static const int _thresholdSeconds = 14400;

  @override
  void initState() {
    super.initState();
    _updateTimers();
  }

  @override
  void didUpdateWidget(covariant PatientDataBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTimers();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  bool _shouldBlink() {
    int durationBraco = int.tryParse(widget.patient.sensorData['braco']!
        .duration
        .replaceAll('s', '')) ??
        0;
    int durationPerna = int.tryParse(widget.patient.sensorData['perna']!
        .duration
        .replaceAll('s', '')) ??
        0;
    return (durationBraco >= _thresholdSeconds || durationPerna >= _thresholdSeconds);
  }

  void _updateTimers() {
    if (_shouldBlink()) {
      if (_blinkTimer == null) {
        _blinkTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
          setState(() {
            _blinkOn = !_blinkOn;
          });
        });
      }
    } else {
      _blinkTimer?.cancel();
      _blinkTimer = null;
      _notificationTimer?.cancel();
      _notificationTimer = null;
      if (_blinkOn) {
        setState(() {
          _blinkOn = false;
        });
      }
    }
  }

  /// Widget para criar um círculo ou elipse com ícone centralizado ou texto.
  /// Se [isEllipse] for verdadeiro, o widget terá largura maior que a altura.
  Widget _buildSensorShape(IconData icon, String value, Color color,
      {bool showValue = false, bool isEllipse = false}) {
    final double width = isEllipse ? 60 * widget.scale : 45 * widget.scale;
    final double height = 45 * widget.scale;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: color, width: 2 * widget.scale),
      ),
      child: Center(
        child: showValue
            ? Text(
          value,
          style: TextStyle(
            fontSize: 13 * widget.scale,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        )
            : Icon(icon, size: 32 * widget.scale, color: color),
      ),
    );
  }

  /// Converte a duração (em segundos, com "s") para um formato legível (ex.: "1h 5m" ou "15m 30s")
  String _formatDuration(String durationStr) {
    int seconds = int.tryParse(durationStr.replaceAll('s', '')) ?? 0;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  /// Constrói o sub-box para cada membro (sem exibir o texto da label)
  Widget _buildLimbSection(SensorInfo data) {
    return Container(
      margin: EdgeInsets.all(4 * widget.scale),
      padding: EdgeInsets.all(4 * widget.scale),
      decoration: BoxDecoration(
        color: Color(0xFFade0c1),
        borderRadius: BorderRadius.circular(12 * widget.scale),
        border: Border.all(color: Color(0xFF145e52)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSensorShape(data.icon, '', Color(0xFF145e52)),
          SizedBox(height: 4 * widget.scale),
          _buildSensorShape(
              _getDirectionIcon(data.direction),
              data.direction,
              Color(0xFF2E7D32)),
          SizedBox(height: 4 * widget.scale),
          _buildSensorShape(
              Icons.access_time,
              _formatDuration(data.duration),
              Color(0xFF145e52),
              showValue: true,
              isEllipse: true),
        ],
      ),
    );
  }

  /// Mapeia a string de direção para um ícone adequado, considerando também direções compostas.
  IconData _getDirectionIcon(String direction) {
    final dir = direction.toLowerCase().replaceAll(' ', '');
    if (dir.contains('pracima/pradireita') ||
        dir.contains('pracima-diredireita')) {
      return Icons.north_east;
    }
    if (dir.contains('pracima/praesquerda') ||
        dir.contains('pracima-direesquerda')) {
      return Icons.north_west;
    }
    if (dir.contains('prabaixo/pradireita') ||
        dir.contains('prabaixo-diredireita')) {
      return Icons.south_east;
    }
    if (dir.contains('prabaixo/praesquerda') ||
        dir.contains('prabaixo-direesquerda')) {
      return Icons.south_west;
    }
    if (dir.contains('pracima')) return Icons.arrow_upward;
    if (dir.contains('prabaixo')) return Icons.arrow_downward;
    if (dir.contains('praesquerda')) return Icons.arrow_back;
    if (dir.contains('pradireita')) return Icons.arrow_forward;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Color(0xFF7bc5a2);
    final Color blinkColor = Colors.redAccent.withOpacity(0.7);
    final Color currentColor = _shouldBlink() && _blinkOn ? blinkColor : baseColor;

    return Container(
      decoration: BoxDecoration(
        color: currentColor,
        borderRadius: BorderRadius.circular(12 * widget.scale),
        border: Border.all(color: Color(0xFF145e52), width: 2 * widget.scale),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(3 * widget.scale),
            child: Column(
              children: [
                Text(
                  widget.patient.name,
                  style: TextStyle(
                    color: Color(0xFF145e52),
                    fontSize: 16 * widget.scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${widget.patient.id}',
                  style: TextStyle(
                    color: Color(0xFF145e52).withOpacity(0.7),
                    fontSize: 14 * widget.scale,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildLimbSection(widget.patient.sensorData['braco']!)),
                Expanded(child: _buildLimbSection(widget.patient.sensorData['perna']!)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
