import 'package:cafe_pos/core/utils/pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PinHasher', () {
    test('verifies the PIN it hashed', () {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hash('1234', salt);

      expect(
        PinHasher.verify(pin: '1234', salt: salt, expectedHash: hash),
        isTrue,
      );
    });

    test('rejects the wrong PIN', () {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hash('1234', salt);

      expect(
        PinHasher.verify(pin: '4321', salt: salt, expectedHash: hash),
        isFalse,
      );
    });

    test('never stores the PIN in the hash', () {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hash('1234', salt);

      expect(hash.contains('1234'), isFalse);
    });

    test('the same PIN under different salts gives different hashes', () {
      final hashA = PinHasher.hash('1234', PinHasher.generateSalt());
      final hashB = PinHasher.hash('1234', PinHasher.generateSalt());

      // Two staff who happen to pick the same PIN must not be recognisable
      // as having done so by looking at the database.
      expect(hashA, isNot(equals(hashB)));
    });

    test('salts are unique per call', () {
      final salts = List.generate(50, (_) => PinHasher.generateSalt());

      expect(salts.toSet().length, 50);
    });

    test('a PIN verified against another salt fails', () {
      final saltA = PinHasher.generateSalt();
      final saltB = PinHasher.generateSalt();
      final hash = PinHasher.hash('1234', saltA);

      expect(
        PinHasher.verify(pin: '1234', salt: saltB, expectedHash: hash),
        isFalse,
      );
    });
  });
}
