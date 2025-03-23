import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:trackord/blocs/chart_settings_bloc.dart';
import 'package:trackord/blocs/indi_chart_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/services/shared_pref_wrapper.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/utils.dart';
import 'package:trackord/widgets/adaptive_scaffold.dart';
import 'package:trackord/widgets/gradient_divider.dart';
import 'package:trackord/widgets/time_filters_widget.dart';

class IndiChartPage extends StatefulWidget {
  final CategoryModel category;

  const IndiChartPage({super.key, required this.category});

  @override
  State<IndiChartPage> createState() => _IndiChartPageState();
}

class _IndiChartPageState extends State<IndiChartPage> {
  final String _indiSelectedRangeKey = "IndiRange";
  final String _showRegressionKey = "ShowRegression";
  late ChartDateRange _selectedPeriod;
  late bool _showRegression;

  @override
  void initState() {
    super.initState();
    _selectedPeriod =
        SharedPrefWrapper().getSelectedChartDateRange(_indiSelectedRangeKey);
    _showRegression = SharedPrefWrapper().getBool(_showRegressionKey);
    final categoryId = widget.category.id!;
    context.read<IndiChartBloc>().add(LoadRecordsRange(
        categoryId, ChartDateRange.getToDate(_selectedPeriod)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        context.read<IndiChartBloc>().add(LeaveIndiChart());
      },
      child: AdaptiveScaffold(
        title: context.l10n.indiChartTitle(widget.category.name),
        body: LayoutBuilder(builder: (context, constraints) {
          final chartHeight = constraints.maxHeight - 180;
          return Column(
            children: [
              TimeFiltersWidget(
                context: context,
                selected: _selectedPeriod,
                onPressed: (period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                  SharedPrefWrapper()
                      .setSelectedChartDateRange(_indiSelectedRangeKey, period);
                  context.read<IndiChartBloc>().add(LoadRecordsRange(
                      widget.category.id!,
                      ChartDateRange.getToDate(_selectedPeriod)));
                },
              ),
              Expanded(
                  child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: _buildChart(),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    if (getChartType() == ChartType.line)
                      const GradientDivider(),
                    if (getChartType() == ChartType.line)
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: SwitchListTile.adaptive(
                          title: Text(
                            context.l10n.showRegressionText,
                          ),
                          secondary: const Icon(
                            Icons.line_axis_outlined,
                            size: 17,
                          ),
                          activeColor: getRegressionColor(context),
                          value: _showRegression,
                          onChanged: (newValue) {
                            setState(() {
                              _showRegression = newValue;
                            });
                            SharedPrefWrapper()
                                .setBool(_showRegressionKey, _showRegression);
                          },
                        ),
                      ),
                  ],
                ),
              )),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildChart() {
    return BlocBuilder<ChartSettingsBloc, ChartSettingsState>(
      builder: (context, chartSettingsState) {
        final chartSettings = chartSettingsState as ChartSettingsLoaded;
        return BlocBuilder<IndiChartBloc, IndiChartState>(
            builder: (context, indiChartState) {
          if (indiChartState is RecordsRangeLoaded) {
            if (indiChartState.records.isEmpty) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.only(left: 50, right: 40),
                child: Text(
                  context.l10n.noDataForSelectedPeriodText,
                ),
              ));
            } else if (indiChartState.records.length == 1) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.only(left: 50, right: 40),
                child: Text(
                  context.l10n.notEnoughDataForSelectedPeriodText,
                ),
              ));
            }

            final sampledRecords =
                sampleRecords(indiChartState.records, 1000).reversed.toList();

            final minX =
                sampledRecords.first.date.millisecondsSinceEpoch.toDouble();
            final maxX =
                sampledRecords.last.date.millisecondsSinceEpoch.toDouble();
            final minY = sampledRecords.map((r) => r.value).reduce(math.min);
            final maxY = sampledRecords.map((r) => r.value).reduce(math.max);

            final xInterval = (maxX - minX) / 3;
            final yInterval = (maxY - minY) / 4;

            if (getChartType() == ChartType.line) {
              return _buildLineChart(
                context,
                sampledRecords,
                minX,
                maxX,
                minY,
                maxY,
                xInterval,
                yInterval,
                chartSettings,
              );
            } else {
              return _buildBarChart(
                context,
                sampledRecords,
                minX,
                maxY,
                minY,
                maxY,
                xInterval,
                yInterval,
              );
            }
          } else if (indiChartState is RecordsRangeError) {
            return Center(
                child: Text(
              context.l10n.errorMsg(indiChartState.message),
            ));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
      },
    );
  }

