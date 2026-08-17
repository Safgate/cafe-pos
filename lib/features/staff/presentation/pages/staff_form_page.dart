import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_validators.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/staff.dart';
import '../bloc/staff_bloc.dart';

/// Add a staff member, or edit an existing one. When [existing] is null this
/// is the "add" flow and a PIN is required; when editing, leaving the PIN
/// fields blank keeps the current PIN.
class StaffFormPage extends StatefulWidget {
  final Staff? existing;

  const StaffFormPage({super.key, this.existing});

  @override
  State<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends State<StaffFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  late StaffRole _role;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _role = widget.existing?.role ?? StaffRole.cashier;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final bloc = context.read<StaffBloc>();
    if (_isEditing) {
      bloc.add(UpdateStaffMember(
        staff: widget.existing!.copyWith(
          name: _nameController.text.trim(),
          role: _role,
        ),
        newPin: _pinController.text.isEmpty ? null : _pinController.text,
      ));
    } else {
      bloc.add(AddStaffMember(
        name: _nameController.text.trim(),
        pin: _pinController.text,
        role: _role,
      ));
    }
    context.pop();
  }

  String? _validatePin(String? value) {
    final entered = value ?? '';
    if (_isEditing && entered.isEmpty) return null; // keep existing PIN
    if (entered.length != 4) return 'Use exactly 4 digits';
    if (int.tryParse(entered) == null) return 'Digits only';
    return null;
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
        title: Text(_isEditing ? 'Edit Staff' : 'Add Staff',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InputLabel(text: 'Name'),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'e.g. Alex Chen'),
                  validator: AppValidators.required('Please enter a name'),
                ),
                const SizedBox(height: 24),
                const InputLabel(text: 'Role'),
                DropdownButtonFormField<StaffRole>(
                  initialValue: _role,
                  items: StaffRole.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.label),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _role = value ?? StaffRole.cashier),
                ),
                const SizedBox(height: 6),
                Text(
                  _role == StaffRole.owner
                      ? 'Owners can manage the menu and staff, view reports '
                          'and the activity log, and edit or void orders.'
                      : 'Cashiers can take orders and log expenses.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                InputLabel(
                    text: _isEditing ? 'New PIN (optional)' : '4-digit PIN'),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: _isEditing ? 'Leave blank to keep' : '••••',
                    counterText: '',
                  ),
                  validator: _validatePin,
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
                  validator: (value) => (value ?? '') == _pinController.text
                      ? null
                      : 'PINs do not match',
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: PrimaryButton(
        onPressed: _submit,
        icon: _isEditing ? Icons.save : Icons.person_add,
        label: _isEditing ? 'Save Changes' : 'Add Staff',
      ),
    );
  }
}
