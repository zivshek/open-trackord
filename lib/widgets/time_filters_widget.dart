import 'package:flutter/material.dart';
import 'package:trackord/utils/defines.dart';

class TimeFiltersWidget extends StatelessWidget {
  final BuildContext context;
  final ChartDateRange selected;
  final void Function(ChartDateRange) onPressed;

  const TimeFiltersWidget({
    super.key,
    required this.context,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ChartDateRange.values.map((period) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              backgroundColor: selected == period
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onPressed: () => onPressed(period),
            child: Text(
              ChartDateRange.getString(context, period),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
