import 'package:trackord/models/category_model.dart';
import 'package:trackord/models/cluster_model.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/services/database_service.dart';
import 'package:trackord/utils/logger.dart';

// The cache always in ASC order, because that's what the database returns
// i.e.
// records[category].first() is the oldest
// records[category].last() is the latest
// When returning, we always return in reverse order (DESC)
// TODO #30: cache in DESC order, and sort on fetching

class RecordsRepository {
  final DatabaseService _databaseService;
  final int _initialFetchCount = 10;
  bool _initialLoaded = false;

  List<ClusterModel> _clusters = [];
  final Map<int, List<CategoryModel>> _categories = {};
  final Map<int, List<RecordModel>> _records = {};
  Map<int, int> _totals = {};

  RecordsRepository(this._databaseService);

  Future<void> initialize() async {
    _initialLoaded = false;
    _clusters.clear();
    _categories.clear();
    _records.clear();
    _totals.clear();
    await _initialLoadCategories();
  }

  int getTotal() {
    return _totals.values.fold(0, (previous, next) => previous + next);
  }

  Future<void> onImportSuccess() async {
    await initialize();
  }

  Future<List<ClusterModel>> getClusters() async {
    return List.from(_clusters);
  }

  Future<Map<int, List<CategoryModel>>> getCategories() async {
    return Map.from(_categories);
  }

  // Getting individual category, no need to use the complex query, thus a separate function
  Future<List<RecordModel>> getRecordsForCategory(
      int categoryId, int limit, int offset) async {
    if (_needsFetching(categoryId, limit, offset)) {
      final int cachedCount = _records[categoryId]?.length ?? 0;
      final int recordsToFetch = (limit + offset) - cachedCount;
      logger.info(
          "Repository: loading $recordsToFetch records for category ${_getCategoryNameFor(categoryId)}");
      final fetched = await _databaseService.getRecordsForCategory(
        categoryId,
        limit: recordsToFetch,
        offset: cachedCount,
      );
      if (fetched.isNotEmpty) {
        _records[categoryId]!.insertAll(0, fetched);
        logger.info(
            "Repository: ${fetched.length} records loaded for category ${_getCategoryNameFor(categoryId)}");
      } else {
        logger.info(
            "Repository: no more records available for category ${_getCategoryNameFor(categoryId)}");
      }
    } else {
      logger.info(
          "Repository: no need to load records $limit records from offset $offset for category ${_getCategoryNameFor(categoryId)}");
    }
    return _getRecordsInDescOrder(categoryId, limit, offset: offset);
  }

  Future<List<RecordModel>> getRecordsForCategoryForRange(
      int categoryId, DateTime to) async {
    await getRecordsForCategoriesForRange([categoryId], to);
    return _getRecordsForRangeInDescOrder(categoryId, to);
  }

  Map<int, (DateTime, DateTime)> _compileRecordsDateRanges(
      List<int> categoryIds, DateTime to) {
    Map<int, (DateTime, DateTime)> ranges = {};
    for (int categoryId in categoryIds) {
      final range = _compileRecordsDateRange(categoryId, to);
      if (range != null) {
        ranges[categoryId] = range;
      }
    }
    return ranges;
  }

  (DateTime, DateTime)? _compileRecordsDateRange(int categoryId, DateTime to) {
    final cachedList = _records[categoryId]!;
    final cachedEarliestRecord = cachedList.isNotEmpty ? cachedList[0] : null;
    if (cachedEarliestRecord != null) {
      DateTime cachedEarliestDate = cachedEarliestRecord.date;
      DateTime from =
          cachedEarliestDate.copyWith(day: cachedEarliestDate.day - 1);
      if (to.isBefore(from) && cachedList.length < _totals[categoryId]!) {
        return (from, to);
      } else {
        logger.info(
            "Repository: no need to load records for category ${_getCategoryNameFor(categoryId)}, we have until $to");
        return null;
      }
    }
    return null;
  }

  Future<Map<int, List<RecordModel>>> getRecordsForCategories(
      List<int> categoryIds, int limitPerCategory) async {
    List<int> categoriesNeedToFetch = [];
    for (int id in categoryIds) {
      if (_records[id]!.length < limitPerCategory &&
          _records[id]!.length < _totals[id]!) {
        categoriesNeedToFetch.add(id);
        // Clear the records of that category, as we will be fetching it again
        _records[id] = [];
      }
    }
    if (categoriesNeedToFetch.isNotEmpty) {
      List<RecordModel> records =
          await _databaseService.getRecordsForCategories(categoriesNeedToFetch,
              limit: limitPerCategory);
      logger.info(
          "Repository: fetched ${records.length} records for categories [${categoriesNeedToFetch.join(', ')}]");
      _onRecordsLoaded(records);
    }

    // Once loaded, this is the default behavior to get from the cache
    Map<int, List<RecordModel>> result = {};
    for (int categoryId in categoryIds) {
      if (_records.containsKey(categoryId)) {
        result[categoryId] =
            _getRecordsInDescOrder(categoryId, limitPerCategory);
      } else {
        result[categoryId] = [];
      }
    }
    return result;
  }

