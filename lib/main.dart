import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/routes/app_routes.dart';
import 'core/data/hive_database.dart';
import 'core/data/sample_menu.dart';
import 'core/service_locator.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/activity/domain/repositories/activity_log_repository.dart';
import 'features/activity/presentation/bloc/activity_bloc.dart';
import 'features/billing/presentation/bloc/billing_bloc.dart';
import 'features/expenses/presentation/bloc/expense_bloc.dart';
import 'features/orders/presentation/bloc/order_history_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/reports/presentation/bloc/report_bloc.dart';
import 'features/settings/presentation/bloc/printer_bloc.dart';
import 'features/settings/presentation/bloc/printer_event.dart';
import 'features/shop/presentation/bloc/shop_bloc.dart';
import 'features/staff/presentation/bloc/auth_bloc.dart';
import 'features/staff/presentation/bloc/staff_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabase.init();
  await di.init();

  // Keep the log from growing without bound, and give a fresh install a menu.
  await di.sl<ActivityLogRepository>().prune();
  await SampleMenu.seedIfEmpty();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // The router's redirect reads this bloc directly, so it has to be the same
  // instance the widget tree provides.
  final AuthBloc _authBloc = di.sl<AuthBloc>();
  late final _router = createRouter(_authBloc);

  @override
  void initState() {
    super.initState();
    _authBloc.add(AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<BillingBloc>.value(value: di.sl<BillingBloc>()),
        BlocProvider<ProductBloc>(
            create: (context) => di.sl<ProductBloc>()..add(LoadProducts())),
        BlocProvider<ShopBloc>(
            create: (context) => di.sl<ShopBloc>()..add(LoadShopEvent())),
        BlocProvider<PrinterBloc>(
            create: (context) => di.sl<PrinterBloc>()..add(InitPrinterEvent())),
        BlocProvider<OrderHistoryBloc>(
            create: (context) => di.sl<OrderHistoryBloc>()),
        BlocProvider<ExpenseBloc>(create: (context) => di.sl<ExpenseBloc>()),
        BlocProvider<ReportBloc>(create: (context) => di.sl<ReportBloc>()),
        BlocProvider<StaffBloc>(create: (context) => di.sl<StaffBloc>()),
        BlocProvider<ActivityBloc>(create: (context) => di.sl<ActivityBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Café POS',
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
