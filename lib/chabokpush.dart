import 'dart:async';

import 'package:flutter/services.dart';
import 'package:chabokpush/chabokEvent.dart';
import 'package:chabokpush/chabokMessage.dart';

// Handlers for various events
typedef void MessageHandler(dynamic);
typedef void ShowNotificationHandler(dynamic);
typedef void NotificationOpenedHandler(dynamic);
typedef void ConnectionHandler(String connectionStatus);

class ChabokPush {
  static ChabokPush _singleToneInstance;
  static const MethodChannel _channel = const MethodChannel('com.chabokpush.flutter/chabokpush');

  // event handlers
  MessageHandler _onMessageHandler;
  ConnectionHandler _onConnectionHandler;
  ShowNotificationHandler _onShowNotificationHandler;
  NotificationOpenedHandler _onNotificationOpenedHandler;

  ChabokPush._() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  static ChabokPush get shared {
    if (_singleToneInstance == null) {
      _singleToneInstance = new ChabokPush._();
    }

    return _singleToneInstance;
  }

  //=============== User Lifecycle

  Future<String> login(String userId) async {
    return _channel.invokeMethod("login", <String, dynamic> {
      'userId': userId
    });
  }

  logout() {
    _channel.invokeMethod("logout");
  }

  Future<String> getUserId() {
    return _channel.invokeMethod("getUserId");
  }

  Future<String> getInstallationId() {
    return _channel.invokeMethod("getInstallationId");
  }

  //=============== Publish Messages

  publish(ChabokMessage message) {
    var msgMap = <String, dynamic> {
      'userId': message.userId,
      'content': message.content
    };

    if(message.channel != null) {
      msgMap['channel'] = message.channel;
    }

    if(message.data != null) {
      msgMap['data'] = message.data;
    }

    if(message.notification != null) {
      msgMap['notification'] = message.notification;
    }

    _channel.invokeMethod("publish", msgMap);
  }

  //=============== User Attributes

  setUserAttributes(dynamic attributes) {
    _channel.invokeMethod("setUserAttributes", attributes);
  }

  unsetUserAttributes(List<String> attributes) {
    _channel.invokeMethod("unsetUserAttributes", attributes);
  }

  unsetUserAttribute(String attribute) {
    _channel.invokeMethod("unsetUserAttributes", [attribute]);
  }

  addToUserAttributeArray(String attributeKey, List<String> attributeValues) {
    _channel.invokeMethod("addToUserAttributeArray", <String, dynamic> {
      'attributeKey': attributeKey,
      'attributeValues': attributeValues
    });
  }

  removeFromUserAttributeArray(String attributeKey, List<String> attributeValues) {
    _channel.invokeMethod("removeFromUserAttributeArray", <String, dynamic> {
      'attributeKey': attributeKey,
      'attributeValue': attributeValues
    });
  }

  incrementUserAttribute(String attributeKey, [int attributeValue=1]) {
    _channel.invokeMethod("incrementUserAttribute", <String, dynamic> {
      'attributeKey': attributeKey,
      'attributeValue': attributeValue
    });
  }

  decrementUserAttribute(String attributeKey, [int attributeValue=1]) {
    _channel.invokeMethod("decrementUserAttribute", <String, dynamic> {
      'attributeKey': attributeKey,
      'attributeValue': attributeValue
    });
  }

  //=============== Track Events

  track(String trackName, [dynamic arguments]) {
    if (trackName == null || trackName.trim().length == 0) {
      throw new Exception("trackName is invalid. Please provide a valid name for track");
    }

    var params = <String, dynamic> {
      'data': arguments,
      'trackName': trackName
    };

    _channel.invokeMethod("track", params);
  }

  trackPurchase(String trackName, ChabokEvent chabokEvent) {
    if (trackName == null || trackName.trim().length == 0) {
      throw new Exception("trackName is invalid. Please provide a valid name for track");
    }

    var data = <String, dynamic> {
      'revenue': chabokEvent.revenue
    };

    if (chabokEvent.currency != null) {
      data['currency'] = chabokEvent.currency;
    }

    if (chabokEvent.data != null) {
      data['data'] = chabokEvent.data;
    }

    var params = <String, dynamic> {
      'data': data,
      'trackName': trackName
    };

    _channel.invokeMethod("trackPurchase", params);
  }

  //=============== Tags

  addTag(tagName) {
    if (tagName == null || tagName.trim().length == 0) {
      throw new Exception("tagName is invalid. Please provide a valid name for tag");
    }
    _channel.invokeMethod("addTag", <String, dynamic> {
      'tagName': tagName
    });
  }

  removeTag(tagName) {
    if (tagName == null || tagName.trim().length == 0) {
      throw new Exception("tagName is invalid. Please provide a valid name for tag");
    }
    _channel.invokeMethod("removeTag", <String, dynamic> {
      'tagName': tagName
    });
  }

  //=============== Handlers

  void setOnMessageCallback(callback) {
    if (callback == null) {
      print("Callback  parameter in setOnMessageCallback method is required.");
      return;
    }

    _channel.invokeMethod("setOnMessageCallback");
    
    this._onMessageHandler = callback;
  }

  void setOnNotificationOpenedHandler(Function callback) {
    if (callback == null) {
      print("Callback  parameter in setOnNotificationOpenedHandler method is required.");
      return;
    }

    _channel.invokeMethod("setOnNotificationOpenedHandler");

    this._onNotificationOpenedHandler = callback;
  }

  void setOnShowNotificationHandler(Function callback) {
    if (callback == null) {
      print("Callback  parameter in setOnShowNotificationHandler method is required.");
      return;
    }

    _channel.invokeMethod("setOnShowNotificationHandler");

    this._onShowNotificationHandler = callback;
  }

  void setOnConnectionHandler(Function callback) {
    if (callback == null) {
      print("Callback  parameter in setOnConnectionHandler method is required.");
      return;
    }

    _channel.invokeMethod("setOnConnectionHandler");

    this._onConnectionHandler = callback;
  }

  // Private function that gets called by ObjC/Java
  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method.contains('onMessageHandler')) {
      if (this._onMessageHandler != null) {
         this._onMessageHandler(call.arguments);
       }
    } else if (call.method.contains('onConnectionHandler')) {
      if(this._onConnectionHandler != null) {
        this._onConnectionHandler(call.arguments);
      }
    } else if (call.method.contains('onShowNotificationHandler')) {
      if (this._onShowNotificationHandler != null) {
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
