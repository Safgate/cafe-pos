import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/activity_log.dart';
import '../bloc/activity_bloc.dart';

/// Owner-only. Append-only: nothing here can be edited or deleted from the
/// app, which is the whole point — it is what makes editing and voiding
/// orders safe to allow.
class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  @override
  void initState() {
    super.initState();
    context.read<ActivityBloc>().add(LoadActivity());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Activity Log',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) => IconButton(
              icon: Icon(
                state.hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                color: state.hasFilters ? AppTheme.primaryColor : null,
              ),
              onPressed: () => _openFilters(context, state),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ActivityBloc, ActivityState>(
        builder: (context, state) {
          if (state.status == ActivityStatus.loading && state.logs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  state.hasFilters
                      ? 'Nothing matches those filters.'
                      : 'Nothing recorded yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: state.logs.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) =>
                _LogTile(log: state.logs[index]),
          );
        },
      ),
    );
  }

  void _openFilters(BuildContext context, ActivityState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final staff = state.staffInLogs;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Filter',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Staff',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip(
                      label: 'Anyone',
                      selected: state.staffIdFilter == null,
                      onTap: () {
                        context.read<ActivityBloc>().add(FilterActivity(
                            action: state.actionFilter, staffId: null));
                        Navigator.pop(sheetContext);
                      },
                    ),
                    ...staff.entries.map((entry) => _filterChip(
                          label: entry.value,
                          selected: state.staffIdFilter == entry.key,
                          onTap: () {
                            context.read<ActivityBloc>().add(FilterActivity(
                                staffId: entry.key,
                                action: state.actionFilter));
                            Navigator.pop(sheetContext);
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Action',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip(
                      label: 'Everything',
                      selected: state.actionFilter == null,
                      onTap: () {
                        context.read<ActivityBloc>().add(FilterActivity(
                            staffId: state.staffIdFilter, action: null));
                        Navigator.pop(sheetContext);
                      },
                    ),
                    ...ActivityActions.all.map((action) => _filterChip(
                          label: ActivityActions.label(action),
                          selected: state.actionFilter == action,
                          onTap: () {
                            context.read<ActivityBloc>().add(FilterActivity(
                                staffId: state.staffIdFilter,
                                action: action));
                            Navigator.pop(sheetContext);
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87, fontSize: 12),
      showCheckmark: false,
    );
  }
}

class _LogTile extends StatelessWidget {
  final ActivityLog log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _colorFor(log.action).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ActivityActions.label(log.action),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _colorFor(log.action)),
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('d MMM, HH:mm').format(log.timestamp),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(log.summary, style: const TextStyle(fontSize: 14)),
        if (log.details.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            log.details,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 4),
        Text('by ${log.staffName}',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  static Color _colorFor(String action) {
    if (action == ActivityActions.orderVoided ||
        action == ActivityActions.authLoginFailed ||
        action.endsWith('.deleted') ||
        action == ActivityActions.staffDeactivated) {
      return Colors.red;
    }
    if (action == ActivityActions.orderEdited ||
        action.endsWith('.updated')) {
      return Colors.orange;
    }
    if (action == ActivityActions.orderCreated) return Colors.green;
    return AppTheme.primaryColor;
  }
}
