import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'pulseira_model.dart';

class PatientDataAdapter extends TypeAdapter<PatientData> {
  @override
  final int typeId = 0; // Certifique-se de usar um ID único para cada adapter

  @override
  PatientData read(BinaryReader reader) {
    // Lê o número de campos gravados
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientData(
      name: fields[0] as String,
      id: fields[1] as String,
      sensorData: (fields[2] as Map).cast<String, SensorInfo>(),
    );
  }

  @override
  void write(BinaryWriter writer, PatientData obj) {
    writer
      ..writeByte(3) // número de campos
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.sensorData);
  }
}

class SensorInfoAdapter extends TypeAdapter<SensorInfo> {
  @override
  final int typeId = 1;

  @override
  SensorInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorInfo(
      direction: fields[0] as String,
      duration: fields[1] as String,
      icon: IconData(fields[2] as int, fontFamily: 'MaterialIcons'),
    );
  }

  @override
  void write(BinaryWriter writer, SensorInfo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.direction)
      ..writeByte(1)
      ..write(obj.duration)
      ..writeByte(2)
      ..write(obj.icon.codePoint);
  }
}