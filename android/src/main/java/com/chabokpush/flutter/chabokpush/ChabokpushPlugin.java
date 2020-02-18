package com.chabokpush.flutter.chabokpush;

import android.content.Context;
import android.net.Uri;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;

import com.adpdigital.push.AdpPushClient;
import com.adpdigital.push.AppState;
import com.adpdigital.push.Callback;
import com.adpdigital.push.ChabokEvent;
import com.adpdigital.push.ChabokNotification;
import com.adpdigital.push.ChabokNotificationAction;
import com.adpdigital.push.ConnectionStatus;
import com.adpdigital.push.NotificationHandler;
import com.adpdigital.push.PushMessage;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * ChabokpushPlugin
 */
public class ChabokpushPlugin extends FlutterRegistrarResponder
        implements FlutterPlugin, MethodCallHandler {

    private static ChabokpushPlugin instance;
    private final Object initLock = new Object();
    private Result onRegisterResult;

    private String lastConnectionStatues;
    private String lastChabokMessage;

    public static ChabokNotification coldStartChabokNotification;
    public static ChabokNotificationAction coldStartChabokNotificationAction;
    private String lastMessageId;

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    public static void registerWith(Registrar registrar) {
        Log("registerWith() invoked");

        if (instance == null) {
            instance = new ChabokpushPlugin();
        }
        instance.init(registrar.context(), registrar.messenger());
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        Log("onAttachedToEngine() invoked");

        init(flutterPluginBinding.getApplicationContext(),
                flutterPluginBinding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        Log("onDetachedFromEngine() invoked");

        context = null;
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;

        activity = null;
        context = null;

        AdpPushClient.get().dismiss();
    }

    private void init(Context applicationContext,
                      BinaryMessenger messenger) {
        synchronized (initLock) {
            if (methodChannel != null) {
                return;
            }

            this.context = applicationContext;

            methodChannel = new MethodChannel(messenger, METHOD_CHANNEL_NAME);
            methodChannel.setMethodCallHandler(this);

            chabokInit();
        }
    }

    private void chabokInit() {
        AdpPushClient.get().addListener(this);
        AdpPushClient.get().addNotificationHandler(new NotificationHandler() {
            @Override
            public boolean buildNotification(ChabokNotification message,
                                             NotificationCompat.Builder builder) {
                String notificationJson = null;

                if (message.getExtras() != null) {
                    Bundle payload = message.getExtras();

                    //FCM message data
                    JSONObject notificationJsonObject = bundleToJson(payload);
                    notificationJson = notificationJsonObject.toString();

                } else if (message.getMessage() != null) {
                    PushMessage payload = message.getMessage();

                    //Chabok message data
                    notificationJson = payload.toJson();
                }

                if (notificationJson != null) {
                    invokeMethodOnUiThread("onShowNotificationHandler",
                            notificationJson);
                }

                return super.buildNotification(message, builder);
            }

            @Override
            public boolean notificationOpened(ChabokNotification message,
                                              ChabokNotificationAction notificationAction) {
                JSONObject notificationJson = null;

                if (message.getExtras() != null) {
                    Bundle payload = message.getExtras();

                    //FCM message data
                    notificationJson = bundleToJson(payload);
                } else if (message.getMessage() != null) {
                    PushMessage payload = message.getMessage();

                    //Chabok message data
                    notificationJson = payload.getData();
                }

                JSONObject notificationOpenedjson = new JSONObject();

                JSONObject notifActionJson = getJsonFromNotificationAction(notificationAction);

                try {
                    notificationOpenedjson.put("action", notifActionJson);
                    notificationOpenedjson.put("message", notificationJson);
                } catch (Exception e) {
                    e.printStackTrace();
                }

                invokeMethodOnUiThread("onNotificationOpenedHandler",
                        notificationOpenedjson.toString());

                return super.notificationOpened(message, notificationAction);
            }
        });
    }

    public ChabokpushPlugin() {
        Log("ChabokpushPlugin() invoked");
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String method = call.method;
        Map<String, Object> arguments = (Map<String, Object>) call.arguments;

        Log("----------- onMethodCall: action = " + method + " , args = " + arguments);

        switch (method) {
            case "login":
                String userId = arguments.get("userId").toString();
                login(userId, result);
                break;
            case "publish":
                JSONObject messageJson = new JSONObject(arguments);
                publish(messageJson, result);
                break;
            case "getUserId":
                getUserId(result);
                break;
            case "getInstallation":
                getInstallation(result);
                break;
            case "setDefaultTracker":
                String defaultTracker = arguments.get("defaultTracker").toString();
                setDefaultTracker(defaultTracker);
                break;
            case "resetBadge":
                resetBadge();
                break;
            case "appWillOpenUrl":
                String url = arguments.get("url").toString();
                appWillOpenUrl(url);
                break;
            case "logout":
                logout();
                break;
            case "addTag": {
                String tagName = arguments.get("tagName").toString();
                addTag(tagName, result);
                break;
            }
            case "removeTag": {
                String tagName = arguments.get("tagName").toString();
                removeTag(tagName, result);
                break;
            }
            case "setUserAttributes":
                JSONObject attributes = new JSONObject(arguments);
                setUserAttributes(attributes);
                break;
            case "track": {
                String trackName = arguments.get("trackName").toString();
                try {
                    JSONObject data = new JSONObject(arguments.get("data").toString());
                    track(trackName, data);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                break;
            }
            case "trackPurchase": {
                String trackName = arguments.get("trackName").toString();
                try {
                    JSONObject data = new JSONObject(arguments.get("data").toString());
                    double revenue = 0;
                    String currency = null;
                    JSONObject eventData = null;

                    if (!data.has("revenue")) {
                        throw new IllegalArgumentException("Invalid revenue");
                    }

                    revenue = data.getDouble("revenue");
                    if (data.has("currency")) {
                        currency = data.getString("currency");
                    }

                    if (data.has("data")) {
                        eventData = data.getJSONObject("data");
                    }

                    ChabokEvent chabokEvent = new ChabokEvent(revenue);
                    if (currency != null) {
                        chabokEvent.setRevenue(revenue, currency);
                    }

                    if (eventData != null) {
                        chabokEvent.setData(eventData);
                    }

                    trackPurchase(trackName, chabokEvent);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                break;
            }
            case "setOnMessageCallback":
                invokeMethodOnUiThread("onMessageHandler", lastChabokMessage);
                break;
            case "setOnConnectionHandler":
                invokeMethodOnUiThread("onConnectionHandler", lastConnectionStatues);
                break;
            case "setOnNotificationOpenedHandler":
                // TODO
                break;
            case "setOnShowNotificationHandler":
                // TODO
                break;
            case "incrementUserAttribute":
//                incrementUserAttribute();
                break;
            case "decrementUserAttribute":
//                decrementUserAttribute();
                break;
            case "addToUserAttributeArray":
//                addToUserAttributeArray();
                break;
            case "removeFromUserAttributeArray":
//                removeFromUserAttributeArray();
                break;
            case "unsetUserAttributes":
//                unsetUserAttributes();
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    public void login(String userId, Result result) {
        this.onRegisterResult = result;
        AdpPushClient.get().login(userId);
    }

    public void publish(JSONObject message, final Result result) {
        try {
            JSONObject dataMap = null;
            if (message.has("data")) {
                dataMap = message.getJSONObject("data");
            }
            String body = message.getString("content");
            String userId = message.getString("userId");
            String channel = message.getString("methodChannel");

            PushMessage msg = new PushMessage();

            if (body != null) {
                msg.setBody(body);
            }
            if (userId != null) {
                msg.setUser(userId);
            }
            if (userId != null) {
                msg.setUser(userId);
            }
            if (channel != null) {
                msg.setChannel(channel);
            }
            if (dataMap != null) {
                msg.setData(dataMap);
            }

            AdpPushClient.get().publish(msg, new Callback() {
                @Override
                public void onSuccess(Object o) {
                    replySuccess(result, "Message published");
                }

                @Override
                public void onFailure(Throwable throwable) {
                    replyError(result, "-1", throwable.getMessage(), throwable);
                }
            });
        } catch (JSONException e) {
            e.printStackTrace();
            replyError(result, "-2", e.getMessage(), e);
        }
    }

    public void logout() {
        AdpPushClient.get().logout();
    }

    public void track(String trackName, JSONObject data) {
        AdpPushClient.get().track(trackName, data);
    }

    public void trackPurchase(String trackName, ChabokEvent eventData) {
        AdpPushClient.get().trackPurchase(trackName, eventData);
    }

    public void addTag(String tagName, final Result result) {
        AdpPushClient.get().addTag(tagName, new Callback() {
            @Override
            public void onSuccess(Object o) {
                Log("The addTags onSuccess: invoked");
                replySuccess(result, "Tag Added");
            }

            @Override
            public void onFailure(Throwable throwable) {
                Log("The addTag onFailure: invoked");
                replyError(result, "-1", throwable.getMessage(), throwable);
            }
        });
    }

    public void removeTag(String tagName, final Result result) {
        AdpPushClient.get().removeTag(tagName, new Callback() {
            @Override
            public void onSuccess(Object o) {
                Log("The removeTag onSuccess: invoked");
                replySuccess(result, "Tag removed");
            }

            @Override
            public void onFailure(Throwable throwable) {
                Log("The removeTag onFailure: invoked");
                replyError(result, "-1", throwable.getMessage(), throwable);
            }
        });
    }

    public void setDefaultTracker(String defaultTracker) {
        AdpPushClient.setDefaultTracker(defaultTracker);
    }

    public void appWillOpenUrl(String link) {
        if (link == null) {
            return;
        }

        Uri uri = Uri.parse(link);
        AdpPushClient.get().appWillOpenUrl(uri);
    }

    public void setUserAttributes(JSONObject attributes) {
        try {
            HashMap<String, Object> attributesMap = (HashMap<String, Object>) jsonToMap(attributes);
            AdpPushClient.get().setUserAttributes(attributesMap);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public String getUserId(Result result) {
        String userId = AdpPushClient.get().getUserId();
        if (result != null) {
            if (userId != null) {
                replySuccess(result, userId);
            } else {
                replyError(result,
                        "-1",
                        "The userId is null, You didn't register yet!",
                        null);
            }
        }

        return userId;
    }

    public String getInstallation(Result result) {
        String installationId = AdpPushClient.get().getUserId();
        if (result != null) {
            if (installationId != null) {
                replySuccess(result, installationId);
            } else {
                replyError(result,
                        "-1",
                        "The installationId is null, You didn't register yet!",
                        null);
            }
        }

        return installationId;
    }

    public void resetBadge() {
        AdpPushClient.get().resetBadge();
    }

    public void unsetUserAttributes(String[] attributes) {
//        AdpPushClient.get().unsetUserAttributes(attributes);
    }

    public void addToUserAttributeArray(String attributeKey, String[] attributeValues) {
        AdpPushClient.get().addToUserAttributeArray(attributeKey, attributeValues);
    }

    public void removeFromUserAttributeArray(String attributeKey, String[] attributeValues) {
        AdpPushClient.get().removeFromUserAttributeArray(attributeKey, attributeValues);
    }

    public void incrementUserAttribute(String attributeKey, Double attributeValue) {
        AdpPushClient.get().incrementUserAttribute(attributeKey, attributeValue);
    }

    public void decrementUserAttribute(String attributeKey, Double attributeValue) {
        AdpPushClient.get().incrementUserAttribute(attributeKey, -attributeValue);
    }

    public void onEvent(AppState state) {
        Log("on AppState received");

        final AppState finalState = state;
        runOnMainThread(new Runnable() {
            public void run() {
                if (finalState == AppState.REGISTERED) {
                    if (onRegisterResult == null) {
                        return;
                    }

                    try {
                        JSONObject successData = new JSONObject();
                        successData.put("registered", true);

                        onRegisterResult.success(successData.toString());
                        onRegisterResult = null;
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
    }

    public void onEvent(final ConnectionStatus status) {
        Log("on ConnectionStatus received");

        String connectionStatus = null;
        switch (status) {
            case CONNECTED:
                Log("Connected to the chabok");
                connectionStatus = "CONNECTED";
                break;
            case CONNECTING:
                Log("Connecting to the chabok");
                connectionStatus = "CONNECTING";
                break;
            case NOT_INITIALIZED:
                Log("NOT_INITIALIZED");
                connectionStatus = "DISCONNECTED";
                break;
            case SOCKET_TIMEOUT:
                Log("SOCKET_TIMEOUT");
                connectionStatus = "DISCONNECTED";
                break;
            case DISCONNECTED:
                Log("Disconnected");
                connectionStatus = "DISCONNECTED";
            default:
                Log("Unknown");
                connectionStatus = "UNKNOWN";
        }

        lastConnectionStatues = connectionStatus;

        invokeMethodOnUiThread("onConnectionHandler", lastConnectionStatues);
    }

    public void onEvent(final PushMessage msg) {
        Log("on PushMessage received");

        lastChabokMessage = msg.toJson();

        invokeMethodOnUiThread("onMessageHandler", lastChabokMessage);
    }

    private static JSONObject getJsonFromNotificationAction(ChabokNotificationAction notificationAction) {
        String notifAction = "OPENED";

        if (notificationAction.type == ChabokNotificationAction.ActionType.ActionTaken) {
            notifAction = "ACTION_TAKEN";
        } else if (notificationAction.type == ChabokNotificationAction.ActionType.Dismissed) {
            notifAction = "DISMISSED";
        }

        JSONObject notifActionJson = new JSONObject();
        try {
            notifActionJson.put("type", notifAction);
            notifActionJson.put("id", notificationAction.actionID);
            notifActionJson.put("url", notificationAction.actionUrl);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return notifActionJson;
    }

    private static Map<String, Object> jsonToMap(JSONObject json) throws JSONException {
        Map<String, Object> retMap = new HashMap<>();
        if (json != JSONObject.NULL) {
            retMap = toMap(json);
        }
        return retMap;
    }

    private static Map<String, Object> toMap(JSONObject object) throws JSONException {
        Map<String, Object> map = new HashMap<>();
        Iterator<String> keysItr = object.keys();
        while (keysItr.hasNext()) {
            String key = keysItr.next();
            Object value = object.get(key);

            if (value instanceof JSONArray) {
                value = toList((JSONArray) value);
            } else if (value instanceof JSONObject) {
                value = toMap((JSONObject) value);
            }
            map.put(key, value);
        }
        return map;
    }

    private static List<Object> toList(JSONArray array) throws JSONException {
        List<Object> list = new ArrayList<>();
        for (int i = 0; i < array.length(); i++) {
            Object value = array.get(i);
            if (value instanceof JSONArray) {
                value = toList((JSONArray) value);
            } else if (value instanceof JSONObject) {
                value = toMap((JSONObject) value);
            }
            list.add(value);
        }
        return list;
    }

    private static JSONObject objectToJSONObject(Object object) {
        Object json = null;
        JSONObject jsonObject = null;
        try {
            json = new JSONTokener(object.toString()).nextValue();
        } catch (JSONException e) {
            e.printStackTrace();
        }
        if (json instanceof JSONObject) {
            jsonObject = (JSONObject) json;
        }
        return jsonObject;
    }

    private static JSONObject bundleToJson(Bundle bundle) {
        JSONObject json = new JSONObject();
        Set<String> keys = bundle.keySet();
        for (String key : keys) {
            try {
                json.put(key, bundle.get(key));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return json;
    }
}
