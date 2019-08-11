import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chabokpush/chabokpush.dart';

void main() {
  const MethodChannel channel = MethodChannel('chabokpush');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await ChabokPush.platformVersion, '42');
  });
}
