import 'package:flutter/services.dart';

enum BluetoothPermissionState {
  granted,
  denied,
  permanentlyDenied,
  unavailable;

  static BluetoothPermissionState fromPlatformValue(String? value) {
    return switch (value) {
      'granted' => granted,
      'permanentlyDenied' => permanentlyDenied,
      'denied' => denied,
      _ => unavailable,
    };
  }
}

abstract class BluetoothPermissionService {
  Future<BluetoothPermissionState> status();
  Future<BluetoothPermissionState> request();
  Future<bool> openAppSettings();
}

class AndroidBluetoothPermissionService implements BluetoothPermissionService {
  static const _channel = MethodChannel(
    'com.talagacoffee.pos/bluetooth_permissions',
  );

  @override
  Future<BluetoothPermissionState> status() async {
    try {
      final value = await _channel.invokeMethod<String>('status');
      return BluetoothPermissionState.fromPlatformValue(value);
    } on PlatformException {
      return BluetoothPermissionState.unavailable;
    } on MissingPluginException {
      return BluetoothPermissionState.unavailable;
    }
  }

  @override
  Future<BluetoothPermissionState> request() async {
    try {
      final value = await _channel.invokeMethod<String>('request');
      return BluetoothPermissionState.fromPlatformValue(value);
    } on PlatformException {
      return BluetoothPermissionState.denied;
    } on MissingPluginException {
      return BluetoothPermissionState.unavailable;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
