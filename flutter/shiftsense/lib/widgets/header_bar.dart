import 'package:flutter/material.dart';

class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showLogo;

  HeaderBar({required this.showLogo});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: showLogo ? Image.asset('assets/logo.png', height: 40) : SizedBox(),
      centerTitle: true,
    );
  }
}