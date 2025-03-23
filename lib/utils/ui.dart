import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trackord/l10n/l10n.dart';

const Duration animDuration = Duration(milliseconds: 200);

Future<void> showDeleteConfirmation(
    BuildContext context, String title, String msg, Function onConfirm) async {
  OkCancelResult result = await showOkCancelAlertDialog(
    context: context,
    title: title,
    message: msg,
    okLabel: context.l10n.deleteButtonText,
    cancelLabel: context.l10n.cancelButtonText,
    isDestructiveAction: true,
    style: AdaptiveStyle.adaptive,
    defaultType: OkCancelAlertDefaultType.cancel,
  );

  if (result == OkCancelResult.ok && context.mounted) {
    onConfirm();
  }
}

Future<int> showBottomSheetSelection(BuildContext context, String title,
    List<String> selections, int currentSelection,
    {int? destructiveIndex, List<String>? subtitles}) async {
  return await showModalBottomSheet<int>(
    context: context,
    builder: (BuildContext context) {
      final height = 150 +
          60 * selections.length.toDouble() +
          32 * (subtitles != null ? subtitles.length : 0);
      return SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: 20,
              ),
              ...selections.asMap().entries.map((entry) {
                final index = entry.key;
                final selection = entry.value;
                final textStyle = TextStyle(
                    color: destructiveIndex != index
                        ? null
                        : Theme.of(context).colorScheme.error);
                return ListTile(
                  visualDensity: VisualDensity.compact,
                  subtitle: subtitles != null && index < subtitles.length
                      ? Text(
                          subtitles[index],
                          style: textStyle,
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  title: Text(
                    selection,
                    style: textStyle,
                  ),
                  trailing: currentSelection == index
                      ? Icon(
                          Icons.radio_button_checked,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    Navigator.of(context)
                        .pop(index); // Pop with the selected index
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  ).then((value) => value ?? -1);
}

void showErrorSnackBar(BuildContext context, String msg) {
  final colorScheme = Theme.of(context).colorScheme;
  showSnackBar(context, Icons.error, msg,
      backgroundColor: colorScheme.errorContainer,
      textColor: colorScheme.onErrorContainer);
}

void showNotificationSnackBar(BuildContext context, String msg) {
  final colorScheme = Theme.of(context).colorScheme;
  showSnackBar(context, Icons.notifications, msg,
      backgroundColor: colorScheme.primaryContainer,
      textColor: colorScheme.onPrimaryContainer);
}

void showSnackBar(BuildContext context, IconData icon, String msg,
    {Color? backgroundColor, Color? textColor}) {
  DelightToastBar(
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(milliseconds: 3000),
      animationDuration: const Duration(milliseconds: 700),
      builder: (context) => ToastCard(
          leading: Icon(
            icon,
            color: textColor,
          ),
          title: Text(
            msg,
            style: TextStyle(color: textColor),
          ),
          color: backgroundColor)).show(context);
}

Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  if (Platform.isIOS) {
    DateTime? selectedDate;
    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: initialDate,
            minimumDate: firstDate,
            maximumDate: lastDate,
            onDateTimeChanged: (DateTime date) {
              selectedDate = date;
            },
          ),
        );
      },
    );
    return selectedDate;
  } else {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
}
