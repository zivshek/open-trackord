import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/logger.dart';
import 'package:trackord/utils/utils.dart';

abstract class AppSettingsEvent {}

class ChangeTheme extends AppSettingsEvent {
  final ThemeMode theme;
  ChangeTheme(this.theme);
}

class ChangeLocale extends AppSettingsEvent {
  final Language language;
  ChangeLocale(this.language);
}

abstract class AppSettingsState {}

class AppSettingsLoaded extends AppSettingsState {
  final ThemeMode theme;
  final Locale? locale;
  final UniqueKey localeKey;

  AppSettingsLoaded(this.theme, this.locale, this.localeKey);

  AppSettingsLoaded copyWith({
    ThemeMode? theme,
    Locale? locale,
    UniqueKey? key,
  }) {
    return AppSettingsLoaded(
      theme ?? this.theme,
      locale,
      key ?? localeKey,
    );
  }
}

class AppSettingsBloc extends Bloc<AppSettingsEvent, AppSettingsState>
    with WidgetsBindingObserver {
  AppSettingsBloc(super.initialState) {
    WidgetsBinding.instance.addObserver(this);

    on<ChangeTheme>((event, emit) {
      final currentState = state as AppSettingsLoaded;
      if (currentState.theme != event.theme) {
        logger.info(
            "AppSettingsBloc: changing theme from old ${currentState.theme} to new ${event.theme}");
        emit(currentState.copyWith(
            theme: event.theme, locale: currentState.locale));
      } else {
        logger.info(
            "AppSettingsBloc: new ${event.theme} == old ${currentState.theme}, no need to change theme.");
      }
    });

    on<ChangeLocale>((event, emit) async {
      final currentState = state as AppSettingsLoaded;
      emit(currentState.copyWith(
        locale: Language.toLocale(event.language),
        key: UniqueKey(),
      ));
    });
  }

  @override
  void didChangePlatformBrightness() {
    logger.info("AppSettingsBloc: reacting to system theme change.");
    add(ChangeTheme(getAppThemeMode()));
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}