  Future<Map<int, List<RecordModel>>> getRecordsForCategoriesForRange(
      List<int> categoryIds, DateTime to) async {
    Map<int, (DateTime, DateTime)> ranges =
        _compileRecordsDateRanges(categoryIds, to);

    if (ranges.isNotEmpty) {
      Map<int, List<RecordModel>> records =
          await _databaseService.getRecordsForCategoriesForRanges(ranges);
      for (var entry in records.entries) {
        if (entry.value.isEmpty) {
          logger.info(
              "Repository: no records available for category ${_getCategoryNameFor(entry.key)} from ${ranges[entry.key]!.$1} to ${ranges[entry.key]!.$2}");
        } else {
          _records[entry.key]!.insertAll(0, entry.value);
          logger.info(
              "Repository: loaded ${entry.value.length} records until $to for category ${_getCategoryNameFor(entry.key)}");
        }
      }
    }

    // Once loaded, this is the default behavior to get from the cache
    Map<int, List<RecordModel>> result = {};
    for (int categoryId in categoryIds) {
      if (_records.containsKey(categoryId)) {
        result[categoryId] = _getRecordsForRangeInDescOrder(categoryId, to);
      }
    }
    return result;
  }

  Future<void> addCluster(ClusterModel cluster) async {
    ClusterModel newCluster = cluster.copyWith(order: _clusters.length);
    newCluster = await _databaseService.insertCluster(newCluster);
    logger.info(
        "Repository: Added cluster ${newCluster.id!}: ${newCluster.name}");
    _clusters.add(newCluster);
    _categories[newCluster.id!] = [];
  }

  Future<void> reorderClustersInCache(int oldIndex, int newIndex) async {
    final c = _clusters.removeAt(oldIndex);
    _clusters.insert(newIndex, c);
  }

  Future<void> submitClustersNewOrders() async {
    await _databaseService.updateClusterOrders(_clusters);
  }

  Future<void> updateCluster(ClusterModel cluster) async {
    await _databaseService.updateCluster(cluster);
    logger.info("Repository: updated cluster ${cluster.id!}: ${cluster.name}");
    for (int i = 0; i < _clusters.length; i++) {
      if (_clusters[i].id == cluster.id) {
        _clusters[i] = cluster;
      }
    }
  }

