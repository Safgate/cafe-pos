import 'package:cafe_pos/core/widgets/input_label.dart';
import 'package:cafe_pos/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../bloc/product_bloc.dart';
import '../widgets/category_field.dart';
import '../widgets/variant_editor.dart';
import '../../domain/entities/product.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/currency.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _sizesKey = GlobalKey<VariantEditorState>();
  final _categoryController = TextEditingController();
  String _name = '';
  double _price = 0.0;

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final sizes = _sizesKey.currentState!.variants;

    final duplicate = _sizesKey.currentState!.duplicateLabel;
    if (duplicate != null) {
      _showError('You have two sizes called "$duplicate".');
      return;
    }

    final duplicates = context
        .read<ProductBloc>()
        .state
        .products
        .where((p) => p.name.toLowerCase() == _name.trim().toLowerCase());
    if (duplicates.isNotEmpty) {
      _showError('"${duplicates.first.name}" is already on the menu.');
      return;
    }

    final product = Product(
      id: const Uuid().v4(),
      name: _name.trim(),
      category: _categoryController.text.trim(),
      price: _price,
      variants: sizes,
    );

    context.read<ProductBloc>().add(AddProduct(product));
    context.pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context
        .read<ProductBloc>()
        .state
        .products
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: const Text('Add Menu Item',
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
                  const InputLabel(text: 'Item Name'),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'e.g. Flat White',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.required('Please enter a name'),
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Category'),
                  CategoryField(
                    controller: _categoryController,
                    suggestions: categories,
                  ),
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Price'),
                  TextFormField(
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
                    validator: AppValidators.price,
                    onSaved: (value) => _price = double.parse(value!),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Used when the item has no sizes. If you add sizes below, '
                    'their prices are charged instead.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Sizes (optional)'),
                  VariantEditor(key: _sizesKey),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: PrimaryButton(
          onPressed: _submit,
          icon: Icons.add_circle,
          label: 'Add Item',
        ));
  }
}
