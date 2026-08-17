import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/domain/entities/product_variant.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../bloc/billing_bloc.dart';
import '../widgets/cart_sheet.dart';

/// The till. Tap items to build an order; sizes are asked for only when the
/// item has them.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _category = _allCategories;

  static const String _allCategories = '__all__';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: BlocBuilder<BillingBloc, BillingState>(
          builder: (context, state) => Text(
            state.isEditing
                ? 'Editing order #${state.editingOrder!.orderNumber}'
                : 'New Order',
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<BillingBloc, BillingState>(
            builder: (context, state) {
              if (state.isEmpty && !state.isEditing) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () =>
                    context.read<BillingBloc>().add(ClearCartEvent()),
                child: Text(state.isEditing ? 'Cancel edit' : 'Clear'),
              );
            },
          ),
        ],
      ),
      body: BlocListener<BillingBloc, BillingState>(
        listenWhen: (prev, curr) => prev.error != curr.error,
        listener: (context, state) {
          if (state.error == null) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        },
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, productState) {
            final products = productState.products;

            if (productState.status == ProductStatus.loading &&
                products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (products.isEmpty) return _buildEmptyMenu(context);

            final categories = _categoriesOf(products);
            final visible = _category == _allCategories
                ? products
                : products.where((p) => p.category == _category).toList();

            return Column(
              children: [
                if (categories.length > 1)
                  _buildCategoryChips(categories),
                Expanded(child: _buildGrid(visible)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const _CartBar(),
    );
  }

  List<String> _categoriesOf(List<Product> products) {
    final named = products
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return [_allCategories, ...named];
  }

  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == _category;
          return ChoiceChip(
            label: Text(category == _allCategories ? 'All' : category),
            selected: selected,
            onSelected: (_) => setState(() => _category = category),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
                color: selected ? AppTheme.primaryColor : Colors.grey.shade300),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<Product> products) {
    final sorted = List<Product>.from(products)
      ..sort((a, b) => a.name.compareTo(b.name));

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _MenuTile(
        product: sorted[index],
        onTap: () => _addToOrder(sorted[index]),
      ),
    );
  }

  Future<void> _addToOrder(Product product) async {
    if (!product.hasVariants) {
      context.read<BillingBloc>().add(AddProductToCartEvent(product));
      return;
    }

    final variant = await showModalBottomSheet<ProductVariant>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(product.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Choose a size',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            ...product.variants.map(
              (variant) => ListTile(
                title: Text(variant.label),
                trailing: Text(
                  money(variant.price),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => Navigator.pop(sheetContext, variant),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (variant != null && mounted) {
      context
          .read<BillingBloc>()
          .add(AddProductToCartEvent(product, variant: variant));
    }
  }

  Widget _buildEmptyMenu(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_cafe_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Your menu is empty',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Add a few items and they will show up here ready to tap.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/menu'),
              icon: const Icon(Icons.add),
              label: const Text('Go to Menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _MenuTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15, height: 1.25),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  product.hasVariants
                      ? 'from ${money(product.displayPrice)}'
                      : money(product.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                  ),
                ),
                if (product.hasVariants) ...[
                  const Spacer(),
                  Icon(Icons.tune, size: 14, color: Colors.grey[400]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Persistent summary bar. Tapping it opens the cart; the button goes to
/// checkout.
class _CartBar extends StatelessWidget {
  const _CartBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingBloc, BillingState>(
      builder: (context, state) {
        if (state.isEmpty) return const SizedBox.shrink();

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => CartSheet.show(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.expand_less, color: Colors.white70),
                          const SizedBox(width: 10),
                          Text(
                            '${state.itemCount} '
                            '${state.itemCount == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            money(state.totalAmount),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton(
                    onPressed: () => context.push('/checkout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Review'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
