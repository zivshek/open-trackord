import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trackord/blocs/chart_settings_bloc.dart';
import 'package:trackord/blocs/app_settings_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/repositories/records_repository.dart';
import 'package:trackord/services/database_service.dart';
import 'package:trackord/services/shared_pref_wrapper.dart';
import 'package:trackord/utils/bloc_providers.dart';
import 'package:trackord/utils/logger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:trackord/utils/router.dart';
import 'package:trackord/utils/theme.dart';
import 'package:trackord/utils/utils.dart';
import 'package:trackord/widgets/adaptive_app.dart';

void main() async {
  setupLogger();
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  GestureBinding.instance.resamplingEnabled = true;

  logger.info('App starting. Initializing database...');
  final databaseService = DatabaseService();
  await databaseService.database;
  logger.info('Database initialized.');

  logger.info('Initializing shared preferences...');
  await SharedPrefWrapper().init();
  logger.info('Shared preferences init complete. Running app...');

  final repository =
      RecordsRepository(databaseService, databaseService: databaseService);
  await repository.initialize();

  final appSettingsState =
      AppSettingsLoaded(getAppThemeMode(), getAppLocale(), UniqueKey());
  final chartSettingsState = ChartSettingsLoaded(
      getChartType(), getShowDot(), getCurved(), getDotSize(), getHorizontal());
  runApp(
    MultiBlocProvider(
      providers: createBlocProviders(
          appSettingsState, chartSettingsState, repository, databaseService),
      child: const MyApp(),
    ),
  );
}

final GoRouter _router = getRouter();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, state) {
        final appSettings = state as AppSettingsLoaded;
        AdaptiveTheme adaptiveTheme =
            AdaptiveTheme(GoogleFonts.robotoTextTheme());

        return AdaptiveApp(
          key: appSettings.localeKey,
          routerConfig: _router,
          title: 'Trackord',
          materialLightTheme: adaptiveTheme.materialLight(),
          materialDarkTheme: adaptiveTheme.materialDark(),
          cupertinoLightTheme: adaptiveTheme.cupertinoLight(),
          cupertinoDarkTheme: adaptiveTheme.cupertinoDark(),
          themeMode: appSettings.theme,
          locale: appSettings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (appSettings.locale != null) {
              return appSettings.locale; // Use user-selected locale
            }
            // 'follow system' is selected, try use system locale
            // check if the system locale is in the supported locales
            Locale? potentialLocale;
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == deviceLocale?.languageCode) {
                if (deviceLocale?.scriptCode == supportedLocale.scriptCode ||
                    deviceLocale?.countryCode == supportedLocale.scriptCode) {
                  // exact match
                  return supportedLocale;
                }
                // first partial match
                potentialLocale ??= supportedLocale;
              }
            }

            // system locale not supported, fallback to English
            return potentialLocale ?? supportedLocales.first;
          },
        );
      },
    );
  }
}
