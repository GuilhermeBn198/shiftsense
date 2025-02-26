import 'package:flutter/material.dart';
import '../widgets/header_bar.dart';
import '../widgets/footer_bar.dart';

class AddPulseirasPage extends StatefulWidget {
  @override
  _AddPulseirasPageState createState() => _AddPulseirasPageState();
}

class _AddPulseirasPageState extends State<AddPulseirasPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();

  void _subscribeTest() {
    // Lógica MQTT de teste aqui
  }

  void _confirmAdd() {
    // Adicionar ao GridView e navegar de volta
    Navigator.pop(context, {
      'name': _nameController.text,
      'patientId': _patientIdController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(showLogo: true),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _patientIdController,
                    decoration: InputDecoration(labelText: 'Paciente ID'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _subscribeTest,
                ),
              ],
            ),
            Expanded(
              child: Container(
                // Área para dados recebidos do MQTT
                color: Colors.grey[100],
                child: Center(child: Text('Dados recebidos aparecerão aqui')),
              ),
            ),
            ElevatedButton(
              onPressed: _confirmAdd,
              child: Text('Confirmar Adição'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FooterBar(
        onHomePressed: () => Navigator.pushReplacementNamed(context, '/landing'),
        onDeletePressed: () {},
        onAddPressed: () {},
      ),
    );
  }
}