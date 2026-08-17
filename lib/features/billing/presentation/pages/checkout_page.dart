import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';
import '../widgets/cart_sheet.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingBloc, BillingState>(
      builder: (context, billingState) {
        if (billingState.completedOrder != null) {
          return _OrderCompleteView(state: billingState);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              billingState.isEditing ? 'Save Changes' : 'Checkout',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 28, color: Theme.of(context).primaryColor),
              // Going back keeps the cart — only an explicit Clear empties it.
              onPressed: () => context.pop(),
            ),
          ),
          body: BlocBuilder<ShopBloc, ShopState>(
            builder: (context, shopState) {
              final shop =
                  shopState is ShopLoaded ? shopState.shop : const Shop();

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        ...billingState.cartItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CartLineTile(item: item),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (shop.upiId.isNotEmpty)
                          _buildPaymentQr(shop, billingState.totalAmount),
                      ],
                    ),
                  ),
                  _buildTotalBar(context, billingState, shop),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentQr(Shop shop, double total) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Scan to Pay',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1)),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: PrettyQrView.data(
              data: 'upi://pay?pa=${shop.upiId}&pn=${shop.name}'
                  '&am=${total.toStringAsFixed(2)}&cu=INR',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBar(
      BuildContext context, BillingState state, Shop shop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GRAND TOTAL',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.2)),
                Text(
                  money(state.totalAmount),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          PrimaryButton(
            onPressed: state.isEmpty
                ? null
                : () => context.read<BillingBloc>().add(CompleteOrderEvent(
                      shopName: shop.name,
                      address1: shop.addressLine1,
                      address2: shop.addressLine2,
                      phone: shop.phoneNumber,
                      footer: shop.footerText,
                    )),
            isLoading: state.isSaving,
            icon: state.isEditing ? Icons.save : Icons.check_circle,
            label: state.isEditing ? 'Save Changes' : 'Complete Order',
          ),
        ],
      ),
    );
  }
}

/// Shown once the order is safely stored.
///
/// The confirmation is keyed off the *save*, not the print — the sale is
/// recorded whether or not the printer cooperated, and the panel says so
/// plainly rather than presenting a failed print as a failed order.
class _OrderCompleteView extends StatelessWidget {
  final BillingState state;

  const _OrderCompleteView({required this.state});

  @override
  Widget build(BuildContext context) {
    final order = state.completedOrder!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  size: 72, color: Color(0xFF16A34A)),
              const SizedBox(height: 20),
              Text(
                state.wasEdit ? 'Order updated' : 'Order saved',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Order #${order.orderNumber}',
                  style: const TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 24),
              Text(
                money(order.total),
                style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 28),
              if (state.isPrinting)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Printing receipt…',
                        style: TextStyle(color: Colors.grey)),
                  ],
                )
              else if (state.printMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state.printFailed
                        ? Colors.amber.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.printFailed
                            ? Icons.print_disabled
                            : Icons.print,
                        size: 18,
                        color: state.printFailed
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(state.printMessage!,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              PrimaryButton(
                onPressed: () {
                  context.read<BillingBloc>().add(AcknowledgeCompletionEvent());
                  context.go('/');
                },
                icon: Icons.point_of_sale,
                label: 'Next Order',
              ),
              TextButton(
                onPressed: () {
                  context.read<BillingBloc>().add(AcknowledgeCompletionEvent());
                  context.go('/history');
                },
                child: const Text('View in order history'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
