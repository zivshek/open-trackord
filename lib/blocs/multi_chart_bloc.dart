import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/repositories/records_repository.dart';

abstract class MultiChartEvent {}

class LoadMultiChartRange extends MultiChartEvent {
  final List<int> categories;
  final DateTime to;

  LoadMultiChartRange(this.categories, this.to);
}

class LeaveMultiChart extends MultiChartEvent {}

abstract class MultiChartState {}

class MultiChartRangeLoaded extends MultiChartState {
  final Map<int, List<RecordModel>> records;

  MultiChartRangeLoaded(this.records);
}

class MultiChartRangeError extends MultiChartState {
  final String message;

  MultiChartRangeError(this.message);
}

class MultiChartBloc extends Bloc<MultiChartEvent, MultiChartState> {
  final RecordsRepository _repository;

  MultiChartBloc(this._repository) : super(MultiChartRangeLoaded({})) {
    on<LoadMultiChartRange>(_onLoadMultiChartRange);
    on<LeaveMultiChart>(_onLeaveMultiChart);
  }

  Future<void> _onLoadMultiChartRange(
      LoadMultiChartRange event, Emitter<MultiChartState> emit) async {
    try {
      if (event.categories.isNotEmpty) {
        final records = await _repository.getRecordsForCategoriesForRange(
            event.categories, event.to);
        emit(MultiChartRangeLoaded(records));
      } else {
        emit(MultiChartRangeLoaded({}));
      }
    } catch (e) {
      emit(MultiChartRangeError(e.toString()));
    }
  }

  void _onLeaveMultiChart(
      LeaveMultiChart event, Emitter<MultiChartState> emit) {
    emit(MultiChartRangeLoaded({}));
  }
}
