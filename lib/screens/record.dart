import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trackord/blocs/new_update_record_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/styling.dart';
import 'package:trackord/utils/ui.dart';
import 'package:trackord/utils/utils.dart';
import 'package:trackord/widgets/adaptive_scaffold.dart';
import 'package:trackord/widgets/dropdown_menu_widget.dart';
import 'package:trackord/widgets/gradient_divider.dart';
import 'package:trackord/widgets/textfield_widget.dart';

class RecordPage extends StatefulWidget {
  final CategoryModel category;
  final RecordModel? record;

  const RecordPage({super.key, required this.category, required this.record});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final TextEditingController _valueController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    context
        .read<NewOrUpdateRecordBloc>()
        .add(LoadRecentRecords(categoryId: widget.category.id!));
    if (widget.record == null) {
      _selectedDate = getDate(DateTime.now());
    } else {
      // Initialize controllers with existing category values if in edit mode
      _valueController.text =
          getRecordValueFull(widget.category.valueType, widget.record!.value);
      _selectedDate = widget.record!.date;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      },
      child: AdaptiveScaffold(
        title: widget.record == null
            ? context.l10n.newRecordTitle(widget.category.name)
            : context.l10n.editRecordTitle(widget.category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRecord,
          ),
        ],
        body: BlocListener<NewOrUpdateRecordBloc, NewOrUpdateRecordState>(
          listener: (context, state) {
            if (state is AddOrUpdateRecordSuccess) {
              context.pop(true);
            } else if (state is AddorUpdateRecordError) {
              if (state.existingRecord == null) {
                showErrorSnackBar(
                    context, context.l10n.errorMsg(state.message));
              } else {
                _showRecordExistsPopup(context, state.existingRecord!);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDateSelectCard(context),
                const SizedBox(height: 16),
                DropdownMenuWidget(
                  items: buildValueTypeDropdownItems(context),
                  selectedItem: ValueType.fromString(widget.category.valueType),
                  onChanged: null,
                  label: context.l10n.categoryValueTypeLabel,
                ),
                const SizedBox(height: 16),
                TextFieldWidget(
                  controller: _valueController,
                  label: '${widget.category.name} (${widget.category.unit})',
                  inputFieldType: widget.category.valueType == "float"
                      ? MyInputFieldType.decimal
                      : MyInputFieldType.integer,
                ),
                const SizedBox(height: 16),
                if (widget.record == null) _buildRecentRecordsSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildRecentRecordsSection(BuildContext context) {
    return Expanded(
      child: Card(
        color: getCardColor(context),
        elevation: getCardElevation(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.recentRecordsText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Expanded(
              child: BlocBuilder<NewOrUpdateRecordBloc, NewOrUpdateRecordState>(
                builder: (context, state) {
                  if (state is RecentRecordsLoaded ||
                      state is AddorUpdateRecordError) {
                    final records = state is RecentRecordsLoaded
                        ? (state).records
                        : (state as AddorUpdateRecordError).previousRecords;
                    return _buildRecentRecordsList(records);
                  } else if (state is RecentRecordsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is RecentRecordsError) {
                    return Center(
                        child: Text(context.l10n.errorMsg(state.message)));
                  } else {
                    return Center(child: Text(context.l10n.noRecordsFoundText));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListView _buildRecentRecordsList(List<RecordModel> records) {
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Column(
          children: [
            ListTile(
              dense: true,
              title: Text(
                '${getRecordValueFull(widget.category.valueType, record.value)} ${widget.category.unit}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              trailing: Text(
                DateFormat('MMM d, yyyy').format(record.date),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            index == records.length - 1 ? Container() : const GradientDivider(),
          ],
        );
      },
    );
  }

  Card _buildDateSelectCard(BuildContext context) {
    return Card(
      elevation: getCardElevation(),
      color: getCardColor(context),
      child: ListTile(
        title: Text(
          DateFormat('MMMM d, yyyy').format(_selectedDate),
          style: getCardLabelStyle(context),
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: _selectDate,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = getDate(picked);
      });
    }
  }

  void _saveRecord() {
    if (_valueController.text.trim().isNotEmpty) {
      final record = RecordModel(
        categoryId: widget.category.id!,
        value: double.parse(_valueController.text.trim()),
        date: getDate(_selectedDate),
        id: widget.record?.id,
      );

      context
          .read<NewOrUpdateRecordBloc>()
          .add(AddOrUpdateRecord(record, widget.record?.date == record.date));
    } else {
      showErrorSnackBar(context, context.l10n.valueIsEmptyText);
    }
  }

  Future<void> _showRecordExistsPopup(
      BuildContext context, RecordModel existingRecord) async {
    await showOkAlertDialog(
      context: context,
      title: context.l10n.recordExistsDialogTitle,
      message: context.l10n.recordExistsDialogBody(
          existingRecord.date.toIso8601String().split('T')[0]),
      okLabel: context.l10n.confirmButtonText,
    );
  }
}
