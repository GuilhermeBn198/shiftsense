import 'package:hive/hive.dart';
import '../models/pulseira_model.dart';

class PatientRepository {
  static const String _boxName = 'patients';

  /// Inicializa o Hive (caso ainda não tenha sido aberto) e abre a box de pacientes.
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      // Certifique-se de já ter chamado Hive.init() no main.dart antes de usar.
      await Hive.openBox<PatientData>(_boxName);
    }
  }

  /// Salva (ou atualiza) um paciente na box usando seu ID como chave.
  Future<void> savePatient(PatientData patient) async {
    final box = Hive.box<PatientData>(_boxName);
    await box.put(patient.id, patient);
  }

  /// Retorna todos os pacientes armazenados na box.
  Future<List<PatientData>> getAllPatients() async {
    final box = Hive.box<PatientData>(_boxName);
    return box.values.toList().cast<PatientData>();
  }

  /// Exclui um paciente a partir do seu ID.
  Future<void> deletePatient(String id) async {
    final box = Hive.box<PatientData>(_boxName);
    await box.delete(id);
  }
}
