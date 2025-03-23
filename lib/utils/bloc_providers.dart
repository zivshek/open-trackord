import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';
import 'package:trackord/blocs/app_settings_bloc.dart';
import 'package:trackord/blocs/categories_bloc.dart';
import 'package:trackord/blocs/chart_settings_bloc.dart';
import 'package:trackord/blocs/clusters_bloc.dart';
import 'package:trackord/blocs/export_import_bloc.dart';
import 'package:trackord/blocs/history_bloc.dart';
import 'package:trackord/blocs/indi_chart_bloc.dart';
import 'package:trackord/blocs/multi_chart_bloc.dart';
import 'package:trackord/blocs/new_update_record_bloc.dart';
import 'package:trackord/repositories/records_repository.dart';
import 'package:trackord/services/database_service.dart';

List<SingleChildWidget> createBlocProviders(
    AppSettingsLoaded appSettingsState,
    ChartSettingsLoaded chartSettingsState,
    RecordsRepository repository,
    DatabaseService databaseService) {
  return [
    BlocProvider(
      create: (context) => AppSettingsBloc(appSettingsState),
    ),
    BlocProvider(
      create: (context) => ChartSettingsBloc(chartSettingsState),
    ),
    BlocProvider<CategoriesBloc>(
      create: (context) {
        final bloc = CategoriesBloc(repository);
        bloc.add(LoadCategories());
        return bloc;
      },
    ),
    BlocProvider<ClustersBloc>(
      create: (context) {
        final bloc = ClustersBloc(repository);
        bloc.add(LoadClustersEvent());
        return bloc;
      },
    ),
    BlocProvider<NewOrUpdateRecordBloc>(
      create: (context) => NewOrUpdateRecordBloc(repository),
    ),
    BlocProvider<HistoryBloc>(
      create: (context) => HistoryBloc(repository),
    ),
    BlocProvider<IndiChartBloc>(
      create: (context) => IndiChartBloc(repository),
    ),
    BlocProvider<MultiChartBloc>(
      create: (context) => MultiChartBloc(repository),
    ),
    BlocProvider<ExportImportBloc>(
      create: (context) => ExportImportBloc(databaseService, repository),
    ),
  ];
}
