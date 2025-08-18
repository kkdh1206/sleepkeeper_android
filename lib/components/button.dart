import 'package:flutter/material.dart';
import 'package:sleep_keeper/theme/colors.dart';

enum ButtonType { primary, secondary, tertiary }

class Button extends StatelessWidget {
  final Function() onTap;
  final String text;
  final ButtonType type;
  const Button({super.key, required this.onTap, required this.text, this.type = ButtonType.tertiary });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 1,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: type == ButtonType.primary ? Colors.white :
              type == ButtonType.secondary ? secondaryBackground :
              Colors.transparent,
            ),
            child: InkWell(
              onTap: onTap,
              splashColor: type == ButtonType.primary ? secondaryBackground.withAlpha(30) : brandMain.withAlpha(30),
              hoverColor: type == ButtonType.primary ? secondaryBackground.withAlpha(30) : brandMain.withAlpha(30),
              highlightColor: type == ButtonType.primary ? secondaryBackground.withAlpha(30) : brandMain.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Text(text, style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: type == ButtonType.primary ? primaryBackground : brandMain)
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
