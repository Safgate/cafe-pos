import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/activity_logger.dart';
import '../../../activity/domain/entities/activity_log.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';
import '../models/shop_model.dart';

class ShopRepositoryImpl implements ShopRepository {
  static const String shopKey = 'shop_details';

  final ActivityLogger logger;

  ShopRepositoryImpl(this.logger);

  @override
  Future<Either<Failure, Shop>> getShop() async {
    try {
      final box = HiveDatabase.shopBox;
      final shop = box.get(shopKey);
      if (shop != null) {
        return Right(shop);
      } else {
        // Neutral placeholders until the owner fills in Shop Details.
        return const Right(Shop(
            name: 'My Café',
            addressLine1: '',
            addressLine2: '',
            phoneNumber: '',
            upiId: '',
            footerText: 'Thank you, see you again!',
            currencySymbol: r'$'));
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateShop(Shop shop) async {
    try {
      final box = HiveDatabase.shopBox;
      final before = box.get(shopKey);
      await box.put(shopKey, ShopModel.fromEntity(shop));

      final changes = <String>[];
      if (before != null && before.currencySymbol != shop.currencySymbol) {
        changes.add(
            'currency ${before.currencySymbol} to ${shop.currencySymbol}');
      }

      await logger.log(
        action: ActivityActions.shopUpdated,
        entityType: 'shop',
        summary: 'Shop details updated',
        details: changes.join('; '),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
