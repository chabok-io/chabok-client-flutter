import 'dart:async';

import 'package:flutter/services.dart';

class Chabokpush {
  static const MethodChannel _channel =
      const MethodChannel('chabokpush');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
