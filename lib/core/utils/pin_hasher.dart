import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 for staff PINs.
///
/// Be clear-eyed about what this buys. A 4-digit PIN has 10,000 possible
/// values, so anyone holding the phone and the Hive file can brute-force it in
/// moments regardless of the hashing. The point here is narrower: a colleague
/// who opens the database cannot simply *read* everyone's PIN, and PINs are
/// never written to disk in the clear. The real security boundary is the
/// device lock and physical control of the phone — the UI should not claim
/// otherwise.
class PinHasher {
  static const int _saltBytes = 16;

  static String generateSalt([Random? random]) {
    final rnd = random ?? Random.secure();
    final bytes = List<int>.generate(_saltBytes, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  static bool verify({
    required String pin,
    required String salt,
    required String expectedHash,
  }) {
    return _constantTimeEquals(hash(pin, salt), expectedHash);
  }

  /// Comparison that does not return early on the first differing character.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
