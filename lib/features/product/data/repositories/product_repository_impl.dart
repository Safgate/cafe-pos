import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/activity_logger.dart';
import '../../../../core/utils/currency.dart';
import '../../../activity/domain/entities/activity_log.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ActivityLogger logger;

  ProductRepositoryImpl(this.logger);

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final box = HiveDatabase.productBox;
      final products = box.values.map((p) => p.toEntity()).toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      final model = ProductModel.fromEntity(product);
      await box.put(model.id, model); // Using ID as key

      await logger.log(
        action: ActivityActions.itemCreated,
        entityType: 'item',
        entityId: product.id,
        summary: 'Added ${product.name} at ${_priceSummary(product)}',
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      final before = box.get(product.id);
      await box.put(product.id, ProductModel.fromEntity(product));

      // A price change is the edit most worth being able to explain later,
      // so it is spelled out rather than logged as "item changed".
      final changes = <String>[];
      if (before != null) {
        if (before.name != product.name) {
          changes.add('renamed from ${before.name}');
        }
        if (_priceSummary(before) != _priceSummary(product)) {
          changes.add(
              'price ${_priceSummary(before)} to ${_priceSummary(product)}');
        }
        if (before.category != product.category) {
          changes.add('category ${before.category} to ${product.category}');
        }
      }

      await logger.log(
        action: ActivityActions.itemUpdated,
        entityType: 'item',
        entityId: product.id,
        summary: 'Updated ${product.name}',
        details: changes.join('; '),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      final box = HiveDatabase.productBox;
      final existing = box.get(id);
      await box.delete(id);

      await logger.log(
        action: ActivityActions.itemDeleted,
        entityType: 'item',
        entityId: id,
        summary: 'Deleted ${existing?.name ?? 'menu item'}',
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  static String _priceSummary(Product product) {
    if (!product.hasVariants) return money(product.price);
    return product.variants
        .map((v) => '${v.label} ${money(v.price)}')
        .join(', ');
  }
}
