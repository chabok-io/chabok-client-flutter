import 'dart:async';

import 'package:flutter/services.dart';
import 'package:chabokpush/ChabokEvent.dart';
import 'package:chabokpush/ChabokMessage.dart';

// Handlers for various events
typedef void MessageHandler(dynamic);
typedef void ShowNotificationHandler(dynamic);
typedef void NotificationOpenedHandler(dynamic);
typedef void ConnectionHandler(String connectionStatus);
typedef void DeepLinkHandler(String deeplink);
typedef void ReferralHandler(String referralId);

class ChabokPush {
  static final ChabokPush _instance = ChabokPush._();
  static const MethodChannel _channel =
      const MethodChannel('com.chabokpush.flutter/chabokpush');

  // event handlers
  MessageHandler _onMessageHandler;
  ConnectionHandler _onConnectionHandler;
  ShowNotificationHandler _onShowNotificationHandler;
  NotificationOpenedHandler _onNotificationOpenedHandler;
  DeepLinkHandler _onDeepLinkHandler;
  ReferralHandler _onReferralHandler;

  ChabokPush._() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  factory ChabokPush() {
    return _instance;
  }

  static ChabokPush get shared {
    return ChabokPush();
  }

  //=============== User Lifecycle

  Future<dynamic> login(String userId) async {
    return _channel.invokeMethod("login", <String, dynamic>{'userId': userId});
  }

  logout() {
    _channel.invokeMethod("logout");
  }

  Future<String> getUserId() async {
    return _channel.invokeMethod("getUserId");
  }

  Future<String> getInstallationId() async {
    return _channel.invokeMethod("getInstallationId");
  }

  //=============== Publish Messages

  publish(ChabokMessage message) {
    var msgMap = <String, dynamic>{
      'userId': message.userId,
      'content': message.content
    };

    if (message.channel != null) {
      msgMap['channel'] = message.channel;
    }

    if (message.data != null) {
      msgMap['data'] = message.data;
    }

    if (message.notification != null) {
      msgMap['notification'] = message.notification;
    }

    _channel.invokeMethod("publish", msgMap);
  }

  //=============== User Attributes

  setUserAttributes(dynamic attributes) {
    var _attrs = {};
    for (var key in attributes.keys) {
      if (attributes[key].runtimeType == DateTime) {
        _attrs['@CHKDATE_' + key] =
            attributes[key].millisecondsSinceEpoch.toString();
      } else {
        _attrs[key] = attributes[key];
      }
    }

    _channel.invokeMethod("setUserAttributes", _attrs);
  }

  unsetUserAttributes(List<String> attributes) {
    _channel.invokeMethod("unsetUserAttributes",
        <String, dynamic>{'attributeValues': attributes});
  }

  unsetUserAttribute(String attribute) {
    _channel.invokeMethod("unsetUserAttributes", <String, dynamic>{
      'attributeValues': [attribute]
    });
  }

  addToUserAttributeArray(String attributeKey, List<String> attributeValues) {
    _channel.invokeMethod("addToUserAttributeArray", <String, dynamic>{
      'attributeKey': attributeKey,
      'attributeValues': attributeValues
    });
  }

  removeFromUserAttributeArray(
      String attributeKey, List<String> attributeValues) {
    _channel.invokeMethod("removeFromUserAttributeArray", <String, dynamic>{
      'attributeKey': attributeKey,
      'attributeValues': attributeValues
    });
  }

  incrementUserAttribute(String attributeKey, [double attributeValue = 1]) {
    _channel.invokeMethod("incrementUserAttribute", <String, dynamic>{
      'attributeKey': attributeKey,
      'attributeValue': attributeValue
    });
  }

  decrementUserAttribute(String attributeKey, [double attributeValue = 1]) {
    _channel.invokeMethod("decrementUserAttribute", <String, dynamic>{
      'attributeKey': attributeKey,
      'attributeValue': attributeValue
    });
  }

  //=============== Track Events

  track(String trackName, [dynamic arguments]) {
    if (trackName == null || trackName.trim().length == 0) {
      throw new Exception(
          "trackName is invalid. Please provide a valid name for track");
    }

    var _data = {};
    for (var key in arguments.keys) {
      if (arguments[key].runtimeType == DateTime) {
        _data['@CHKDATE_' + key] =
            arguments[key].millisecondsSinceEpoch.toString();
      } else {
        _data[key] = arguments[key];
      }
    }

    var params = <String, dynamic>{'data': _data, 'trackName': trackName};

    _channel.invokeMethod("track", params);
  }

