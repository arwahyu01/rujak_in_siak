import 'dart:convert';
import 'dart:math';

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newUuid() => _uuid.v4();

String randomSecretBase64([int bytes = 32]) {
  final random = Random.secure();
  final values = List<int>.generate(bytes, (_) => random.nextInt(256));
  return base64Encode(values);
}
