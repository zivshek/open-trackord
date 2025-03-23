import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trackord/blocs/app_settings_bloc.dart';
import 'package:trackord/blocs/categories_bloc.dart';
import 'package:trackord/blocs/chart_settings_bloc.dart';
import 'package:trackord/blocs/clusters_bloc.dart';
import 'package:trackord/blocs/export_import_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/services/shared_pref_wrapper.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/logger.dart';
import 'package:trackord/utils/ui.dart';
import 'package:trackord/utils/utils.dart';
import 'package:trackord/widgets/adaptive_scaffold.dart';
import 'package:trackord/widgets/gradient_divider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Language _language;
  late ThemeMode _theme;
  //late bool _isLineChart;
  late bool _showDots;
  late bool _curved;
  late bool _horizontal;
  late double _dotSize;
  bool _isInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = SharedPrefWrapper();
    setState(() {
      _language = Language.values[prefs.getInt(kLanguageKey)];
      _theme = ThemeMode.values[prefs.getInt(kThemeModeKey)];

      //_isLineChart = prefs.getBool('isLineChart', defaultValue: true);
      _showDots = getShowDot();
      _curved = getCurved();
      _dotSize = getDotSize();
      _horizontal = getHorizontal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: context.l10n.settingsTitle,
      body: BlocListener<ExportImportBloc, ExportImportState>(
        listener: (context, state) {
          if (state is ExportImportComplete) {
            if (state.isExport && state.exportPath != null) {
              showNotificationSnackBar(
                  context, context.l10n.fileExportedMessage(state.exportPath!));
            } else if (!state.isExport) {
              if (state.importError != null) {
                showNotificationSnackBar(
                    context,
                    context.l10n
                        .fileImportedFailureMessage(state.importError!));
              } else {
                context.read<ClustersBloc>().add(LoadClustersEvent());
                context.read<CategoriesBloc>().add(LoadCategories());
                if (!state.deleted) {
                  showNotificationSnackBar(
                      context, context.l10n.fileImportedSuccessMessage);
                } else {
                  showNotificationSnackBar(
                      context, context.l10n.deleteAllDataSuccessMessage);
                }
              }
            }

            setState(() {
              _isInProgress = false;
            });
          }
        },
        child: Stack(children: [
          ListView(
            children: [
              _buildLanguageSetting(context),
              _buildThemeSetting(context),
              // Chart settings
              const GradientDivider(),
              // SwitchListTile(
              //   title: Text(context.l10n.chartTypeSettingTitle),
              //   subtitle: Text(_isLineChart ? 'Line Chart' : 'Bar Chart'),
              //   value: _isLineChart,
              //   onChanged: (bool value) {
              //     setState(() {
              //       _isLineChart = value;
              //     });
              //   },
              // ),
              // Horizontal
              SwitchListTile.adaptive(
                title: Text(context.l10n.horizontalSettingTitle),
                value: _horizontal,
                onChanged: (bool value) async {
                  setState(() {
                    _horizontal = value;
                  });

                  await SharedPrefWrapper()
                      .setBool(kHorizontalKey, _horizontal);

                  if (context.mounted) {
                    context.read<ChartSettingsBloc>().add(ToggleHorizontal());
                  }
                },
              ),
              // Curved
              SwitchListTile.adaptive(
                title: Text(context.l10n.curvedSettingTitle),
                value: _curved,
                onChanged: (bool value) async {
                  setState(() {
                    _curved = value;
                  });

                  await SharedPrefWrapper().setBool(kCurvedKey, _curved);

                  if (context.mounted) {
                    context.read<ChartSettingsBloc>().add(ToggleCurved());
                  }
                },
              ),
              SwitchListTile.adaptive(
                title: Text(context.l10n.showDotsSettingTitle),
                value: _showDots,
                onChanged: (bool value) async {
                  setState(() {
                    _showDots = value;
                  });

                  await SharedPrefWrapper().setBool(kShowDotsKey, _showDots);

                  if (context.mounted) {
                    context.read<ChartSettingsBloc>().add(ToggleShowDot());
                  }
                },
              ),
              if (_showDots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 30,
                    ),
                    Text(context.l10n.dotSizeSettingTitle),
                    Flexible(
                      child: Slider.adaptive(
                        value: _dotSize,
                        max: 7,
                        min: 0,
                        label: _dotSize.toStringAsFixed(2),
                        onChangeEnd: (value) async {
                          await SharedPrefWrapper()
                              .setDouble(kDotSizeKey, _dotSize);

                          if (context.mounted) {
                            context
                                .read<ChartSettingsBloc>()
                                .add(ChangeDotSize(_dotSize));
                          }
                        },
                        onChanged: (double value) async {
                          setState(() {
                            _dotSize = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: Platform.isIOS ? 21 : 19,
                    ),
                  ],
                ),

              const GradientDivider(),
              ListTile(
                title: Text(context.l10n.exportToCSVSettingTitle),
                onTap: () => _onExportToCSV(context),
              ),

              ListTile(
                title: Text(context.l10n.importFromCSVSettingTitle),
                onTap: () => _onImportCSV(context),
              ),

              ListTile(
                title: Text(context.l10n.deleteAllDataSettingTitle,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => _onDeleteAllData(),
              ),

              const GradientDivider(),
              if (kDebugMode)
                ListTile(
                  title: const Text("Debug Load Data (En)"),
                  onTap: () => _onDebugLoadData(context, true),
                ),
              if (kDebugMode)
                ListTile(
                  title: const Text("Debug Load Data (Cn)"),
                  onTap: () => _onDebugLoadData(context, false),
                ),
              ListTile(
                title: Text(context.l10n.licensesSettingTitle),
                onTap: () => context.push('/licenses'),
              ),
              ListTile(
                title: Text(context.l10n.privacyPolicySettingTitle),
                subtitle: Text(context.l10n.privacyPolicySubtitle),
                onTap: _onOpenPrivacyPolicy,
              ),
              ListTile(
                title: Text(context.l10n.feedbackSettingTitle),
                onTap: _onOpenFeedback,
              ),
              const SizedBox(
                height: 150,
              )
            ],
          ),
          if (_isInProgress) const Center(child: CircularProgressIndicator())
        ]),
      ),
    );
  }

  Future<void> _onOpenFeedback() async {
    final Uri url = Uri(
        scheme: 'mailto',
        path: 'trackord.dev@gmail.com',
        queryParameters: {'subject': 'Trackord feedback'});

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _onDeleteAllData() async {
    await showDeleteConfirmation(
      context,
      context.l10n.deleteAllDataSettingTitle,
      context.l10n.deleteAllDataConfirmText,
      _onConfirmDeleteAllData,
    );
  }

  Future<void> _onConfirmDeleteAllData() async {
    if (!_isInProgress) {
      final exportImportBloc = context.read<ExportImportBloc>();
      final String? selectedDirectory = await _getExportDirectory();

      if (selectedDirectory == null) {
        logger.info('User canceled the directory selection');
        return;
      }

      setState(() {
        _isInProgress = true;
      });

      if (context.mounted) {
        exportImportBloc.add(DeleteAllDataEvent(selectedDirectory));
      }
    }
  }

  Future<void> _onExportToCSV(BuildContext context) async {
    final exportImportBloc = context.read<ExportImportBloc>();
    if (!_isInProgress) {
      final String? selectedDirectory = await _getExportDirectory();

      if (selectedDirectory == null) {
        logger.info('User canceled the directory selection');
        return;
      }

      setState(() {
        _isInProgress = true;
      });

      if (context.mounted) {
        exportImportBloc.add(ExportToCSVEvent(selectedDirectory));
      }
    }
  }

  Future<void> _onDebugLoadData(BuildContext context, bool en) async {
    if (!_isInProgress) {
      setState(() {
        _isInProgress = true;
      });

      String mockDataPath =
          en ? 'mock/mock_data_en.csv' : 'mock/mock_data_cn.csv';
      if (context.mounted) {
        context
            .read<ExportImportBloc>()
            .add(ImportFromCSVEvent(mockDataPath, ImportOption.nuke));
      }
    }
  }

  Future<void> _onImportCSV(BuildContext context) async {
    if (!_isInProgress) {
      String? file = await _selectCSVToImport();
      if (file == null) {
        logger.info('User canceled the file selection');
        return;
      }

      int result = -1;
      if (context.mounted) {
        result = await showBottomSheetSelection(
          context,
          context.l10n.importOptionSettingTitle,
          ImportOption.values
              .map((option) => ImportOption.toLocalizedTitle(option, context))
              .toList(),
          -1,
          subtitles: ImportOption.values
              .map(
                  (option) => ImportOption.toLocalizedSubtitle(option, context))
              .toList(),
          destructiveIndex: ImportOption.nuke.index,
        );
      }

      if (result == -1) {
        logger.info('User canceled the import option selection');
        return;
      }

      setState(() {
        _isInProgress = true;
      });

      final importOption = ImportOption.values[result];

      if (context.mounted) {
        context
            .read<ExportImportBloc>()
            .add(ImportFromCSVEvent(file, importOption));
      }
    }
  }

  Future<String?> _selectCSVToImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      return result.files.first.path;
    } catch (e) {
      return null;
    }
  }

  void _onOpenPrivacyPolicy() async {
    var appLocale = getAppLocale();
    Locale? potentialLocale;
    if (appLocale == null) {
      final systemLocaleString = Platform.localeName;
      final parts = systemLocaleString.split('_');
      final systemLocale =
          parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
      for (var supportedLocale in AppLocalizations.supportedLocales) {
        if (supportedLocale.languageCode == systemLocale.languageCode) {
          if (systemLocale.scriptCode == supportedLocale.scriptCode ||
              systemLocale.countryCode == supportedLocale.scriptCode) {
            appLocale = supportedLocale;
            break;
          }
          potentialLocale ??= supportedLocale;
        }
      }
    }
    appLocale ??= potentialLocale ?? Language.toLocale(Language.english);
    if (appLocale!.languageCode == 'en') {
      await launchUrl(
          Uri.parse('https://trackordev.github.io/trackord/privacy/en'),
          mode: LaunchMode.platformDefault);
    } else if (appLocale.languageCode == 'zh') {
      if (appLocale.scriptCode == 'Hant' ||
          appLocale.countryCode == 'Hant' ||
          appLocale.countryCode == 'HK' ||
          appLocale.countryCode == 'TW') {
        await launchUrl(
            Uri.parse('https://trackordev.github.io/trackord/privacy/zh_hant'),
            mode: LaunchMode.platformDefault);
      } else {
        await launchUrl(
            Uri.parse('https://trackordev.github.io/trackord/privacy/zh'),
            mode: LaunchMode.platformDefault);
      }
    }
  }

  ListTile _buildThemeSetting(BuildContext context) {
    return ListTile(
      title: Text(context.l10n.themeSettingTitle),
      subtitle: Text(
        getThemeModeLocalizedText(_theme, context),
      ),
      onTap: () async {
        int result = await showBottomSheetSelection(
          context,
          context.l10n.themeSettingTitle,
          ThemeMode.values
              .map((mode) => getThemeModeLocalizedText(mode, context))
              .toList(),
          _theme.index,
        );

        if (result != -1 && result != _theme.index) {
          setState(() {
            _theme = ThemeMode.values[result];
          });

          await SharedPrefWrapper().setInt(kThemeModeKey, _theme.index);

          if (context.mounted) {
            context.read<AppSettingsBloc>().add(ChangeTheme(_theme));
          }
        }
      },
    );
  }

  ListTile _buildLanguageSetting(BuildContext context) {
    return ListTile(
      title: Text(context.l10n.languageSettingTitle),
      subtitle: Text(
        getLanguageLocalizedText(_language, context),
      ),
      onTap: () async {
        int result = await showBottomSheetSelection(
          context,
          context.l10n.languageSettingTitle,
          Language.values
              .map((language) => getLanguageLocalizedText(language, context))
              .toList(),
          _language.index,
        );

        if (result != -1 && result != _language.index) {
          setState(() {
            _language = Language.values[result];
          });

          await SharedPrefWrapper().setInt(kLanguageKey, _language.index);

          if (context.mounted) {
            context.read<AppSettingsBloc>().add(ChangeLocale(_language));
          }
        }
      },
    );
  }

  Future<String?> _getExportDirectory() async {
    if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } else {
      return await FilePicker.platform.getDirectoryPath();
    }
  }
}