  trackPurchase(String trackName, ChabokEvent chabokEvent) {
    if (trackName == null || trackName.trim().length == 0) {
      throw new Exception(
          "trackName is invalid. Please provide a valid name for track");
    }

    var data = <String, dynamic>{'revenue': chabokEvent.revenue};

    if (chabokEvent.currency != null) {
      data['currency'] = chabokEvent.currency;
    }

    var _data = {};
    if (chabokEvent.data != null) {
      for (var key in chabokEvent.data.keys) {
        if (chabokEvent.data[key].runtimeType == DateTime) {
          _data['@CHKDATE_' + key] =
              chabokEvent.data[key].millisecondsSinceEpoch.toString();
        } else {
          _data[key] = chabokEvent.data[key];
        }
      }
      data['data'] = _data;
    }

    var params = <String, dynamic>{'data': data, 'trackName': trackName};

    _channel.invokeMethod("trackPurchase", params);
  }

  //=============== Tags

  Future<dynamic> addTag(tagName) async {
    if (tagName == null || tagName.trim().length == 0) {
      throw new Exception(
          "tagName is invalid. Please provide a valid name for tag");
    }
    return _channel.invokeMethod("addTags", <String, dynamic>{
      'tags': [tagName]
    });
  }

  Future<dynamic> addTags(List<String> tags) async {
    if (tags == null || tags.length == 0) {
      throw new Exception(
          "tags is invalid. Please provide a valid tag for addTags");
    }
    return _channel.invokeMethod("addTags", <String, dynamic>{'tags': tags});
  }

  Future<dynamic> removeTag(tagName) async {
    if (tagName == null || tagName.trim().length == 0) {
      throw new Exception(
          "tagName is invalid. Please provide a valid name for tag");
    }
    return _channel.invokeMethod("removeTags", <String, dynamic>{
      'tags': [tagName]
    });
  }

  Future<dynamic> removeTags(tags) async {
    if (tags == null || tags.length == 0) {
      throw new Exception(
          "tags is invalid. Please provide a valid tag for removeTags");
    }
    return _channel.invokeMethod("removeTags", <String, dynamic>{'tags': tags});
  }

  //=============== subscription

  Future<String> subscribe(String channelName) async {
    if (channelName == null || channelName.trim().length == 0) {
      throw new Exception(
          "channelName is invalid. Please provide a valid name for subscribe");
    }

    var params = <String, dynamic>{'channelName': channelName};

    return _channel.invokeMethod("subscribe", params);
  }

  Future<String> unsubscribe(String channelName) async {
    if (channelName == null || channelName.trim().length == 0) {
      throw new Exception(
          "channelName is invalid. Please provide a valid name for unsubscribe");
    }

    var params = <String, dynamic>{'channelName': channelName};

    return _channel.invokeMethod("unsubscribe", params);
  }

  //=============== Handlers

  void setOnMessageCallback(callback) {
    if (callback == null) {
      print("Callback parameter in setOnMessageCallback method is required.");
      return;
    }

    _channel.invokeMethod("setOnMessageCallback");

    this._onMessageHandler = callback;
  }

  void setOnNotificationOpenedHandler(Function callback) {
    if (callback == null) {
      print(
          "Callback parameter in setOnNotificationOpenedHandler method is required.");
      return;
    }

    _channel.invokeMethod("setOnNotificationOpenedHandler");

    this._onNotificationOpenedHandler = callback;
  }

  void setOnShowNotificationHandler(Function callback) {
    if (callback == null) {
      print(
          "Callback parameter in setOnShowNotificationHandler method is required.");
      return;
    }

    _channel.invokeMethod("setOnShowNotificationHandler");

    this._onShowNotificationHandler = callback;
  }

  void setOnConnectionHandler(Function callback) {
    if (callback == null) {
      print("Callback parameter in setOnConnectionHandler method is required.");
      return;
    }

    _channel.invokeMethod("setOnConnectionHandler");

    this._onConnectionHandler = callback;
  }

  void setOnDeepLinkHandler(Function callback) {
    if (callback == null) {
      print("Callback parameter in setOnDeepLinkHandler method is required.");
      return;
    }

    _channel.invokeMethod("setOnDeepLinkHandler");

    this._onDeepLinkHandler = callback;
  }

  void setOnReferralHandler(Function callback) {
    if (callback == null) {
      print("Callback parameter in setOnReferralHandler method is required.");
      return;
    }

    _channel.invokeMethod("setOnReferralHandler");

    this._onReferralHandler = callback;
  }

  // Private function that gets called by ObjC/Java
  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method.contains('onMessageHandler')) {
      if (this._onMessageHandler != null) {
        this._onMessageHandler(call.arguments);
      }
    } else if (call.method.contains('onConnectionHandler')) {
      if (this._onConnectionHandler != null) {
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
    } else if (call.method.contains('setOnDeepLinkHandler')) {
      if (this._onDeepLinkHandler != null) {
        this._onDeepLinkHandler(call.arguments);
      }
    } else if (call.method.contains('setOnReferralHandler')) {
      if (this._onReferralHandler != null) {
        this._onReferralHandler(call.arguments);
      }
    }
    return null;
  }
}
