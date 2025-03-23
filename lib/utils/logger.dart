import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

final logger = Logger('TrackordLogger');

void setupLogger() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.OFF;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
  });
}
