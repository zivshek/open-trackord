import 'package:flutter/material.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/services/shared_pref_wrapper.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/logger.dart';

Brightness getStatusBarBrightness(BuildContext context) {
  return Theme.of(context).brightness;
}

Brightness getStatusBarIconBrightness(BuildContext context) {
  final appBrightness = Theme.of(context).brightness;
  return appBrightness == Brightness.light ? Brightness.dark : Brightness.light;
}

ThemeMode getAppThemeMode() {
  return ThemeMode.values[SharedPrefWrapper().getInt(kThemeModeKey)];
}

Locale? getAppLocale() {
  return Language.toLocale(
      Language.values[SharedPrefWrapper().getInt(kLanguageKey)]);
}

ChartType getChartType() {
  return ChartType.line;
  //return ChartType.values[SharedPrefWrapper().getInt(kChartTypeKey)];
}

List<String> getRecentUnits() {
  return SharedPrefWrapper().getStringList(kRecentUnitsKey) ?? [];
}

bool getShowDot() {
  return SharedPrefWrapper().getBool(kShowDotsKey, defaultValue: true);
}

bool getCurved() {
  return SharedPrefWrapper().getBool(kCurvedKey, defaultValue: false);
}

double getDotSize() {
  return SharedPrefWrapper().getDouble(kDotSizeKey, defaultValue: 3);
}

bool getHorizontal() {
  return SharedPrefWrapper().getBool(kHorizontalKey, defaultValue: false);
}

List<DropdownMenuItem<ValueType>> buildValueTypeDropdownItems(
    BuildContext context) {
  return [
    DropdownMenuItem(
        value: ValueType.float, child: Text(context.l10n.valueTypeFloat)),
    DropdownMenuItem(
        value: ValueType.integer, child: Text(context.l10n.valueTypeInt)),
  ];
}

String getRecordValueFull(String valueType, double? value) {
  if (value == null) {
    return "";
  }
  if (valueType == 'float') {
    return value.toStringAsFixed(1);
  }
  return value.toInt().toString();
}

String getRecordValueShort(String valueType, double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 10000) {
    return '${(value / 1000).toStringAsFixed(0)}k';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  } else if (value >= 10) {
    return valueType == 'float'
        ? value.toStringAsFixed(0)
        : value.toInt().toString();
  } else {
    return valueType == 'float'
        ? value.toStringAsFixed(1)
        : value.toInt().toString();
  }
}

DateTime getDate(DateTime datetime) {
  return datetime.copyWith(
      year: datetime.year, month: datetime.month, day: datetime.day);
}

List<RecordModel> sampleRecords(List<RecordModel> records, int maxSamples) {
  if (records.length <= maxSamples) return records;

  final sampledRecords = <RecordModel>[];
  final step = records.length ~/ maxSamples;
  for (var i = 0; i < records.length; i += step) {
    sampledRecords.add(records[i.floor()]);
  }
  // Ensure the last record is included
  if (sampledRecords.last != records.last) {
    sampledRecords.add(records.last);
  }
  return sampledRecords;
}

bool hasDuplicates(List<dynamic> list) {
  final seen = <dynamic>{};
  for (final item in list) {
    if (seen.contains(item)) {
      logger.info("duplicate found, $item");
      return true;
    }
    seen.add(item);
  }
  return false;
}
