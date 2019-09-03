import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:chabokpush/chabokpush.dart';
import 'package:chabokpush/ChabokEvent.dart';
import 'package:chabokpush/ChabokMessage.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';


  @override
  void initState() {
    super.initState();

    ChabokPush.init('chabok-starter','70df4ae2e1fd03518ce3e3b21ee7ca7943577749','chabok-starter','chabok-starter','839879285435', true);

    ChabokPush.shared.getUserId().then((userId) => ChabokPush.shared.register(userId), onError: (e) => ChabokPush.shared.registerAsGuest());

    ChabokPush.shared.setOnMessageCallback((message){
      print('Got message --> ' + message);
    });

    ChabokPush.shared.setOnConnectionHandler((status) {
      print('Connection status = ' + status);
    });

    ChabokPush.shared.setOnNotificationOpenedHandler((notif) {
      var notifObject = json.decode(notif);

      print('User intract with notification = ' + notifObject['action'].toString() +
          ', \n notification payload = ' + notifObject['message'].toString());
    });

    ChabokPush.shared.setOnShowNotificationHandler((notif) {
      print('Notificatio show to user' + notif);
    });

    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion = '0.0.1';
    // Platform messages may fail, so we use a try/catch PlatformException.
//    try {
//      platformVersion = await ChabokPush.platformVersion;
//    } on PlatformException {
//      platformVersion = 'Failed to get platform version.';
//    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  //======================

  _addTagButtonClicked(){
    ChabokPush.shared.addTag("FLUTTER");
  }

  _trackPurchaseButtonClicked(){
    ChabokPush.shared.trackPurchase("Purchase", new ChabokEvent(20000,'RIAL'));
  }

  _trackAddToCartButtonClicked(){
    ChabokPush.shared.track("AddToCart", <String, dynamic>{
      'value': 'pID_123'
    });
  }

  _setUserAttributesButtonClicked(){
    ChabokPush.shared.setUserAttributes(<String, dynamic>{
      'firstName': 'Chabok',
      'lastName': "Realtime Solutions",
      'age': 4
    });
  }

  _publishMessageButtonClicked() {
    ChabokPush.shared.publish(new ChabokMessage("989125336383", "default","Hi dude"));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Chabok starter for flutter'),
        ),
          body: GridView.count(
            primary: false,
            padding: const EdgeInsets.all(20.0),
            crossAxisSpacing: 10.0,
            crossAxisCount: 2,
            children: <Widget>[
              RaisedButton(
                onPressed: _addTagButtonClicked,
                child: Text(
                    'AddTag',
                    style: TextStyle(fontSize: 20)
                ),
              ),
              RaisedButton(
                onPressed: _trackPurchaseButtonClicked,
                child: const Text(
                    'TrackPurchase',
                    style: TextStyle(fontSize: 20)
                ),
              ),
              RaisedButton(
                onPressed: _trackAddToCartButtonClicked,
                child: const Text(
                    'AddToCart',
                    style: TextStyle(fontSize: 20)
                ),
              ),
              RaisedButton(
                onPressed: _setUserAttributesButtonClicked,
                child: const Text(
                    'userAttributes',
                    style: TextStyle(fontSize: 20)
                ),
              ),
              RaisedButton(
                onPressed: _publishMessageButtonClicked,
                child: const Text(
                    'publish message',
                    style: TextStyle(fontSize: 20)
                ),
              ),
            ],
          )
      ),
    );
  }
}
