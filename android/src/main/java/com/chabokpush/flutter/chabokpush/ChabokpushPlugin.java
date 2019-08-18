package com.chabokpush.flutter.chabokpush;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.app.Activity;
import android.content.Context;
import java.util.HashMap;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import com.adpdigital.push.Callback;
import com.adpdigital.push.AppState;
import com.adpdigital.push.ChabokMessage;
import com.adpdigital.push.ChabokNotification;
import com.adpdigital.push.ChabokNotificationAction;
import com.adpdigital.push.NotificationHandler;
import com.adpdigital.push.PushMessage;
import com.adpdigital.push.ChabokEvent;
import com.adpdigital.push.AdpPushClient;
import com.adpdigital.push.ConnectionStatus;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** ChabokpushPlugin */
public class ChabokpushPlugin extends FlutterRegistrarResponder implements MethodCallHandler {
  private static Context context = null;
  private static final String TAG = "CHK";
  private static Activity activity = null;

  private Result onRegisterResult;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    context = registrar.context();
    activity = registrar.activity();

//    final MethodChannel channel = new MethodChannel(registrar.messenger(), "chabokpush");
//    channel.setMethodCallHandler(new ChabokpushPlugin());

    ChabokpushPlugin plugin = new ChabokpushPlugin();

//    plugin.waitingForUserPrivacyConsent = false;
    plugin.channel = new MethodChannel(registrar.messenger(), "chabokpush");
    plugin.channel.setMethodCallHandler(plugin);
    plugin.flutterRegistrar = registrar;
  }

  private void Log(String message){
    android.util.Log.d(TAG, message);
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
//    if (call.method.equals("getPlatformVersion")) {
//      result.success("Android " + android.os.Build.VERSION.RELEASE);
//    } else {
//      result.notImplemented();
//    }
    String action = call.method;
    Map<String, Object> arguments = (Map<String, Object>) call.arguments;

    Log("----------- onMethodCall: action = " + action + " , args = " + arguments);

    if (action.equals("init")){
      String appId = arguments.get("appId").toString();
      String apiKey = arguments.get("apiKey").toString();
      String username = arguments.get("username").toString();
      String password = arguments.get("password").toString();
      String senderId = arguments.get("senderId").toString();
      boolean devMode = Boolean.parseBoolean(arguments.get("devMode").toString());

      init(appId, apiKey, username, password, senderId, devMode, result);
    } else if (action.equals("registerAsGuest")){
      String GUID = null;

      if (arguments.containsKey("guestId")){
        GUID = arguments.get("guestId").toString();
      }

      registerAsGuest(GUID, result);
    } else if (action.equals("register")){
      String userId = arguments.get("userId").toString();
      register(userId, result);
    } else if (action.equals("publish")){
      JSONObject messageJson = new JSONObject(arguments);

      publish(messageJson, result);
    } else if (action.equals("getUserId")){
      getUserId(result);
    } else if (action.equals("getInstallation")){
      getInstallation(result);
    } else if (action.equals("setDefaultTracker")){
      String defaultTracker = arguments.get("defaultTracker").toString();
      setDefaultTracker(defaultTracker);
    } else if (action.equals("resetBadge")){
      resetBadge();
    } else if (action.equals("appWillOpenUrl")){
      String url = arguments.get("url").toString();

      appWillOpenUrl(url);
    } else if (action.equals("unregister")){
      unregister();
    } else if (action.equals("addTag")){
      String tagName = arguments.get("tagName").toString();

      addTag(tagName, result);
    } else if (action.equals("removeTag")){
      String tagName = arguments.get("tagName").toString();

      removeTag(tagName, result);
    } else if (action.equals("setUserAttributes")){
      JSONObject attributes = new JSONObject(arguments);

      setUserAttributes(attributes);
    } else if (action.equals("track")){
      String trackName = arguments.get("trackName").toString();
      try {
        JSONObject data = new JSONObject(arguments.get("data").toString());

        track(trackName, data);
      } catch (JSONException e) {
        e.printStackTrace();
      }
    } else if (action.equals("trackPurchase")){
      String trackName = arguments.get("trackName").toString();
      try {
        JSONObject data = new JSONObject(arguments.get("eventData").toString());

        double revenue = 0;
        String currency = null;
        JSONObject eventData = null;
        if (!data.has("revenue")){
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
        if (currency != null){
          chabokEvent.setRevenue(revenue, currency);
        }

        if (eventData != null){
          chabokEvent.setData(eventData);
        }

        trackPurchase(trackName, chabokEvent);
      } catch (JSONException e) {
        e.printStackTrace();
      }
    } else {
      result.notImplemented();
    }
  }


  public void init(String appId, String apiKey, String username, String password, String senderId,
                   boolean devMode, Result result) {
    AdpPushClient chabok = AdpPushClient.init(
            context,
            activity.getClass(),
            appId,
            apiKey,
            username,
            password,
            senderId
    );

    if (chabok != null) {
     Log("init: Initialized successfully");

      result.success("Initialized successfully");
    } else {
      Log("Could not init Chabok parameters");

      result.error("NOT_INITIALIZE", "Could not init Chabok parameters", null);
      return;
    }

    chabok.setDevelopment(devMode);
    chabok.addListener(this);
  }

  public void registerAsGuest(String guid ,Result result) {
    this.onRegisterResult = result;
    AdpPushClient.get().registerAsGuest(guid);
  }

  public void register(String userId, Result result) {
    this.onRegisterResult = result;
    AdpPushClient.get().register(userId);
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
          result.success("Message published");
        }

        @Override
        public void onFailure(Throwable throwable) {
          result.error(TAG, throwable.getMessage(), throwable);
        }
      });
    } catch (JSONException e) {
      e.printStackTrace();
      result.error(TAG, e.getMessage(), e);
    }
  }

  public void unregister(){
    AdpPushClient.get().unregister();
  }

  public void track(String trackName, JSONObject data){
    AdpPushClient.get().track(trackName, data);
  }

  public void trackPurchase(String trackName, ChabokEvent eventData){
    AdpPushClient.get().trackPurchase(trackName, eventData);
  }

  public void addTag(String tagName, final Result result){
    AdpPushClient.get().addTag(tagName, new Callback() {
      @Override
      public void onSuccess(Object o) {
        Log("The addTags onSuccess: called");
        result.success("Tag Added");
      }

      @Override
      public void onFailure(Throwable throwable) {
        Log("The addTag onFailure: called");
        result.error(TAG, throwable.getMessage(), throwable);
      }
    });
  }

  public void removeTag(String tagName, final Result result){
    AdpPushClient.get().removeTag(tagName, new Callback() {
      @Override
      public void onSuccess(Object o) {
        android.util.Log.d(TAG, "The removeTag onSuccess: called");
        result.success("Tag removed");
      }

      @Override
      public void onFailure(Throwable throwable) {
        android.util.Log.d(TAG, "The removeTag onFailure: called");
        result.error(TAG, throwable.getMessage(), throwable);
      }
    });
  }

  public void setDefaultTracker(String defaultTracker){
    AdpPushClient.get().setDefaultTracker(defaultTracker);
  }

  public void appWillOpenUrl(String link) {
    if (link == null) {
      return;
    }

    Uri uri = Uri.parse(link);
    AdpPushClient.get().appWillOpenUrl(uri);
  }

  public void setUserAttributes(JSONObject attributes){
    try {
      HashMap<String, Object> attributesMap = (HashMap<String, Object>) jsonToMap(attributes);
      AdpPushClient.get().setUserAttributes(attributesMap);
    } catch (Exception e){
      e.printStackTrace();
    }
  }

  public String getUserId(Result result){
    String userId = AdpPushClient.get().getUserId();

    if (result != null){
      if (userId != null){
        result.success(userId);
      } else {
        result.error(TAG, "The userId is null, You didn't register yet!", null);
      }
    }

    return userId;
  }

  public String getInstallation(Result result){
    String installationId = AdpPushClient.get().getUserId();

    if (result != null){
      if (installationId != null){
        result.success(installationId);
      } else {
        result.error(TAG, "The installationId is null, You didn't register yet!", null);
      }
    }

    return installationId;
  }

  public void resetBadge(){
    AdpPushClient.get().resetBadge();
  }

  public void setOnConnectionStatusResult(Result result){
    this.onConnectionStatusResult = result;
  }

  public void onEvent(AppState state){

    final AppState finalState = state;
    this.activity.runOnUiThread(new Runnable() {
      public void run() {
        Log("=================== onEvent: state = " + finalState + ", this.onRegisterResult = " + onRegisterResult);
        if (finalState == AppState.REGISTERED){
          if ( onRegisterResult == null){
            return;
          }

          try {
            JSONObject successData = new JSONObject();
            successData.put("registered", true);

            onRegisterResult.success(successData.toString());
          } catch (JSONException e) {
            e.printStackTrace();
          }

        }
      }
    });
  }

  public void onEvent(final ConnectionStatus status) {
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
      case DISCONNECTED:
        Log("Disconnected");
        connectionStatus = "DISCONNECTED";
        break;
      case NOT_INITIALIZED:
        Log("NOT_INITIALIZED");
        connectionStatus = "NOT_INITIALIZED";
        break;
      case SOCKET_TIMEOUT:
        Log("SOCKET_TIMEOUT");
        connectionStatus = "SOCKET_TIMEOUT";
        break;
      default:
        Log("Disconnected");
        connectionStatus = "DISCONNECTED";
    }

    if (this.onConnectionStatusResult != null){
      successCallback(this.onConnectionStatusResult, connectionStatus);
    }
  }

  public void onEvent(final PushMessage msg) {
    invokeMethodOnUiThread("onMessageHandler", msg.toJson());
      }

  public void successCallback(Result result, String message){
    result.success(message);
  }

  public void successCallback(Result result, JSONObject data){
    result.success(data);
  }

  public void failureCallback(Result result, String message){
    result.error(TAG, message, null);
  }

  public void failureCallback(Result result, JSONObject data){
    result.error(TAG, data.toString(), null);
  }

  /**
   * Gets the application context from cordova's main activity.
   *
   * @return the application context
   */
  private Context getApplicationContext() {
    return this.context;
  }

  public static Map<String, Object> jsonToMap(JSONObject json) throws JSONException {
    Map<String, Object> retMap = new HashMap<String, Object>();

    if(json != JSONObject.NULL) {
      retMap = toMap(json);
    }
    return retMap;
  }

  public static Map<String, Object> toMap(JSONObject object) throws JSONException {
    Map<String, Object> map = new HashMap<String, Object>();

    Iterator<String> keysItr = object.keys();
    while(keysItr.hasNext()) {
      String key = keysItr.next();
      Object value = object.get(key);

      if(value instanceof JSONArray) {
        value = toList((JSONArray) value);
      }

      else if(value instanceof JSONObject) {
        value = toMap((JSONObject) value);
      }
      map.put(key, value);
    }
    return map;
  }

  public static List<Object> toList(JSONArray array) throws JSONException {
    List<Object> list = new ArrayList<Object>();
    for(int i = 0; i < array.length(); i++) {
      Object value = array.get(i);
      if(value instanceof JSONArray) {
        value = toList((JSONArray) value);
      }

      else if(value instanceof JSONObject) {
        value = toMap((JSONObject) value);
      }
      list.add(value);
    }
    return list;
  }

  public static JSONObject objectToJSONObject(Object object){
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

  public JSONObject bundleToJson(Bundle bundle) {
    JSONObject json = new JSONObject();
    Set<String> keys = bundle.keySet();
    for (String key : keys) {
      try {
        json.put(key, bundle.get(key));
        //json.put(key, JSONObject.wrap(bundle.get(key)));
      } catch (JSONException e) {

      }
    }

    return json;
  }
}
