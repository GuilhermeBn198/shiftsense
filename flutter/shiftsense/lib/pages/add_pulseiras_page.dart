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
    // Lógica MQTT de teste
  }

  void _confirmAdd() {
    Navigator.pop(context, {
      'name': _nameController.text,
      'patientId': _patientIdController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(showLogo: true),
      body: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85, // Redução de 15%
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  margin: EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text('Dados recebidos aparecerão aqui')),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FooterBar(
        onHomePressed: () => Navigator.pop(context),
        onDeletePressed: () => Navigator.pop(context),
        onAddPressed: _confirmAdd, // Botão de + agora confirma a adição
      ),
    );
  }
}