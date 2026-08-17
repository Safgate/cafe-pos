import 'package:get_it/get_it.dart';

import '../features/activity/data/repositories/activity_log_repository_impl.dart';
import '../features/activity/domain/repositories/activity_log_repository.dart';
import '../features/activity/presentation/bloc/activity_bloc.dart';
import '../features/billing/presentation/bloc/billing_bloc.dart';
import '../features/expenses/data/repositories/expense_repository_impl.dart';
import '../features/expenses/domain/repositories/expense_repository.dart';
import '../features/expenses/presentation/bloc/expense_bloc.dart';
import '../features/orders/data/repositories/order_repository_impl.dart';
import '../features/orders/domain/repositories/order_repository.dart';
import '../features/orders/presentation/bloc/order_history_bloc.dart';
import '../features/product/data/repositories/product_repository_impl.dart';
import '../features/product/domain/repositories/product_repository.dart';
import '../features/product/domain/usecases/product_usecases.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../features/reports/data/report_exporter.dart';
import '../features/reports/domain/usecases/get_report_usecase.dart';
import '../features/reports/presentation/bloc/report_bloc.dart';
import '../features/settings/data/repositories/printer_repository_impl.dart';
import '../features/settings/domain/repositories/printer_repository.dart';
import '../features/settings/presentation/bloc/printer_bloc.dart';
import '../features/shop/data/repositories/shop_repository_impl.dart';
import '../features/shop/domain/repositories/shop_repository.dart';
import '../features/shop/domain/usecases/shop_usecases.dart';
import '../features/shop/presentation/bloc/shop_bloc.dart';
import '../features/staff/data/repositories/staff_repository_impl.dart';
import '../features/staff/domain/repositories/staff_repository.dart';
import '../features/staff/presentation/bloc/auth_bloc.dart';
import '../features/staff/presentation/bloc/staff_bloc.dart';
import 'services/activity_logger.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Activity log first: every other repository writes to it.
  sl.registerLazySingleton<ActivityLogRepository>(
    () => ActivityLogRepositoryImpl(),
  );
  sl.registerLazySingleton(() => ActivityLogger(sl()));

  // Repositories
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<PrinterRepository>(
    () => PrinterRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));
  sl.registerLazySingleton(
    () => GetReportUseCase(orderRepository: sl(), expenseRepository: sl()),
  );

  // Services
  sl.registerLazySingleton(
    () => ReportExporter(
      orderRepository: sl(),
      expenseRepository: sl(),
      logger: sl(),
    ),
  );

  // Blocs
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => ShopBloc(getShopUseCase: sl(), updateShopUseCase: sl()),
  );
  sl.registerFactory(() => PrinterBloc(repository: sl()));
  sl.registerFactory(() => StaffBloc(repository: sl()));

  // Singletons: the router reads AuthBloc directly for its redirect, and the
  // cart has to survive switching tabs.
  sl.registerLazySingleton(() => AuthBloc(repository: sl(), logger: sl()));
  sl.registerLazySingleton(() => BillingBloc(orderRepository: sl()));
  sl.registerFactory(() => OrderHistoryBloc(repository: sl()));
  sl.registerFactory(() => ExpenseBloc(repository: sl()));
  sl.registerFactory(() => ReportBloc(getReport: sl()));
  sl.registerFactory(() => ActivityBloc(repository: sl()));
}
