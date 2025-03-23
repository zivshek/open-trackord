import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trackord/repositories/records_repository.dart';
import 'package:trackord/services/database_service.dart';
import 'package:trackord/utils/defines.dart';

abstract class ExportImportEvent {}

class ExportToCSVEvent extends ExportImportEvent {
  final String selecteDirectory;

  ExportToCSVEvent(this.selecteDirectory);
}

class ImportFromCSVEvent extends ExportImportEvent {
  final String file;
  final ImportOption option;

  ImportFromCSVEvent(this.file, this.option);
}

class DeleteAllDataEvent extends ExportImportEvent {
  final String? file;

  DeleteAllDataEvent(this.file);
}

abstract class ExportImportState {}

class ExportImportInProgress extends ExportImportState {}

class ExportImportComplete extends ExportImportState {
  final bool isExport;
  final String? exportPath;
  final String? importError;
  final bool deleted;
  ExportImportComplete(this.isExport, this.exportPath, this.importError,
      {this.deleted = false});
}

class ExportImportBloc extends Bloc<ExportImportEvent, ExportImportState> {
  final DatabaseService _database;
  final RecordsRepository _repository;

  ExportImportBloc(this._database, this._repository)
      : super(ExportImportComplete(true, null, null)) {
    on<ExportToCSVEvent>((event, emit) async {
      emit(ExportImportInProgress());
      try {
        String path = await _database.exportToCSV(event.selecteDirectory);
        emit(ExportImportComplete(true, path, null));
      } catch (e) {
        emit(ExportImportComplete(true, null, e.toString()));
      }
    });

    on<ImportFromCSVEvent>(
      (event, emit) async {
        emit(ExportImportInProgress());
        try {
          String? error =
              await _database.importFromCSV(event.file, event.option);
          if (error == null) {
            await _repository.onImportSuccess();
          }
          emit(ExportImportComplete(false, null, error));
        } catch (e) {
          emit(ExportImportComplete(false, null, e.toString()));
        }
      },
    );

    on<DeleteAllDataEvent>(
      (event, emit) async {
        emit(ExportImportInProgress());
        try {
          if (event.file != null) {
            await _database.exportToCSV(event.file!);
          }
          await _database.deleteAllData();
          await _repository.onImportSuccess();
          emit(ExportImportComplete(false, null, null, deleted: true));
        } catch (e) {
          emit(ExportImportComplete(false, null, e.toString()));
        }
      },
    );
  }
}
