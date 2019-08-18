import 'dart:async';

import 'package:flutter/services.dart';
import 'package:chabokpush/ChabokEvent.dart';
import 'package:chabokpush/ChabokMessage.dart';

// Handlers for various events
typedef void onMessageHandler(dynamic);
typedef void onShowNotificationHandler(dynamic);
typedef void onNotificationOpenedHandler(dynamic);
typedef void onConnectionHandler(String connectionStatus);


class ChabokPush {
  // event handlers
  onMessageHandler _onMessageHandler;
  onConnectionHandler _onConnectionHandler;
  onShowNotificationHandler _onShowNotificationHandler;
  onNotificationOpenedHandler _onNotificationOpenedHandler;

  static ChabokPush _singleToneInstance;
  static const MethodChannel _channel =
      const MethodChannel('chabokpush');

  static ChabokPush get shared {
    if (_singleToneInstance == null){
      _singleToneInstance = new ChabokPush._();
    }

    return _singleToneInstance;
  }

  static init (appId, apiKey, username, password, senderId, devMode) {
    _channel.invokeMethod("init",<String, dynamic>{
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

  void setOnMessageCallback(callback){
    if (callback == null){
      print("Callback  parameter in setOnMessageCallback method is required.");
      return;
    }
    this._onMessageHandler = callback;
  }

  void setOnNotificationOpenedHandler(Function callback){
    if (callback == null){
      print("Callback  parameter in setOnNotificationOpenedHandler method is required.");
      return;
    }
    this._onNotificationOpenedHandler = callback;
  }

  void setOnShowNotificationHandler(Function callback){
    if (callback == null){
      print("Callback  parameter in setOnShowNotificationHandler method is required.");
      return;
    }
    this._onShowNotificationHandler = callback;
  }

  void setOnConnectionHandler(Function callback){
    if (callback == null){
      print("Callback  parameter in setOnConnectionHandler method is required.");
      return;
    }
    this._onConnectionHandler = callback;
  }

  ChabokPush._(){
    _channel.setMethodCallHandler(_handleMethod);
  }

  // Private function that gets called by ObjC/Java
  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method.contains('onMessageHandler')){
      if (this._onMessageHandler != null){
         this._onMessageHandler(call.arguments);
       }
    } else if (call.method.contains('onConnectionHandler')) {
      if(this._onConnectionHandler != null) {
        this._onConnectionHandler(call.arguments);
      }
    } else if (call.method.contains('onShowNotificationHandler')) {
      if (this._onShowNotificationHandler != null){
        this._onShowNotificationHandler(call.arguments);
      }
    } else if (call.method.contains('onNotificationOpenedHandler')) {
      if (this._onNotificationOpenedHandler != null) {
        this._onNotificationOpenedHandler(call.arguments);
      }
    }
    return null;
  }
}
