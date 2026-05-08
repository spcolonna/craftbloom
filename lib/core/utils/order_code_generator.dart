import 'dart:math';
import 'package:craftbloom/core/config/app_config.dart';

abstract final class OrderCodeGenerator {
  static final _random = Random.secure();
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate() {
    final buffer = StringBuffer(AppConfig.orderCodePrefix);
    buffer.write('-');
    for (var i = 0; i < AppConfig.orderCodeRandomChars; i++) {
      buffer.write(_chars[_random.nextInt(_chars.length)]);
    }
    return buffer.toString(); // Ej: CB-A4F7K2 (9 chars, dentro del límite de 12)
  }
}
