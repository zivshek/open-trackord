import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trackord/blocs/categories_bloc.dart';
import 'package:trackord/blocs/history_bloc.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/utils/styling.dart';
import 'package:trackord/utils/utils.dart';
import 'package:trackord/widgets/adaptive_scaffold.dart';
import 'package:trackord/widgets/gradient_divider.dart';

class HistoryPage extends StatefulWidget {
  final CategoryModel category;

  const HistoryPage({super.key, required this.category});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _lastOffset = 0;
  int _offset = 0;
  final int _limit = 15;
  bool _isLoading = false;
  bool _hasMoreRecords = true;
  late ScrollController _scrollController;
  int _indexInEditMode = -1;
  bool _anyUpdate = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastOffset = 0;
      _offset = 0;
      _isLoading = false;
      _hasMoreRecords = true;
      _indexInEditMode = -1;
      _anyUpdate = false;
      _fetchRecords();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (_anyUpdate) {
          context.read<CategoriesBloc>().add(LoadCategories());
        }
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      },
      child: AdaptiveScaffold(
        title: context.l10n.historyTitle(widget.category.name),
        body: BlocBuilder<HistoryBloc, HistoryState>(
          buildWhen: (previous, current) => previous != current,
          builder: (context, state) {
            if (state is HistoryLoaded || state is HistoryError) {
              final records = state is HistoryLoaded
                  ? state.records
                  : (state as HistoryError).records;
              _lastOffset = _offset;
              _offset = records.length;
              _hasMoreRecords = state is HistoryLoaded
                  ? state.hasMoreRecords
                  : (state as HistoryError).hasMoreRecords;
              _isLoading = false;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: getCardElevation(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.atEdge &&
                          scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                        _fetchRecords(); // Fetch more records when scrolled to the bottom
                      }
                      return false;
                    },
                    child: Stack(children: [
                      ListView.builder(
                        controller: _scrollController,
                        itemCount: records.length +
                            (_isLoading
                                ? 1
                                : 0), // Show loading indicator if loading
                        itemBuilder: (context, index) {
                          if (index < records.length) {
                            final record = records[index];
                            final inEditMode = _indexInEditMode == index;
                            return Column(
                              children: [
                                _buildRecord(
                                    index, record, inEditMode, context),
                                index == records.length - 1
                                    ? Container()
                                    : const GradientDivider(),
                              ],
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                      if (_isLoading)
                        Positioned(
                          top: 0, // Position it at the top
                          left: 0,
                          right: 0,
                          child: Container(
                            color: const Color.fromARGB(50, 226, 226, 226),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              );
            } else {
              return const Center(
                  child: Text('No records available')); // No records available
            }
          },
        ),
      ),
    );
  }

  GestureDetector _buildRecord(
      int index, RecordModel record, bool inEditMode, BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (_indexInEditMode != index) {
          setState(() {
            _indexInEditMode = index;
          });
        } else {
          setState(() {
            _indexInEditMode = -1;
          });
        }
      },
      child: ListTile(
        title: Text(
            '${getRecordValueFull(widget.category.valueType, record.value)} ${widget.category.unit}'),
        trailing: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(
                right: inEditMode ? 90 : 0,
              ),
              child: Text(
                DateFormat('MMM d, yyyy').format(record.date),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            AnimatedPositioned(
              duration: inEditMode
                  ? const Duration(milliseconds: 200)
                  : const Duration(milliseconds: 50),
              right: inEditMode ? -20 : -120,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: inEditMode
                    ? const Duration(milliseconds: 200)
                    : const Duration(milliseconds: 50),
                opacity: inEditMode ? 1.0 : 0.0,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit,
                          color: Theme.of(context).colorScheme.primary),
                      onPressed: () async {
                        final result = await context
                            .push<bool>('/edit_record/${record.id}');
                        if (result == true && context.mounted) {
                          _indexInEditMode = -1;
                          context.read<HistoryBloc>().add(LoadRecordsPagenation(
                              widget.category.id!,
                              _offset - _lastOffset,
                              _limit));
                          _anyUpdate = true;
                        }
                      },
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          color: Theme.of(context).colorScheme.errorContainer),
                      onPressed: () =>
                          _showDeleteRecordConfirmation(context, record),
                      enableFeedback: true,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _fetchRecords() async {
    if (_isLoading || !_hasMoreRecords) return; // Prevent multiple loads

    setState(() {
      _isLoading = true;
    });

    context.read<HistoryBloc>().add(LoadRecordsPagenation(
        widget.category.id!, _offset, _limit,
        screenHeight: MediaQuery.of(context).size.height));
  }

  Future<void> _showDeleteRecordConfirmation(
      BuildContext context, RecordModel record) async {
    OkCancelResult result = await showOkCancelAlertDialog(
        context: context,
        title: context.l10n.deleteRecordDialogTitle,
        message: context.l10n.deleteRecordDialogBody(
            DateFormat('MMM d, yyyy').format(record.date)),
        okLabel: context.l10n.deleteButtonText,
        cancelLabel: context.l10n.cancelButtonText,
        isDestructiveAction: true,
        style: AdaptiveStyle.adaptive,
        defaultType: OkCancelAlertDefaultType.cancel);

    if (result == OkCancelResult.ok && context.mounted) {
      context.read<HistoryBloc>().add(HistoryDeleteRecordEvent(record));
      _indexInEditMode = -1;
      _anyUpdate = true;
    }
  }
}
