import 'package:cafe_pos/core/widgets/input_label.dart';
import 'package:cafe_pos/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/product_bloc.dart';
import '../widgets/category_field.dart';
import '../widgets/variant_editor.dart';
import '../../domain/entities/product.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/currency.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _sizesKey = GlobalKey<VariantEditorState>();
  late final TextEditingController _categoryController;
  late String _name;
  late double _price;

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _price = widget.product.price;
    _categoryController =
        TextEditingController(text: widget.product.category);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final duplicate = _sizesKey.currentState!.duplicateLabel;
    if (duplicate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('You have two sizes called "$duplicate".'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final updatedProduct = Product(
      id: widget.product.id,
      name: _name.trim(),
      category: _categoryController.text.trim(),
      price: _price,
      stock: widget.product.stock,
      variants: _sizesKey.currentState!.variants,
    );

    context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
    context.pop();
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
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 32, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: const Text('Edit Menu Item',
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
                    initialValue: _name,
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
                    initialValue: _price.toStringAsFixed(2),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
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
                    'Used when the item has no sizes. If sizes are listed '
                    'below, their prices are charged instead.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Sizes (optional)'),
                  VariantEditor(
                    key: _sizesKey,
                    initial: widget.product.variants,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.history, size: 18, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Changing the price affects future orders only. '
                            'Past orders keep the price they were sold at.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: PrimaryButton(
          onPressed: _submit,
          icon: Icons.save,
          label: 'Save Changes',
        ));
  }
}
