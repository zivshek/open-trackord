import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trackord/blocs/categories_bloc.dart';
import 'package:trackord/blocs/clusters_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/models/cluster_model.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/utils/ui.dart';
import 'package:trackord/widgets/category_widget.dart';
import 'package:trackord/widgets/modified_expansion_tile_card.dart';

class ClusterWidget extends StatefulWidget {
  final bool reorderingClusters;
  final int index;
  final ClusterModel cluster;
  final CategoriesLoaded categoriesState;
  final GlobalKey<ModifiedExpansionTileCardState> globalKey;
  final bool expanded;
  final Function(bool) onClusterExpansionChanged;
  final Function(int) onActivateReorderingMode;

  const ClusterWidget({
    super.key,
    required this.reorderingClusters,
    required this.index,
    required this.cluster,
    required this.categoriesState,
    required this.expanded,
    required this.onClusterExpansionChanged,
    required this.onActivateReorderingMode,
    required this.globalKey,
  });

  @override
  State<ClusterWidget> createState() => _ClusterWidgetState();
}

class _ClusterWidgetState extends State<ClusterWidget>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: 0.5);
  static final Animatable<double> _fullTween =
      Tween<double>(begin: 0.0, end: 1.0);

  late AnimationController _clusterShowEditButtonsController;

  late Animatable<double> _turnsTween;

  late Animation<double> _iconTurns;
  late Animation<double> _slideAnimation;

  final Map<int, GlobalKey<CategoryWidgetState>> _categoriesKeys = {};

  bool _reordered = false;
  bool _isReorderingCategories = false;
  bool _showClusterEditButtons = false;
  int? _expandedCategoryId;

  @override
  void initState() {
    super.initState();

    _turnsTween = CurveTween(curve: Curves.easeInOut);

    _clusterShowEditButtonsController =
        AnimationController(vsync: this, duration: animDuration);

    _iconTurns =
        _clusterShowEditButtonsController.drive(_halfTween.chain(_turnsTween));

    _slideAnimation =
        _clusterShowEditButtonsController.drive(_fullTween.chain(_turnsTween));
  }

  @override
  void dispose() {
    _clusterShowEditButtonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cluster = widget.cluster;
    final categoriesState = widget.categoriesState;
    final categories = categoriesState.categories
        .where((c) => c.clusterId == cluster.id)
        .toList();

    String clusterName = cluster.name;
    if (cluster.id == 0) {
      clusterName = context.l10n.defaultCluster;
    }
    clusterName += ' (${categories.length})';

    return GestureDetector(
      child: IgnorePointer(
        ignoring: widget.reorderingClusters,
        child: ModifiedExpansionTileCard(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
          borderRadius: BorderRadius.zero,
          key: widget.globalKey,
          title: Text(clusterName),
          initiallyExpanded: widget.expanded,
          heightFactorCurve: Curves.easeInOut,
          trailing: widget.reorderingClusters
              ? const Icon(Icons.expand_more, color: Colors.grey)
              : null,
          onExpansionChanged: widget.onClusterExpansionChanged,
          children: [
            _buildCategoriesList(categories, cluster, categoriesState),
            OverflowBar(children: [
              AnimatedSwitcher(
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
                child: _isReorderingCategories
                    ?
                    // show a confirm button when in edit mode
                    _buildConfirmEditBtn(cluster.id!)
                    : // only show the add new category button when not in edit mode
                    _buildClusterActions(cluster.id!),
              ),
            ]),
          ],
        ),
      ),
      onLongPress: () {
        // If reordering, user can only press the check button to confirm
        if (widget.reorderingClusters || _isReorderingCategories) {
          return;
        }

        widget.onActivateReorderingMode(cluster.id!);
      },
    );
  }

  ReorderableListView _buildCategoriesList(List<CategoryModel> categories,
      ClusterModel cluster, CategoriesLoaded state) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) =>
          _onReorderCategories(cluster.id!, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final category = categories[index];
        final record = state.records[category.id!];

        return KeyedSubtree(
          key: ValueKey("category_actions_${category.id}"),
          child: _buildCategoryRow(category, context, cluster, record, index),
        );
      },
    );
  }

  Row _buildCategoryRow(CategoryModel category, BuildContext context,
      ClusterModel cluster, RecordModel? record, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(index, context),
        _buildCategoryWidget(category, record),
        _buildDeleteButton(context, category),
      ],
    );
  }

  AnimatedContainer _buildDeleteButton(
      BuildContext context, CategoryModel category) {
    return AnimatedContainer(
      duration: animDuration,
      width: _isReorderingCategories ? 30 : 0,
      child: AnimatedOpacity(
        opacity: _isReorderingCategories ? 1.0 : 0.0,
        duration: animDuration,
        child: Transform.translate(
          offset: const Offset(-3, 0),
          child: IconButton(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => showDeleteConfirmation(
                context,
                context.l10n.deleteTrackerTitle,
                context.l10n.deleteTrackerConfirmText,
                () => context
                    .read<CategoriesBloc>()
                    .add(DeleteCategory(category))),
          ),
        ),
      ),
    );
  }

  Expanded _buildCategoryWidget(CategoryModel category, RecordModel? record) {
    final categoryKey = _categoriesKeys.putIfAbsent(
        category.id!, () => GlobalKey<CategoryWidgetState>());
    return Expanded(
      child: GestureDetector(
        onLongPress: () => _toggleCategoriesReorderMode(),
        child: CategoryWidget(
          key: categoryKey,
          category: category,
          latestRecord: record,
          onExpansionChanged: (isExpanded) {
            if (isExpanded && _expandedCategoryId != category.id) {
              _collapseExpandedCategory();
            }
            _expandedCategoryId = isExpanded ? category.id : null;
          },
          isReorderingMode: _isReorderingCategories,
        ),
      ),
    );
  }

  AnimatedContainer _buildDragHandle(int index, BuildContext context) {
    return AnimatedContainer(
      duration: animDuration,
      width: _isReorderingCategories ? 30 : 0,
      child: AnimatedOpacity(
        opacity: _isReorderingCategories ? 1.0 : 0.0,
        duration: animDuration,
        child: ReorderableDragStartListener(
          index: index,
          enabled: _isReorderingCategories,
          child: Icon(
            Icons.drag_handle,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmEditBtn(int clusterId) {
    return ListTile(
      key: Key('confirm_edit_btn$clusterId'),
      title: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              _toggleCategoriesReorderMode();
            },
            child: Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCategoriesReorderMode() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isReorderingCategories) {
        if (_reordered) {
          context
              .read<CategoriesBloc>()
              .add(SubmitNewCategoryOrdersEvent(widget.cluster.id!));
          _reordered = false;
        }
      }

      _isReorderingCategories = !_isReorderingCategories;

      if (_isReorderingCategories) {
        _collapseExpandedCategory();
      }
    });
  }

  Widget _buildClusterActions(int clusterId) {
    return ListTile(
      title: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: AnimatedSize(
            duration: animDuration,
            curve: Curves.easeInOut,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
                onPressed: () {
                  context.push('/new_category/$clusterId');
                },
                child: Text(
                  context.l10n.newTrackerTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              if (clusterId != 0) const SizedBox(width: 4),
              if (clusterId != 0)
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: animDuration,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return RotationTransition(
                        turns: _iconTurns,
                        child: child,
                      );
                    },
                    child: const RotatedBox(
                      quarterTurns: 3,
                      child: Icon(
                        Icons.expand_more,
                      ),
                    ),
                  ),
                  onPressed: _toggleClusterEditButtons,
                ),
              if (clusterId != 0)
                AnimatedOpacity(
                  duration: animDuration,
                  curve: Curves.easeInOutExpo,
                  opacity: _showClusterEditButtons ? 1.0 : 0,
                  child: SizeTransition(
                    sizeFactor: _slideAnimation,
                    axisAlignment: -1,
                    axis: Axis.horizontal,
                    child: Row(
                      children: [
                        IconButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                          onPressed: () {
                            context.push('/edit_cluster/$clusterId');
                          },
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () {
                            showDeleteConfirmation(
                                context,
                                context.l10n.deleteClusterTitle,
                                context.l10n.deleteClusterConfirmText,
                                () => context.read<ClustersBloc>().add(
                                    DeleteClusterEvent(clusterId: clusterId)));
                          },
                          icon: Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  void _collapseExpandedCategory() {
    if (_categoriesKeys.containsKey(_expandedCategoryId)) {
      _categoriesKeys[_expandedCategoryId]!.currentState?.collapse();
    }
  }

  void _toggleClusterEditButtons() {
    setState(() {
      _showClusterEditButtons = !_showClusterEditButtons;
      if (_showClusterEditButtons) {
        _clusterShowEditButtonsController.forward();
      } else {
        _clusterShowEditButtonsController.reverse();
      }
    });
  }

  void _onReorderCategories(int clusterId, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    context
        .read<CategoriesBloc>()
        .add(ReorderCategories(clusterId, oldIndex, newIndex));
    _reordered = true;
  }
}
