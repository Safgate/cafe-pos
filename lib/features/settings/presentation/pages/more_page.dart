import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
// For the StaffRole.label extension.
import '../../../staff/domain/entities/staff.dart';
import '../../../staff/presentation/bloc/auth_bloc.dart';

/// Everything that is not the till: expenses, staff, the log, shop details and
/// the printer. Owner-only destinations are hidden from cashiers rather than
/// shown and then refused.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final staff = auth.staff;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('More',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (staff != null) _buildWhoami(context, staff.name, staff.role.label),
          const SizedBox(height: 24),
          _sectionLabel('Money'),
          _tile(
            context,
            icon: Icons.receipt_long,
            title: 'Expenses',
            subtitle: 'Stock, rent, wages, utilities',
            route: '/more/expenses',
          ),
          const SizedBox(height: 24),
          if (auth.canManageStaff || auth.canViewActivityLog) ...[
            _sectionLabel('Management'),
            if (auth.canManageStaff)
              _tile(
                context,
                icon: Icons.people_outline,
                title: 'Staff',
                subtitle: 'Add people and set what they can do',
                route: '/more/staff',
              ),
            if (auth.canViewActivityLog)
              _tile(
                context,
                icon: Icons.history,
                title: 'Activity Log',
                subtitle: 'Every action, and who took it',
                route: '/more/activity',
              ),
            const SizedBox(height: 24),
          ],
          _sectionLabel('Setup'),
          _tile(
            context,
            icon: Icons.storefront,
            title: 'Shop Details',
            subtitle: 'Name, address, currency, receipt footer',
            route: '/more/shop',
          ),
          _tile(
            context,
            icon: Icons.print_outlined,
            title: 'Printer',
            subtitle: 'Pair a Bluetooth thermal printer',
            route: '/more/printer',
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLockRequested()),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Lock Screen'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoami(BuildContext context, String name, String role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            child: const Icon(Icons.person, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Signed in as $role',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            color: Colors.grey),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => context.push(route),
      ),
    );
  }
}
