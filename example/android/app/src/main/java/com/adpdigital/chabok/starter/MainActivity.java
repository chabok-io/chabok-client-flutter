package com.adpdigital.chabok.starter;

import androidx.annotation.NonNull;

import com.adpdigital.push.AdpPushClient;
import com.adpdigital.push.LogLevel;
import com.adpdigital.push.config.Environment;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        AdpPushClient.setLogLevel(LogLevel.VERBOSE);
        AdpPushClient.configureEnvironment(Environment.SANDBOX);

        GeneratedPluginRegistrant.registerWith(flutterEngine);
    }
}
