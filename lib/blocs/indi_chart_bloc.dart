import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/repositories/records_repository.dart';

abstract class IndiChartEvent {}

class LoadRecordsRange extends IndiChartEvent {
  final int categoryId;
  final DateTime to;

  LoadRecordsRange(this.categoryId, this.to);
}

class LeaveIndiChart extends IndiChartEvent {}

abstract class IndiChartState {}

class RecordsRangeLoaded extends IndiChartState {
  final List<RecordModel> records;

  RecordsRangeLoaded(this.records);
}

class RecordsRangeError extends IndiChartState {
  final String message;

  RecordsRangeError(this.message);
}

class IndiChartBloc extends Bloc<IndiChartEvent, IndiChartState> {
  final RecordsRepository _repository;

  IndiChartBloc(this._repository) : super(RecordsRangeLoaded([])) {
    on<LoadRecordsRange>(_onLoadRecordsRange);
    on<LeaveIndiChart>(_onLeaveIndiChart);
  }

  Future<void> _onLoadRecordsRange(
      LoadRecordsRange event, Emitter<IndiChartState> emit) async {
    try {
      final records = await _repository.getRecordsForCategoryForRange(
          event.categoryId, event.to);
      emit(RecordsRangeLoaded(records));
    } catch (e) {
      emit(RecordsRangeError(e.toString()));
    }
  }

  void _onLeaveIndiChart(LeaveIndiChart event, Emitter<IndiChartState> emit) {
    emit(RecordsRangeLoaded([]));
  }
}
