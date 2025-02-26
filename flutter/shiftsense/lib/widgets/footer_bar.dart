import 'package:flutter/material.dart';

class FooterBar extends StatelessWidget {
  final Function() onHomePressed;
  final Function() onDeletePressed;
  final Function() onAddPressed;

  FooterBar({
    required this.onHomePressed,
    required this.onDeletePressed,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: onHomePressed,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onDeletePressed,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: onAddPressed,
          ),
        ],
      ),
    );
  }
}