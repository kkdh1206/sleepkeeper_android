import 'package:flutter/material.dart';

class Option extends StatelessWidget {
  final String text;
  final Widget child;
  const Option(this.text, {super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white))),
          child,
        ],
      ),
    );
  }
}
