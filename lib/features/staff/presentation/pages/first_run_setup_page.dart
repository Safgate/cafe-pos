import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';

/// Shown once, when the staff box is empty: create the Owner account.
class FirstRunSetupPage extends StatefulWidget {
  const FirstRunSetupPage({super.key});

  @override
  State<FirstRunSetupPage> createState() => _FirstRunSetupPageState();
}

class _FirstRunSetupPageState extends State<FirstRunSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthOwnerSetupRequested(
          name: _nameController.text.trim(),
          pin: _pinController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(Icons.local_cafe,
                          size: 48, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('Set up your till',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Create the owner account. You can add staff later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const InputLabel(text: 'Your Name'),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(hintText: 'e.g. Sam Rivera'),
                      validator:
                          AppValidators.required('Please enter your name'),
                    ),
                    const SizedBox(height: 24),
                    const InputLabel(text: '4-digit PIN'),
                    TextFormField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                          hintText: '••••', counterText: ''),
                      validator: (value) {
                        if (value == null || value.length != 4) {
                          return 'Use exactly 4 digits';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Digits only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const InputLabel(text: 'Confirm PIN'),
                    TextFormField(
                      controller: _confirmController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                          hintText: '••••', counterText: ''),
                      validator: (value) => value == _pinController.text
                          ? null
                          : 'PINs do not match',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: Colors.blueGrey),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The PIN keeps staff out of each other\'s '
                              'accounts and stamps every action with a name. '
                              'It is not a substitute for locking the phone '
                              'itself.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      Text(state.error!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 32),
                    PrimaryButton(
                      onPressed: _submit,
                      icon: Icons.check_circle,
                      label: 'Create Account',
                      isLoading: state.isBusy,
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
}
