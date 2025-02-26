import 'package:flutter/material.dart';
import '../widgets/header_bar.dart';
import '../widgets/footer_bar.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  List<String> _gridItems = List.generate(12, (index) => 'Item ${index + 1}');
  bool _showDelete = false;

  void _toggleDelete() {
    setState(() {
      _showDelete = !_showDelete;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _gridItems.removeAt(index);
      // Lógica para dessinscrever do tópico MQTT aqui
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(showLogo: true),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
        ),
        itemCount: _gridItems.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                color: Colors.grey[200],
                child: Center(child: Text(_gridItems[index])),
              ),
              if (_showDelete)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _deleteItem(index),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: FooterBar(
        onHomePressed: () => Navigator.pushReplacementNamed(context, '/landing'),
        onDeletePressed: _toggleDelete,
        onAddPressed: () => Navigator.pushNamed(context, '/add'),
      ),
    );
  }
}