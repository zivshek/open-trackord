import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trackord/blocs/categories_bloc.dart';
import 'package:trackord/blocs/clusters_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/models/cluster_model.dart';
import 'package:trackord/services/shared_pref_wrapper.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/ui.dart';
import 'package:trackord/utils/utils.dart';
import 'package:trackord/widgets/adaptive_scaffold.dart';
import 'package:trackord/widgets/dropdown_menu_widget.dart';
import 'package:trackord/widgets/textfield_widget.dart';

class CategoryPage extends StatefulWidget {
  final ClusterModel cluster;
  final CategoryModel? category; // Nullable for create mode

  const CategoryPage({super.key, required this.cluster, this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _unitFieldKey = GlobalKey();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();
  ValueType _selectedValueType = ValueType.integer;
  ClusterModel? _selectedCluster;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && getRecentUnits().isNotEmpty) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });

    _unitController.addListener(() {
      if (!_focusNode.hasFocus) {
        return;
      }
      String currentText = _unitController.text;
      final filteredUnits = getRecentUnits()
          .where(
              (unit) => unit.toLowerCase().contains(currentText.toLowerCase()))
          .toList();

      if (filteredUnits.isEmpty) {
        _hideOverlay();
      } else {
        if (_overlayEntry != null) {
          _overlayEntry?.markNeedsBuild();
        } else {
          _showOverlay();
        }
      }
    });

    if (widget.category != null) {
      // Initialize controllers with existing category values if in edit mode
      _nameController.text = widget.category!.name;
      _unitController.text = widget.category!.unit;
      _notesController.text = widget.category!.notes ?? "";
      _selectedValueType = ValueType.fromString(widget.category!.valueType);
    }

    _selectedCluster = widget.cluster;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clustersState = context.read<ClustersBloc>().state;
    List<ClusterModel> clusters = [];
    if (clustersState is ClustersLoaded) {
      clusters = clustersState.clusters;
    }
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      },
      child: AdaptiveScaffold(
        title: widget.category == null
            ? context.l10n.newTrackerTitle
            : context.l10n.editTrackerTitle(widget.category?.name ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                showErrorSnackBar(context, context.l10n.valueIsEmptyText);
              } else {
                _saveCategory();
              }
            },
          ),
        ],
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownMenuWidget(
                  items: [
                    for (var cluster in clusters)
                      DropdownMenuItem(
                        value: cluster,
                        child: Text(cluster.name),
                      )
                  ],
                  selectedItem: widget.cluster,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCluster = value;
                      });
                    }
                  },
                  label: context.l10n.clusterDropdownLabel,
                ),
                const SizedBox(height: 16),
                TextFieldWidget(
                  controller: _nameController,
                  label: context.l10n.categoryNameLabel,
                  inputFieldType: MyInputFieldType.text,
                ),
                const SizedBox(height: 16),
                TextFieldWidget(
                  key: _unitFieldKey,
                  controller: _unitController,
                  label: context.l10n.categoryUnitLabel,
                  inputFieldType: MyInputFieldType.text,
                  focusNode: _focusNode,
                  layerLink: _layerLink,
                ),
                const SizedBox(height: 16),
                DropdownMenuWidget(
                    items: buildValueTypeDropdownItems(context),
                    selectedItem: _selectedValueType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedValueType = value;
                        });
                      }
                    },
                    label: context.l10n.categoryValueTypeLabel),
                const SizedBox(height: 16),
                TextFieldWidget(
                  controller: _notesController,
                  label: context.l10n.categoryNotesLabel,
                  inputFieldType: MyInputFieldType.text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final category = CategoryModel(
        id: widget.category?.id, // Use existing ID if editing
        clusterId: _selectedCluster!.id!,
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        valueType: _selectedValueType.name,
        order: 0, // Set to 0 for now, it'll be assigned in the repository
        notes: _notesController.text,
      );

      if (category.unit != "") {
        final recentUnits = getRecentUnits();
        final List<String> updatedUnits = [
          category.unit,
          ...recentUnits.where((unit) => unit != category.unit)
        ].take(7).toList();
        SharedPrefWrapper().setStringList(kRecentUnitsKey, updatedUnits);
      }

      if (widget.category == null) {
        context.read<CategoriesBloc>().add(AddCategory(category));
      } else {
        context
            .read<CategoriesBloc>()
            .add(UpdateCategory(category, widget.cluster.id!));
      }
      GoRouter.of(context).pop();
    }
  }

  void _showOverlay() {
    _hideOverlay();

    final overlay = Overlay.of(context);
    final RenderBox renderBox =
        _unitFieldKey.currentContext?.findRenderObject() as RenderBox;

    final size = renderBox.size;
    List<String> filteredUnits = getRecentUnits()
        .where((unit) =>
            unit.toLowerCase().contains(_unitController.text.toLowerCase()))
        .toList();
    const double horizontalPadding = 10;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              _hideOverlay();
              _focusNode.unfocus();
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        Positioned(
          width: size.width - 2 * horizontalPadding,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(horizontalPadding, size.height + 5),
            child: Material(
              elevation: 4,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(filteredUnits[index]),
                      onTap: () {
                        _unitController.text = filteredUnits[index];
                        _hideOverlay();
                        _focusNode.unfocus();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ]),
    );

    _overlayEntry!.markNeedsBuild();

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