  Widget _buildLineChart(
    BuildContext context,
    List<RecordModel> sampledRecords,
    double minX,
    double maxX,
    double minY,
    double maxY,
    double xInterval,
    double yInterval,
    ChartSettingsLoaded settings,
  ) {
    List<LineChartBarData> lines = [
      LineChartBarData(
        spots: sampledRecords
            .map((record) => FlSpot(
                  record.date.millisecondsSinceEpoch.toDouble(),
                  record.value,
                ))
            .toList(),
        isCurved: settings.curved,
        preventCurveOverShooting: false,
        color: getLineColor(context),
        barWidth: 3,
        dotData: FlDotData(
          show: settings.showDot,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: settings.dotSize,
            color: getLineColor(context),
          ),
        ),
        belowBarData: BarAreaData(show: false),
      )
    ];

    if (_showRegression) {
      final regression = _calculateRegressionLine(sampledRecords);
      lines.add(LineChartBarData(
        spots: regression,
        isCurved: false,
        color: getRegressionColor(context),
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RotatedBox(
        quarterTurns: settings.horizontal ? -1 : 0,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  minIncluded: false,
                  maxIncluded: false,
                  interval: xInterval != 0 ? xInterval : null,
                  getTitlesWidget: (value, meta) {
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          ChartDateRange.getFormattedDate(
                              date, _selectedPeriod),
                          style: Theme.of(context).textTheme.bodySmall,
                        ));
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  maxIncluded: false,
                  showTitles: true,
                  reservedSize: 25,
                  interval: yInterval != 0 ? yInterval : null,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 1.0),
                      child: Text(
                        getRecordValueShort(widget.category.valueType, value),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
                show: true,
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1)),
            lineBarsData: lines,
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipBorder: const BorderSide(color: Colors.black38),
                getTooltipColor: (touchedSpot) =>
                    Theme.of(context).colorScheme.surfaceBright,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final flSpot = barSpot;
                    if (flSpot.barIndex == 1) {
                      return null;
                    }
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
                    return LineTooltipItem(
                      '${flSpot.y.toStringAsFixed(2)} ${widget.category.unit}\n${DateFormat('MMM d, yyyy').format(date)}',
                      Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    List<RecordModel> sampledRecords,
    double minX,
    double maxX,
    double minY,
    double maxY,
    double xInterval,
    double yInterval,
  ) {
    List<BarChartGroupData> bars = sampledRecords.asMap().entries.map((entry) {
      final record = entry.value;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: record.value,
            color: getLineColor(context),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                minIncluded: true,
                maxIncluded: true,
                interval: xInterval != 0 ? xInterval : 10,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sampledRecords.length) {
                    final date = sampledRecords[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        ChartDateRange.getFormattedDate(date, _selectedPeriod),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 25,
                interval: yInterval != 0 ? yInterval : 10,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 1.0),
                    child: Text(
                      getRecordValueShort(widget.category.valueType, value),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          barGroups: bars,
          minY: minY,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (touchedSpot) =>
                  Theme.of(context).colorScheme.surfaceBright,
              tooltipBorder: const BorderSide(color: Colors.black38),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final record = sampledRecords[group.x.toInt()];
                return BarTooltipItem(
                  '${record.value.toStringAsFixed(2)} ${widget.category.unit}\n${DateFormat('MMM d, yyyy').format(record.date)}',
                  Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Theme.of(context).colorScheme.onSurface),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _calculateRegressionLine(List<RecordModel> records) {
    if (records.isEmpty) return [];

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = records.length;

    for (var record in records) {
      double x = record.date.millisecondsSinceEpoch.toDouble();
      double y = record.value;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;

    return [
      FlSpot(records.first.date.millisecondsSinceEpoch.toDouble(),
          slope * records.first.date.millisecondsSinceEpoch + intercept),
      FlSpot(records.last.date.millisecondsSinceEpoch.toDouble(),
          slope * records.last.date.millisecondsSinceEpoch + intercept),
    ];
  }

  Color getLineColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color getRegressionColor(BuildContext context) {
    return Theme.of(context).colorScheme.onTertiaryFixedVariant;
  }
}
