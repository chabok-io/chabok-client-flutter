import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:chabokpush/chabokpush.dart';
import 'package:chabokpush/chabokEvent.dart';
import 'package:chabokpush/chabokMessage.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  final TextEditingController channelController = TextEditingController();

  Color connectionColor = Colors.red;
  String connectionString = "UNKNOWN";
  String logString = "";

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    ChabokPush.shared.getUserId().then((userId) {
      print('userId = $userId');
      userIdController.text = userId;
    });

    ChabokPush.shared.setOnMessageCallback((message) {
      var msg = json.decode(message);
      print('Got message = $msg');

      setState(() {
        logString += '\n' + message;
      });
    });

    ChabokPush.shared.setOnConnectionHandler((status) {
      print('Connection status = $status');

      setState(() {
        connectionString = status;
      });

      switch (status) {
        case 'CONNECTED':
          setState(() {
            connectionColor = Colors.green;
          });
          break;
        case 'CONNECTING':
          setState(() {
            connectionColor = Colors.yellow;
          });
          break;
        case 'DISCONNECTED':
        default:
          setState(() {
            connectionColor = Colors.red;
          });
      }
    });

    ChabokPush.shared.setOnNotificationOpenedHandler((notif) {
      var notifObject = json.decode(notif);
      var actionType = notifObject["actionType"];
      var message = notifObject["message"];
      print('User intract with notification = $actionType\nnotification payload = $message');
    });

    ChabokPush.shared.setOnShowNotificationHandler((notif) {
      var notifObject = json.decode(notif);
      var message = notifObject["message"];
      print('Notification show to user = $message');
    });

    ChabokPush.shared.setOnDeepLinkHandler((deeplink) {
      print('Deeplink = $deeplink');
    });

    ChabokPush.shared.setOnReferralHandler((referralId) {
      print('ReferralId = $referralId');
    });
  }

  @override
  void deactivate() {
    // print('deactivate() invoked.');
    super.deactivate();
  }

  @override
  void dispose() {
    // print('dispose() invoked.');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // print('state = $state');
  }

  //======================

  _login() {
    ChabokPush.shared.login(userIdController.text.toString());
  }

  _logout() {
    ChabokPush.shared.logout();
  }

  _addTag() {
    ChabokPush.shared.addTag(tagController.text.toString());
  }

  _removeTag() {
    ChabokPush.shared.removeTag(tagController.text.toString());
  }

  _setUserAttributes() {
    ChabokPush.shared.setUserAttributes(<String, dynamic> {
      'firstName': 'Farbod',
      'lastName': "Samsamipour",
      'age': 28,
      'birthday': new DateTime(1992),
      'isVIP': true,
      'cars': ['bmw', 'mazda3']
    });
  }

  _unsetUserAttributes() {
    ChabokPush.shared.unsetUserAttributes([
      'firstName',
      'lastName',
      'age',
      'birthday',
      'isVIP',
      'cars'
    ]);
  }

  _addToArray() {
    ChabokPush.shared.addToUserAttributeArray('cars', ['pride']);
  }

  _removeFromArray() {
    ChabokPush.shared.removeFromUserAttributeArray('cars', ['pride']);
  }

  _increment() {
    ChabokPush.shared.incrementUserAttribute('age');
  }

  _decrement() {
    ChabokPush.shared.decrementUserAttribute('age');
  }

  _trackPurchase() {
    var chabokEvent = new ChabokEvent(15000, 'RIAL');
    chabokEvent.setData(<String, dynamic> {
      'purchaseDate': new DateTime.now()
    });
    ChabokPush.shared.trackPurchase("Purchase", chabokEvent);
  }

  _addToCart() {
    ChabokPush.shared.track("AddToCart", <String, dynamic> {
      'orderId': 'oID_123',
      'orderDate': new DateTime.now(),
      'isBlackFriday': true,
      'orderSize': 69
    });
  }

  _like() {
    ChabokPush.shared.track("Like", <String, dynamic> {
      'postId': 'pID_123',
      'likeDate': new DateTime.now(),
      'isOwner': false,
      'likeCount': 85
    });
  }

  _comment() {
    ChabokPush.shared.track("Comment", <String, dynamic> {
      'postId': 'pID_123',
      'commentDate': new DateTime.now(),
      'isOwner': false,
      'commentCount': 85
    });
  }

  _subscribe() {
    ChabokPush.shared.subscribe(channelController.text.toString())
    .then((channel) {
      setState(() {
        logString += '\nsuccessfully subscribed to channel: $channel';
      });
    }).catchError((error) {
        var channel = channelController.text.toString();
        setState(() {
          logString += '\nfailed to subscribe to channel: $channel with error: $error';
        });
    });
  }

  _unsubscribe() {
    ChabokPush.shared.unsubscribe(channelController.text.toString())
    .then((channel) {
      setState(() {
        logString += '\nsuccessfully unsubscribed from channel: $channel';
      });
    }).catchError((error) {
        var channel = channelController.text.toString();
        setState(() {
          logString += '\nfailed to unsubscribe from channel: $channel with error: $error';
        });
    });
  }

  _publishMessage() {
    ChabokPush.shared.publish(new ChabokMessage(
      userIdController.text.toString(),
      "default",
      "Hi dude!")
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 10.0);
    Color color = Theme.of(context).primaryColor;

    Widget connectionSection = Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              color: connectionColor
            )
          ),
          Container(
            padding: EdgeInsets.only(left: 8),
            child: Text(connectionString),
          )
        ]
      )
    );

    Widget loginSection = Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: userIdController,
              decoration: InputDecoration(
                labelText: 'User Id'
              )
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: MaterialButton(
              color: color,
              onPressed: _login,
              child: Text("Login",
                textAlign: TextAlign.center,
                style: style.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                )
              )
            )
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: MaterialButton(
              color: color,
              onPressed: _logout,
              child: Text("Logout",
                textAlign: TextAlign.center,
                style: style.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                )
              )
            ),
          ),
        ],
      ),
    );

    Widget tagSection = Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: tagController,
              decoration: InputDecoration(
                labelText: 'Tag Name'
              )
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: MaterialButton(
              color: color,
              onPressed: _addTag,
              child: Text("Add Tag",
                textAlign: TextAlign.center,
                style: style.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                )
              )
            )
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: MaterialButton(
              color: color,
              onPressed: _removeTag,
              child: Text("Remove Tag",
                textAlign: TextAlign.center,
                style: style.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                )
              )
            ),
          ),
        ],
      ),
    );

    Widget attributeSection = Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Attributes:',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold
                )
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _setUserAttributes,
                    child: Text("Set Attributes",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                )
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _unsetUserAttributes,
                    child: Text("Unset Attributes",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                )
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _addToArray,
                    child: Text("Add to Array (cars)",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _removeFromArray,
                    child: Text("Remove from Array (cars)",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                )
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _increment,
                    child: Text("Increment (age)",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                    padding: const EdgeInsets.all(8),
                    child: MaterialButton(
                      color: color,
                      onPressed: _decrement,
                      child: Text("Decrement (age)",
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                        )
                      )
                    )
                  )
              )
            ],
          )
        ],
      ),
    );

    Widget eventSection = Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Events:',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold
                )
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _addToCart,
                    child: Text("Add to Cart",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                )
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _trackPurchase,
                    child: Text("Purchase (15,000)",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                )
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _like,
                    child: Text("Like",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                )
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _comment,
                    child: Text("Comment",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                )
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: MaterialButton(
                    color: color,
                    onPressed: _publishMessage,
                    child: Text("Publish Message (to me!)",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      )
                    )
                  )
                ),
              ),
            ],
          ),
        ],
      ),
    );

    Widget subscriptionSection = Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: channelController,
              decoration: InputDecoration(
                labelText: 'Channel Name'
              )
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: MaterialButton(
              color: color,
              onPressed: _subscribe,
              child: Text("Subscribe",
                textAlign: TextAlign.center,
                style: style.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                )
              )
            )
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: MaterialButton(
              color: color,
              onPressed: _unsubscribe,
              child: Text("Unsubscribe",
                textAlign: TextAlign.center,
                style: style.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                )
              )
            ),
          ),
        ],
      ),
    );

    Widget logSection = Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Logs:',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold
                )
              )
            ]
          ),
          Row(
            children: [
              Text(
                logString,
                overflow: TextOverflow.fade,
              )
            ]
          )
        ]
      )
    );

    return MaterialApp(
      title: 'Chabok Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Chabok Flutter Starter App'),
        ),
        body: ListView(
          children: [
            connectionSection,
            Divider(),
            loginSection,
            Divider(),
            tagSection,
            Divider(),
            subscriptionSection,
            Divider(),
            attributeSection,
            Divider(),
            eventSection,
            Divider(),
            logSection
          ],
        ),
      ),
    );
  }
}