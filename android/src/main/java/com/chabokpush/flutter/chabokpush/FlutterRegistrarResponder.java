package com.chabokpush.flutter.chabokpush;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import java.util.HashMap;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;

abstract class FlutterRegistrarResponder implements ActivityAware {
    private final static boolean DEBUG = true;
    private final static String TAG = "CHABOK";

    static final String METHOD_CHANNEL_NAME = "com.chabokpush.flutter/chabokpush";

    static MethodChannel methodChannel;
    Context context = null;
    Activity activity = null;

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        Log("onAttachedToActivity() invoked.");

        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        Log("onDetachedFromActivityForConfigChanges() invoked.");

        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        Log("onReattachedToActivityForConfigChanges() invoked.");

        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        Log("onAttachedToActivity() invoked.");

        activity = null;
    }

    /**
     * MethodChannel class is home to success() method used by Result class
     * It has the @UiThread annotation and must be run on UI thread, otherwise a RuntimeException will be thrown
     * This will communicate success back to Dart
     */
    protected void replySuccess(final MethodChannel.Result reply,
                                final Object response) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                reply.success(response);
            }
        });
    }

    /**
     * MethodChannel class is home to error() method used by Result class
     * It has the @UiThread annotation and must be run on UI thread, otherwise a RuntimeException will be thrown
     * This will communicate error back to Dart
     */
    protected void replyError(final MethodChannel.Result reply,
                              final String tag,
                              final String message,
                              final Object response) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                reply.error(tag, message, response);
            }
        });
    }

    /**
     * MethodChannel class is home to notImplemented() method used by Result class
     * It has the @UiThread annotation and must be run on UI thread, otherwise a RuntimeException will be thrown
     * This will communicate not implemented back to Dart
     */
    protected void replyNotImplemented(final MethodChannel.Result reply) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                reply.notImplemented();
            }
        });
    }

    protected void runOnMainThread(final Runnable runnable) {
        if (activity != null) {
            activity.runOnUiThread(runnable);
        } else {
            Log.e(TAG, "Error ~> runOnMainThread() invoked before onAttachedToActivity()");
        }
    }

    protected void invokeMethodOnUiThread(final String methodName,
                                          final String json) {
        final MethodChannel channel = this.methodChannel;
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                channel.invokeMethod(methodName, json);
            }
        });
    }

    protected void invokeMethodOnUiThread(final String methodName,
                                          final HashMap map) {
        final MethodChannel channel = this.methodChannel;
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                channel.invokeMethod(methodName, map);
            }
        });
    }

    protected static void Log(String message) {
        if (DEBUG) {
            Log.d(TAG, message);
        }
    }
}
