import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:darq/darq.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/models/cluster_model.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/import_utils.dart';
import 'package:trackord/utils/logger.dart';

class DatabaseService {
  static Database? _database;
  // We started from 5
  // 6: added 'notes' in category
  // 7: add a constraint of (category_id, date) in records table
  // 8: add clusters table and 'cluster_id' in category
  static const int _databaseVersion = 8;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    logger.info("Initializing mobile database");
    String path = join(await getDatabasesPath(), 'trackord.db');
    logger.info("Database path: $path");
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clusters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        `order` INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      INSERT INTO clusters (id, name, `order`) VALUES (0, 'default', 0);
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TINYTEXT NOT NULL,
        value_type TINYTEXT NOT NULL,
        `order` INTEGER NOT NULL,
        notes TEXT,
        cluster_id INTEGER,
        FOREIGN KEY (cluster_id) REFERENCES clusters (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        value REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        UNIQUE(category_id, date)
      )
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    // Change value_type into TINYTEXT and add the 'notes' column
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE categories_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          unit TINYTEXT NOT NULL,
          value_type TINYTEXT NOT NULL,
          `order` INTEGER NOT NULL,
          notes TEXT
        );
      ''');

      // Copy data to the new table
      await db.execute('''
        INSERT INTO categories_new (id, name, unit, value_type, `order`)
        SELECT id, name, unit, value_type, `order`
        FROM categories;
      ''');

      // Drop the old table
      await db.execute('DROP TABLE categories;');

      // Rename the new table to the original table name
      await db.execute('ALTER TABLE categories_new RENAME TO categories;');
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE new_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_id INTEGER NOT NULL,
          value REAL NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
          UNIQUE(category_id, date)
        )
      ''');

      await db.execute('''
        INSERT INTO new_records (id, category_id, value, date)
        SELECT id, category_id, value, date FROM records
      ''');

      // Drop the old table
      await db.execute('DROP TABLE records;');

      // Rename the new table to the original table name
      await db.execute('ALTER TABLE new_records RENAME TO records;');
    }

    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE clusters(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          `order` INTEGER NOT NULL
        );
      ''');

      await db.execute('''
        INSERT INTO clusters (id, name, `order`) VALUES (0, 'default', 0);
      ''');

      await db.execute('''
        CREATE TABLE categories_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          unit TINYTEXT NOT NULL,
          value_type TINYTEXT NOT NULL,
          `order` INTEGER NOT NULL,
          notes TEXT,
          cluster_id INTEGER,
          FOREIGN KEY (cluster_id) REFERENCES clusters (id)
        );
      ''');

      // Copy data to the new table
      await db.execute('''
        INSERT INTO categories_new (id, name, unit, value_type, `order`, cluster_id)
        SELECT id, name, unit, value_type, `order`, 0
        FROM categories;
      ''');

      // Drop the old table
      await db.execute('DROP TABLE categories;');

      // Rename the new table to the original table name
      await db.execute('ALTER TABLE categories_new RENAME TO categories;');
    }
  }

  Future<List<ClusterModel>> getClusters() async {
    final db = await database;
    List<Map<String, dynamic>> maps =
        await db.query('clusters', orderBy: '"order" ASC');

    if (maps.isEmpty) {
      await db.execute('''
        INSERT INTO clusters (id, name, `order`) VALUES (0, 'default', 0);
      ''');

      maps = await db.query('clusters', orderBy: '"order" ASC');
    }
    return List.generate(maps.length, (i) => ClusterModel.fromMap(maps[i]));
  }

  // The 'order' is determined in the repository
  Future<ClusterModel> insertCluster(ClusterModel cluster) async {
    final db = await database;
    final int id = await db.insert('clusters', cluster.toMap());
    return cluster.copyWith(id: id);
  }

  Future<int> updateCluster(ClusterModel cluster) async {
    final db = await database;
    return await db.update(
      'clusters',
      cluster.toMap(),
      where: 'id = ?',
      whereArgs: [cluster.id],
    );
  }

  Future<void> updateClusterOrders(List<ClusterModel> clusters) async {
    final db = await database;

    final buffer = StringBuffer();
    buffer.write('UPDATE clusters SET `order` = CASE `id` ');

    for (int i = 0; i < clusters.length; i++) {
      buffer.write('WHEN ${clusters[i].id} THEN $i ');
    }

    buffer
        .write('END WHERE `id` IN (${clusters.map((c) => c.id).join(', ')});');

    final sql = buffer.toString();
    await db.execute(sql);
  }

  Future<void> deleteCluster(int clusterId, List<CategoryModel> categories,
      int defaultCategoryLength) async {
    assert(clusterId != 0);

    final db = await database;

    await db.transaction((txn) async {
      if (categories.isNotEmpty) {
        String updateQuery = '''
      UPDATE categories
      SET cluster_id = 0,
          "order" = CASE id
          ${categories.asMap().entries.map((entry) {
          return 'WHEN ${entry.value.id} THEN ${defaultCategoryLength + entry.key}';
        }).join('\n')}
          ELSE "order"
          END
      WHERE cluster_id = ?
      ''';
        await txn.rawUpdate(updateQuery, [clusterId]);
        logger.info(
            'Changed ${categories.length} categories to the default cluster');
      }

      await txn.delete(
        'clusters',
        where: 'id = ?',
        whereArgs: [clusterId],
      );
      logger.info('Deleted cluster $clusterId');
    });
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('categories', orderBy: '"order" ASC');
    return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
  }

  // The 'order' is determined in the repository
  Future<CategoryModel> insertCategory(CategoryModel category) async {
    final db = await database;
    final int id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<List<RecordModel>> getRecordsForCategories(List<int> categoryIds,
      {int? limit}) async {
    if (categoryIds.isEmpty) {
      return [];
    }
    final db = await database;

    // Construct the subquery for the row numbers partitioned by category and ordered by date
    final subQuery = '''
      SELECT r.*, ROW_NUMBER() OVER (PARTITION BY r.category_id ORDER BY r.date DESC) as row_num
      FROM records r
      WHERE r.category_id IN (${List.filled(categoryIds.length, '?').join(',')})
    ''';

    // Generate the ORDER BY clause dynamically to maintain the order of categoryIds
    final orderByCategoryIds = categoryIds.asMap().entries.map((entry) {
      return "WHEN ${entry.value} THEN ${entry.key}";
    }).join(' ');

    // Construct the main query with the custom order for categories
    final mainQuery = '''
      SELECT * FROM ($subQuery) sub
      WHERE sub.row_num <= ${limit ?? 10000}
      ORDER BY CASE sub.category_id $orderByCategoryIds END, sub.category_id, sub.date DESC
    ''';

    final List<Map<String, dynamic>> maps =
        await db.rawQuery(mainQuery, categoryIds);

    return List.generate(maps.length, (i) {
      return RecordModel.fromMap(maps[i]);
    }).reversed.toList();
  }

  Future<List<RecordModel>> getRecordsForCategory(int categoryId,
      {int? limit, int? offset}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) {
      return RecordModel.fromMap(maps[i]);
    }).reversed.toList();
  }

  // (from, to] from is more recent
  Future<List<RecordModel>> getRecordsForCategoryForRange(
      int categoryId, DateTime from, DateTime to) async {
    logger.info("getRecordsForCategory from $from, to $to");
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: 'category_id = ? AND DATE(date) <= ? AND DATE(date) >= ?',
      whereArgs: [categoryId, from.toIso8601String(), to.toIso8601String()],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return RecordModel.fromMap(maps[i]);
    }).reversed.toList();
  }

  // (from, to] from is more recent
  Future<Map<int, List<RecordModel>>> getRecordsForCategoriesForRanges(
      Map<int, (DateTime, DateTime)> categoryFromToDates) async {
    logger.info("getRecordsForCategoriesForRange from $categoryFromToDates");
    final db = await database;
    final whereClauses = categoryFromToDates.entries.map((entry) {
      final categoryId = entry.key;
      final fromDate = entry.value.$1.toIso8601String();
      final toDate = entry.value.$2.toIso8601String();
      return "(category_id = $categoryId AND date <= '$fromDate' AND date >= '$toDate')";
    }).join(' OR ');

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM records WHERE $whereClauses ORDER BY date ASC',
    );

    // Init with the original requests and an empty list
    // so later we know for which category we didn't get any records
    Map<int, List<RecordModel>> recordsMap = categoryFromToDates.keys
        .toMap((categoryId) => MapEntry(categoryId, []));
    for (var map in maps) {
      final record = RecordModel.fromMap(map);
      recordsMap[record.categoryId]!.add(record);
    }

    return recordsMap;
  }

  Future<RecordModel?> recordExists(RecordModel record) async {
    final db = await database;
    final List<Map<String, dynamic>> existingRecords = await db.query(
      'records',
      where: 'category_id = ? AND date(date) = date(?)',
      whereArgs: [
        record.categoryId,
        record.date.toIso8601String().split('T')[0],
      ],
      limit: 1,
    );

    if (existingRecords.isNotEmpty) {
      // Update existing record
      return RecordModel.fromMap(existingRecords.first);
    }
    return null;
  }

  // It's the caller's job to ensure it doesn't exist
  Future<RecordModel> insertRecord(RecordModel record) async {
    final db = await database;
    final id = await db.insert('records', record.toMap()..remove('id'));
    logger.info('Inserted new record with id: $id');
    return record.copyWith(id: id);
  }

  Future<RecordModel> updateRecord(RecordModel record) async {
    final db = await database;
    await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    logger.info('Updated existing record with id: ${record.id}');
    return record;
  }

  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCategoryOrders(List<CategoryModel> categories) async {
    final db = await database;

    final buffer = StringBuffer();
    buffer.write('UPDATE categories SET `order` = CASE `id` ');

    for (int i = 0; i < categories.length; i++) {
      buffer.write('WHEN ${categories[i].id} THEN $i ');
    }

    buffer.write(
        'END WHERE `id` IN (${categories.map((c) => c.id).join(', ')});');

    final sql = buffer.toString();
    await db.execute(sql);
  }

  Future<CategoryModel?> getCategoryById(int categoryId) async {
    logger.info('DatabaseService: Getting category $categoryId');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    if (maps.isNotEmpty) {
      logger.info('DatabaseService: Found category $categoryId');
      return CategoryModel.fromMap(maps.first);
    }

    logger.info('DatabaseService: No category found for id $categoryId');
    return null;
  }

  Future<int> getCategoriesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM categories');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getRecordsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<int, int>> getRecordsCountForCategories(
      List<int> categoryIds) async {
    if (categoryIds.isEmpty) {
      return {};
    }

    final db = await database;
    final placeholders = List.filled(categoryIds.length, '?').join(',');
    final result = await db.rawQuery(
      'SELECT category_id, COUNT(*) as count FROM records WHERE category_id IN ($placeholders) GROUP BY category_id',
      categoryIds,
    );

    Map<int, int> counts = {for (var id in categoryIds) id: 0};
    for (var row in result) {
      final categoryId = row['category_id'] as int;
      final count = row['count'] as int;
      counts[categoryId] = count;
    }

    return counts;
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'records',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });

    logger.info('Deleted category $categoryId and all associated records');
  }

  Future<String> exportToCSV(String selectedDirectory) async {
    final db = await database;

    StringBuffer csvBuffer = StringBuffer();

    csvBuffer.writeln('Database version');
    csvBuffer.writeln('$_databaseVersion');
    csvBuffer.writeln();

    csvBuffer.writeln('Table');
    csvBuffer.writeln('clusters');
    csvBuffer.writeln('Cluster ID, Name, Order');
    await db.query('clusters').then((rows) {
      for (var row in rows) {
        List<String> values = [
          row['id'].toString(),
          row['name'].toString(),
          row['order'].toString(),
        ];
        csvBuffer.writeln(const ListToCsvConverter().convert([values]));
      }
    });
    csvBuffer.writeln();

    csvBuffer.writeln('Table');
    csvBuffer.writeln('categories');
    csvBuffer.writeln(
        'Category ID, Name, Unit, Value Type, Order, Notes, Cluster ID');
    await db.query('categories').then((rows) {
      for (var row in rows) {
        List<String> values = [
          row['id'].toString(),
          row['name'].toString(),
          row['unit'].toString(),
          row['value_type'].toString(),
          row['order'].toString(),
          row['notes'].toString(),
          row['cluster_id'].toString(),
        ];
        csvBuffer.writeln(const ListToCsvConverter().convert([values]));
      }
    });

    csvBuffer.writeln();
    csvBuffer.writeln('Table');
    csvBuffer.writeln('records');

    // Write records table to CSV
    csvBuffer.writeln('Record ID, Category ID, Value, Date');
    await db.query('records').then((rows) {
      for (var row in rows) {
        List<String> values = [
          row['id'].toString(),
          row['category_id'].toString(),
          row['value'].toString(),
          row['date'].toString(),
        ];
        csvBuffer.writeln(const ListToCsvConverter().convert([values]));
      }
    });

    // Mark end
    csvBuffer.writeln('End');

    // UTF-8 BOM bytes
    final List<int> bom = [0xEF, 0xBB, 0xBF];

    // Convert the CSV content to UTF-8 bytes
    final List<int> contentBytes = utf8.encode(csvBuffer.toString());

    // Combine BOM and content bytes
    final List<int> finalBytes = [...bom, ...contentBytes];

    Uint8List csvBytes = Uint8List.fromList(finalBytes);

    String filePath =
        '$selectedDirectory/exported_data_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    File csvFile = File(filePath);

    await csvFile.writeAsBytes(csvBytes);

    if (Platform.isIOS) {
      final documentsIndex = filePath.indexOf('/Documents/');
      if (documentsIndex != -1) {
        final documentsEndIndex = documentsIndex + '/Documents/'.length;
        return '/Documents/Trackord/${filePath.substring(documentsEndIndex)}';
      }
    }

    return filePath;
  }

  Future<String?> importFromCSVRows(
      List<List<dynamic>> rows, ImportOption option) async {
    final db = await database;
    final importer = CSVImporter(db);

    await db.transaction((txn) async {
      if (option == ImportOption.nuke) {
        await txn.delete('clusters');
        await txn.delete('categories');
        await txn.delete('records');

        // Insert default cluster
        await txn.insert('clusters', {'id': 0, 'name': 'Default', 'order': 0});
      }

      String? currentTable;
      List<Map<String, dynamic>> recordsToInsert = [];

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.first == '') continue;

        if (row[0] == 'Database version') {
          i++; // Skip version info
          continue;
        }

        if (row[0] == 'Table') {
          // Process any pending records before switching tables
          await importer.processRecordsBatch(txn, recordsToInsert, option);
          recordsToInsert.clear();

          // Get new table name and skip headers
          if (i + 1 < rows.length) {
            currentTable = rows[i + 1][0].toString();
            i += 2;
          }
          continue;
        }

        switch (currentTable) {
          case 'clusters':
            await importer.processClusterRow(txn, row);
            break;
          case 'categories':
            await importer.processCategoryRow(txn, row);
            break;
          case 'records':
            if (row.length >= 4 && row[0] != 'End') {
              recordsToInsert.add(importer.parseRecordRow(row));
            }
            break;
        }
      }

      // Process any remaining records
      await importer.processRecordsBatch(txn, recordsToInsert, option);
    });

    importer.stats.logReport(option);
    return null;
  }

  Future<String?> importFromCSV(String filePath, ImportOption option) async {
    try {
      String csvContent;
      if (filePath.startsWith('mock')) {
        csvContent = await rootBundle.loadString(filePath);
      } else {
        final file = File(filePath);
        // Read file as bytes first to check for BOM
        final List<int> fileBytes = await file.readAsBytes();

        // Check for BOM (UTF-8 BOM: EF BB BF)
        if (fileBytes.length >= 3 &&
            fileBytes[0] == 0xEF &&
            fileBytes[1] == 0xBB &&
            fileBytes[2] == 0xBF) {
          // Skip BOM when converting to string
          csvContent = utf8.decode(fileBytes.sublist(3));
        } else {
          // No BOM found, use the content as is
          csvContent = utf8.decode(fileBytes);
        }
      }

      return await importFromCsvContent(csvContent);
    } catch (e) {
      return 'Parsing CSV error';
    }
  }

  Future<String?> importFromCsvContent(String content) async {
    List<List<dynamic>> rows =
        const CsvToListConverter().convert(content, eol: '\n');
    return await importFromCSVRows(rows, ImportOption.nuke);
  }

  Future<void> deleteAllData() async {
    final db = await database;
    db.transaction((txn) async {
      await txn.delete('clusters');
      await txn.delete('categories');
      await txn.delete('records');

      // Insert default cluster
      await txn.insert('clusters', {'id': 0, 'name': 'Default', 'order': 0});
    });
  }
}
