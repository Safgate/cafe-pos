import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../staff/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_history_bloc.dart';

class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Order #${order.orderNumber}',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (order.voided) _buildVoidBanner(),
          _buildMeta(),
          const SizedBox(height: 20),
          ...order.lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text('${line.quantity}x',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text('${money(line.unitPrice)} each',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Text(money(line.lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1)),
              Text(
                money(order.total),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildActions(context, auth),
        ],
      ),
    );
  }

  Widget _buildVoidBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('This order was voided',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Reason: ${order.voidReason}',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            'By ${order.voidedByStaffName} on '
            '${DateFormat('d MMM yyyy, HH:mm').format(order.voidedAt!)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          const Text(
            'It stays in the history but does not count towards revenue.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _metaRow('Taken',
              DateFormat('d MMM yyyy, HH:mm').format(order.createdAt)),
          _metaRow('Served by', order.createdByStaffName),
          if (order.wasEdited) ...[
            _metaRow('Edited',
                '${order.revision} ${order.revision == 1 ? 'time' : 'times'}'),
            _metaRow(
              'Last edit',
              '${order.lastEditedByStaffName}, '
                  '${DateFormat('d MMM, HH:mm').format(order.updatedAt!)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, AuthState auth) {
    final shopState = context.watch<ShopBloc>().state;
    final shop = shopState is ShopLoaded ? shopState.shop : const Shop();

    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            context.read<BillingBloc>().add(ReprintReceiptEvent(
                  order: order,
                  shopName: shop.name,
                  address1: shop.addressLine1,
                  address2: shop.addressLine2,
                  phone: shop.phoneNumber,
                  footer: shop.footerText,
                ));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sending to printer…')),
            );
          },
          icon: const Icon(Icons.print),
          label: const Text('Reprint Receipt'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48)),
        ),
        if (!order.voided && auth.canEditOrders) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _startEdit(context),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Order'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
        if (!order.voided && auth.canVoidOrders) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _confirmVoid(context),
            icon: const Icon(Icons.block),
            label: const Text('Void Order'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
        if (!order.voided && !auth.canEditOrders) ...[
          const SizedBox(height: 16),
          const Text(
            'Only an owner can edit or void an order.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  void _startEdit(BuildContext context) {
    final products = context.read<ProductBloc>().state.products;
    context.read<BillingBloc>().add(StartEditingOrderEvent(
          order: order,
          currentProducts: products,
        ));
    context.go('/');
  }

  Future<void> _confirmVoid(BuildContext context) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Void this order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The order is kept and stays visible in history, but stops '
              'counting towards revenue. Say why:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. customer cancelled',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return; // a reason is required
              Navigator.pop(dialogContext, text);
            },
            child: const Text('Void', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    controller.dispose();
    if (reason == null || !context.mounted) return;

    context
        .read<OrderHistoryBloc>()
        .add(VoidOrderRequested(orderId: order.id, reason: reason));
    context.pop();
  }
}
