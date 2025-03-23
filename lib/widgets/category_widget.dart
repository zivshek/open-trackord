import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trackord/blocs/categories_bloc.dart';
import 'package:trackord/models/category_model.dart';
import 'package:trackord/models/record_model.dart';
import 'package:trackord/utils/styling.dart';
import 'package:trackord/utils/utils.dart';
import 'package:trackord/widgets/custom_icon_button.dart';

class CategoryWidget extends StatefulWidget {
  final CategoryModel category;
  final RecordModel? latestRecord;
  final ValueChanged<bool> onExpansionChanged;
  final bool isReorderingMode;
  const CategoryWidget({
    super.key,
    required this.category,
    required this.latestRecord,
    required this.onExpansionChanged,
    this.isReorderingMode = false,
  });

  @override
  State<CategoryWidget> createState() => CategoryWidgetState();
}

class CategoryWidgetState extends State<CategoryWidget>
    with SingleTickerProviderStateMixin {
  final Duration _duration = const Duration(milliseconds: 300);

  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<double> _fadeAnimation;

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _duration, vsync: this);

    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    ));

    if (_expanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void expand() {
    if (_expanded) return;
    setState(() {
      _expanded = true;
      _controller.forward();
    });
  }

  void collapse() {
    if (!_expanded) return;
    setState(() {
      _expanded = false;
      _controller.reverse();
    });
  }

  void toggleExpansion() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward(); // Expand
      } else {
        _controller.reverse(); // Collapse
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Card(
        elevation: getCardElevation(),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: Theme.of(context).colorScheme.outline, width: 0.1)),
        child: AnimatedBuilder(
          animation: _sizeAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Material(
                color: Color.lerp(
                    getCardColor(context),
                    Theme.of(context).colorScheme.secondaryContainer,
                    _controller.value), // Color transition
                child: Column(
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        if (!widget.isReorderingMode) {
                          toggleExpansion();
                          widget.onExpansionChanged(_expanded);
                        }
                      },
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16, // Reduce right padding in edit mode
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.category.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                widget.latestRecord != null
                                    ? _buildLatestRecord(context)
                                    : Container(),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: _duration, // Set animation duration
                      curve: Curves.easeInOut,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _expanded
                            ? _buildExpandedContent(context)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Column _buildLatestRecord(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getRecordValueFull(
                  widget.category.valueType, widget.latestRecord?.value),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            ),
            const SizedBox(width: 5),
            Text(
              widget.category.unit,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            ),
          ],
        ),
        if (widget.latestRecord?.date != null)
          Text(
            DateFormat('dd MMM yyyy').format(widget.latestRecord!.date),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconButton(
              icon: Icons.edit,
              iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
              btnColor: Theme.of(context).colorScheme.primaryContainer,
              onPressed: () =>
                  context.push<bool>('/edit_category/${widget.category.id}'),
            ),
            const SizedBox(width: 10),
            CustomIconButton(
              icon: Icons.add,
              iconColor: Theme.of(context).colorScheme.onSecondary,
              btnColor: Theme.of(context).colorScheme.secondary,
              onPressed: () async {
                final result = await context
                    .push<bool>('/new_record/${widget.category.id}');
                if (result == true && context.mounted) {
                  context.read<CategoriesBloc>().add(LoadCategories());
                }
              },
            ),
            const SizedBox(width: 10),
            CustomIconButton(
              icon: Icons.bar_chart,
              iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
              btnColor: Theme.of(context).colorScheme.primaryContainer,
              onPressed: () =>
                  context.push('/indi_chart/${widget.category.id}'),
            ),
            const SizedBox(width: 10),
            CustomIconButton(
              icon: Icons.history,
              iconColor: Theme.of(context).colorScheme.onSecondary,
              btnColor: Theme.of(context).colorScheme.secondary,
              onPressed: () async {
                await context.push('/category_history/${widget.category.id}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
