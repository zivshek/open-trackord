import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trackord/services/shared_pref_wrapper.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/logger.dart';

abstract class ChartSettingsEvent {}

class ChangeChartType extends ChartSettingsEvent {
  final ChartType type;
  ChangeChartType(this.type);
}

class ToggleShowDot extends ChartSettingsEvent {}

class ToggleCurved extends ChartSettingsEvent {}

class ChangeDotSize extends ChartSettingsEvent {
  final double size;
  ChangeDotSize(this.size);
}

class ToggleHorizontal extends ChartSettingsEvent {}

abstract class ChartSettingsState {}

class ChartSettingsLoaded extends ChartSettingsState {
  final ChartType type;
  final bool showDot;
  final bool curved;
  final double dotSize;
  final bool horizontal;

  ChartSettingsLoaded(
      this.type, this.showDot, this.curved, this.dotSize, this.horizontal);

  ChartSettingsLoaded copyWith({
    ChartType? type,
    bool? showDot,
    bool? curved,
    double? dotSize,
    bool? horizontal,
  }) {
    return ChartSettingsLoaded(
      type ?? this.type,
      showDot ?? this.showDot,
      curved ?? this.curved,
      dotSize ?? this.dotSize,
      horizontal ?? this.horizontal,
    );
  }
}

class ChartSettingsBloc extends Bloc<ChartSettingsEvent, ChartSettingsState>
    with WidgetsBindingObserver {
  ChartSettingsBloc(super.initialState) {
    on<ChangeChartType>((event, emit) {
      final currentState = state as ChartSettingsLoaded;
      final newType =
          ChartType.values[SharedPrefWrapper().getInt(kChartTypeKey)];
      if (currentState.type != newType) {
        logger.info(
            "ChartSettingsBloc: changing chart type from old ${currentState.type} to new $newType.");
        emit(currentState.copyWith(type: newType));
      } else {
        logger.info(
            "AppSettingsBloc: new $newType == old ${currentState.type}, no need to change theme.");
      }
    });

    on<ToggleShowDot>((event, emit) {
      final currentState = state as ChartSettingsLoaded;
      emit(currentState.copyWith(
          showDot: !currentState.showDot, dotSize: currentState.dotSize));
    });

    on<ChangeDotSize>((event, emit) {
      final currentState = state as ChartSettingsLoaded;
      emit(currentState.copyWith(dotSize: event.size));
    });

    on<ToggleCurved>((event, emit) {
      final currentState = state as ChartSettingsLoaded;
      emit(currentState.copyWith(curved: !currentState.curved));
    });

    on<ToggleHorizontal>((event, emit) {
      final currentState = state as ChartSettingsLoaded;
      emit(currentState.copyWith(horizontal: !currentState.horizontal));
    });
  }
}
