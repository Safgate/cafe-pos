import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/expense.dart';
import '../bloc/expense_bloc.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  double _amount = 0;
  String _category = ExpenseCategories.supplies;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 3),
      // Expenses can be back-dated but not booked into the future.
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        // Keep the time-of-day so same-day entries stay in entry order.
        _date = DateTime(picked.year, picked.month, picked.day,
            DateTime.now().hour, DateTime.now().minute);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    context.read<ExpenseBloc>().add(AddExpense(
          amount: _amount,
          category: _category,
          note: _noteController.text.trim(),
          date: _date,
        ));
    context.pop();
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
        title: const Text('Log Expense',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                const InputLabel(text: 'Amount'),
                TextFormField(
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '${currencySymbol()} ',
                    prefixStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  validator: (value) {
                    final base = AppValidators.price(value);
                    if (base != null) return base;
                    if (double.parse(value!) == 0) {
                      return 'Enter an amount above zero';
                    }
                    return null;
                  },
                  onSaved: (value) => _amount = double.parse(value!),
                ),
                const SizedBox(height: 24),
                const InputLabel(text: 'Category'),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  items: ExpenseCategories.all
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(
                      () => _category = value ?? ExpenseCategories.other),
                ),
                const SizedBox(height: 24),
                const InputLabel(text: 'Note (optional)'),
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      hintText: 'e.g. Milk delivery from Harrow Dairy'),
                ),
                const SizedBox(height: 24),
                const InputLabel(text: 'Date'),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(DateFormat('EEEE, d MMMM yyyy').format(_date)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Defaults to today. Back-date it if the money went out '
                  'earlier — reports follow this date.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: PrimaryButton(
        onPressed: _submit,
        icon: Icons.add_circle,
        label: 'Log Expense',
      ),
    );
  }
}
