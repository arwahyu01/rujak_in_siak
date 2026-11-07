import '../../core/utils/json_utils.dart';

class AppUser {
  const AppUser({
    required this.uuid,
    required this.name,
    this.email,
    this.username,
    this.phone,
    this.businessUuid,
    this.outletUuid,
    this.roles = const [],
    this.permissions = const [],
    this.hasPin = false,
    this.authenticationVersion = 0,
  });

  final String uuid;
  final String name;
  final String? email;
  final String? username;
  final String? phone;
  final String? businessUuid;
  final String? outletUuid;
  final List<String> roles;
  final List<String> permissions;
  final bool hasPin;
  final int authenticationVersion;

  bool get isOwner => roles.contains('owner');

  bool can(String permission) => permissions.contains(permission);

  bool canAny(Iterable<String> values) => values.any(permissions.contains);

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uuid: asStringOr(json['uuid'], ''),
      name: asStringOr(json['name'], 'Pengguna'),
      email: asStringOrNull(json['email']),
      username: asStringOrNull(json['username']),
      phone: asStringOrNull(json['phone']),
      businessUuid: asStringOrNull(json['business_id']),
      outletUuid: asStringOrNull(json['outlet_id']),
      roles: asStringList(json['roles']),
      permissions: asStringList(json['permissions']),
      hasPin: asBool(json['has_pin']),
      authenticationVersion: asIntOr(json['authentication_version'], 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'email': email,
    'username': username,
    'phone': phone,
    'business_id': businessUuid,
    'outlet_id': outletUuid,
    'roles': roles,
    'permissions': permissions,
    'has_pin': hasPin,
    'authentication_version': authenticationVersion,
  };
}

class AppDevice {
  const AppDevice({
    required this.uuid,
    required this.name,
    required this.terminalCode,
    this.status = 'active',
    this.outletUuid,
    this.outletName,
    this.outletCode,
    this.lastSequence = 0,
  });

  final String uuid;
  final String name;
  final String terminalCode;
  final String status;
  final String? outletUuid;
  final String? outletName;
  final String? outletCode;
  final int lastSequence;

  bool get isActive => status == 'active';

  factory AppDevice.fromJson(Map<String, dynamic> json) {
    final outlet = asMapOrNull(json['outlet']);
    return AppDevice(
      uuid: asStringOr(json['uuid'], ''),
      name: asStringOr(json['name'], 'Perangkat'),
      terminalCode: asStringOr(json['terminal_code'], 'POS1'),
      status: asStringOr(json['status'], 'active'),
      outletUuid: outlet == null ? null : asStringOrNull(outlet['uuid']),
      outletName: outlet == null ? null : asStringOrNull(outlet['name']),
      outletCode: outlet == null ? null : asStringOrNull(outlet['code']),
      lastSequence: asIntOr(json['last_sequence'], 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'terminal_code': terminalCode,
    'status': status,
    'last_sequence': lastSequence,
    'outlet': outletUuid == null
        ? null
        : {'uuid': outletUuid, 'name': outletName, 'code': outletCode},
  };
}

class OfflineLease {
  const OfflineLease({
    required this.token,
    required this.id,
    this.issuedAt,
    this.expiresAt,
    this.permissions = const [],
    this.roles = const [],
  });

  final String token;
  final String id;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final List<String> permissions;
  final List<String> roles;

  bool get isExpired => expiresAt == null || DateTime.now().isAfter(expiresAt!);

  Duration get remaining {
    if (expiresAt == null) return Duration.zero;
    final value = expiresAt!.difference(DateTime.now());
    return value.isNegative ? Duration.zero : value;
  }

  factory OfflineLease.fromJson(Map<String, dynamic> json) {
    final lease = asMapOrNull(json['lease']) ?? const {};
    final merged = {...lease, ...json};
    return OfflineLease(
      token: asStringOr(json['token'], ''),
      id: asStringOr(merged['id'], ''),
      issuedAt: asDate(merged['issued_at']),
      expiresAt: asDate(merged['expires_at']),
      permissions: asStringList(merged['permissions']),
      roles: asStringList(merged['roles']),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'lease': {
      'id': id,
      'issued_at': issuedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'permissions': permissions,
      'roles': roles,
    },
  };
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.sessionUuid,
    required this.user,
    this.tokenExpiresAt,
    this.device,
    this.lease,
    this.baseUrl,
  });

  final String token;
  final String sessionUuid;
  final AppUser user;
  final DateTime? tokenExpiresAt;
  final AppDevice? device;
  final OfflineLease? lease;
  final String? baseUrl;

  bool get hasToken =>
      token.isNotEmpty &&
      (tokenExpiresAt == null || DateTime.now().isBefore(tokenExpiresAt!));

  bool get leaseValid => lease != null && !lease!.isExpired;

  AuthSession copyWith({
    String? token,
    String? sessionUuid,
    AppUser? user,
    DateTime? tokenExpiresAt,
    AppDevice? device,
    OfflineLease? lease,
    String? baseUrl,
  }) {
    return AuthSession(
      token: token ?? this.token,
      sessionUuid: sessionUuid ?? this.sessionUuid,
      user: user ?? this.user,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      device: device ?? this.device,
      lease: lease ?? this.lease,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final leaseJson = asMapOrNull(json['offline_lease']);
    return AuthSession(
      token: asStringOr(json['token'], ''),
      sessionUuid: asStringOr(json['session_uuid'], ''),
      user: AppUser.fromJson(asMap(json['user'])),
      tokenExpiresAt: asDate(json['expires_at']),
      device: json['device'] == null
          ? null
          : AppDevice.fromJson(asMap(json['device'])),
      lease: leaseJson == null ? null : OfflineLease.fromJson(leaseJson),
      baseUrl: asStringOrNull(json['base_url']),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'session_uuid': sessionUuid,
    'user': user.toJson(),
    'expires_at': tokenExpiresAt?.toIso8601String(),
    'device': device?.toJson(),
    'offline_lease': lease?.toJson(),
    'base_url': baseUrl,
  };
}
