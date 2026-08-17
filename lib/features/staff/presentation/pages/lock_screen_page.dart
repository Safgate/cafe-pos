import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/pin_pad.dart';
import 'first_run_setup_page.dart';

/// Sign-in: pick your name, then enter your PIN.
///
/// Picking first (rather than entering a bare PIN) avoids two people happening
/// to choose the same four digits, and it means the log always knows exactly
/// whose account an attempt was against.
class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  Staff? _selected;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AuthStatus.loggedOut) {
          setState(() => _selected = null);
        }
      },
      builder: (context, state) {
        if (state.status == AuthStatus.needsSetup) {
          return const FirstRunSetupPage();
        }

        if (state.status == AuthStatus.unknown) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          body: SafeArea(
            child: _selected == null
                ? _buildStaffPicker(context, state)
                : _buildPinEntry(context, state),
          ),
        );
      },
    );
  }

  Widget _buildStaffPicker(BuildContext context, AuthState state) {
    if (state.activeStaff.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No active staff accounts. Reinstall the app to run setup again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.local_cafe, size: 48, color: AppTheme.primaryColor),
        const SizedBox(height: 16),
        const Text('Who is on the till?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Tap your name to sign in',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.activeStaff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final staff = state.activeStaff[index];
              return _StaffTile(
                staff: staff,
                onTap: () => setState(() => _selected = staff),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPinEntry(BuildContext context, AuthState state) {
    final staff = _selected!;
    return SingleChildScrollView(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selected = null),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Not you?'),
            ),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              _initials(staff.name),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(staff.name,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          Text(staff.role.label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          PinPad(
            busy: state.isBusy,
            errorText: state.error,
            onCompleted: (pin) => context
                .read<AuthBloc>()
                .add(AuthLoginRequested(staffId: staff.id, pin: pin)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final Staff staff;
  final VoidCallback onTap;

  const _StaffTile({required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                _initials(staff.name),
                style: const TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(staff.role.label,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
