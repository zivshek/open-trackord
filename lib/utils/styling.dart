import 'package:flutter/material.dart';
import 'package:trackord/utils/utils.dart';

Text getAppBarTitle(BuildContext context, String title) {
  return Text(title, style: TextStyle(color: getAppBarIconColor(context)));
}

Color getAppBarColor(BuildContext context) {
  return Theme.of(context).colorScheme.secondaryContainer;
}

Color getAppBarIconColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSecondaryContainer;
}

Color getPersistentNavColor(BuildContext context) {
  return Theme.of(context).colorScheme.secondaryContainer;
}

Color getCardColor(BuildContext context) {
  return Theme.of(context).colorScheme.surfaceContainer;
}

TextStyle getCardLabelStyle(BuildContext context) {
  return TextStyle(color: Theme.of(context).colorScheme.onSurface);
}

double getCardElevation() {
  return 1;
}

List<Color> getLineColors(BuildContext context) {
  final appBrightness = getStatusBarBrightness(context);
  return appBrightness == Brightness.light ? colorsForLight : colorsForDark;
}

const List<Color> colorsForLight = [
  Color(0xFF3498DB), // Soft Blue
  Color(0xFFE74C3C), // Tomato Red
  Color(0xFF2ECC71), // Mint Green
  Color(0xFFF39C12), // Warm Amber
  Color(0xFF9B59B6), // Lavender Purple
  Color(0xFF1ABC9C), // Cool Teal
  Color(0xFFE67E22), // Pumpkin Orange
  Color(0xFF34495E), // Slate Gray
  Color(0xFFC0392B), // Rich Red
  Color(0xFF16A085), // Sea Green
  Color(0xFF2980B9), // Bright Blue
  Color(0xFFD35400), // Tangerine
  Color(0xFF8E44AD), // Amethyst
  Color(0xFF27AE60), // Jade Green
  Color(0xFFF1C40F), // Bright Yellow
  Color(0xFF2C3E50), // Deep Slate Blue
  Color(0xFFBDC3C7), // Soft Silver
  Color(0xFF7F8C8D), // Muted Gray
  Color(0xFFFF7675), // Pastel Coral
  Color(0xFF74B9FF), // Sky Blue
];
const List<Color> colorsForDark = [
  Color(0xFF16A085), // Muted Teal
  Color(0xFF2980B9), // Muted Blue
  Color(0xFFC0392B), // Muted Red
  Color(0xFF8E44AD), // Muted Purple
  Color(0xFFD35400), // Muted Orange
  Color(0xFF27AE60), // Muted Green
  Color(0xFFAF7AC5), // Soft Purple
  Color(0xFF7F8C8D), // Muted Gray
  Color(0xFF34495E), // Deep Slate
  Color(0xFF2C3E50), // Dark Blue
  Color(0xFFE67E22), // Muted Amber
  Color(0xFF95A5A6), // Light Gray
  Color(0xFF6C5CE7), // Soft Indigo
  Color(0xFF2D3436), // Charcoal Gray
  Color(0xFF81ECEC), // Muted Cyan
  Color(0xFF74B9FF), // Muted Sky Blue
  Color(0xFFA29BFE), // Soft Lavender
  Color(0xFFBDC3C7), // Soft Silver
  Color(0xFF636E72), // Warm Gray
  Color(0xFF1F618D), // Deep Ocean Bluee
];
