import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackord/utils/defines.dart';

const String kThemeModeKey = "ThemeMode";
const String kLanguageKey = "Language";
const String kChartTypeKey = "ChartType";
const String kShowDotsKey = "ShowDots";
const String kCurvedKey = "Curved";
const String kHorizontalKey = "Horizontal";
const String kDotSizeKey = "DotSize";
const String kRecentUnitsKey = "RecentUnits";

class SharedPrefWrapper {
  static final SharedPrefWrapper _instance = SharedPrefWrapper._internal();
  late SharedPreferences _prefs;

  // Private constructor
  SharedPrefWrapper._internal();

  // Factory constructor to return the same instance
  factory SharedPrefWrapper() {
    return _instance;
  }

  // Load all preferences at startup
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Synchronous getters
  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  ChartDateRange getSelectedChartDateRange(String key,
      {ChartDateRange defaultValue = ChartDateRange.oneMonth}) {
    int? index = _prefs.getInt(key);
    return ChartDateRange.values[index ?? 0];
  }

  // Synchronous setters
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  Future<void> setSelectedChartDateRange(
      String key, ChartDateRange period) async {
    await _prefs.setInt(key, period.index);
  }
}
