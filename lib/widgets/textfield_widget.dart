import 'package:flutter/material.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/styling.dart';

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.inputFieldType,
    this.focusNode,
    this.layerLink,
  });

  final TextEditingController controller;
  final String label;
  final MyInputFieldType inputFieldType;
  final FocusNode? focusNode;
  final LayerLink? layerLink;

  @override
  Widget build(BuildContext context) {
    Widget textField = Card(
      color: getCardColor(context),
      elevation: getCardElevation(),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 2),
        child: _buildAndroidTextFormField(context),
      ),
    );

    if (layerLink != null) {
      return CompositedTransformTarget(
        link: layerLink!,
        child: textField,
      );
    }

    return textField;
  }

  TextFormField _buildAndroidTextFormField(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      minLines: 1,
      maxLines: 5,
      controller: controller,
      onEditingComplete: () => focusNode?.unfocus(),
      style: Theme.of(context)
          .textTheme
          .bodyLarge!
          .copyWith(color: Theme.of(context).colorScheme.primary),
      keyboardType: MyInputFieldType.getTextInputType(inputFieldType),
      inputFormatters: MyInputFieldType.getTextInputFormatters(inputFieldType),
      decoration: InputDecoration(
        labelStyle: getCardLabelStyle(context),
        labelText: label,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => controller.clear(),
        ),
      ),
    );
  }
}
