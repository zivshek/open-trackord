import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/repositories/records_repository.dart';

abstract class HistoryEvent {}

class LoadRecordsPagenation extends HistoryEvent {
  final int categoryId;
  final int offset;
  final int limit;
  final double? screenHeight;

  LoadRecordsPagenation(this.categoryId, this.offset, this.limit,
      {this.screenHeight});
}

class HistoryDeleteRecordEvent extends HistoryEvent {
  RecordModel record;
  HistoryDeleteRecordEvent(this.record);
}

abstract class HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<RecordModel> records;
  final int offset;
  final bool hasMoreRecords;
  HistoryLoaded(
    this.records,
    this.offset,
    this.hasMoreRecords,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HistoryLoaded &&
        listEquals(other.records, records) &&
        other.offset == offset &&
        other.hasMoreRecords == hasMoreRecords;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(records),
        offset,
        hasMoreRecords,
      );
}

class HistoryError extends HistoryState {
  final List<RecordModel> records;
  final int offset;
  final bool hasMoreRecords;
  final String message;
  HistoryError(this.records, this.offset, this.hasMoreRecords, this.message);
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final RecordsRepository _repository;

  HistoryBloc(this._repository) : super(HistoryLoaded([], 0, true)) {
    on<LoadRecordsPagenation>(_onLoadPagenation);
    on<HistoryDeleteRecordEvent>(_onDeleteRecord);
  }

  Future<void> _onLoadPagenation(
      LoadRecordsPagenation event, Emitter<HistoryState> emit) async {
    if (state is HistoryLoaded) {
      try {
        emit(HistoryLoaded([], 0, true));
        final int offset = event.offset;
        int limit = event.limit;
        if (offset == 0 && event.screenHeight != null) {
          const itemHeight = 63.0;
          final visibleItemCount = (event.screenHeight! / itemHeight).ceil();
          if (visibleItemCount > event.limit) {
            limit = visibleItemCount + 2;
          }
        }
        final records = await _repository.getRecordsForCategory(
            event.categoryId, limit + offset, 0);
        final int newOffset = limit + offset;
        emit(HistoryLoaded(records, newOffset, records.length == newOffset));
      } catch (e) {
        emit(HistoryError((state as HistoryLoaded).records, event.offset,
            (state as HistoryLoaded).hasMoreRecords, e.toString()));
      }
    }
  }

  Future<void> _onDeleteRecord(
      HistoryDeleteRecordEvent event, Emitter<HistoryState> emit) async {
    if (state is HistoryLoaded) {
      try {
        await _repository.deleteRecord(event.record);
        final historyLoadedState = state as HistoryLoaded;
        List<RecordModel> updatedRecords = List.from(historyLoadedState.records)
          ..remove(event.record);
        emit(HistoryLoaded(updatedRecords, historyLoadedState.offset,
            historyLoadedState.hasMoreRecords));
      } catch (e) {
        emit(HistoryError(
            (state as HistoryLoaded).records,
            (state as HistoryLoaded).offset,
            (state as HistoryLoaded).hasMoreRecords,
            e.toString()));
      }
    }
  }
}
