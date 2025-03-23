import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:choice/choice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hidable/hidable.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:trackord/blocs/categories_bloc.dart';
import 'package:trackord/blocs/chart_settings_bloc.dart';
import 'package:trackord/blocs/export_import_bloc.dart';
import 'package:trackord/blocs/multi_chart_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/models/record_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trackord/services/shared_pref_wrapper.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/logger.dart';
import 'package:trackord/utils/styling.dart';
import 'package:trackord/utils/utils.dart';
import 'package:trackord/widgets/adaptive_scaffold.dart';
import 'package:trackord/widgets/gradient_divider.dart';
import 'package:trackord/widgets/time_filters_widget.dart';

class MultiChartPage extends StatefulWidget {
  const MultiChartPage({super.key});

  @override
  State<MultiChartPage> createState() => _MultiChartPageState();
}

class _MultiChartPageState extends State<MultiChartPage> {
  final String _multiSelectedRangeKey = "MultiRange";
  final String _multiSelectedCategoriesKey = "MultiCategories";
  final String _reviewPopupShowedKey = "ReviewPopupShowed";
  final String _multiChartOpenCountKey = "MultiChartOpenCount";
  final int _openCountForInAppReview = 5;

  final Map<int, bool> _selectedCategories = {};
  late ChartDateRange _selectedTimeRange;

