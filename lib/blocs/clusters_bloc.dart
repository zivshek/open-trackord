import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trackord/models/cluster_model.dart';
import 'package:trackord/repositories/records_repository.dart';

abstract class ClustersEvent {}

class LoadClustersEvent extends ClustersEvent {}

class AddClusterEvent extends ClustersEvent {
  final ClusterModel cluster;

  AddClusterEvent({required this.cluster});
}

class DeleteClusterEvent extends ClustersEvent {
  final int clusterId;

  DeleteClusterEvent({required this.clusterId});
}

class EditClusterEvent extends ClustersEvent {
  final ClusterModel cluster;

  EditClusterEvent({required this.cluster});
}

class ReorderClustersEvent extends ClustersEvent {
  final int oldIndex;
  final int newIndex;

  ReorderClustersEvent({required this.oldIndex, required this.newIndex});
}

class SubmitClustersNewOrdersEvent extends ClustersEvent {}

// States
abstract class ClustersState {}

class ClustersInitial extends ClustersState {}

class ClustersLoading extends ClustersState {}

class ClustersLoaded extends ClustersState {
  final List<ClusterModel> clusters;

  ClustersLoaded({required this.clusters});
}

class ClustersError extends ClustersState {
  final String message;

  ClustersError({required this.message});
}

class ClustersBloc extends Bloc<ClustersEvent, ClustersState> {
  final RecordsRepository _repository;

  ClustersBloc(this._repository) : super(ClustersInitial()) {
    on<LoadClustersEvent>((event, emit) async {
      emit(ClustersLoading());
      try {
        final clusters = await _repository.getClusters();
        emit(ClustersLoaded(clusters: clusters));
      } catch (e) {
        emit(ClustersError(message: e.toString()));
      }
    });

    on<AddClusterEvent>((event, emit) async {
      try {
        await _repository.addCluster(event.cluster);
        add(LoadClustersEvent());
      } catch (e) {
        emit(ClustersError(message: e.toString()));
      }
    });

    on<DeleteClusterEvent>((event, emit) async {
      try {
        await _repository.deleteCluster(event.clusterId);
        add(LoadClustersEvent());
      } catch (e) {
        emit(ClustersError(message: e.toString()));
      }
    });

    on<EditClusterEvent>((event, emit) async {
      try {
        await _repository.updateCluster(event.cluster);
        add(LoadClustersEvent());
      } catch (e) {
        emit(ClustersError(message: e.toString()));
      }
    });

    on<ReorderClustersEvent>((event, emit) async {
      try {
        await _repository.reorderClustersInCache(
            event.oldIndex, event.newIndex);
        final clusters = await _repository.getClusters();
        emit(ClustersLoaded(clusters: clusters));
      } catch (e) {
        emit(ClustersError(message: e.toString()));
      }
    });

    on<SubmitClustersNewOrdersEvent>((event, emit) async {
      try {
        await _repository.submitClustersNewOrders();
      } catch (e) {
        emit(ClustersError(message: e.toString()));
      }
    });
  }
}
