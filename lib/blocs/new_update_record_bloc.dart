import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/repositories/records_repository.dart';
import 'package:trackord/utils/logger.dart';

// For add record screen
abstract class NewOrUpdateRecordEvent {}

class LoadRecentRecords extends NewOrUpdateRecordEvent {
  final int categoryId;
  LoadRecentRecords({required this.categoryId});
}

class AddOrUpdateRecord extends NewOrUpdateRecordEvent {
  final RecordModel record;
  final bool forceUpdateIfExists;
  AddOrUpdateRecord(this.record, this.forceUpdateIfExists);
}

// States
abstract class NewOrUpdateRecordState {}

class RecentRecordsLoading extends NewOrUpdateRecordState {}

class RecentRecordsLoaded extends NewOrUpdateRecordState {
  final List<RecordModel> records;
  RecentRecordsLoaded(this.records);
}

class AddOrUpdateRecordSuccess extends NewOrUpdateRecordState {}

class AddorUpdateRecordError extends NewOrUpdateRecordState {
  final String message;
  final RecordModel? existingRecord;
  final RecordModel? newRecord;
  final List<RecordModel> previousRecords;
  AddorUpdateRecordError(this.message, this.previousRecords,
      {this.existingRecord, this.newRecord});
}

class RecentRecordsError extends NewOrUpdateRecordState {
  final String message;
  RecentRecordsError(this.message);
}

class NewOrUpdateRecordBloc
    extends Bloc<NewOrUpdateRecordEvent, NewOrUpdateRecordState> {
  final RecordsRepository _repository;

  NewOrUpdateRecordBloc(this._repository) : super(RecentRecordsLoading()) {
    on<LoadRecentRecords>(_onLoadRecentRecords);
    on<AddOrUpdateRecord>(_onAddOrUpdateRecord);
  }

  Future<void> _onLoadRecentRecords(
      LoadRecentRecords event, Emitter<NewOrUpdateRecordState> emit) async {
    emit(RecentRecordsLoading());
    try {
      final records =
          await _repository.getRecordsForCategory(event.categoryId, 10, 0);
      emit(RecentRecordsLoaded(records));
    } catch (e) {
      emit(RecentRecordsError(e.toString()));
    }
  }

  Future<void> _onAddOrUpdateRecord(
      AddOrUpdateRecord event, Emitter<NewOrUpdateRecordState> emit) async {
    try {
      RecordModel? existingRecord =
          await _repository.recordExists(event.record);
      if (existingRecord != null) {
        if (event.forceUpdateIfExists) {
          await _repository
              .updateRecord(event.record.copyWith(id: existingRecord.id!));
          logger.info('Updated record for category ${event.record.categoryId}');
          emit(AddOrUpdateRecordSuccess());
        } else {
          logger.info('Error, record exists for the chosen date.');
          emit(AddorUpdateRecordError(
              'Record exists for the chosen date.',
              state is AddorUpdateRecordError
                  ? (state as AddorUpdateRecordError).previousRecords
                  : (state as RecentRecordsLoaded).records,
              existingRecord: existingRecord,
              newRecord: event.record));
        }
      } else if (event.record.id != null) {
        await _repository.updateRecord(event.record);
        logger.info('Updated record for category ${event.record.categoryId}');
        emit(AddOrUpdateRecordSuccess());
      } else {
        await _repository.addRecord(event.record);
        logger.info('Added record for category ${event.record.categoryId}');
        emit(AddOrUpdateRecordSuccess());
      }
    } catch (e) {
      logger.info('Error adding/updating record: $e');
      if (state is RecentRecordsLoaded || state is AddorUpdateRecordError) {
        emit(AddorUpdateRecordError(
            e.toString(),
            state is AddorUpdateRecordError
                ? (state as AddorUpdateRecordError).previousRecords
                : (state as RecentRecordsLoaded).records));
      }
    }
  }
}