  late List<Color> _colors;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedTimeRange =
        SharedPrefWrapper().getSelectedChartDateRange(_multiSelectedRangeKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadPage();
      _incrementOpenCount();
    });

    context.read<ExportImportBloc>().stream.listen((state) {
      if (state is ExportImportComplete &&
          !state.isExport &&
          state.importError == null) {
        _reloadPage();
      }
    });
  }

  void _reloadPage() {
    setState(() {
      final categoriesState = context.read<CategoriesBloc>().state;
      if (categoriesState is CategoriesLoaded) {
        for (var category in categoriesState.categories) {
          _selectedCategories[category.id!] = false;
        }

        final selectedCategories =
            SharedPrefWrapper().getStringList(_multiSelectedCategoriesKey);
        if (selectedCategories != null) {
          for (var selected in selectedCategories) {
            int id = int.parse(selected);
            if (_selectedCategories.containsKey(id)) {
              _selectedCategories[id] = true;
            }
          }
        }
        _loadRecordsForSelectedCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _colors = getLineColors(context);
    return AdaptiveScaffold(
      title: context.l10n.multiChartTitle,
      body: LayoutBuilder(builder: (context, constraints) {
        final chartHeight = constraints.maxHeight - 180;
        return Column(
          children: [
            Hidable(
              controller: _scrollController,
              deltaFactor: 0.06,
              child: TimeFiltersWidget(
                context: context,
                selected: _selectedTimeRange,
                onPressed: (period) {
                  if (period != _selectedTimeRange) {
                    setState(() {
                      _selectedTimeRange = period;
                    });
                    SharedPrefWrapper().setSelectedChartDateRange(
                        _multiSelectedRangeKey, period);
                    _loadRecordsForSelectedCategories();
                  }
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: _buildChart(),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const GradientDivider(),
                    _buildCategoryToggleButtons(),
                    const SizedBox(
                      height: 70,
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildChart() {
    return BlocBuilder<ChartSettingsBloc, ChartSettingsState>(
      builder: (context, chartSettingsState) {
        final chartSettings = chartSettingsState as ChartSettingsLoaded;
        return BlocBuilder<MultiChartBloc, MultiChartState>(
          builder: (context, state) {
            if (state is MultiChartRangeLoaded) {
              final selectedCategories = _getSelectedCategories();
              if (selectedCategories.isEmpty) {
                return Center(child: Text(context.l10n.selectCharactersText));
              }

              if (state.records.isEmpty) {
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 50, right: 40),
                  child: Text(
                    context.l10n.noDataForSelectedPeriodText,
                  ),
                ));
              }

              final lineBarsData =
                  _getLineBarsData(state.records, chartSettings);

              final allRecords = state.records.values.fold<List<RecordModel>>(
                  [], (result, element) => result..addAll(element));
              allRecords.sort((a, b) => a.date.compareTo(b.date));

              final minX = allRecords.isNotEmpty
                  ? allRecords.first.date.millisecondsSinceEpoch.toDouble()
                  : 0;
              final maxX = allRecords.isNotEmpty
                  ? allRecords.last.date.millisecondsSinceEpoch.toDouble()
                  : 0;
              final yStep = chartSettings.horizontal ? 7 : 3;
              final yInterval = (maxX - minX) / yStep;

              final minY = allRecords.isNotEmpty
                  ? allRecords.map((r) => r.value).reduce(min)
                  : 0;
              final maxY = allRecords.isNotEmpty
                  ? allRecords.map((r) => r.value).reduce(max)
                  : 0;
              final xStep = chartSettings.horizontal ? 3 : 7;
              final xInterval = (maxY - minY) / xStep;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: RotatedBox(
                  quarterTurns: chartSettings.horizontal ? -1 : 0,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: lineBarsData,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            interval: yInterval != 0 ? yInterval : 10,
                            minIncluded: false,
                            maxIncluded: false,
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                              return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    ChartDateRange.getFormattedDate(
                                        date, _selectedTimeRange),
                                    style: const TextStyle(fontSize: 12),
                                  ));
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: xInterval != 0 ? xInterval : 10,
                            maxIncluded: false,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 1.0),
                                child: Text(
                                  getRecordValueShort("float", value),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                              color: Colors.grey[300], strokeWidth: 1);
                        },
                      ),
                      borderData: FlBorderData(
                          show: true,
                          border:
                              Border.all(color: Colors.grey[400]!, width: 1)),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBorder:
                              const BorderSide(color: Colors.black38),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipColor: (touchedSpot) =>
                              const Color.fromARGB(230, 255, 255, 255),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else if (state is MultiChartRangeError) {
              return Center(child: Text(context.l10n.errorMsg(state.message)));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }

  List<LineChartBarData> _getLineBarsData(
      Map<int, List<RecordModel>> allRecords, ChartSettingsLoaded settings) {
    return allRecords.entries
        .map((entry) {
          if (entry.value.length < 2) {
            return null;
          }
          final categoryRecords = sampleRecords(entry.value, 700);
          final categoriesState =
              context.read<CategoriesBloc>().state as CategoriesLoaded;
          int colorIndex = categoriesState.categories
              .indexWhere((category) => category.id == entry.key);
          Color lineColor = _colors[colorIndex % _colors.length];

          return LineChartBarData(
            spots: categoryRecords
                .map((record) => FlSpot(
                      record.date.millisecondsSinceEpoch.toDouble(),
                      record.value,
                    ))
                .toList(),
            isCurved: settings.curved,
            preventCurveOverShooting: false,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: settings.showDot,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: settings.dotSize,
                color: lineColor,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          );
        })
        .where((element) => element != null)
        .cast<LineChartBarData>()
        .toList();
  }

  Widget _buildCategoryToggleButtons() {
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        if (state is CategoriesLoaded) {
          final choices = state.categories;
          final selected = _getSelectedCategories();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Choice<CategoryModel>.inline(
              clearable: true,
              multiple: true,
              value: selected,
              itemCount: choices.length + 2,
              itemBuilder: (selection, i) {
                if (i == 0) {
                  return ChoiceChip(
                    label: Text(context.l10n.selectAllBtnText),
                    elevation: 1.0,
                    side: BorderSide.none,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    selected: false, // "All" should not be selectable
                    onSelected: (_) {
                      // Select all choices
                      for (var choice in choices) {
                        selection.onSelected(choice);
                      }
                      _selectAll(choices);
                    },
                  );
                } else if (i == 1) {
                  // "None" Chip
                  return ChoiceChip(
                    label: Text(context.l10n.selectNoneBtnText),
                    elevation: 1.0,
                    side: BorderSide.none,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    selected: false, // "None" should not be selectable
                    onSelected: (_) {
                      // Deselect all choices
                      for (var choice in choices) {
                        selection.onSelected(choice);
                      }
                      _deselectAll(choices);
                    },
                  );
                } else {
                  final index = i - 2;
                  return ChoiceChip(
                    label: Text(choices[index].name),
                    checkmarkColor: _colors[index % _colors.length],
                    side: BorderSide.none,
                    elevation: 1.0,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    selected: selection.selected(choices[index]),
                    onSelected: (selected) {
                      selection.onSelected(choices[index]);
                      _setSelectedCategory(choices[index], selected);
                    },
                  );
                }
              },
              listBuilder: choices.isEmpty
                  ? ChoiceList.createScrollable(spacing: 10)
                  : ChoiceList.createWrapped(runSpacing: 0),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  void _selectAll(List<CategoryModel> categories) {
    bool anychange = false;
    for (var category in categories) {
      if (_selectedCategories[category.id!] != true) {
        _selectedCategories[category.id!] = true;
        anychange = true;
      }
    }

    if (anychange) {
      setState(() {});
      _saveSelectedCategories();
      logger.info('Selected all categories: ${categories.length}');
      _loadRecordsForSelectedCategories();
    }
  }

  void _deselectAll(List<CategoryModel> categories) {
    bool anychange = false;
    for (var category in categories) {
      if (_selectedCategories[category.id!] == true) {
        _selectedCategories[category.id!] = false;
        anychange = true;
      }
    }

    if (anychange) {
      setState(() {});
      SharedPrefWrapper().setStringList(_multiSelectedCategoriesKey, []);
      logger.info('Deselected all categories');
      _loadRecordsForSelectedCategories();
    }
  }

  void _setSelectedCategory(CategoryModel category, bool selected) {
    setState(() {
      _selectedCategories[category.id!] = selected;
    });
    _saveSelectedCategories();
    _loadRecordsForSelectedCategories();
  }

  void _loadRecordsForSelectedCategories() {
    final selectedCategoryIds = _selectedCategories.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedCategoryIds.isNotEmpty) {
      context.read<MultiChartBloc>().add(LoadMultiChartRange(
          selectedCategoryIds, ChartDateRange.getToDate(_selectedTimeRange)));
    } else {
      context
          .read<MultiChartBloc>()
          .add(LoadMultiChartRange([], DateTime.now()));
    }
  }

  List<CategoryModel> _getSelectedCategories() {
    final categoriesState = context.read<CategoriesBloc>().state;
    if (categoriesState is CategoriesLoaded) {
      return categoriesState.categories
          .where((category) => _selectedCategories[category.id] == true)
          .toList();
    }
    return [];
  }

  void _saveSelectedCategories() {
    SharedPrefWrapper().setStringList(
        _multiSelectedCategoriesKey,
        _selectedCategories.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key.toString())
            .toList());
  }

  Future<void> _incrementOpenCount() async {
    final reviewPopupShowed =
        SharedPrefWrapper().getBool(_reviewPopupShowedKey);
    if (!reviewPopupShowed) {
      final openCount = SharedPrefWrapper().getInt(_multiChartOpenCountKey);
      if (openCount >= _openCountForInAppReview - 1) {
        await _showReviewPopup(context);
      } else {
        SharedPrefWrapper().setInt(_multiChartOpenCountKey, openCount + 1);
      }
    }
  }

  Future<void> _showReviewPopup(BuildContext context) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      message: context.l10n.internalReviewText,
      okLabel: context.l10n.yesButtonText,
      cancelLabel: context.l10n.cancelButtonText,
    );

    if (result == OkCancelResult.ok) {
      await _showNativeReviewPopup();
    } else {
      SharedPrefWrapper().setInt(_multiChartOpenCountKey, 0);
    }
  }

  Future<void> _showNativeReviewPopup() async {
    final InAppReview inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        SharedPrefWrapper().setBool(_reviewPopupShowedKey, true);
      }
    } catch (e) {
      logger.info("Error showing review popup: $e");
    }
  }
}
