import 'dart:async';

import 'package:flutter/services.dart';
import 'package:chabokpush/ChabokEvent.dart';
import 'package:chabokpush/ChabokMessage.dart';

// Handlers for various events
typedef void onMessageHandler(ChabokMessage message);

class ChabokPush {
  // event handlers
  onMessageHandler _onMessageHandler;

  static ChabokPush _singleToneInstance = null;
  static const MethodChannel _channel =
      const MethodChannel('chabokpush');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static ChabokPush get get {
    return _singleToneInstance;
  }

  static ChabokPush init (appId, apiKey, username, password, senderId, devMode) {
    if (_singleToneInstance != null){
      return _singleToneInstance;
    }

    var state = _channel.invokeMethod("init",<String, dynamic>{
      'appId': appId,
      'apiKey': apiKey,
      'username': username,
      'password': password,
      'senderId': senderId,
      'devMode': devMode
    }).catchError((e) {
      print(e);
      throw new Exception(e);
    });

    print(state);

    _singleToneInstance = new ChabokPush._();
    return _singleToneInstance;
  }

  Future<String> register(String userId){
    return _channel.invokeMethod("register", <String, dynamic> {
      'userId': userId
    });
  }

  Future<String> registerAsGuest([String guestId]){
    var param = <String, dynamic> {};
    if (guestId != null){
      param['guestId'] = guestId;
    }
    return _channel.invokeMethod("registerAsGuest", param);
  }

  unregister(){
    _channel.invokeMethod("unregister");
  }

  publish(ChabokMessage message){
    var msgMap = <String, dynamic>{
      'userId': message.userId,
      'content': message.content
    };

    if(message.channel != null){
      msgMap['channel'] = message.channel;
    }

    if(message.data != null){
      msgMap['data'] = message.data;
    }

    if(message.notification != null){
      msgMap['notification'] = message.notification;
    }

    _channel.invokeMethod("publish", msgMap);
  }

  //=============== Custom data

  track(String trackName,[ dynamic arguments ]){
    if (trackName == null || trackName.trim().length == 0){
      throw new Exception("trackName is invalid. Please provide a valid name for track");
    }

    var params = <String, dynamic> {
      'data': arguments,
      'trackName': trackName
    };

    _channel.invokeMethod("track", params);
  }

  trackPurchase(String trackName, ChabokEvent chabokEvent){
    if (trackName == null || trackName.trim().length == 0){
      throw new Exception("trackName is invalid. Please provide a valid name for track");
    }

    var data = <String, dynamic> {
      'revenue': chabokEvent.revenue
    };

    if (chabokEvent.currency != null){
      data['currency'] = chabokEvent.currency;
    }

    if (chabokEvent.data != null){
      data['data'] = chabokEvent.data;
    }

    var params = <String, dynamic> {
      'eventData': data,
      'trackName': trackName
    };

    _channel.invokeMethod("trackPurchase", params);
  }

  addTag(tagName){
    if (tagName == null || tagName.trim().length == 0){
      throw new Exception("tagName is invalid. Please provide a valid name for tag");
    }
    _channel.invokeMethod("addTag", <String, dynamic> {
      'tagName': tagName
    });
  }

  removeTag(tagName){
    if (tagName == null || tagName.trim().length == 0){
      throw new Exception("tagName is invalid. Please provide a valid name for tag");
    }
    _channel.invokeMethod("removeTag", <String, dynamic> {
      'tagName': tagName
    });
  }

  setUserAttributes(dynamic attributes){
    _channel.invokeMethod("setUserAttributes", attributes);
  }

  Future<String> getUserId(){
    return _channel.invokeMethod("getUserId");
  }

  Future<String> getInstallationId(){
    return _channel.invokeMethod("getInstallationId");
  }

  void setOnMessageCallback(Function callback){
    this._onMessageHandler = callback;
  }

  ChabokPush._(){
    _channel.setMethodCallHandler(_handleMethod);
  }

  // Private function that gets called by ObjC/Java
  Future<Null> _handleMethod(MethodCall call) async {
    print('ccccaaaaaallllleeeedddddd = ' + call.arguments);
    if (call.method == 'onMessageHandler'){
       this._onMessageHandler(call.arguments.cast<String, dynamic>());
    }
    return null;
  }
}
