import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class AdaptiveTheme {
  final TextTheme textTheme;

  const AdaptiveTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff365e9d),
      surfaceTint: Color(0xff365e9d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff82a8ec),
      onPrimaryContainer: Color(0xff001c40),
      secondary: Color(0xff515f79),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffd9e4ff),
      onSecondaryContainer: Color(0xff3c4962),
      tertiary: Color(0xff814a87),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffd091d4),
      onTertiaryContainer: Color(0xff36013f),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffda342e),
      onErrorContainer: Color(0xff410002),
      surface: Color(0xfff9f9ff),
      onSurface: Color(0xff1a1c20),
      onSurfaceVariant: Color(0xff434750),
      outline: Color(0xff737781),
      outlineVariant: Color(0xffc3c6d2),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3035),
      inversePrimary: Color(0xffaac7ff),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff001b3e),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff194683),
      secondaryFixed: Color(0xffd6e3ff),
      onSecondaryFixed: Color(0xff0d1c32),
      secondaryFixedDim: Color(0xffb9c7e5),
      onSecondaryFixedVariant: Color(0xff3a4760),
      tertiaryFixed: Color(0xffffd6fe),
      onTertiaryFixed: Color(0xff35013e),
      tertiaryFixedDim: Color(0xfff2b0f5),
      onTertiaryFixedVariant: Color(0xff67326d),
      surfaceDim: Color(0xffdad9df),
      surfaceBright: Color(0xfff9f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff3f3f9),
      surfaceContainer: Color(0xffeeedf3),
      surfaceContainerHigh: Color(0xffe8e7ed),
      surfaceContainerHighest: Color(0xffe2e2e8),
    );
  }

  ThemeData materialLight() {
    return materialTheme(lightScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffaac7ff),
      surfaceTint: Color(0xffaac7ff),
      onPrimary: Color(0xff002f64),
      primaryContainer: Color(0xff6e94d6),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffb9c7e5),
      onSecondary: Color(0xff233148),
      secondaryContainer: Color(0xff323f58),
      onSecondaryContainer: Color(0xffc6d4f3),
      tertiary: Color(0xfff2b0f5),
      onTertiary: Color(0xff4d1a55),
      tertiaryContainer: Color(0xffbc7fc0),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff121317),
      onSurface: Color(0xffe2e2e8),
      onSurfaceVariant: Color(0xffc3c6d2),
      outline: Color(0xff8d909b),
      outlineVariant: Color(0xff434750),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e8),
      inversePrimary: Color(0xff365e9d),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff001b3e),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff194683),
      secondaryFixed: Color(0xffd6e3ff),
      onSecondaryFixed: Color(0xff0d1c32),
      secondaryFixedDim: Color(0xffb9c7e5),
      onSecondaryFixedVariant: Color(0xff3a4760),
      tertiaryFixed: Color(0xffffd6fe),
      onTertiaryFixed: Color(0xff35013e),
      tertiaryFixedDim: Color(0xfff2b0f5),
      onTertiaryFixedVariant: Color(0xff67326d),
      surfaceDim: Color(0xff121317),
      surfaceBright: Color(0xff38393e),
      surfaceContainerLowest: Color(0xff0c0e12),
      surfaceContainerLow: Color(0xff1a1c20),
      surfaceContainer: Color(0xff1e2024),
      surfaceContainerHigh: Color(0xff282a2e),
      surfaceContainerHighest: Color(0xff333539),
    );
  }

  ThemeData materialDark() {
    return materialTheme(darkScheme());
  }

  ThemeData materialTheme(ColorScheme colorScheme) => ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ));

  CupertinoThemeData cupertinoLight() {
    return cupertinoTheme(lightScheme());
  }

  CupertinoThemeData cupertinoDark() {
    return cupertinoTheme(darkScheme());
  }

  CupertinoThemeData cupertinoTheme(ColorScheme colorScheme) {
    return CupertinoThemeData(
      brightness: colorScheme.brightness,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.surface,
      barBackgroundColor: colorScheme.surface,
      primaryContrastingColor: colorScheme.onPrimary,
      textTheme: CupertinoTextThemeData(
        primaryColor: colorScheme.onSurface,
        textStyle: textTheme.bodyMedium,
      ),
    );
  }
}
