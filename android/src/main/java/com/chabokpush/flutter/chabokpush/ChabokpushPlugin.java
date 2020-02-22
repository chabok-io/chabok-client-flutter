package com.chabokpush.flutter.chabokpush;

import android.content.Context;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;

import com.adpdigital.push.AdpPushClient;
import com.adpdigital.push.AppState;
import com.adpdigital.push.Callback;
import com.adpdigital.push.ChabokEvent;
import com.adpdigital.push.ChabokNotification;
import com.adpdigital.push.ChabokNotificationAction;
import com.adpdigital.push.ConnectionStatus;
import com.adpdigital.push.Datetime;
import com.adpdigital.push.DeferredDataListener;
import com.adpdigital.push.NotificationHandler;
import com.adpdigital.push.PushMessage;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.lang.ref.WeakReference;
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
    private static final Object initLock = new Object();
    private static Result onRegisterResult;

    private static ChabokNotification coldStartChabokNotification;
    private static ChabokNotificationAction coldStartChabokNotificationAction;
    private static String lastShownMessageId;
    private static String lastOpenedMessageId;

    private static String lastConnectionStatues;
    private static String lastChabokMessage;

    private static String deferredDeepLink;
    private static String referrerId;

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
        logDebug("registerWith() invoked");

        if (instance == null) {
            instance = new ChabokpushPlugin();
        }
        instance.init(registrar.context(), registrar.messenger());
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        logDebug("onAttachedToEngine() invoked");

        init(flutterPluginBinding.getApplicationContext(),
                flutterPluginBinding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        logDebug("onDetachedFromEngine() invoked");

        methodChannel.setMethodCallHandler(null);
        methodChannel = null;

        if (activity != null) {
            activity.clear();
        }
        activity = null;

        if (context != null) {
            context.clear();
        }
        context = null;

        AdpPushClient.get().removeListener(this);
        AdpPushClient.get().dismiss();
    }

    private void init(Context applicationContext,
                      BinaryMessenger messenger) {
        synchronized (initLock) {
            if (methodChannel != null) {
                return;
            }

            context = new WeakReference<>(applicationContext);

            methodChannel = new MethodChannel(messenger, METHOD_CHANNEL_NAME);
            methodChannel.setMethodCallHandler(this);

            postInit();
        }
    }

    private void postInit() {
        if (context != null && context.get() != null && AdpPushClient.getContext() == null) {
            AdpPushClient.setApplicationContext(context.get());
        }

        AdpPushClient.get().addListener(this);
        AdpPushClient.get().addNotificationHandler(new NotificationHandler() {
            @Override
            public boolean buildNotification(ChabokNotification message,
                                             NotificationCompat.Builder builder) {
                coldStartChabokNotification = message;
                coldStartChabokNotificationAction = null;

                handleNotificationShown();

                return super.buildNotification(message, builder);
            }

            @Override
            public boolean notificationOpened(ChabokNotification message,
                                              ChabokNotificationAction notificationAction) {
                coldStartChabokNotification = message;
                coldStartChabokNotificationAction = notificationAction;

                handleNotificationOpened();

                return super.notificationOpened(message, notificationAction);
            }
        });

        AdpPushClient.get().setDeferredDataListener(new DeferredDataListener() {
            @Override
            public boolean launchReceivedDeeplink(Uri uri) {
                logDebug("launchReceivedDeeplink");

                if (uri != null) {
                    deferredDeepLink = uri.toString();
                    handleDeepLink();
                }
                return false;
            }

            @Override
            public void onReferralReceived(String id) {
                logDebug("onReferralReceived");

                referrerId = id;
                handleReferralId();
            }
        });
    }

    public ChabokpushPlugin() {
        logDebug("ChabokpushPlugin() invoked");
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String method = call.method;
        Map<String, Object> arguments = (Map<String, Object>) call.arguments;

        logDebug("----------- onMethodCall: action = " + method + " , args = " + arguments);

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
                List<String> tags = (List<String>) arguments.get("tags");
                addTags(tags.toArray(new String[tags.size()]), result);
                break;
            }
            case "removeTag": {
                List<String> tags = (List<String>) arguments.get("tags");
                removeTags(tags.toArray(new String[tags.size()]), result);
                break;
            }
            case "setUserAttributes":
                JSONObject attributes = new JSONObject(arguments);
                setUserAttributes(attributes);
                break;
            case "track": {
                String trackName = arguments.get("trackName").toString();
                try {
                    JSONObject data = new JSONObject((Map) arguments.get("data"));
                    track(trackName, data);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                break;
            }
            case "trackPurchase": {
                String trackName = arguments.get("trackName").toString();
                try {
                    JSONObject data = new JSONObject((Map) arguments.get("data"));
                    trackPurchase(trackName, data);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                break;
            }
            case "setOnMessageCallback":
                handleChabokMessage();
                break;
            case "setOnConnectionHandler":
                handleConnectionStaus();
                break;
            case "setOnNotificationOpenedHandler":
                coldStartChabokNotification = AdpPushClient.get().getLastNotificationData();
                coldStartChabokNotificationAction = AdpPushClient.get().getLastNotificationAction();
                handleNotificationOpened();
                break;
            case "setOnShowNotificationHandler":
                coldStartChabokNotification = AdpPushClient.get().getLastNotificationData();
                handleNotificationShown();
                break;
            case "incrementUserAttribute":
                String attributeKey1 = arguments.get("attributeKey").toString();
                Double attributesValue1 = (Double) arguments.get("attributeValue");
                incrementUserAttribute(attributeKey1, attributesValue1);
                break;
            case "decrementUserAttribute": {
                String attributeKey = arguments.get("attributeKey").toString();
                Double attributesValue = (Double) arguments.get("attributeValue");
                decrementUserAttribute(attributeKey, attributesValue);
                break;
            }
            case "addToUserAttributeArray": {
                String attributeKey = arguments.get("attributeKey").toString();
                List<String> attributesValues = (List<String>) arguments.get("attributeValues");
                addToUserAttributeArray(attributeKey,
                        attributesValues.toArray(new String[attributesValues.size()]));
                break;
            }
            case "removeFromUserAttributeArray": {
                String attributeKey = arguments.get("attributeKey").toString();
                List<String> attributesValues = (List<String>) arguments.get("attributeValues");
                removeFromUserAttributeArray(attributeKey,
                        attributesValues.toArray(new String[attributesValues.size()]));
                break;
            }
            case "unsetUserAttributes": {
                List<String> attributesValues = (List<String>) arguments.get("attributeValues");
                unsetUserAttributes(attributesValues.toArray(new String[attributesValues.size()]));
                break;
            }
            case "setOnDeepLinkHandler":
                handleDeepLink();
                break;
            case "setOnReferralHandler":
                handleReferralId();
                break;
            case "subscribe": {
                String channelName = arguments.get("channelName").toString();
                subscribe(channelName, result);
                break;
            }
            case "unsubscribe": {
                String channelName = arguments.get("channelName").toString();
                unsubscribe(channelName, result);
                break;
            }
            default:
                replyNotImplemented(result);
                break;
        }
    }

    public void login(String userId, Result result) {
        onRegisterResult = result;
        AdpPushClient.get().login(userId);
    }

    public void logout() {
        AdpPushClient.get().logout();
    }

    public void track(String trackName, JSONObject data) {
        try {
            if (data != null) {
                JSONObject modifiedEvents = new JSONObject();
                Iterator<String> keys = data.keys();
                while (keys.hasNext()) {
                    String key = keys.next();
                    if (key.startsWith("@CHKDATE_")) {
                        String actualKey = key.substring(9);
                        if (data.get(key) instanceof String) {
                            modifiedEvents.put(actualKey,
                                    new Datetime(Long.valueOf(data.getString(key))));
                        }
                    } else {
                        modifiedEvents.put(key, data.get(key));
                    }
                }
                AdpPushClient.get().track(trackName, modifiedEvents);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void trackPurchase(String trackName, JSONObject data) {
        try {
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
                JSONObject modifiedEvents = new JSONObject();
                Iterator<String> keys = eventData.keys();
                while (keys.hasNext()) {
                    String key = keys.next();
                    if (key.startsWith("@CHKDATE_")) {
                        String actualKey = key.substring(9);
                        if (eventData.get(key) instanceof String) {
                            modifiedEvents.put(actualKey,
                                    new Datetime(Long.valueOf(eventData.getString(key))));
                        }
                    } else {
                        modifiedEvents.put(key, eventData.get(key));
                    }
                }
                chabokEvent.setData(modifiedEvents);
            }

            AdpPushClient.get().trackPurchase(trackName, chabokEvent);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void publish(JSONObject message, final Result result) {
        try {
            JSONObject dataMap = null;
            if (message.has("data")) {
                dataMap = message.getJSONObject("data");
            }
            String body = message.getString("content");
            String userId = message.getString("userId");
            String channel = message.getString("channel");

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

    public void subscribe(final String channel, final Result result) {
        AdpPushClient.get().subscribe(channel, new Callback() {
            @Override
            public void onSuccess(Object o) {
                replySuccess(result, channel);
            }

            @Override
            public void onFailure(Throwable throwable) {
                replyError(result, "-1", throwable.getMessage(), throwable);
            }
        });
    }

    public void unsubscribe(final String channel, final Result result) {
        AdpPushClient.get().unsubscribe(channel, new Callback() {
            @Override
            public void onSuccess(Object o) {
                replySuccess(result, channel);
            }

            @Override
            public void onFailure(Throwable throwable) {
                replyError(result, "-1", throwable.getMessage(), throwable);
            }
        });
    }

    public void addTags(String[] tags, final Result result) {
        AdpPushClient.get().addTag(tags, new Callback() {
            @Override
            public void onSuccess(Object o) {
                logDebug("The addTags onSuccess: invoked");
                replySuccess(result, "Tag Added");
            }

            @Override
            public void onFailure(Throwable throwable) {
                logDebug("The addTag onFailure: invoked");
                replyError(result, "-1", throwable.getMessage(), throwable);
            }
        });
    }

    public void removeTags(String[] tags, final Result result) {
        AdpPushClient.get().removeTag(tags, new Callback() {
            @Override
            public void onSuccess(Object o) {
                logDebug("The removeTag onSuccess: invoked");
                replySuccess(result, "Tag removed");
            }

            @Override
            public void onFailure(Throwable throwable) {
                logDebug("The removeTag onFailure: invoked");
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

    public void setUserAttributes(JSONObject userInfo) {
        if (userInfo != null) {
            HashMap<String, Object> userInfoMap = null;
            try {
                userInfoMap = (HashMap<String, Object>) jsonToMap(userInfo);
                HashMap<String, Object> modifiedInfo = new HashMap<>();
                for (Map.Entry<String, Object> entry : userInfoMap.entrySet()) {
                    if (entry.getKey().startsWith("@CHKDATE_")) {
                        String actualKey = entry.getKey().substring(9);
                        if (entry.getValue() instanceof String) {
                            modifiedInfo.put(actualKey,
                                    new Datetime(Long.valueOf((String) entry.getValue())));
                        }
                    } else {
                        modifiedInfo.put(entry.getKey(), entry.getValue());
                    }
                }
                AdpPushClient.get().setUserAttributes(modifiedInfo);
            } catch (JSONException e) {
                e.printStackTrace();
            }
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
        AdpPushClient.get().unsetUserAttributes(attributes);
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
        logDebug("on AppState received");

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
        logDebug("on ConnectionStatus received");

        String connectionStatus = null;
        switch (status) {
            case CONNECTED:
                logDebug("Connected to the chabok");
                connectionStatus = "CONNECTED";
                break;
            case CONNECTING:
                logDebug("Connecting to the chabok");
                connectionStatus = "CONNECTING";
                break;
            case NOT_INITIALIZED:
                logDebug("NOT_INITIALIZED");
                connectionStatus = "NOT_INITIALIZED";
                break;
            case SOCKET_TIMEOUT:
                logDebug("SOCKET_TIMEOUT");
                connectionStatus = "SocketTimeout";
                break;
            case DISCONNECTED:
                logDebug("Disconnected");
                connectionStatus = "DISCONNECTED";
            default:
                logDebug("Unknown");
                connectionStatus = "UNKNOWN";
        }

        lastConnectionStatues = connectionStatus;

        handleConnectionStaus();
    }

    public void onEvent(final PushMessage msg) {
        logDebug("on PushMessage received");

        JSONObject message = new JSONObject();

        try {
            message.put("id", msg.getId());
            message.put("body", msg.getBody());
            message.put("sound", msg.getSound());
            message.put("sentId", msg.getSentId());
            message.put("channel", msg.getChannel());
            message.put("senderId", msg.getSenderId());
            message.put("expireAt", msg.getExpireAt());
            message.put("alertText", msg.getAlertText());
            message.put("createdAt", msg.getCreatedAt());
            message.put("alertTitle", msg.getAlertTitle());
            message.put("intentType", msg.getIntentType());
            message.put("receivedAt", msg.getReceivedAt());

            if (msg.getData() != null) {
                message.put("data", msg.getData());
            }

            if (msg.getNotification() != null) {
                message.put("notification", msg.getNotification());
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        lastChabokMessage = message.toString();

        handleChabokMessage();
    }

    private void handleNotificationOpened() {
        if (!isAttachedToHost()) {
            return;
        }

        if (coldStartChabokNotificationAction != null &&
                coldStartChabokNotification != null &&
                (lastOpenedMessageId == null ||
                        !lastOpenedMessageId.contentEquals(coldStartChabokNotification.getId()))) {
            lastOpenedMessageId = coldStartChabokNotification.getId();

            final JSONObject response = getJsonNotificationObject(coldStartChabokNotification,
                    coldStartChabokNotificationAction);
            invokeMethodOnUiThread("onNotificationOpenedHandler", response.toString());
        }
    }

    private void handleNotificationShown() {
        if (!isAttachedToHost()) {
            return;
        }

        if (coldStartChabokNotification != null &&
                (lastShownMessageId == null ||
                        !lastShownMessageId.contentEquals(coldStartChabokNotification.getId()))) {
            lastShownMessageId = coldStartChabokNotification.getId();

            final JSONObject response = getJsonNotificationObject(coldStartChabokNotification, null);
            invokeMethodOnUiThread("onShowNotificationHandler", response.toString());
        }
    }

    private void handleDeepLink() {
        if (isAttachedToHost() && !TextUtils.isEmpty(deferredDeepLink)) {
            invokeMethodOnUiThread("setOnDeepLinkHandler", deferredDeepLink);
        }
    }

    private void handleReferralId() {
        if (isAttachedToHost() && !TextUtils.isEmpty(referrerId)) {
            invokeMethodOnUiThread("setOnReferralHandler", referrerId);
        }
    }

    private void handleConnectionStaus() {
        if (isAttachedToHost() && !TextUtils.isEmpty(lastConnectionStatues)) {
            invokeMethodOnUiThread("onConnectionHandler", lastConnectionStatues);
        }
    }

    private void handleChabokMessage() {
        if (isAttachedToHost() && !TextUtils.isEmpty(lastChabokMessage)) {
            invokeMethodOnUiThread("onMessageHandler", lastChabokMessage);
        }
    }

    private static JSONObject getJsonNotificationObject(ChabokNotification message,
                                                        ChabokNotificationAction notificationAction) {
        final JSONObject response = new JSONObject();
        try {
            if (notificationAction != null) {
                if (notificationAction.actionID != null) {
                    response.put("actionId", notificationAction.actionID);
                }
                if (notificationAction.actionUrl != null) {
                    response.put("actionUrl", notificationAction.actionUrl);
                }

                if (notificationAction.type == ChabokNotificationAction.ActionType.Opened) {
                    response.put("actionType", "opened");
                } else if (notificationAction.type == ChabokNotificationAction.ActionType.Dismissed) {
                    response.put("actionType", "dismissed");
                } else if (notificationAction.type == ChabokNotificationAction.ActionType.ActionTaken) {
                    response.put("actionType", "action_taken");
                }
            } else {
                response.put("actionType", "shown");
            }

            JSONObject msgMap = new JSONObject();

            if (message.getTitle() != null) {
                msgMap.put("title", message.getTitle());
            }
            if (message.getId() != null) {
                msgMap.put("id", message.getId());
            }

            if (message.getText() != null) {
                msgMap.put("body", message.getText());
            }
            if (message.getTrackId() != null) {
                msgMap.put("trackId", message.getTrackId());
            }
            if (message.getTopicName() != null) {
                msgMap.put("channel", message.getTopicName());
            }

            if (message.getSound() != null) {
                msgMap.put("sound", message.getSound());
            }

            try {
                Bundle data = message.getExtras();
                if (data != null) {
                    msgMap.put("data", data);
                } else if (message.getMessage() != null) {
                    PushMessage payload = message.getMessage();
                    //Chabok message data
                    if (payload != null) {
                        msgMap.put("data", payload.getData());
                    }
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }

            response.put("message", msgMap);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return response;
    }

    private static JSONObject getJsonFromNotificationAction(ChabokNotificationAction notificationAction) {
        String notifAction = "shown";
        if (notificationAction != null) {
            if (notificationAction.type == ChabokNotificationAction.ActionType.ActionTaken) {
                notifAction = "action_taken";
            } else if (notificationAction.type == ChabokNotificationAction.ActionType.Dismissed) {
                notifAction = "dismissed";
            } else if (notificationAction.type == ChabokNotificationAction.ActionType.Opened) {
                notifAction = "opened";
            }
        }

        JSONObject notifActionJson = new JSONObject();
        try {
            notifActionJson.put("type", notifAction);
            if (notificationAction != null) {
                notifActionJson.put("id", notificationAction.actionID);
                notifActionJson.put("url", notificationAction.actionUrl);
            }
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
