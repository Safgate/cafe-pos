import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff.dart';
import '../bloc/staff_bloc.dart';

class StaffListPage extends StatefulWidget {
  const StaffListPage({super.key});

  @override
  State<StaffListPage> createState() => _StaffListPageState();
}

class _StaffListPageState extends State<StaffListPage> {
  @override
  void initState() {
    super.initState();
    context.read<StaffBloc>().add(LoadStaff());
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
        title: const Text('Staff',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: BlocConsumer<StaffBloc, StaffState>(
        listener: (context, state) {
          if (state.message == null) return;
          final isError = state.status == StaffStatus.error;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message!),
            backgroundColor: isError ? Colors.red : Colors.green,
          ));
        },
        builder: (context, state) {
          if (state.status == StaffStatus.loading && state.staff.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: state.staff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final staff = state.staff[index];
              return _buildTile(context, staff);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/more/staff/add'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.person_add, size: 26),
      ),
    );
  }

  Widget _buildTile(BuildContext context, Staff staff) {
    return Opacity(
      opacity: staff.active ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(staff.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: staff.isOwner
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          staff.role.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: staff.isOwner
                                ? AppTheme.primaryColor
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    staff.active ? 'Active' : 'Deactivated',
                    style: TextStyle(
                      fontSize: 12,
                      color: staff.active ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  color: AppTheme.primaryColor, size: 20),
              onPressed: () =>
                  context.push('/more/staff/edit/${staff.id}', extra: staff),
            ),
            if (staff.active)
              IconButton(
                icon: const Icon(Icons.person_off_outlined,
                    color: Colors.red, size: 20),
                onPressed: () => _confirmDeactivate(context, staff),
                tooltip: 'Deactivate',
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, Staff staff) {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text('Deactivate staff member'),
        content: Text(
            '${staff.name} will no longer be able to sign in. Their name '
            'stays on the orders and log entries they already made.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<StaffBloc>().add(DeactivateStaffMember(staff.id));
              Navigator.pop(innerContext);
            },
            child:
                const Text('Deactivate', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
