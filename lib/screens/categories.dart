import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trackord/blocs/categories_bloc.dart';
import 'package:trackord/blocs/clusters_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/logger.dart';
import 'package:trackord/utils/ui.dart';
import 'package:trackord/widgets/adaptive_scaffold.dart';
import 'package:trackord/widgets/cluster_widget.dart';
import 'package:trackord/widgets/gradient_divider.dart';
import 'package:trackord/widgets/modified_expansion_tile_card.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  int? _expandedClusterId;
  bool _reordered = false;
  bool _reorderingClusters = false;

  final Map<int, GlobalKey<ModifiedExpansionTileCardState>> _clusterTileKeys =
      {};

  late AnimationController _clusterReorderController;
  late Animation<double> _paddingAnimation;

  @override
  void initState() {
    super.initState();

    _clusterReorderController = AnimationController(
      vsync: this,
      duration: animDuration,
    );

    _paddingAnimation =
        Tween<double>(begin: 16, end: 0).animate(CurvedAnimation(
      parent: _clusterReorderController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _clusterReorderController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      },
      child: AdaptiveScaffold(
        title: context.l10n.categoriesPageDefaultTitle,
        actions: [
          _buildClusterActions(),
        ],
        body: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return MultiBlocListener(
      listeners: [
        _buildCategoriesBlocListener(),
        _buildClustersBlocListener(),
      ],
      child: _buildClustersStateBuilder(),
    );
  }

  BlocListener<CategoriesBloc, CategoriesState> _buildCategoriesBlocListener() {
    return BlocListener<CategoriesBloc, CategoriesState>(
      listener: (context, state) {
        if (state is CategoriesError) {
          showErrorSnackBar(context, context.l10n.errorMsg(state.message));
        }
      },
    );
  }

  BlocListener<ClustersBloc, ClustersState> _buildClustersBlocListener() {
    return BlocListener<ClustersBloc, ClustersState>(
      listener: (context, state) {
        if (state is ClustersError) {
          showErrorSnackBar(context, context.l10n.errorMsg(state.message));
        }
        if (state is ClustersLoaded) {
          if (state.clusters.length == 1) {
            setState(() {
              _expandedClusterId = state.clusters.first.id;
            });
          }
          context.read<CategoriesBloc>().add(LoadCategories());
        }
      },
    );
  }

  Widget _buildClustersStateBuilder() {
    return Builder(builder: (context) {
      final clustersState = context.watch<ClustersBloc>().state;
      final categoriesState = context.watch<CategoriesBloc>().state;
      // Actual data
      if (clustersState is ClustersLoaded &&
          categoriesState is CategoriesLoaded) {
        return _buildClustersList(clustersState, categoriesState);
      }

      // Handle loading
      if (clustersState is ClustersLoading ||
          categoriesState is CategoriesLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      // Handle errors
      if (clustersState is ClustersError) {
        return Center(
            child: Text(context.l10n.errorMsg(clustersState.message)));
      }

      if (categoriesState is CategoriesError) {
        return Center(
            child: Text(context.l10n.errorMsg(categoriesState.message)));
      }

      return const Center(child: Text("Error loading categories"));
    });
  }

  SingleChildScrollView _buildClustersList(
      ClustersLoaded clustersState, CategoriesLoaded categoriesState) {
    return SingleChildScrollView(
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: clustersState.clusters.length,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) {
          final cluster = clustersState.clusters.elementAt(index);
          final clusterKey = _clusterTileKeys.putIfAbsent(
              cluster.id!, () => GlobalKey<ModifiedExpansionTileCardState>());
          return KeyedSubtree(
              key: Key('cluster_${cluster.id}'),
              child: Column(
                spacing: 2,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Row(
                      children: [
                        // Drag handle in reordering clusters
                        AnimatedContainer(
                          duration: animDuration,
                          width: _reorderingClusters ? 50 : 0,
                          curve: Curves.easeInOut,
                          child: AnimatedOpacity(
                            opacity: _reorderingClusters ? 1.0 : 0.0,
                            duration: animDuration,
                            child: ReorderableDragStartListener(
                              index: index,
                              enabled: _reorderingClusters,
                              child: Icon(
                                Icons.drag_handle,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                        // Cluster widget
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _paddingAnimation,
                            builder: (context, child) => Padding(
                              padding: EdgeInsets.only(
                                left: _paddingAnimation.value,
                                right: 10,
                              ),
                              child: child,
                            ),
                            child: ClusterWidget(
                                reorderingClusters: _reorderingClusters,
                                index: index,
                                globalKey: clusterKey,
                                cluster: cluster,
                                categoriesState: categoriesState,
                                expanded: _expandedClusterId == cluster.id,
                                onClusterExpansionChanged: (value) {
                                  if (value) {
                                    if (_expandedClusterId != cluster.id) {
                                      _expandedClusterId = cluster.id;
                                    }
                                  } else {
                                    _expandedClusterId = null;
                                  }
                                },
                                onActivateReorderingMode: (clusterId) {
                                  setState(() {
                                    _reorderingClusters = true;
                                    _clusterReorderController.forward();
                                    if (_expandedClusterId != null) {
                                      _collapseClusterTilesExcept(null);
                                    }
                                  });
                                }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const GradientDivider(),
                ],
              ));
        },
        onReorder: (int oldIndex, int newIndex) {
          _onReorderClusters(oldIndex, newIndex);
        },
      ),
    );
  }

  Widget _buildClusterActions() {
    return AnimatedSwitcher(
      duration: animDuration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final value = min(rotate.value, pi / 2);
            return Transform(
              transform: Matrix4.rotationX(value),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      child: _reorderingClusters
          ? _buildConfirmClusterReorderBtn()
          : _buildAddClusterOrCategoryBtn(),
    );
  }

  PopupMenuButton<String> _buildAddClusterOrCategoryBtn() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add),
      onSelected: (value) {
        switch (value) {
          case 'new_cluster':
            context.push('/new_cluster');
            break;
          case 'new_category':
            context.push('/new_category/0');
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'new_cluster',
          child: Row(
            children: [
              const Icon(Icons.folder_outlined),
              const SizedBox(width: 8),
              Text(context.l10n.newClusterTitle),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'new_category',
          child: Row(
            children: [
              const Icon(Icons.bookmarks_outlined),
              const SizedBox(width: 8),
              Text(context.l10n.newTrackerTitle),
            ],
          ),
        ),
      ],
    );
  }

  IconButton _buildConfirmClusterReorderBtn() {
    return IconButton(
      key: ValueKey(_reorderingClusters),
      onPressed: () {
        if (_reorderingClusters && _reordered) {
          context.read<ClustersBloc>().add(SubmitClustersNewOrdersEvent());
          _reordered = false;
        }
        setState(() {
          _reorderingClusters = false;
          _clusterReorderController.reverse();
        });
      },
      style: Platform.isAndroid
          ? ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            )
          : null,
      icon: const Icon(
        Icons.check,
      ),
    );
  }

  void _onReorderClusters(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    context
        .read<ClustersBloc>()
        .add(ReorderClustersEvent(oldIndex: oldIndex, newIndex: newIndex));
    _reordered = true;
  }

  void _collapseClusterTilesExcept(int? exceptionClusterId) {
    for (var entry in _clusterTileKeys.entries) {
      if (entry.key == exceptionClusterId) {
        continue;
      }
      entry.value.currentState?.collapse();
    }
  }
}
