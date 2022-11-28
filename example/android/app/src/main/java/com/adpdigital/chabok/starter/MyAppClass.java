package com.adpdigital.chabok.starter;

import com.adpdigital.push.AdpPushClient;
import com.adpdigital.push.LogLevel;
import com.adpdigital.push.config.Environment;

import io.flutter.app.FlutterApplication;

public class MyAppClass extends FlutterApplication {

    @Override
    public void onCreate() {
        super.onCreate();

        AdpPushClient.setLogLevel(LogLevel.VERBOSE);
        AdpPushClient.configureEnvironment(Environment.PRODUCTION);
    }
}
