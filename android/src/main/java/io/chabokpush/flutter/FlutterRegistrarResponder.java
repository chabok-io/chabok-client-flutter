package io.chabokpush.flutter;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import java.lang.ref.WeakReference;
import java.util.HashMap;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;

abstract class FlutterRegistrarResponder implements ActivityAware {
    private final static boolean DEBUG = true;
    private final static String TAG = "CHABOK";

    static final String METHOD_CHANNEL_NAME = "com.chabokpush.flutter/chabokpush";

    static MethodChannel methodChannel;

    static WeakReference<Context> context = null;
    static WeakReference<Activity> activity = null;

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        logDebug("onAttachedToActivity() invoked.");

        activity = new WeakReference<>(binding.getActivity());
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        logDebug("onDetachedFromActivityForConfigChanges() invoked.");

        if (activity != null) {
            activity.clear();
        }
        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        logDebug("onReattachedToActivityForConfigChanges() invoked.");

        activity = new WeakReference<>(binding.getActivity());
    }

    @Override
    public void onDetachedFromActivity() {
        logDebug("onDetachedFromActivity() invoked.");

        if (activity != null) {
            activity.clear();
        }
        activity = null;
    }

    /**
     * MethodChannel class is home to success() method used by Result class
     * It has the @UiThread annotation and must be run on UI thread, otherwise a RuntimeException will be thrown
     * This will communicate success back to Dart
     */
    void replySuccess(final MethodChannel.Result reply,
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
    void replyError(final MethodChannel.Result reply,
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
    void replyNotImplemented(final MethodChannel.Result reply) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                reply.notImplemented();
            }
        });
    }

    void runOnMainThread(final Runnable runnable) {
        if (isAttachedToHost()) {
            activity.get().runOnUiThread(runnable);
        } else {
            logError("MethodChannel.invokeMethod() ignored! ~> " +
                    "runOnMainThread() invoked before onAttachedToActivity() " +
                    "or after onDetachedFromActivity()");
        }
    }

    void invokeMethodOnUiThread(final String methodName,
                                final String json) {
        final MethodChannel channel = methodChannel;
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                if (channel != null) {
                    channel.invokeMethod(methodName, json);
                }
            }
        });
    }

    void invokeMethodOnUiThread(final String methodName,
                                final HashMap map) {
        final MethodChannel channel = methodChannel;
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                if (channel != null) {
                    channel.invokeMethod(methodName, map);
                }
            }
        });
    }

    static void logDebug(String message) {
        if (DEBUG) {
            Log.d(TAG, message);
        }
    }

    static void logError(String message) {
        if (DEBUG) {
            Log.e(TAG, message);
        }
    }

    boolean isAttachedToHost() {
        return activity != null &&
                activity.get() != null;
    }
}
