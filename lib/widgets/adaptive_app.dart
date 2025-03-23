// filepath: /Volumes/Storage/dev/Trackord/lib/widgets/adaptive_app.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

class AdaptiveApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  final RouterConfig<Object> routerConfig;
  final String title;
  final ThemeData materialLightTheme;
  final ThemeData materialDarkTheme;
  final CupertinoThemeData cupertinoLightTheme;
  final CupertinoThemeData cupertinoDarkTheme;
  final ThemeMode themeMode;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;
  final Iterable<Locale> supportedLocales;
  final Locale? Function(Locale?, Iterable<Locale>)? localeResolutionCallback;

  const AdaptiveApp({
    super.key,
    this.navigatorKey,
    required this.routerConfig,
    required this.title,
    required this.materialLightTheme,
    required this.materialDarkTheme,
    required this.cupertinoLightTheme,
    required this.cupertinoDarkTheme,
    required this.themeMode,
    this.locale,
    required this.localizationsDelegates,
    required this.supportedLocales,
    this.localeResolutionCallback,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      final isDarkMode = themeMode == ThemeMode.dark ||
          (themeMode == ThemeMode.system &&
              MediaQuery.of(context).platformBrightness == Brightness.dark);

      return Theme(
        data: isDarkMode ? materialDarkTheme : materialLightTheme,
        child: ScaffoldMessenger(
          child: Material(
            child: CupertinoApp.router(
              debugShowCheckedModeBanner: false,
              key: navigatorKey,
              routerConfig: routerConfig,
              title: title,
              theme: isDarkMode ? cupertinoDarkTheme : cupertinoLightTheme,
              locale: locale,
              localizationsDelegates: localizationsDelegates,
              supportedLocales: supportedLocales,
              localeResolutionCallback: localeResolutionCallback,
            ),
          ),
        ),
      );
    } else {
      return ScaffoldMessenger(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          key: navigatorKey,
          routerConfig: routerConfig,
          title: title,
          theme: materialLightTheme,
          darkTheme: materialDarkTheme,
          themeMode: themeMode,
          locale: locale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          localeResolutionCallback: localeResolutionCallback,
        ),
      );
    }
  }
}