  Future<void> deleteCluster(int clusterId) async {
    if (clusterId == 0) return;

    final categoriesToMove = _categories[clusterId] ?? [];
    final defaultCategoryLength = _categories[0]?.length ?? 0;

    await _databaseService.deleteCluster(
        clusterId, _categories[clusterId]!, defaultCategoryLength);

    final updatedCategories = categoriesToMove.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      return category.copyWith(
        clusterId: 0,
        order: defaultCategoryLength + index,
      );
    }).toList();

    _categories[0]!.addAll(updatedCategories);

    _clusters.removeWhere((cluster) => cluster.id == clusterId);
    _categories.remove(clusterId);
  }

  Future<void> addCategory(CategoryModel category) async {
    final int clusterId = category.clusterId;
    CategoryModel newCategory =
        category.copyWith(order: _categories[clusterId]!.length);
    newCategory = await _databaseService.insertCategory(newCategory);
    logger.info(
        "Repository: Added category ${newCategory.id!}: ${newCategory.name} to cluster $clusterId");
    _categories[clusterId]!.add(newCategory);
    _records[newCategory.id!] = [];
    _totals[newCategory.id!] = 0;
  }

  // We don't update the order from here
  Future<void> updateCategory(CategoryModel category, int oldClusterId) async {
    final int newClusterId = category.clusterId;
    if (newClusterId != oldClusterId) {
      // Remove it from the old cluster
      _categories[oldClusterId]!.remove(category);
      // Add to new cluster with the new order (last)
      _categories[newClusterId]!
          .add(category.copyWith(order: _categories[newClusterId]!.length));
    } else {
      var categories = _categories[newClusterId];
      int index = categories!.indexOf(category);
      categories[index] = category;
    }

    await _databaseService.updateCategory(category);
    logger
        .info("Repository: updated category ${category.id!}: ${category.name}");
  }

  // This is current order from the UI
  void reorderCategoriesInCache(int clusterId, int oldIndex, int newIndex) {
    final c = _categories[clusterId]!.removeAt(oldIndex);
    _categories[clusterId]!.insert(newIndex, c);
  }

  Future<void> submitCategoriesNewOrders(int clusterId) async {
    var categories = _categories[clusterId]!;
    await _databaseService.updateCategoryOrders(categories);
  }

  Future<void> deleteCategory(CategoryModel category) async {
    await _databaseService.deleteCategory(category.id!);
    logger
        .info("Repository: deleted category ${category.id!}: ${category.name}");
    _categories[category.clusterId]!.removeWhere((c) => c.id == category.id!);
    _records.remove(category.id!);
    _totals.remove(category.id!);
  }

  Future<RecordModel?> recordExists(RecordModel record) async {
    return await _databaseService.recordExists(record);
  }

  Future<void> updateRecord(RecordModel record) async {
    await _databaseService.updateRecord(record);
    await _onAddOrUpdateRecord(record);
  }

  Future<int> addRecord(RecordModel record) async {
    RecordModel newRecord = await _databaseService.insertRecord(record);
    await _onAddOrUpdateRecord(newRecord);
    _totals[record.categoryId] = (_totals[record.categoryId] ?? 0) + 1;
    return newRecord.id!;
  }

  Future<void> _onAddOrUpdateRecord(RecordModel record) async {
    final records = _records[record.categoryId]!;

    // for updating, we definitely have the id, but its date might have changed,
    // we need to find its place to insert, and delete from the old place
    records.remove(record);

    if (records.isNotEmpty) {
      final oldestInCache = records.first;
      // it might be from a past date that we have no cache yet, we need to cache until then
      if (record.date.isBefore(oldestInCache.date)) {
        await getRecordsForCategoryForRange(record.categoryId, record.date);
      }

      // binary search for date for inserting
      int low = 0;
      int high = records.length - 1;
      while (low <= high) {
        int mid = (low + high) ~/ 2;
        if (records[mid].date.isBefore(record.date)) {
          low = mid + 1;
        } else if (records[mid].date.isAfter(record.date)) {
          high = mid - 1;
        } else {
          // record of same date exists, update it and early return
          // this shouldn't happen since we changed the logic,
          records[mid] = record;
          return;
        }
      }

      records.insert(low, record);
    } else {
      records.add(record);
    }
  }

  Future<void> deleteRecord(RecordModel record) async {
    await _databaseService.deleteRecord(record.id!);
    logger.info(
        "Repository: deleted record ${record.id!} in category ${_getCategoryNameFor(record.categoryId)}");
    _records[record.categoryId]!.remove(record);
    _totals[record.categoryId] = _totals[record.categoryId]! - 1;
  }

  // Initial load only
  Future<void> _initialLoadCategories() async {
    if (!_initialLoaded) {
      _clusters = await _databaseService.getClusters();
      logger.info("Repository: ${_clusters.length} clusters loaded");

      final categories = await _databaseService.getCategories();
      for (var cluster in _clusters) {
        _categories[cluster.id!] = categories
            .where((category) => category.clusterId == cluster.id!)
            .toList();

        for (var category in _categories[cluster.id!]!) {
          _records[category.id!] = [];
        }
      }
      logger.info("Repository: ${categories.length} categories loaded");

      final categorieIds = categories.map((category) => category.id!).toList();
      // Load counts for all categories at once
      _totals =
          await _databaseService.getRecordsCountForCategories(categorieIds);
      logger.info("Repository: total records count: ${getTotal()}");

      // Load initial records for all categories at once
      List<RecordModel> records = await _databaseService
          .getRecordsForCategories(categorieIds, limit: _initialFetchCount);
      _onRecordsLoaded(records);
      _initialLoaded = true;
    }
  }

  // _records[record.categoryId] shouldn't be empty at this point
  void _onRecordsLoaded(List<RecordModel> records) {
    for (var record in records) {
      _records[record.categoryId]!.add(record);
    }
    logger.info("Repository: ${records.length} records loaded");
  }

  bool _needsFetching(int categoryId, int limit, int offset) {
    final int cachedCount = _records[categoryId]?.length ?? 0;
    // Only fetch for those we don't have the requested count,
    // and we are sure there are more in the database
    return cachedCount < (limit + offset) && cachedCount < _totals[categoryId]!;
  }

  List<RecordModel> _getRecordsInDescOrder(int categoryId, int count,
      {int offset = 0}) {
    return _records[categoryId]!.reversed.skip(offset).take(count).toList();
  }

  List<RecordModel> _getRecordsForRangeInDescOrder(
      int categoryId, DateTime to) {
    return _records[categoryId]!
        .where((record) => record.date.isAfter(to))
        .toList()
        .reversed
        .toList();
  }

  String _getCategoryNameFor(int id) {
    for (var categories in _categories.values) {
      for (var category in categories) {
        if (category.id == id) {
          return category.name;
        }
      }
    }
    return "Unknown";
  }
}
