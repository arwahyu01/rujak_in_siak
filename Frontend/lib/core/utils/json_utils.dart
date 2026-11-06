Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

List<dynamic> asList(dynamic value) =>
    value is List ? value : const <dynamic>[];

String? asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String asStringOr(dynamic value, String fallback) =>
    asString(value) ?? fallback;

String? asStringOrNull(dynamic value) => asString(value);

List<String> asStringList(dynamic value) =>
    asList(value).map(asString).whereType<String>().toList(growable: false);

int asIntOr(dynamic value, int fallback) => asInt(value, fallback);

int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

DateTime? asDate(dynamic value) {
  final text = asString(value);
  if (text == null) return null;
  return DateTime.tryParse(text)?.toLocal();
}

Map<String, dynamic>? asMapOrNull(dynamic value) {
  final map = asMap(value);
  return map.isEmpty ? null : map;
}

List<Map<String, dynamic>> asMapList(dynamic value) =>
    asList(value).map(asMap).where((item) => item.isNotEmpty).toList();
