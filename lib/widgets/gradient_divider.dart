import 'package:flutter/material.dart';

class GradientDivider extends StatelessWidget {
  const GradientDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outline;
    return Container(
      height: 0.3,
      decoration: BoxDecoration(
        color: dividerColor,
        gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              dividerColor.withAlpha(0),
              dividerColor,
              dividerColor,
              dividerColor,
              dividerColor.withAlpha(0),
            ]),
        shape: BoxShape.rectangle,
      ),
    );
  }
}
