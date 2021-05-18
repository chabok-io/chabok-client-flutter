# Table of contents:
* [Project Notes](#project-notes)
* [Android contributing instructions:](#android-contributing-instructions)
    - [Notes](#notes)
    - [Update Android native SDK](#update-android-native-sdk)
    - [Without any breaking changes](#without-any-breaking-changes)
    - [With breaking changes](#with-breaking-changes)
* [iOS contributing instructions:](#ios-contributing-instructions)
    - [Notes](#notes-1)
    - [Update iOS native SDK](#update-ios-native-sdk)
    - [Without any breaking changes](#without-any-breaking-changes-1)
    - [With breaking changes](#with-breaking-changes-1)


## Project Notes
1. For developing in this project use **Android** IDE and download the **Dart** plugin. This is the best IDE and more compatible with Flutter platform.

2. All Dart module codes are in `/lib` path. After applied changes in the native modules, Don't forget apply them on the Dart module if need.

3. SDK initialization should be in native side for each platform. For example: iOS users should call `configureEnvironment` method from native SDK in `AppDelegate.m` class.

4. For install package first add your package to `pubspec.yml` file like bellow:

``` yml
dependencies:
  chabokpush_flutter: ^3.0.0
```
Then use following command:

```
flutter pub get
```

## Android contributing instructions:

### Notes:
1) For developing Android native bridge use **Android Studio** IDE.

2) Never change the `FlutterRegistrarResponder` class. When this class may change you need to support for specific version on the Flutter. Their breaking changes always affects of this module.

3) Flutter has two-way communication channel from the native module to Dart module and conversely. For use this service call `MethodChannel` class.

4) For running project on android device follow the instruction:

```
flutter run
```

or 
```
flutter run -d {{DEVICE_NAME}}
```

### Update Android native SDK:
All Chabok libraries follow the semantic versioning.

#### Without any breaking changes:
If it hasn't any breaking changes follow this instruction:

```
cd android

vi build.gradle
```

Just change Chabok Android SDK Version:

from:
```
 api 'com.adpdigital.push:chabok-lib:3.4.0'
```
to:
```
 api 'com.adpdigital.push:chabok-lib:3.6.0'
```

#### With breaking changes
If it has some breaking changes first follow the above instruction. After that if breaking changes includes code changes, don't forget apply all changes in `ChabokpushPlugin.java` bridge class.
The `ChabokpushPlugin` is a simple bridge for connect the native module and Dart module.

## iOS contributing instructions:

### Notes:
1) For developing iOS native bridge use **Android Studio** or **Xcode** IDE. Open project from `/ios` path.

2) For testing iOS bridge you should use `cocoapods` with `1.7.5` version.

3) For running project on iOS device follow the instruction:

```
flutter run
```

or
```
flutter run -d {{DEVICE_NAME}}
```
### Update iOS native SDK:
All Chabok libraries follow the semantic versioning.

#### Without any breaking changes:
If it hasn't any breaking changes follow this instruction:

```
cd ios
vi chabokpush.podspec
```

Just change Chabok iOS SDK Version:

from:
```
 s.dependency "ChabokPush", "~> 2.2.0"
```
to:
```
 s.dependency "ChabokPush", "~> 2.4.0"
```

And copy last version of iOS framework into the `/ios`:

#### With breaking changes
If it has some breaking changes first follow the above instruction. After that if breaking changes includes code changes, don't forget apply all changes in `/Classes/ChabokpushPlugin.m` bridge class.
The `chabokpush.dart` is a simple bridge for connect the native module and Dart module.
