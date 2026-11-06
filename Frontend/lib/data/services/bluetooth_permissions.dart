import 'package:flutter/services.dart';

class BluetoothPermissions {
  const BluetoothPermissions._();

  static const _channel = MethodChannel('rujak_pos/bluetooth_permissions');

  static Future<bool> ensure() async {
    try {
      return await _channel.invokeMethod<bool>('ensure') ?? false;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return false;
    }
  }
}
