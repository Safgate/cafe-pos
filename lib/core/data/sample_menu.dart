import 'package:uuid/uuid.dart';

import '../../features/product/data/models/product_model.dart';
import '../../features/product/data/models/product_variant_model.dart';
import 'hive_database.dart';

/// Puts a small café menu in place on first launch, so a fresh install opens
/// on something you can actually tap rather than an empty grid.
class SampleMenu {
  const SampleMenu._();

  static const String _seededKey = 'sample_menu_seeded';

  static Future<void> seedIfEmpty() async {
    final settings = HiveDatabase.settingsBox;

    // Only ever seed once. An owner who clears the menu on purpose should not
    // find it refilled the next time the app starts.
    if (settings.get(_seededKey) == true) return;
    if (HiveDatabase.productBox.isNotEmpty) {
      await settings.put(_seededKey, true);
      return;
    }

    const uuid = Uuid();
    final box = HiveDatabase.productBox;

    ProductModel item(
      String name,
      String category,
      double price, {
      List<(String, double)> sizes = const [],
    }) {
      return ProductModel(
        id: uuid.v4(),
        name: name,
        category: category,
        price: price,
        stock: 0,
        variants: sizes
            .map((s) => ProductVariantModel(label: s.$1, price: s.$2))
            .toList(),
      );
    }

    final samples = <ProductModel>[
      item('Espresso', 'Coffee', 2.20),
      item('Americano', 'Coffee', 2.60,
          sizes: const [('Small', 2.60), ('Large', 3.10)]),
      item('Latte', 'Coffee', 3.00,
          sizes: const [('Small', 2.80), ('Medium', 3.20), ('Large', 3.60)]),
      item('Cappuccino', 'Coffee', 3.00,
          sizes: const [('Small', 2.80), ('Large', 3.40)]),
      item('Flat White', 'Coffee', 3.20),
      item('Tea', 'Coffee', 2.20),
      item('Iced Latte', 'Cold Drinks', 3.40,
          sizes: const [('Regular', 3.40), ('Large', 3.90)]),
      item('Orange Juice', 'Cold Drinks', 2.80),
      item('Sparkling Water', 'Cold Drinks', 2.00),
      item('Croissant', 'Pastries', 2.50),
      item('Almond Croissant', 'Pastries', 3.00),
      item('Banana Bread', 'Pastries', 2.90),
    ];

    for (final product in samples) {
      await box.put(product.id, product);
    }

    await settings.put(_seededKey, true);
  }
}
