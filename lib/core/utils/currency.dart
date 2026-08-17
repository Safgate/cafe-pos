import '../data/hive_database.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/shop/data/repositories/shop_repository_impl.dart';

/// Fallback used before the owner has configured a shop, or if the box cannot
/// be read for any reason.
const String kDefaultCurrencySymbol = r'$';

/// The shop's configured currency symbol.
///
/// This reads the Hive box directly and synchronously rather than going through
/// [ShopBloc]. That is deliberate: `PrinterHelper` and the PDF report builder
/// format money without a `BuildContext`, and threading the symbol through every
/// widget would touch far more code than it earns.
String currencySymbol() {
  try {
    final ShopModel? shop =
        HiveDatabase.shopBox.get(ShopRepositoryImpl.shopKey);
    final symbol = shop?.currencySymbol.trim() ?? '';
    return symbol.isEmpty ? kDefaultCurrencySymbol : symbol;
  } catch (_) {
    return kDefaultCurrencySymbol;
  }
}

/// Formats an amount for display: `$4.50`.
String money(double amount) =>
    '${currencySymbol()}${amount.toStringAsFixed(2)}';

/// Formats an amount without the symbol, for thermal receipt columns where
/// width is tight and the symbol is already in the header.
String amountOnly(double amount) => amount.toStringAsFixed(2);
