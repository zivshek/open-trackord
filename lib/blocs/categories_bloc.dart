import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/repositories/records_repository.dart';
import 'dart:developer' as developer;

// Bloc for the categories screen

// Events
abstract class CategoriesEvent {}

// Load categories with one record
class LoadCategories extends CategoriesEvent {}

class AddCategory extends CategoriesEvent {
  final CategoryModel category;
  AddCategory(this.category);
}

// Updates the category's name and unit
class UpdateCategory extends CategoriesEvent {
  final CategoryModel category;
  final int oldClusterId;
  UpdateCategory(this.category, this.oldClusterId);
}

class DeleteCategory extends CategoriesEvent {
  final CategoryModel category;
  DeleteCategory(this.category);
}

class ReorderCategories extends CategoriesEvent {
  final int clusterId;
  final int oldIndex;
  final int newIndex;
  ReorderCategories(this.clusterId, this.oldIndex, this.newIndex);
}

class SubmitNewCategoryOrdersEvent extends CategoriesEvent {
  final int clusterId;
  SubmitNewCategoryOrdersEvent(this.clusterId);
}

// States
abstract class CategoriesState {}

class CategoriesLoading extends CategoriesState {}

// Categories with 1 record
class CategoriesLoaded extends CategoriesState {
  final Map<int, RecordModel?> records;
  final List<CategoryModel> categories;
  final int total;
  final bool failed;
  CategoriesLoaded(this.categories, this.records, this.total,
      {this.failed = false});
}

class CategoriesError extends CategoriesState {
  final String message;
  CategoriesError(this.message);
}

// Bloc
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final RecordsRepository _repository;

  CategoriesBloc(this._repository) : super(CategoriesLoading()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<ReorderCategories>(_onReorderCategories);
    on<SubmitNewCategoryOrdersEvent>(_onSubmitNewCategoryOrders);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<CategoriesState> emit) async {
    emit(CategoriesLoading());
    await _reloadCategories(emit, false);
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    bool failed = false;
    try {
      await _repository.addCategory(event.category);
    } catch (e, stackTrace) {
      developer.log('Error adding category', error: e, stackTrace: stackTrace);
      failed = true;
    }

    if (state is CategoriesLoaded) {
      await _reloadCategories(emit, failed);
    }
  }

  Future<void> _onUpdateCategory(
      UpdateCategory event, Emitter<CategoriesState> emit) async {
    bool failed = false;
    try {
      await _repository.updateCategory(event.category, event.oldClusterId);
    } catch (e, stackTrace) {
      developer.log('Error adding category', error: e, stackTrace: stackTrace);
      failed = true;
    }

    if (state is CategoriesLoaded) {
      await _reloadCategories(emit, failed);
    }
  }

  Future<void> _onReorderCategories(
      ReorderCategories event, Emitter<CategoriesState> emit) async {
    bool failed = false;
    try {
      _repository.reorderCategoriesInCache(
          event.clusterId, event.oldIndex, event.newIndex);
    } catch (e, stackTrace) {
      developer.log('Error adding category', error: e, stackTrace: stackTrace);
      failed = true;
    }
    if (state is CategoriesLoaded) {
      await _reloadCategories(emit, failed);
    }
  }

  Future<void> _onSubmitNewCategoryOrders(
      SubmitNewCategoryOrdersEvent event, Emitter<CategoriesState> emit) async {
    try {
      await _repository.submitCategoriesNewOrders(event.clusterId);
    } catch (e, stackTrace) {
      developer.log('Error adding category', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onDeleteCategory(
      DeleteCategory event, Emitter<CategoriesState> emit) async {
    bool failed = false;
    try {
      await _repository.deleteCategory(event.category);
    } catch (e, stackTrace) {
      developer.log('Error deleting category',
          error: e, stackTrace: stackTrace);
      failed = true;
    }
    if (state is CategoriesLoaded) {
      await _reloadCategories(emit, failed);
    }
  }

  Future<void> _reloadCategories(
      Emitter<CategoriesState> emit, bool failed) async {
    try {
      final categoriesMap = await _repository.getCategories();
      final categoryIds = categoriesMap.values
          .expand((list) => list)
          .map((category) => category.id!)
          .toList();

      var categoriesWithRecords =
          await _repository.getRecordsForCategories(categoryIds, 1);
      Map<int, RecordModel?> categoriesWithOneRecord =
          categoriesWithRecords.map((categoryId, records) {
        RecordModel? firstRecord = records.isNotEmpty ? records.first : null;
        return MapEntry(categoryId, firstRecord);
      });

      emit(CategoriesLoaded(categoriesMap.values.expand((x) => x).toList(),
          categoriesWithOneRecord, _repository.getTotal(),
          failed: failed));
    } catch (e, stackTrace) {
      developer.log('Error reloading category',
          error: e, stackTrace: stackTrace);
      emit(CategoriesError(e.toString()));
    }
  }
}
