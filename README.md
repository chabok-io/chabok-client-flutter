<p align="center"> 
  <img src="https://raw.githubusercontent.com/chabok-io/chabok-client-flutter/master/Flutter.png">
</p>

# Chabok Push Client for Flutter
[![pub package](https://img.shields.io/pub/v/chabokpush.svg)](https://pub.dev/packages/chabokpush)

Flutter wrapper for chabok library.
This client library supports Flutter to use chabok push library.
A Wrapper around native library to use chabok functionalities in Flutter environment.

## Installation
For installation refer to [Flutter docs](https://doc.chabok.io/flutter/introducing.html) and platform specific parts (Android and iOS).

## Release Note
You can find release note [here](https://doc.chabok.io/flutter/release-note.html).

## Support
Please visit [Issues](https://github.com/chabok-io/chabok-client-flutter/issues).

## Getting Started - Android
1. Add Google and Chabok plugins to `build.gradle` project level file.

```groovy
buildscript {
    repositories {
        google()
        jcenter()
	
        maven {
            url "https://plugins.gradle.org/m2/" 
        }
    }
    
    dependencies {
    	classpath "com.android.tools.build:gradle:3.4.2"
	
        classpath "io.chabok.plugin:chabok-services:1.0.0"
        classpath "com.google.gms:google-services:4.3.2"
    }
}
```

2. Apply Google and Chabok plugins to `build.gradle` application level file.

```groovy
dependencies {
    // your project dependencies
}

apply plugin: 'io.chabok.plugin.chabok-services'
apply plugin: 'com.google.gms.google-services'
```

4. Initialize Chabok SDK in your `MainApplication.java`:

```java
import com.adpdigital.push.AdpPushClient;
import com.adpdigital.push.config.Environment;

import io.flutter.app.FlutterApplication;

public class MainApplication extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();
	
        AdpPushClient.configureEnvironment(Environment.SANDBOX); // or PRODUCTION
    }
}
```

## Getting started - iOS

1. Ensure your iOS projects Pods are up-to-date:

```bash
$ cd ios
$ pod install --repo-update
```

2. Initialize Chabok SDK in your `AppDelegate.m`:

```objectivec
#import "AppDelegate.h"
#import <AdpPushClient/AdpPushClient.h>

- (BOOL)application:(UIApplication *)application
            didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [PushClientManager.defaultManager configureEnvironment:Sandbox]; // or PRODUCTION
    
    [GeneratedPluginRegistrant registerWithRegistry:self];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
```

## Basic Usage
In your `main.dart`:

### Initialize
For initializing the Chabok SDK in dart add bellow lines in `import` section:

```dart
import 'package:chabokpush/chabokpush.dart';
import 'package:chabokpush/ChabokEvent.dart';
import 'package:chabokpush/ChabokMessage.dart';
```

### Login user
To login user in the Chabok service use `login` method:
```dart
ChabokPush.shared.login('USER_ID');
```

### Logout user
To logout user in the Chabok service use `logout` method:
```dart
ChabokPush.shared.logout();
```

### Set user attributes
To set user attributes in the Chabok service use `setUserAttributes` method:
```dart
ChabokPush.shared.setUserAttributes(<String, dynamic> {
  'firstName': 'Farbod',
  'lastName': "Samsamipour",
  'age': 28,
  'birthday': new DateTime(1992),
  'isVIP': true,
  'friends': ['hussein', 'habibi']
});
```

### Unset user attributes
To unset user attributes in the Chabok service user `unsetUserAttributes` method:
```dart
ChabokPush.shared.unsetUserAttributes([
  'isVIP'
]);
```

### Getting message
To get the Chabok message call `setOnMessageCallback`:

```dart
ChabokPush.shared.setOnMessageCallback((message) {
  var msg = json.decode(message);
  print('Got message = $msg');
});
```

### Getting connection status
To get connection state call `setOnConnectionHandler`:

```dart
ChabokPush.shared.setOnConnectionHandler((status) {
  print('Connection status = $status');
});
```

### Publish message
For publishing a message use `publish` method:

```dart
ChabokPush.shared.publish(new ChabokMessage(
  "RECEIVER_USER_ID",
  "CHANNEL_NAME",
  "YOUR MESSAGE")
);
```

### Subscribe on channel
To subscribe on a channel use `subscribe` method:
```dart
ChabokPush.shared.subscribe('CHANNEL_NAME')
  .then((channel) {
    print('successfully subscribed on channel: $channel');
  }).catchError((error) {
    print('failed to subscribe on channel with error: $error');
  });
```

### Unsubscribe from channel
To unsubscribe from channel use `unSubscribe` method: 

```dart
ChabokPush.shared.subscribe('CHANNEL_NAME')
  .then((channel) {
    print('successfully unsubscribed from channel: $channel');
  }).catchError((error) {
    print('failed to unsubscribe from channel with error: $error');
  });
```

### Track
To track user interactions use `track` method :
```dart
ChabokPush.shared.track("AddToCart", <String, dynamic> {
  'orderId': 'order_123',
  'orderDate': new DateTime.now(),
  'isBlackFriday': true,
  'orderSize': 69
});
```

### Add tag
Adding tag to user use `addTag` method:

```dart
ChabokPush.shared.addTag("YOUR_TAG")
  .then((response) {
    print('successfully add tag');
  }).catchError((error) {
      print('failed to add tag with error: $error');
  });
```

### Remove tag
Removing tag from user use `removeTag` method:

```dart
ChabokPush.shared.removeTag("YOUR_TAG")
  .then((response) {
    print('successfully remove tag');
  }).catchError((error) {
      print('failed to remove tag with error: $error');
  });
```
