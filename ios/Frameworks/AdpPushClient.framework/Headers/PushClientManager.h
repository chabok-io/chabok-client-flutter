//
//  PushClientManager.h
//  AdpPushClient
//
//  Created by Chabok Realtime Solution on 6/14/15.

//  Copyright (c) 2015 Behrad Zari. All rights reserved.
//  Copyright (c) 2015 Farshad Mousalou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CoreGeoLocation.h"
#import "EventMessage.h"
#import "ChabokEvent.h"
#import "ChabokLogger.h"

@import UserNotifications;

@class PushClientMessage,PushClientManager,PushClientDeliveryMessage;

/*!
 * Enum for Server Reachability network
 */
typedef NS_ENUM(NSUInteger, PushClientServerReachabilityNetworkType){
    /** Push Server Reachability found no network */
    PushClientServerReachabilityNoNetworkFoundType,
    /** Push Server reach through Celluar Network like 2G or 3G or 4G */
    PushClientServerReachabilityCelluarNetworkType,
    /** Push Server Reachable via Wi Fi network */
    PushClientServerReachabilityWifiNetworkType
};


typedef NS_ENUM(NSUInteger, ChabokEnvironmentType){
    Sandbox,
    Production
};

/*!
 * Enum for Server Connection State
 */
typedef NS_ENUM(NSInteger, PushClientServerConnectionState){
    /** Push Client start connecting to server*/
    PushClientServerConnectingStartState = -2,
    /** Push Client connect to server*/
    PushClientServerConnectingState = -1,
    /** Push Client connected to server*/
    PushClientServerConnectedState,
    /** Push Client disconnected when disconnected from server*/
    PushClientServerDisconnectedState,
    /** Push Client disconnected by Error*/
    PushClientServerDisconnectedErrorState,
    /** Push Client disconnected when socket was time out*/
    PushClientServerSocketTimeoutState
};


/*!
 * Enum for Push Client Error code 
 */
typedef NS_ENUM(NSInteger, PushClientErrorCode) {
    /** Error code when you are not initialized yet */
    kPushClientNotInitializedErrorCode =-5001,
    /** Error code when push client parameter was not valid */
    kPushClientParameterNotValidErrorCode =-5002,
    /** Error Code for failure in registration Application*/
    kPushClientFailRegisterApplicationErrorCode = -5009,
    /** Error Code for failure in register user in server*/
    kPushClientFailRegisterUserErrorCode  = -5010,
    /** Error code when server is not reachability*/
    kPushClientServerReachabilityErrorCode  = -5011,
    /** Error code for server connection*/
    kPushClientServerConnectionErrorCode = -5012 ,
    /** Error code for failure in verification request*/
    kPushClientFailVerficationErrorCode = -5013,
    /** Error code for failure in verify user code */
    kPushClientFailVerifyUserCodeErrorCode = - -5014,
    /** Error code when device has no internet connection */
    kPushClientNoInternetConnectionErrorCode =-5030,
};

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

typedef void (^PushClientMessageHandlerBlock)(PushClientMessage *message);

typedef void (^PushClientMessageUILocalNotificationHandlerBlock)(PushClientMessage *message);

typedef void (^PushClientMessageDeliveredHandlerBlock )(PushClientMessage *message);

typedef void (^PushClientServerReachabilityCallBackBlock)(
        BOOL isReachable,
        PushClientServerReachabilityNetworkType networkType) ;

typedef void (^PushClientServerConnectionStateHandlerBlock)(void);

typedef void (^PushClientRegistrationHandlerBlock)(BOOL isRegistered,NSString *userId,NSError *error) ;

typedef void (^PushClientLoginHandlerBlock)(BOOL loggedIn, NSError *error) ;


typedef void (^PushClientVerificationHandlerBlock)(BOOL sent,NSError *error);

typedef void (^PushClientVerifyUserCodeHandlerBlock)(BOOL isVerify,NSError *error);


/*!
 @description notification string for observing and callback through NSNotificationCenter
 */

/** push client received new message notification */
extern NSString *const kPushClientDidReceivedMessageNotification;

