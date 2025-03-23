import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trackord/blocs/clusters_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/models/cluster_model.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/ui.dart';
import 'package:trackord/widgets/adaptive_scaffold.dart';
import 'package:trackord/widgets/textfield_widget.dart';

class ClusterPage extends StatefulWidget {
  final ClusterModel? cluster; // Nullable for create mode

  const ClusterPage({super.key, this.cluster});

  @override
  State<ClusterPage> createState() => _ClusterPageState();
}

class _ClusterPageState extends State<ClusterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.cluster != null) {
      _nameController.text = widget.cluster!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      },
      child: AdaptiveScaffold(
        title: widget.cluster == null
            ? context.l10n.newClusterTitle
            : context.l10n.editClusterTitle(widget.cluster?.name ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                showErrorSnackBar(context, context.l10n.valueIsEmptyText);
              } else {
                _saveCluster();
              }
            },
          ),
        ],
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFieldWidget(
              controller: _nameController,
              label: context.l10n.categoryNameLabel,
              inputFieldType: MyInputFieldType.text,
            ),
          ),
        ),
      ),
    );
  }

  void _saveCluster() {
    if (_formKey.currentState!.validate()) {
      final cluster = ClusterModel(
        id: widget.cluster?.id, // Use existing ID if editing
        name: _nameController.text.trim(),
        order: 0, // Set to 0 for now, it'll be assigned in the repository
      );

      if (widget.cluster == null) {
        context.read<ClustersBloc>().add(AddClusterEvent(cluster: cluster));
      } else {
        context.read<ClustersBloc>().add(EditClusterEvent(cluster: cluster));
      }
      GoRouter.of(context).pop();
    }
  }
}
