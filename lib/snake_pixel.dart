import 'package:flutter/material.dart';

class SnakePixel extends StatelessWidget {
  final Color color;
  SnakePixel({ this.color=Colors.white});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