/** push client got ack about sent message */
extern NSString *const kPushClientDidDeliveredMessageNotification;

/** push client server reachability changed */
extern NSString *const kPushClientDidChangeServerReachabilityNotification;

/** push client user registration success notification */
extern NSString *const kPushClientDidRegisterUserNotification;

/** push client user or app registration failure notification */
extern NSString *const kPushClientDidFailRegisterUserNotification;

/** push client server connection state notification */
extern NSString *const kPushClientDidChangeServerConnectionStateNotification;

/** push client sent request verification notification */
extern NSString *const kPushClientDidSentVerificationCodeNotification;

/** push client failure in sent verification request notification */
extern NSString *const kPushClientDidFailSentVerificationCodeNotification;

/** push client verify user code notification */
extern NSString *const kPushClientDidVerifyUserCodeNotification;

/** push client verify user code failure notification */
extern NSString *const kPushClientDidFailInVerifyUserCodeNotification;

/** push client error domain */
extern NSString *const kPushClientErrorDomain;

/* ChabokPush detect app was new installed */
extern NSString *const kPushClientDetectAppNewInstall;

/* ChabokPush detect app was Launched */
extern NSString *const kPushClientDetectAppWasLaunched;

#pragma clang diagnostic pop

/** Push Client Manager delegate gives your application control over the
 @note handleEvent and newMessage are required interfaces, the rest is optional
 */
@protocol PushClientManagerDelegate <NSObject>
@optional

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
- (void)pushClientManagerDidReceivedMessage:(PushClientMessage *)message;

- (void)pushClientManagerDidReceivedDelivery:(PushClientDeliveryMessage *)delivery;

- (void)pushClientManagerDidReceivedEventMessage:(EventMessage *)eventMessage;

- (void)pushClientManagerUILocalNotificationDidReceivedMessage:(PushClientMessage *)message;

- (void)pushClientManagerDidDeliveredMessage:(PushClientMessage *)message;

- (void)pushClientManagerDidChangeServerReachiability:(BOOL)reachable
                                          networkType:(PushClientServerReachabilityNetworkType)networkType;

- (void)pushClientManagerDidRegisterUser:(BOOL)registration;

- (void)pushClientManagerDidFailRegisterUser:(NSError *)error;

- (void)pushClientManagerDidChangedServerConnectionState;

- (void)pushClientManagerDidSentVerificationCode;

- (void)pushClientManagerDidFailSentVerificationCode:(NSError *)error;

- (void)pushClientManagerDidVerifyUserCode:(BOOL)verify;

- (void)pushClientManagerDidFailInVerifyUserCode:(NSError *)error;

- (void)pushClientManagerDidSubscribed:(NSString *) channel;

- (void)pushClientManagerDidFailInSubscribe:(NSError *) error;

- (void)pushClientManagerDidUnsubscribed:(NSString *) channel;

- (void)pushClientManagerDidFailInUnsubscribe:(NSError *) error;

- (void)pushClientManagerDidFailInPublish:(NSError *) error;

