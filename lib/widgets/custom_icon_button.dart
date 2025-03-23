import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final Color iconColor;
  final Color btnColor;
  final void Function() onPressed;
  final IconData icon;

  const CustomIconButton({
    super.key,
    required this.iconColor,
    required this.onPressed,
    required this.icon,
    required this.btnColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: iconColor,
      ),
      style: IconButton.styleFrom(backgroundColor: btnColor),
      onPressed: onPressed,
    );
  }
}
