import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/logger.dart';

class ImportStats {
  int importedClusterCount = 0;
  int skippedClusterCount = 0;
  int importedCategoryCount = 0;
  int skippedCategoryCount = 0;
  int importedRecordCount = 0;
  int skippedRecordCount = 0;

  void logReport(ImportOption option) {
    logger.info('Import report');
    logger.info('\tImport option: ${option.name}');
    logger.info('\timportedClusterCount: $importedClusterCount');
    logger.info('\tskippedClusterCount: $skippedClusterCount');
    logger.info('\timportedCategoryCount: $importedCategoryCount');
    logger.info('\tskippedCategoryCount: $skippedCategoryCount');
    logger.info('\timportedRecordCount: $importedRecordCount');
    logger.info('\tskippedRecordCount: $skippedRecordCount');
  }
}

class CSVImporter {
  final Database database;
  final ImportStats stats = ImportStats();
  final Map<int, int> clusterIdMapping = {};
  final Map<int, int> categoryIdMapping = {};

  CSVImporter(this.database);

  Future<void> processClusterRow(Transaction txn, List<dynamic> row) async {
    if (row.length < 3 || row.first == "") return;

    final oldId = row[0] as int;
    final clusterData = {
      'id': oldId,
      'name': row[1],
      'order': row[2],
    };

    try {
      final conflictAlgorithm =
          oldId == 0 ? ConflictAlgorithm.ignore : ConflictAlgorithm.fail;
      await txn.insert('clusters', clusterData,
          conflictAlgorithm: conflictAlgorithm);
      stats.importedClusterCount++;
    } catch (e) {
      final result = await txn.query(
        'clusters',
        where: 'id = ?',
        whereArgs: [clusterData['id']],
        limit: 1,
      );

      final existing = CategoryModel.fromMap(result.first);
      if (existing.name == clusterData['name']) {
        stats.skippedClusterCount++;
      } else {
        clusterData.remove('id');
        final newId = await txn.insert('clusters', clusterData,
            conflictAlgorithm: ConflictAlgorithm.fail);
        clusterIdMapping[oldId] = newId;
        stats.importedClusterCount++;
      }
    }
  }

  Future<void> processCategoryRow(Transaction txn, List<dynamic> row) async {
    if (row.length < 6 || row.first == "") return;

    final oldId = row[0] as int;
    final categoryData = {
      'id': oldId,
      'name': row[1],
      'unit': row[2],
      'value_type': row[3],
      'order': row[4],
      'notes': row[5],
      'cluster_id': row.length >= 7 ? row[6] : 0,
    };

    try {
      await txn.insert('categories', categoryData,
          conflictAlgorithm: ConflictAlgorithm.fail);
      stats.importedCategoryCount++;
    } catch (e) {
      final result = await txn.query(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryData['id']],
        limit: 1,
      );

      final existing = CategoryModel.fromMap(result.first);
      if (existing.name == categoryData['name']) {
        stats.skippedCategoryCount++;
      } else {
        categoryData.remove('id');
        final newId = await txn.insert('categories', categoryData,
            conflictAlgorithm: ConflictAlgorithm.fail);
        categoryIdMapping[oldId] = newId;
        stats.importedCategoryCount++;
      }
    }
  }

  Future<void> processRecordsBatch(
    Transaction txn,
    List<Map<String, dynamic>> records,
    ImportOption option,
  ) async {
    if (records.isEmpty) return;

    if (option == ImportOption.mergeAndSkip) {
      for (var record in records) {
        int result = await txn.rawInsert('''
          INSERT OR IGNORE INTO records (category_id, value, date)
          SELECT ?, ?, ?
          WHERE NOT EXISTS (
            SELECT 1 FROM records 
            WHERE category_id = ? AND date = ?
          )
        ''', [
          record['category_id'],
          record['value'],
          record['date'],
          record['category_id'],
          record['date']
        ]);

        if (result == 0) {
          stats.skippedRecordCount++;
        }
      }
    } else {
      for (var record in records) {
        await txn.rawInsert('''
          INSERT INTO records (category_id, value, date)
          VALUES (?, ?, ?)
          ON CONFLICT(category_id, date) DO UPDATE SET
          value = excluded.value
        ''', [record['category_id'], record['value'], record['date']]);

        stats.importedRecordCount++;
      }
    }
  }

  Map<String, dynamic> parseRecordRow(List<dynamic> row) {
    final categoryId = row[1] as int;
    final newCategoryId = categoryIdMapping[categoryId] ?? categoryId;

    String date;
    try {
      date = DateFormat('M/d/yyyy').parse(row[3]).toIso8601String();
    } catch (e) {
      date = row[3];
    }

    return {
      'category_id': newCategoryId,
      'value': row[2],
      'date': date,
    };
  }
}
