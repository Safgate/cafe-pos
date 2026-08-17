import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_range.dart';
import '../../features/activity/presentation/pages/activity_log_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../features/orders/domain/entities/order.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/presentation/pages/order_history_page.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/reports/presentation/pages/dashboard_page.dart';
import '../../features/reports/presentation/pages/report_drilldown_page.dart';
import '../../features/settings/presentation/pages/more_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/staff/domain/entities/staff.dart';
import '../../features/staff/presentation/bloc/auth_bloc.dart';
import '../../features/staff/presentation/pages/lock_screen_page.dart';
import '../../features/staff/presentation/pages/staff_form_page.dart';
import '../../features/staff/presentation/pages/staff_list_page.dart';
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    // Start locked rather than showing the till for a frame before the auth
    // check lands.
    initialLocation: '/lock',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),

    // Nothing but the lock screen is reachable until someone signs in.
    redirect: (context, state) {
      final authState = authBloc.state;
      final atLock = state.matchedLocation == '/lock';

      if (authState.status == AuthStatus.unknown) return null;
      if (!authState.isLoggedIn) return atLock ? null : '/lock';
      if (atLock) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreenPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Order
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'checkout',
                    builder: (context, state) => const CheckoutPage(),
                  ),
                ],
              ),
            ],
          ),

          // History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const OrderHistoryPage(),
                routes: [
                  GoRoute(
                    path: 'order/:id',
                    builder: (context, state) {
                      final order = state.extra as Order?;
                      // Reached without the order in hand (e.g. a deep link).
                      if (order == null) return const OrderHistoryPage();
                      return OrderDetailPage(order: order);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) {
                  if (!authBloc.state.canViewReports) {
                    return const RestrictedPage(
                      title: 'Reports',
                      message:
                          'Reports are visible to owners only. Ask an owner '
                          'to sign in if you need the figures.',
                    );
                  }
                  return const DashboardPage();
                },
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final args = state.extra as Map<String, dynamic>?;
                      final range =
                          args?['range'] as DateRange? ?? DateRange.today();
                      return ReportDrilldownPage(
                        range: range,
                        initialTab: (args?['tab'] as int?) ?? 0,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Menu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/menu',
                builder: (context, state) {
                  if (!authBloc.state.canManageMenu) {
                    return const RestrictedPage(
                      title: 'Menu',
                      message:
                          'Only an owner can change the menu. You can still '
                          'take orders from the Order tab.',
                    );
                  }
                  return const ProductListPage();
                },
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddProductPage(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) {
                      final product = state.extra as Product?;
                      if (product == null) return const ProductListPage();
                      return EditProductPage(product: product);
                    },
                  ),
                ],
              ),
            ],
          ),

          // More
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MorePage(),
                routes: [
                  GoRoute(
                    path: 'expenses',
                    builder: (context, state) => const ExpenseListPage(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (context, state) => const AddExpensePage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'staff',
                    builder: (context, state) => const StaffListPage(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (context, state) => const StaffFormPage(),
                      ),
                      GoRoute(
                        path: 'edit/:id',
                        builder: (context, state) => StaffFormPage(
                          existing: state.extra as Staff?,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'activity',
                    builder: (context, state) => const ActivityLogPage(),
                  ),
                  GoRoute(
                    path: 'shop',
                    builder: (context, state) => const ShopDetailsPage(),
                  ),
                  GoRoute(
                    path: 'printer',
                    builder: (context, state) => const SettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Nudges GoRouter to re-run its redirect whenever auth changes, so signing
/// in, locking or signing out moves the user without any screen having to
/// navigate by hand.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