- (void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response
          withCompletionHandler:(void (^)(void))completionHandler;

- (void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification
          withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler;

- (void) userNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification;

- (BOOL) chabokDeeplinkResponse:(NSURL *_Nonnull)deeplink;

- (void) chabokReferralResponse:(NSString *)referralId;

#pragma clang diagnostic pop

@end




/*!
 @description PushClientManager is manager for request for register the device and user to server,
 then communicate with server via SSL connection or non-secure connection.
 It encapsulated the connecting and server reachability and message,
 which determine the success or failure of registration or communication with server
*/
NS_CLASS_AVAILABLE_IOS(7_0)
@interface PushClientManager : NSObject<UNUserNotificationCenterDelegate>


/**
 * use this method for local server access
 * @param flag option for switch remote to local server YES means Local Server and No Remote Server
 * @note local server not support ssl connection dont set useSSLConnection with true value
 */
+ (void)setDevelopment:(BOOL)flag DEPRECATED_MSG_ATTRIBUTE("This method has been replaced with configureEnvironment method");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

/*!
 *@discription The Singletone of PushClientManager, Use this for avoid doublicate connection.
 
 
 @code 
    // Objective-C
    PushClientManager *defaultManager = [PushClientManager defaultManager];
 
    //Swift
    let pushManager = PushClientManager.defaultManager()
 @endcode
 
 @return singletone object of PushClientManager
*/
+ (instancetype)defaultManager;

+ (void) disableSdk;

+ (void)resetBadge;


- (instancetype) init NS_UNAVAILABLE;
/**
 The UserId which store disk or runtime
 */
@property (nonatomic, readonly) NSString *userId;
#pragma clang diagnostic pop


/**
 The UserId which store disk or runtime
 */
@property (nonatomic, readwrite) NSDictionary * _Nullable userInfo DEPRECATED_MSG_ATTRIBUTE("This property has been replaced with userAttributes");


/**
 This property is for gathering user attributes such as first name, last name, age, gender and etc.
 */
@property (nonatomic, readwrite) NSDictionary * _Nullable userAttributes;

@property (nonatomic, readonly) NSDictionary * _Nullable lastNotificationAction;
@property (nonatomic, readonly) NSDictionary * _Nullable lastNotificationData;
/*!
 The usingSSLConenction used as secure connection in Manager
 */
@property (nonatomic, readwrite) BOOL usingSSLConnection;


/*!
 @discription The Server Reachability Connection Network Type
 @see PushClientServerReachabilityNetworkType
 */
@property (nonatomic, readonly) PushClientServerReachabilityNetworkType serverNetworkType;


/*!
 @discription The Server Connection State which present connecting state
 @see PushClientServerConnectionState
 */
@property (nonatomic, readonly) PushClientServerConnectionState connectionState;


/*!
 @discription present server is reachable or not
 */
@property (nonatomic, readonly) BOOL isServerReachable;


/**
 The isRegistered used as flag for success in registration
 */
@property (nonatomic, readonly) BOOL isRegistered;


/**
 For expiring session in background. Default value is 180 second.
 */
@property (nonatomic) NSTimeInterval sessionTimeout;


/**
 Automatically track screen views and remove *ViewControler* in ViewController class name.
 By default is false.
 */
@property (nonatomic) BOOL automaticallyTrackScreens;

/**
 the deliveryTopicState use to detect to subscribe to delivery or not
*/
@property (nonatomic,readwrite) BOOL deliveryChannelEnabeled;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
/*!
 * @description messageHandler is block type which is used as callback when new message received
 * @return object of "PushClientMessage" Class
 * @see PushClientMessageHandlerBlock
 */
@property (nonatomic, copy) PushClientMessageHandlerBlock messageHandler;

@property (nonatomic, copy) PushClientMessageUILocalNotificationHandlerBlock messageUILocalNotificationHandler;


@property (nonatomic, copy) PushClientMessageDeliveredHandlerBlock messageDeliveredHandler;




/*!
 * @description registrationHandler is block type which is used as callback when
 * userId has been registered or occour error in registration process return params in block
 *
 * isRegistered  flag for present Is user registered or not
 * userId registration userId
 * error return object of "NSError" when registration had been failed.
 *
 * @see PushClientRegistrationHandlerBlock 
 * @see PushClientErrorCode
 */
@property (nonatomic, copy) PushClientRegistrationHandlerBlock registrationHandler;


/*!
 * @description serverConnectionStateHandler is block type which is used as callback when
 * server connection state has been changed use connection type property connectionState
 * @see -connectionState PushClientServerConnectionStateHandlerBlock
 */
@property (nonatomic, copy) PushClientServerConnectionStateHandlerBlock serverConnectionStateHandler;


/*!
 * @description serverReachabilityHandler is block type which is used as callback when
 * server connection network type has been changed
 * @see -isReachable or -serverNetworkType PushClientServerReachabilityCallBackBlock
 */

@property (nonatomic, copy) PushClientServerReachabilityCallBackBlock serverReachabilityHandler;


/*!
 * @description verificationHandler is block type which is used as callback when
 * manager enhanced and send request to server
 * @see -PushClientVerificationHandlerBlock
 */
@property (nonatomic, copy) PushClientVerificationHandlerBlock verificationHandler;


/*!
 * @description serverReachabilityHandler is block type which is used as callback when
 * server connection network type has been changed
 * @see -connectionState PushClientServerReachabilityCallBackBlock
 */
@property (nonatomic, copy) PushClientVerifyUserCodeHandlerBlock verifiyUserCodeHandler;


/*!
 * @description failureError is last fail error in registration or connection error
 * @see -PushClientErrorCode
 */
@property (nonatomic, strong,readonly)  NSError *failureError;

/*!
 * @description get instance of CoreGeoLocation
 * @see -CoreGeoLocation
 * @author AdpDigital co.
 */
@property (nonatomic, strong ,readonly) CoreGeoLocation *instanceCoreGeoLocation;

@property (nonatomic) BOOL enableLocationOnLaunch;

@property (nonatomic, strong) NSDictionary *locationOnLaunchWithDictionary;

/*!
 * @description delegate for legacy callback in objective-c or swift is protocol
 * @see -PushClientManagerDelegate
 */
@property (nonatomic, weak) id<PushClientManagerDelegate> delegate;

@property (nonatomic, assign) ChabokLogLevel logLevel;

-(void) setEnableRealtime:(BOOL) disableRealtime;

/*!
 * @description addDelegate method purpose for multi delegation and callback support,
 * and add new delegate object in delegate objects list
 * @see -PushClientManagerDelegate
 * return void
 */
- (void)addDelegate:(id<PushClientManagerDelegate>)delegate;


/*!
 * @description removeDelegate method purpose for delete delegate object in delegation list
 * @see -PushClientManagerDelegate
 * return void
 */
- (void)removeDelegate:(id<PushClientManagerDelegate>)delegate;


/*!
 * @description remove all delegation object which manager used for callback
 * return void
 */
- (void)removeAllDelegates;


//###Change codes untill this line

/*!
 
 @discussion This method reset PushClientManager configs.
 
 @author AdpDigital co.
 
 */
- (void) reset;

/*
 * =============================================================
 * =========================================== Registration APIs
 * =============================================================
 */

#pragma mark - Registration APIs

/*!
 * @description register application
 * @param appId application Name
 * @return boolean value for success registration validation and process or not
 * if methods return no check failureError or manager callBack registration fail
 * in -pushClientManagerDidFailRegisterUser:error or registrationBlock property
 */

- (BOOL)initWithAppId:(NSString *)appId
               apiKey:(NSString *)apiKey
             username:(NSString *)username
             password:(NSString *)password;

- (BOOL) configureEnvironment:(ChabokEnvironmentType) environment;
- (BOOL) configureEnvironment:(ChabokEnvironmentType) environment
                  withGuestId:(NSString *) guestId;
/**
 For tracking pre-install campaigns

 @param defaultTracker is trackerId
 */
- (void)setDefaultTracker:(NSString *) defaultTracker;

- (BOOL) login:(NSString *) userId;
- (BOOL) login:(NSString *) userId hash:(NSString *) hash;
- (BOOL) login:(NSString *) userId tagName:(NSString *) tagName;
- (BOOL) login:(NSString *) userId userAttributes:(NSDictionary *) attributes;
- (BOOL) login:(NSString *) userId handler:(PushClientLoginHandlerBlock) handler;
- (BOOL) login:(NSString *) userId event:(NSString *) eventName data:(NSDictionary *) data;

- (BOOL) logout;

- (NSString*)getInstallationId;

#pragma mark - subscribe methods

/*!
 * @description Subscribe client to a public channel. If channel was subscribed successfully invoke pushClientManagerDidSubscribed: delegate method.
 
 * @param channel is default set public, for subscribe to private channel set private/sth for a private channel
 
 */
- (void)subscribe:(NSString *)channel;

/*!
 * @description Subscribe client to public channels. If channels was subscribed successfully invoke pushClientManagerDidSubscribed: delegate method.
 
 * @param channels is default set public, for subscribe to private channel set private/sth for a private channel
 
 */
- (void)subscribeList:(NSArray *)channels;

/*!
 * @description Subscribe client to a public channel. If channel was subscribed successfully invoke pushClientManagerDidSubscribed: delegate method.
 
 * @param channel is default set public, for subscribe to private channel set private/sth for a private channel
 
 * @param live means get messages when client was connected
 */
- (void)subscribe:(NSString *)channel live:(BOOL)live;

#pragma mark - subscribe to event

/*!
 subscribeEvent:
 
 Discussion:
    This method subscribe to an public event
 
 @param eventName is NSString.
 */
- (void)subscribeEvent:(NSString*)eventName;

/*!
 subscribeEvent:live
 
 Discussion:
    This method subscribe to an public event
 
 @param eventName is NSString.
 
 @param live is BOOL. Yes means when you receive event if you was connected.
 */
- (void)subscribeEvent:(NSString*)eventName live:(BOOL)live;

/*!
 subscribeEvent:installationId
 
 Discussion:
    This method subscribe to an private event
 
 @param eventName for subscribing on and event with name.
 
 @param installationId set user installationId or DeviceId;
 
 */
- (void)subscribeEvent:(NSString*)eventName installationId:(NSString *)installationId;

/*!
 subscribeEvent:installationId:live
 
 Discussion:
    This method subscribe to an private event
 
 @param eventName is NSString.
 
 @param installationId set user installationId or DeviceId;
 
 @param live is BOOL. Yes means when you receive event if you was connected.
 */
- (void)subscribeEvent:(NSString*)eventName installationId:(NSString *)installationId live:(BOOL)live;

#pragma mark - unsubscribe methods

/*!
 * @description Unsubscribe client to public channel. If channel was unsubscribed successfully invoke pushClientManagerDidUnsubscribed: delegate method.
 
 * @param channel Can a private channel name or public/sth for a public channel
 */
- (void)unsubscribe:(NSString *)channel;

#pragma mark - unsubscribe to event


/*!
 unsubscribeEvent:eventName
 
 Discussion:
 This method unsubscribe to eventname.
 
 @param eventName is NSString.
 
 @author AdpDigital co.
 */
- (void)unsubscribeEvent:(NSString *)eventName;

/*!
 unsubscribeEvent:forPublic
 
 Discussion:
 This method unsubscribe to eventname.
 
 @param eventName event name.
 
 @param installationId set user installationId or DeviceId.
 
 @author AdpDigital co.
 */
- (void)unsubscribeEvent:(NSString *)eventName installationId:(NSString *)installationId;


#pragma mark - publish methods
/*!
 * @description Publish a message to a channel
 
 * @param message is the PushClientMessage you want to sent out
 */
- (BOOL)publish:(PushClientMessage *)message;

/*!
 * @description Publish a message to a channel
 
 * @param channel for publish on it
 
 * @param text is message body.
 
 */
- (BOOL)publish:(NSString *)channel withText:(NSString *) text;

/*!
 * @description Publish a message to a channel
 
 * @param userId for determine how get the message
 
 * @param channel for publish on it
 
 * @param text is message body.
 
 */
- (BOOL)publish:(NSString *)userId toChannel:(NSString *)channel withText:(NSString *) text;

#pragma mark - publish events

/*!
 * @description Publish event with data
 * @param eventName is the NSString to sent event with deviceId.
 * @param data is the NSDictionary you want to sent out.
 * @author AdpDigital co.
 *
 */
- (BOOL)publishEvent:(NSString*)eventName data:(NSDictionary*)data;
- (BOOL)publishEvent:(NSString*)eventName data:(NSDictionary*)data live:(BOOL)live;
- (BOOL)publishEvent:(NSString*)eventName data:(NSDictionary*)data stateful:(BOOL)stateful;
- (BOOL)publishEvent:(NSString*)eventName data:(NSDictionary*)data live:(BOOL)live stateful:(BOOL)stateful;

#pragma mark - tag methods

/*!
 
 @discussion This method add tag for current user.
 
 @param name of tag
 
 @author Chabok Realtime Solutions co.
 
 */
- (void) addTag:(NSString *) name;

/**
 * Add array of tags.
 *
 * @param tagsName array of tags
 *
 * @author Chabok Realtime Solutions co.
 */
- (void) addTags:(NSArray *) tagsName;

/*!

 @discussion This method add tag for current user.

 @param name of tag
 
 @param success invoked when add successfully
 
 @param failure invoked when fail adding tag.
 
 @author Chabok Realtime Solutions co.

 */
- (void) addTag:(NSString *)name success:(void (^)(NSInteger count))success
        failure:(void (^)(NSError *error))failure;

/*!
 
 @discussion This method add array of tags for current user.
 
 @param tagsName array of tags
 
 @param success invoked when add successfully
 
 @param failure invoked when fail adding tag.
 
 @author Chabok Realtime Solutions co.
 
 */
- (void) addTags:(NSArray *)tagsName success:(void (^)(NSInteger count))success
        failure:(void (^)(NSError *error))failure;
/*!
 
 @discussion This method remove tag for current user.
 
 @param name of tag
 
 @author Chabok Realtime Solutions co.
 
 */
- (void) removeTag:(NSString *) name;

/*!
 
 @discussion This method remove array of tags for current user.
 
 @param tagsName array of tags
 
 @author Chabok Realtime Solutions co.
 
 */
- (void) removeTags:(NSArray *) tagsName;

/*!

 @discussion This method add tag for current user.
 
 @param name of tag

 @param success invoked when add successfully

 @param failure invoked when fail adding tag.
     
 @author AdpDigital co.
     
 */
- (void) removeTag:(NSString *)name  success:(void (^)(NSInteger count))success
           failure:(void (^)(NSError *error))failure;

/*!
 
 @discussion This method add array of tags for current user.
 
 @param tagsName array of tags
 
 @param success invoked when add successfully
 
 @param failure invoked when fail adding tag.
 
 @author Chabok Realtime Solutions co.
 
 */
- (void) removeTags:(NSArray *)tagsName
            success:(void (^)(NSInteger count))success
            failure:(void (^)(NSError *error))failure;
/*!
 * @description Mark a message as read
 * @message messageId id of PushClientMessage
 */
- (BOOL)markAsRead:(id)messageId;
    

/*!
 * @description Mark a message as dismissed
 * @message messageId id of PushClientMessage
 */
- (BOOL)messageDismissed:(id)messageId;


/*!
 * @description Return list of user channels
 * @return list of String channel names
 */
- (NSArray*)deviceSubscriptions;


/*!
 * @description Update notification settings for a channel
 * @channel the channel to update settings for
 * @sound sound file name for channel notifications or null
 * @alert notification should have an alert text or not
 */
- (void)updateNotificationSettings:(NSString *)channel sound:(NSString *)sound alert:(BOOL)alert;


/*!
 * @description get current notification settings for a channel
 * @return dict containing alert, sound keys or nil
 */
- (NSDictionary *)notificationSettingsFor:(NSString *)channel;

/*
 * =============================================================
 * =========================================== Verification APIs
 * =============================================================
 */

#pragma mark - Verification APIs

/*!
 * @description request Verification Code To Server
 * @param userId userId which registered
 * @return boolean value for success registration verification and
 * sent reqest to sever and received verification code via message
   or not if methods return no check failureError or manager callBack  fail in
   -pushCLientManagerDidFailSentVerificationCode: or verficationHandler property
 */
- (BOOL)requestVerificationCode:(NSString *)userId;

- (BOOL)requestVerificationCode:(NSString *)userId
                          media:(NSString *)media;

- (BOOL)requestVerificationCode:(NSString *)userId
                completionBlock:(PushClientVerificationHandlerBlock)block;

- (BOOL)requestVerificationCode:(NSString *)userId
                          media:(NSString *)media
                completionBlock:(PushClientVerificationHandlerBlock)block;


/*!
 * @description verify User Code which requested from server
 * @param userId same userId which register in server
 * @param userCode verification code which fetch from server
 * @return boolean value for success input validation and send request for verify userCode or 
                   not if methods return no check failureError or manager callBack verify user code fail in
                   -pushClientManagerDidFailInVerifyUserCode:error or verifyUserCodeHandler property
 */
- (BOOL)verifyUserCode:(NSString *)userId
              userCode:(NSString *)userCode;

- (BOOL)verifyUserCode:(NSString *)userId
              userCode:(NSString *)userCode
       completionBlock:(PushClientVerifyUserCodeHandlerBlock)block;



- (void)removeAppLifeCyclesFunctionality;

/*
 * =============================================================
 * ================================ Application Crash Report Log
 * =============================================================
 */

#pragma mark - Application Crash Report Log

/**
 * Report crash log to Server
 * @param userInfo The Crash Log information such as application bundleId and thread crashed
 *
 */
- (void)applicationCrashedWithUserInfo:(NSDictionary *)userInfo saveOnDisk:(BOOL)saveOnDisk;

#pragma mark - NotificationExtensionService methods

// Call this method in your app Notification Service Extension
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler;

/**
 Call this method in your app Notification Service Extension.
 

 @param mutableNotificationContent is a mutable copy of content in UNNotificationRequest.
 for example:
 
    //objective-c:
    [PushClientManager.defaultManager didReceiveNotificationContent:[request.content mutableCopy]
                                        withContentHandler:contentHandler];
 
 @param contentHandler for show notification after download attached data.
 */
- (void)didReceiveNotificationContent:(UNMutableNotificationContent *_Nonnull)mutableNotificationContent
                   withContentHandler:(void (^_Nonnull)(UNNotificationContent * _Nonnull))contentHandler;

#pragma mark - Screen view

/**
 Store screenView to local storage, When app become to background, try to publish screenView for current session.
 If app become to background and didn't come back to foreground after sessionTimeOut property value, creating new session and at next time open the app or become to foreground, publish screenViews with last session.

 @param screenView is page or screen name.
 */
-(void) screenView:(NSString *) screenView;

#pragma mark - Tracking methods


/**
 Track user interaction realtime.

 @param trackName is tracker name. It could be Purchase for click on special button
 @param data for trackName.
 */
-(void) track:(NSString * _Nonnull) trackName data:(NSDictionary * _Nullable) data;


/**
Track user revenue realtime.

@param revenue of user
*/
-(void) trackRevenue:(double) revenue;

/**
 Track user revenue realtime.

 @param event name
 @param chabokEvent contains revenue and currency
 */
-(void) trackPurchase:(NSString * _Nonnull) event chabokEvent:(ChabokEvent * _Nonnull) chabokEvent;
#pragma mark - Deeplink



/**
 This method is for adding value to users' numerical attribute.

 @param attribute name
 */
-(void) incrementUserAttribute:(NSString *_Nonnull) attribute;
-(void) incrementUserAttribute:(NSString *_Nonnull) attribute value:(NSInteger) value __attribute__((deprecated("This method has been replaced with incrementUserAttributeValue:value")));

/**
 This method is for adding values to users' numerical attributes.

 @param attributes array
 */
-(void) incrementUserAttributes:(NSArray<NSString *> *_Nonnull) attributes;

/**
 This method is for adding value to users' numerical attribute.
 
 @param attribute name
 @param value of attribute
 */
-(void) incrementUserAttributeValue:(NSString *_Nonnull) attribute value:(double) value;

/**
 This method is for adding values to users' numerical attributes.

 @param attributes name with value
 */
-(void) incrementUserAttributeValues:(NSDictionary<NSString *, NSNumber *> *_Nonnull) attributes;

-(void) unsetUserAttribute:(NSString *_Nonnull) attributeKey;

-(void) addToUserAttributeArray:(NSString *_Nonnull) attributeKey attributeValue:(NSString *) attributeValue;

-(void) addToUserAttributeArray:(NSString *_Nonnull) attributeKey attributeValues:(NSArray<NSString *> *) attributeValues;

-(void) removeFromUserAttributeArray:(NSString *_Nonnull) attributeKey attributeValue:(NSString *) attributeValue;

-(void) removeFromUserAttributeArray:(NSString *_Nonnull) attributeKey attributeValues:(NSArray<NSString *> *) attributeValues;

@end
