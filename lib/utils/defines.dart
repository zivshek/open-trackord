import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:trackord/l10n/l10n.dart';

const double kNavBarHeight = 80;

enum ValueType {
  float,
  integer;

  static ValueType fromString(String s) => switch (s) {
        "float" => float,
        "ValueType.float" => float,
        "ValueType.integer" => integer,
        "integer" => integer,
        "int" => integer,
        _ => float,
      };

  static String getValueTypeLocalizedText(ValueType vt, BuildContext context) =>
      switch (vt) {
        ValueType.float => context.l10n.valueTypeFloat,
        ValueType.integer => context.l10n.valueTypeInt,
      };
}

enum MyInputFieldType {
  text,
  decimal,
  integer;

  static TextInputType getTextInputType(MyInputFieldType type) {
    switch (type) {
      case MyInputFieldType.text:
        return TextInputType.text;
      case MyInputFieldType.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case MyInputFieldType.integer:
        return TextInputType.number;
    }
  }

  static List<TextInputFormatter>? getTextInputFormatters(
      MyInputFieldType type) {
    switch (type) {
      case MyInputFieldType.integer:
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return null;
    }
  }
}

enum ChartDateRange {
  oneMonth,
  sixMonths,
  oneYear,
  yearToDate,
  max;

  static String getString(BuildContext context, ChartDateRange range) {
    switch (range) {
      case ChartDateRange.oneMonth:
        return context.l10n.chartRange1M;
      case ChartDateRange.sixMonths:
        return context.l10n.chartRange6M;
      case ChartDateRange.oneYear:
        return context.l10n.chartRange1Y;
      case ChartDateRange.yearToDate:
        return context.l10n.chartRangeYTD;
      case ChartDateRange.max:
        return context.l10n.chartRangeMax;
    }
  }

  static String getFormattedDate(DateTime date, ChartDateRange range) {
    switch (range) {
      case ChartDateRange.oneMonth:
        return DateFormat('MMM d').format(date);
      case ChartDateRange.sixMonths:
      case ChartDateRange.oneYear:
      case ChartDateRange.yearToDate:
      case ChartDateRange.max:
        return DateFormat('MMM yyyy').format(date);
    }
  }

  static DateTime getToDate(ChartDateRange range) {
    final now = DateTime.now();
    switch (range) {
      case ChartDateRange.oneMonth:
        return DateTime(now.year, now.month - 1, now.day);
      case ChartDateRange.sixMonths:
        return DateTime(now.year, now.month - 6, now.day);
      case ChartDateRange.yearToDate:
        return DateTime(now.year, 1, 1);
      case ChartDateRange.oneYear:
        return DateTime(now.year - 1, now.month, now.day);
      default:
        return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

String getThemeModeLocalizedText(ThemeMode themeMode, BuildContext context) =>
    switch (themeMode) {
      ThemeMode.system => context.l10n.followSystem,
      ThemeMode.light => context.l10n.themeModeLight,
      ThemeMode.dark => context.l10n.themeModeDark,
    };

enum Language {
  system,
  english,
  chineseSimplified,
  chineseTraditional;

  static Locale? toLocale(Language language) => switch (language) {
        Language.english => const Locale('en'),
        Language.chineseSimplified => const Locale('zh'),
        Language.chineseTraditional =>
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        _ => null,
      };
}

String getLanguageLocalizedText(Language language, BuildContext context) =>
    switch (language) {
      Language.system => context.l10n.followSystem,
      Language.english => 'English',
      Language.chineseSimplified => '中文-简体',
      Language.chineseTraditional => '中文-繁体',
    };

enum ChartType {
  line,
  bar,
}

enum ImportOption {
  nuke,
  mergeAndOverwrite,
  mergeAndSkip;

  static String toLocalizedTitle(ImportOption option, BuildContext context) =>
      switch (option) {
        ImportOption.nuke => context.l10n.importOptionNuke,
        ImportOption.mergeAndOverwrite =>
          context.l10n.importOptionMergeOverwrite,
        ImportOption.mergeAndSkip => context.l10n.importOptionMergeSkip,
      };

  static String toLocalizedSubtitle(
          ImportOption option, BuildContext context) =>
      switch (option) {
        ImportOption.nuke => context.l10n.importOptionNukeSubtitle,
        ImportOption.mergeAndOverwrite =>
          context.l10n.importOptionMergeOverwriteSubtitle,
        ImportOption.mergeAndSkip => context.l10n.importOptionMergeSkipSubtitle,
      };
}
