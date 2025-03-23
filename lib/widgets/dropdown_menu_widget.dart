import 'package:flutter/material.dart';
import 'package:trackord/utils/styling.dart';

class DropdownMenuWidget<T> extends StatelessWidget {
  const DropdownMenuWidget({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.label,
  });

  final List<DropdownMenuItem<T>> items;
  final T? selectedItem;
  final ValueChanged<T?>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: getCardColor(context),
      elevation: getCardElevation(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
        child: DropdownButtonFormField<T>(
          value: selectedItem,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            filled: true,
            fillColor: getCardColor(context),
            labelStyle: getCardLabelStyle(context),
          ),
          items: items,
          onChanged: onChanged,
          style: getCardLabelStyle(context),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerLow,
          alignment: AlignmentDirectional.bottomStart,
        ),
      ),
    );
  }
}
