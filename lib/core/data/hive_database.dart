import 'package:hive_flutter/hive_flutter.dart';
import '../../features/activity/data/models/activity_log_model.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../../features/orders/data/models/order_line_model.dart';
import '../../features/orders/data/models/order_model.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/data/models/product_variant_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/staff/data/models/staff_model.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String orderBoxName = 'orders';
  static const String expenseBoxName = 'expenses';
  static const String staffBoxName = 'staff';
  static const String activityLogBoxName = 'activity_log';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters. TypeIds are permanent — never renumber them.
    Hive.registerAdapter(ProductModelAdapter()); // 0
    Hive.registerAdapter(ShopModelAdapter()); // 1
    Hive.registerAdapter(ProductVariantModelAdapter()); // 2
    Hive.registerAdapter(OrderModelAdapter()); // 3
    Hive.registerAdapter(OrderLineModelAdapter()); // 4
    Hive.registerAdapter(ExpenseModelAdapter()); // 5
    Hive.registerAdapter(StaffModelAdapter()); // 6
    Hive.registerAdapter(ActivityLogModelAdapter()); // 7

    // Open Boxes
    await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<ShopModel>(shopBoxName);
    await Hive.openBox(settingsBoxName); // Generic box for simple key-value
    await Hive.openBox<OrderModel>(orderBoxName);
    await Hive.openBox<ExpenseModel>(expenseBoxName);
    await Hive.openBox<StaffModel>(staffBoxName);
    await Hive.openBox<ActivityLogModel>(activityLogBoxName);
  }

  static Box<ProductModel> get productBox =>
      Hive.box<ProductModel>(productBoxName);
  static Box<ShopModel> get shopBox => Hive.box<ShopModel>(shopBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box<OrderModel> get orderBox => Hive.box<OrderModel>(orderBoxName);
  static Box<ExpenseModel> get expenseBox =>
      Hive.box<ExpenseModel>(expenseBoxName);
  static Box<StaffModel> get staffBox => Hive.box<StaffModel>(staffBoxName);
  static Box<ActivityLogModel> get activityLogBox =>
      Hive.box<ActivityLogModel>(activityLogBoxName);
}
