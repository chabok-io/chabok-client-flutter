package com.chabokpush.flutter.chabokpush;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** ChabokpushPlugin */
public class ChabokpushPlugin implements MethodCallHandler {
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "chabokpush");
    channel.setMethodCallHandler(new ChabokpushPlugin());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else {
      result.notImplemented();
    }
  }

  public void init(String appId, String apiKey, String username, String password,
                   boolean devMode, CallbackContext callbackContext) {
    Class activityClass = this.cordova.getActivity().getClass();
    Context context = getApplicationContext();

    AdpPushClient chabok = AdpPushClient.init(
            context,
            activityClass,
            appId,
            apiKey,
            username,
            password
    );

    if (chabok != null) {
      android.util.Log.d(TAG, "init: Initilized sucessfully");

      callbackContext.success("Initilized sucessfully");
    } else {
      android.util.Log.d(TAG, "Could not init chabok parameters");

      callbackContext.error("Could not init chabok parameters");
      return;
    }

    chabok.setDevelopment(devMode);
    chabok.addListener(this);
  }

  public void registerAsGuest(CallbackContext callbackContext) {
    this.onRegisterCallbackContext = callbackContext;
    AdpPushClient.get().registerAsGuest();
  }

  public void register(String userId, CallbackContext callbackContext) {
    this.onRegisterCallbackContext = callbackContext;
    AdpPushClient.get().register(userId);
  }

  public void publish(JSONObject message, CallbackContext callbackContext) {
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
          callbackContext.success("Message published");
        }

        @Override
        public void onFailure(Throwable throwable) {
          callbackContext.error(throwable.getMessage());
        }
      });
    } catch (JSONException e) {
      e.printStackTrace();
      callbackContext.error(e.getMessage());
    }
  }

  public void unregister(){
    AdpPushClient.get().unregister();
  }

  public void track(String trackName, JSONObject data){
    AdpPushClient.get().track(trackName, data);
  }

  public void addTag(String tagName, CallbackContext callbackContext){
    AdpPushClient.get().addTag(tagName, new Callback() {
      @Override
      public void onSuccess(Object o) {
        android.util.Log.d(TAG, "The addTags onSuccess: called");
        callbackContext.success("Tag Added");
      }

      @Override
      public void onFailure(Throwable throwable) {
        android.util.Log.d(TAG, "The addTag onFailure: called");
        callbackContext.error(throwable.getMessage());
      }
    });
  }

  public void removeTag(String tagName, CallbackContext callbackContext){
    AdpPushClient.get().removeTag(tagName, new Callback() {
      @Override
      public void onSuccess(Object o) {
        android.util.Log.d(TAG, "The removeTag onSuccess: called");
        callbackContext.success("Tag removed");
      }

      @Override
      public void onFailure(Throwable throwable) {
        android.util.Log.d(TAG, "The removeTag onFailure: called");
        callbackContext.error(throwable.getMessage());
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

  public void setUserInfo(JSONObject userInfo){
    try {
      HashMap<String, Object> userInfoMap = (HashMap<String, Object>) jsonToMap(userInfo);
      AdpPushClient.get().setUserInfo(userInfoMap);
    } catch (Exception e){
      e.printStackTrace();
    }
  }

  public String getUserId(CallbackContext callbackContext){
    String userId = AdpPushClient.get().getUserId();

    if (callbackContext != null){
      if (userId != null){
        callbackContext.success(userId);
      } else {
        callbackContext.error("The userId is null, You didn't register yet!");
      }
    }

    return userId;
  }

  public String getInstallation(CallbackContext callbackContext){
    String installationId = AdpPushClient.get().getUserId();

    if (callbackContext != null){
      if (installationId != null){
        callbackContext.success(installationId);
      } else {
        callbackContext.error("The installationId is null, You didn't register yet!");
      }
    }

    return installationId;
  }

  public void resetBadge(){
    AdpPushClient.get().resetBadge();
  }

  public void setOnMessageCallbackContext(CallbackContext callbackContext){
    this.onMessageCallbackContext = callbackContext;
  }

  public void setOnConnectionStatusCallbackContext(CallbackContext callbackContext){
    this.onConnectionStatusCallbackContext = callbackContext;
  }

  public void onEvent(AppState state){
    android.util.Log.d(TAG, "=================== onEvent: state = " + state + ", this.onRegisterCallbackContext = " + this.onRegisterCallbackContext);
    if (state == AppState.REGISTERED){
      if ( this.onRegisterCallbackContext == null){
        return;
      }

      try {
        JSONObject successData = new JSONObject();
        successData.put("registered", true);

        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, successData);
        this.onRegisterCallbackContext.sendPluginResult(pluginResult);
      } catch (JSONException e) {
        e.printStackTrace();
      }

    }
  }

  public void onEvent(final ConnectionStatus status) {
    String connectionStatus = null;

    switch (status) {
      case CONNECTED:
        android.util.Log.d(TAG, "Connected to the chabok");
        connectionStatus = "CONNECTED";
        break;
      case CONNECTING:
        android.util.Log.d(TAG, "Connecting to the chabok");
        connectionStatus = "CONNECTING";
        break;
      case DISCONNECTED:
        android.util.Log.d(TAG, "Disconnected");
        connectionStatus = "DISCONNECTED";
        break;
      case NOT_INITIALIZED:
        android.util.Log.d(TAG, "NOT_INITIALIZED");
        connectionStatus = "NOT_INITIALIZED";
        break;
      case SOCKET_TIMEOUT:
        android.util.Log.d(TAG, "SOCKET_TIMEOUT");
        connectionStatus = "SOCKET_TIMEOUT";
        break;
      default:
        android.util.Log.d(TAG, "Disconnected");
        connectionStatus = "DISCONNECTED";
    }

    if (connectionStatus != null && this.onConnectionStatusCallbackContext != null){
      successCallback(this.onConnectionStatusCallbackContext, connectionStatus);
    }
  }

  public void onEvent(final PushMessage msg) {
    final CallbackContext callbackContext = this.onMessageCallbackContext;

    this.cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
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

        if (message != null && callbackContext != null) {
          successCallback(callbackContext, message);
        }
      }
    });
  }

  public void successCallback(CallbackContext callbackContext, String message){
    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, message);
    pluginResult.setKeepCallback(true);
    callbackContext.sendPluginResult(pluginResult);
  }

  public void successCallback(CallbackContext callbackContext, JSONObject data){
    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, data);
    pluginResult.setKeepCallback(true);
    callbackContext.sendPluginResult(pluginResult);
  }

  public void failureCallback(CallbackContext callbackContext, String message){
    PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, message);
    pluginResult.setKeepCallback(true);
    callbackContext.sendPluginResult(pluginResult);
  }

  public void failureCallback(CallbackContext callbackContext, JSONObject data){
    PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, data);
    pluginResult.setKeepCallback(true);
    callbackContext.sendPluginResult(pluginResult);
  }

  /**
   * Gets the application context from cordova's main activity.
   *
   * @return the application context
   */
  private Context getApplicationContext() {
    return this.cordova.getActivity().getApplicationContext();
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
}
