import 'package:intl/intl.dart';
import 'package:craftbloom/core/config/app_config.dart';

abstract final class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: AppConfig.locale,
    symbol: '${AppConfig.currencySymbol} ',
    decimalDigits: 0,
  );

  static String format(double amount) => _formatter.format(amount);

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${AppConfig.currencySymbol} ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${AppConfig.currencySymbol} ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return format(amount);
  }
}
