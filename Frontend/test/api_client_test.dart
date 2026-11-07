import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/network/api_client.dart';

void main() {
  test('configuring a token keeps the previously configured device id', () {
    final api = ApiClient();
    api.configure(baseUrl: 'http://localhost', deviceUuid: 'device-1');

    api.configure(token: 'token-1');

    expect(api.deviceUuid, 'device-1');
  });

  test('explicit null still clears the device id', () {
    final api = ApiClient()
      ..configure(deviceUuid: 'device-1')
      ..configure(deviceUuid: null);

    expect(api.deviceUuid, isNull);
  });
}
