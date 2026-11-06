import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import '../utils/app_uuid.dart';

/// Local screen-lock PIN. This is deliberately not the backend PIN: it only
/// guards the device session and is never sent to the server.
class PinService {
  static const int _iterations = 60000;

  Future<String> newSalt() async => randomSecretBase64(16);

  Future<String> hash(String pin, String salt) {
    return Isolate.run(() => _derive(pin, salt, _iterations));
  }

  Future<bool> verify({
    required String pin,
    required String hash,
    required String salt,
  }) async {
    final candidate = await this.hash(pin, salt);
    return _constantTimeEquals(candidate, hash);
  }

  static String _derive(String pin, String salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    var block = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
    final result = List<int>.from(block);
    for (var round = 1; round < iterations; round++) {
      block = hmac.convert(block).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= block[index];
      }
    }
    return base64Encode(result);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var index = 0; index < a.length; index++) {
      diff |= a.codeUnitAt(index) ^ b.codeUnitAt(index);
    }
    return diff == 0;
  }
}
