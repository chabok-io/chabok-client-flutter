#import "ChabokpushPlugin.h"
#import <AdpPushClient/AdpPushClient.h>

static NSString *const METHOD_CHANNEL_NAME = @"com.chabokpush.flutter/chabokpush";

@interface PushClientManager(PushManager)
-(NSString *) getMessageIdFromPayload:(NSDictionary *)payload;
@end

@interface ChabokpushPlugin()<PushClientManagerDelegate>

@property(nonatomic, retain) FlutterMethodChannel *channel;

@property (nonatomic, strong) NSString *appId;
@property (class) NSDictionary *coldStartNotificationResult;

@end

static NSString* RCTCurrentAppBackgroundState() {
    static NSDictionary *states;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        states = @{
            @(UIApplicationStateActive): @"active",
            @(UIApplicationStateBackground): @"background",
            @(UIApplicationStateInactive): @"inactive"
        };
    });
    
    return states[@([[UIApplication sharedApplication] applicationState])] ?: @"unknown";
}

@implementation ChabokpushPlugin

@dynamic coldStartNotificationResult;
static NSDictionary *_coldStartNotificationResult;

NSString *_lastNotificationId;
NSString *_lastKnownState;
NSString *_lastMessage;
NSString *_deepLink;
NSString *_referralId;

FlutterResult _subscriptionResult;
FlutterResult _unsubscriptionResult;

+(void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel =
    [FlutterMethodChannel methodChannelWithName:METHOD_CHANNEL_NAME
                                binaryMessenger:[registrar messenger]];
    ChabokpushPlugin *instance = [[ChabokpushPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
    
    [instance postInit];
}

-(void)dealloc {
    [self.channel setMethodCallHandler:nil];
    self.channel = nil;
    
    _subscriptionResult = nil;
    _unsubscriptionResult = nil;
    
    [PushClientManager.defaultManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *method = call.method;
    NSDictionary *arguments = call.arguments;
    
    NSLog(@"----------- onMethodCall: action = %@ , args = %@", method, [arguments description]);
    
    if ([@"login" isEqualToString:method]) {
        NSString *userId = arguments[@"userId"];
        [self login:userId withResult:result];
    } else if ([@"publish" isEqualToString:method]) {
        [self publish:arguments withResult:result];
    } else if ([@"getUserId" isEqualToString:method]) {
        [self getUserId:result];
    } else if ([@"getInstallation" isEqualToString:method]) {
        [self getInstallationId:result];
    } else if ([@"setDefaultTracker" isEqualToString:method]) {
        NSString *defaultTracker = arguments[@"defaultTracker"];
        [self setDefaultTracker:defaultTracker];
    } else if ([@"resetBadge" isEqualToString:method]) {
        [self resetBadge];
    } else if ([@"appWillOpenUrl" isEqualToString:method]) {
        [self appWillOpenUrl];
    } else if ([@"logout" isEqualToString:method]) {
        [self logout];
    } else if ([@"addTags" isEqualToString:method]) {
        NSArray<NSString *> *tags = arguments[@"tags"];
        [self addTags:tags withResult:result];
    } else if ([@"removeTags" isEqualToString:method]) {
        NSArray<NSString *> *tags = arguments[@"tags"];
        [self removeTags:tags withResult:result];
    } else if ([@"setUserAttributes" isEqualToString:method]) {
        [self setUserAttributes:arguments];
    } else if ([@"unsetUserAttributes" isEqualToString:method]) {
        NSArray<NSString *> *attributeValues = arguments[@"attributeValues"];
        [self unsetUserAttributes:attributeValues];
    } else if ([@"track" isEqualToString:method]) {
        NSString *trackName = arguments[@"trackName"];
        NSDictionary *eventData = arguments[@"data"];
        [self track:trackName withData:eventData];
    } else if ([@"trackPurchase" isEqualToString:method]) {
        NSString *eventName = arguments[@"trackName"];
        NSDictionary *eventData = arguments[@"data"];
        [self trackPurchase:eventName withData:eventData];
    } else if ([@"setOnMessageCallback" isEqualToString:method]) {
        [self sendLastChabokMessage];
    } else if ([@"setOnConnectionHandler" isEqualToString:method]) {
        [self sendConnectionStatus];
    } else if ([@"setOnNotificationOpenedHandler" isEqualToString:method]) {
        [self handleNotificationOpened];
    } else if ([@"setOnShowNotificationHandler" isEqualToString:method]) {
        [self handleNotificationShown];
    } else if ([@"incrementUserAttribute" isEqualToString:method]) {
        NSString *attributeKey = arguments[@"attributeKey"];
        NSNumber *attributeValue = arguments[@"attributeValue"];
        [self incrementUserAttribute:attributeKey withValue:[attributeValue longValue]];
    } else if ([@"decrementUserAttribute" isEqualToString:method]) {
        NSString *attributeKey = arguments[@"attributeKey"];
        NSNumber *attributeValue = arguments[@"attributeValue"];
        [self decrementUserAttribute:attributeKey withValue:[attributeValue longValue]];
    } else if ([@"addToUserAttributeArray" isEqualToString:method]) {
        NSString *attributeKey = arguments[@"attributeKey"];
        NSArray<NSString *> *attributeValues = arguments[@"attributeValues"];
        [self addToUserAttributeArray:attributeKey withValues:attributeValues];
    } else if ([@"removeFromUserAttributeArray" isEqualToString:method]) {
        NSString *attributeKey = arguments[@"attributeKey"];
        NSArray<NSString *> *attributeValues = arguments[@"attributeValues"];
        [self removeFromUserAttributeArray:attributeKey withValues:attributeValues];
    } else if ([@"setOnDeepLinkHandler" isEqualToString:method]) {
        [self handleDeepLink];
    } else if ([@"setOnReferralHandler" isEqualToString:method]) {
        [self handleReferral];
    } else if ([@"subscribe" isEqualToString:method]) {
        NSString *channelName = arguments[@"channelName"];
        [self subscribe:channelName withResult:result];
    } else if ([@"unsubscribe" isEqualToString:method]) {
        NSString *channelName = arguments[@"channelName"];
        [self unsubscribe:channelName withResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(void)postInit {
    // notification delegates
    [PushClientManager.defaultManager addDelegate:self];
    _lastKnownState = RCTCurrentAppBackgroundState();
    for (NSString *name in @[UIApplicationDidBecomeActiveNotification,
                             UIApplicationDidEnterBackgroundNotification,
                             UIApplicationDidFinishLaunchingNotification]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppStateDidChange)
                                                     name:name
                                                   object:nil];
    }
    
    [self sendConnectionStatus];
    
    NSDictionary *lastNotification = [PushClientManager.defaultManager lastNotificationAction];
    if (lastNotification) {
        NSString *actionId = lastNotification[@"actionId"];
        if (!actionId) {
            actionId = [lastNotification[@"actionType"] lowercaseString];
            if ([actionId containsString:@"opened"]) {
                if (@available(iOS 10.0, *)) {
                    actionId = UNNotificationDefaultActionIdentifier;
                }
            } else {
                if (@available(iOS 10.0, *)) {
                    actionId = UNNotificationDismissActionIdentifier;
                }
            }
        }
        // prepare last notification
        [ChabokpushPlugin notificationOpened:[PushClientManager.defaultManager lastNotificationData]
                                    actionId:actionId];
        
        // send notification event
        [self handleNotificationOpened];
    }
}

-(BOOL) isAttachedToHost {
    return [_lastKnownState isEqualToString:@"active"] || [_lastKnownState isEqualToString:@"inactive"];
}

-(void)handleAppStateDidChange {
    NSString *newState = RCTCurrentAppBackgroundState();
    if (![newState isEqualToString:_lastKnownState]) {
        _lastKnownState = newState;
    }
    
    if ([self isAttachedToHost]) {
        NSDictionary *lastNotification = [PushClientManager.defaultManager lastNotificationAction];
        if (lastNotification) {
            NSString *actionId = lastNotification[@"actionId"];
            if (!actionId) {
                actionId = [lastNotification[@"actionType"] lowercaseString];
                if ([actionId containsString:@"opened"]) {
                    if (@available(iOS 10.0, *)) {
                        actionId = UNNotificationDefaultActionIdentifier;
                    }
                } else {
                    if (@available(iOS 10.0, *)) {
                        actionId = UNNotificationDismissActionIdentifier;
                    }
                }
            }
            // prepare last notification
            [ChabokpushPlugin notificationOpened:[PushClientManager.defaultManager lastNotificationData]
                                        actionId:actionId];
            
            // send notification event
            [self handleNotificationOpened];
        }
    }
}

#pragma mark - chabok delegate methods
-(BOOL)chabokDeeplinkResponse:(NSURL *)deeplink {
    NSLog(@"chabokDeeplinkResponse() invoked");
    
    if (deeplink) {
        _deepLink = [deeplink absoluteString];
    }
    [self handleDeepLink];
    
    return NO;
}

-(void)chabokReferralResponse:(NSString *)referralId {
    NSLog(@"chabokReferralResponse() invoked");
    
    _referralId = referralId;
    [self handleReferral];
}

-(void)handleDeepLink {
    if ([self isAttachedToHost] && self.channel && _deepLink) {
        [self.channel invokeMethod:@"setOnDeepLinkHandler" arguments:_deepLink];
    }
}

-(void)handleReferral {
    if ([self isAttachedToHost] && self.channel && _referralId) {
        [self.channel invokeMethod:@"setOnReferralHandler" arguments:_referralId];
    }
}

#pragma mark - register

-(void)login:(NSString *)userId withResult:(FlutterResult)result {
    NSLog(@"login() invoked");
    
    if (!userId || [userId isEqual:[NSNull null]]) {
        NSString *msg = @"Could not register userId to chabok";
        
        NSLog(@"%@", msg);
        result([FlutterError errorWithCode:@"-1"
                                   message:msg
                                   details:nil]);
        return;
    }
    
    [PushClientManager.defaultManager login:userId
                                    handler:^(BOOL isRegistered, NSError *error) {
        NSLog(@"isRegistered : %d userId : %@ error : %@", isRegistered, userId, error);
        
        if (error || !isRegistered) {
            NSDictionary *jsonDic = @{@"registered":@(NO),
                                      @"error":error
            };
            NSString *json = [self dictionaryToJson:jsonDic];
            result([FlutterError errorWithCode:@"-1"
                                       message:@"Could not register userId to chabok"
                                       details:json]);
        } else {
            NSDictionary *jsonDic = @{@"registered":@(YES)};
            NSString *json = [self dictionaryToJson:jsonDic];
            result(json);
        }
    }];
}

#pragma mark - unregister

-(void) logout {
    NSLog(@"logout() invoked");
    
    [PushClientManager.defaultManager logout];
}

#pragma mark - user
-(void) getInstallationId:(FlutterResult)result {
    NSLog(@"getInstallationId() invoked");
    
    NSString *installationId = [PushClientManager.defaultManager getInstallationId];
    if (!installationId) {
        NSString *msg = @"The installationId is null, You didn't register yet!";
        
        NSLog(@"%@", msg);
        result([FlutterError errorWithCode:@"-1"
                                   message:msg
                                   details:nil]);
    } else {
        result(installationId);
    }
}

-(void) getUserId:(FlutterResult)result {
    NSLog(@"getUserId() invoked");
    
    NSString *userId = [PushClientManager.defaultManager userId];
    if (!userId) {
        NSString *msg = @"The userId is null, You didn't register yet!";
        
        NSLog(@"%@", msg);
        result([FlutterError errorWithCode:@"-1"
                                   message:msg
                                   details:nil]);
    } else {
        result(userId);
    }
}

#pragma mark - tags

-(void) addTags:(NSArray<NSString *> *)tags withResult:(FlutterResult)result {
    NSLog(@"addTags() invoked");
    
    if (![PushClientManager.defaultManager getInstallationId]) {
        NSString *msg = @"UserId not registered yet.";
        
        NSLog(@"%@", msg);
        result([FlutterError errorWithCode:@"-1"
                                   message:msg
                                   details:nil]);
        return;
    }
    
    [PushClientManager.defaultManager addTags:tags
                                      success:^(NSInteger count) {
        NSDictionary *jsonDic = @{@"count":@(count)};
        NSString *json = [self dictionaryToJson:jsonDic];
        result(json);
    } failure:^(NSError *error) {
        NSDictionary *jsonDic = @{@"count":@(0),
                                  @"error":error
        };
        NSString *json = [self dictionaryToJson:jsonDic];
        result([FlutterError errorWithCode:@"-1"
                                   message:@"Could not add tag"
                                   details:json]);
    }];
}

-(void) removeTags:(NSArray<NSString *> *)tags withResult:(FlutterResult)result {
    NSLog(@"removeTags() invoked");
    
    if (![PushClientManager.defaultManager getInstallationId]) {
        NSString *msg = @"UserId not registered yet.";
        
        NSLog(@"%@", msg);
        result([FlutterError errorWithCode:@"-1"
                                   message:msg
                                   details:nil]);
        return;
    }
    
    [PushClientManager.defaultManager removeTags:tags
                                         success:^(NSInteger count) {
        NSDictionary *jsonDic = @{@"count":@(count)};
        NSString *json = [self dictionaryToJson:jsonDic];
        result(json);
    } failure:^(NSError *error) {
        NSDictionary *jsonDic = @{@"count":@(0),
                                  @"error":error
        };
        NSString *json = [self dictionaryToJson:jsonDic];
        result([FlutterError errorWithCode:@"-1"
                                   message:@"Could not remove tag"
                                   details:json]);
    }];
}

#pragma mark - publish

-(void) publish:(NSDictionary *)message withResult:(FlutterResult)result {
    NSLog(@"publish() invoked");
    
    NSDictionary *data = [message valueForKey:@"data"];
    NSString *userId = [message valueForKey:@"userId"];
    NSString *content = [message valueForKey:@"content"];
    NSString *channel = [message valueForKey:@"channel"];
    
    PushClientMessage *chabokMessage;
    if (data) {
        chabokMessage = [[PushClientMessage alloc] initWithMessage:content withData:data toUserId:userId channel:channel];
    } else {
        chabokMessage = [[PushClientMessage alloc] initWithMessage:content toUserId:userId channel:channel];
    }
    
    BOOL publishState = [PushClientManager.defaultManager publish:chabokMessage];
    result(@(publishState));
}

#pragma mark - badge
-(void) resetBadge {
    NSLog(@"resetBadge() invoked");
    
    [PushClientManager resetBadge];
}

#pragma mark - track
-(void) track:(NSString *)trackName withData:(NSDictionary *)trackData {
    NSLog(@"track() invoked");
    
    [PushClientManager.defaultManager track:trackName
                                       data:[ChabokpushPlugin getFormattedData:trackData]];
}

-(void) trackPurchase:(NSString *)eventName withData:(NSDictionary *)data {
    NSLog(@"trackPurchase() invoked");
    
    ChabokEvent *chabokEvent = [[ChabokEvent alloc] init];
    
    if (![data valueForKey:@"revenue"]) {
        [NSException raise:@"Invalid revenue" format:@"Please provide a revenue."];
    }
    chabokEvent.revenue = [[data valueForKey:@"revenue"] doubleValue];
    if ([data valueForKey:@"currency"]) {
        chabokEvent.currency = [data valueForKey:@"currency"];
    }
    if ([data valueForKey:@"data"]) {
        chabokEvent.data = [ChabokpushPlugin getFormattedData:[data valueForKey:@"data"]];
    }
    
    [PushClientManager.defaultManager trackPurchase:eventName
                                        chabokEvent:chabokEvent];
}

#pragma mark - default tracker
-(void) setDefaultTracker:(NSString *)defaultTracker {
    NSLog(@"setDefaultTracker() invoked");
    
    [PushClientManager.defaultManager setDefaultTracker:defaultTracker];;
}

#pragma mark - userInfo
-(void) setUserAttributes:(NSDictionary *)userInfo {
    NSLog(@"setUserAttributes() invoked");
    
    [PushClientManager.defaultManager setUserAttributes:[ChabokpushPlugin getFormattedData:userInfo]];
}

-(void) unsetUserAttributes:(NSArray<NSString *> *)attributes {
    NSLog(@"unsetUserAttribute() invoked");
    
    [PushClientManager.defaultManager unsetUserAttributes:attributes];
}

-(void) incrementUserAttribute:(NSString *)attribute withValue:(long)value {
    NSLog(@"incrementUserAttribute() invoked");
    
    [PushClientManager.defaultManager incrementUserAttributeValue:attribute value:value];
}

-(void) decrementUserAttribute:(NSString *)attribute withValue:(long)value {
    NSLog(@"decrementUserAttribute() invoked");
    
    [PushClientManager.defaultManager incrementUserAttributeValue:attribute value:(value * -1)];
}

-(void) addToUserAttributeArray:(NSString *)attribute withValues:(NSArray<NSString *> *)values {
    NSLog(@"addToUserAttributeArray() invoked");
    
    [PushClientManager.defaultManager addToUserAttributeArray:attribute attributeValues:values];
}

-(void) removeFromUserAttributeArray:(NSString *)attribute withValues:(NSArray<NSString *> *)values {
    NSLog(@"removeFromUserAttributeArray() invoked");
    
    [PushClientManager.defaultManager removeFromUserAttributeArray:attribute attributeValues:values];
}

-(void) getUserAttributes:(FlutterResult)result {
    NSLog(@"getUserAttributes() invoked");
    
    NSDictionary *userInfo = PushClientManager.defaultManager.userAttributes;
    NSString *json = [self dictionaryToJson:userInfo];
    result(json);
}

#pragma mark - subscribe
-(void) subscribe:(NSString *)channel withResult:(FlutterResult)result {
    NSLog(@"subscribe() invoked");
    
    _subscriptionResult = result;
    [PushClientManager.defaultManager subscribe:channel];
}

-(void) unsubscribe:(NSString *)channel withResult:(FlutterResult)result {
    NSLog(@"unsubscribe() invoked");
    
    _unsubscriptionResult = result;
    [PushClientManager.defaultManager unsubscribe:channel];
}

#pragma mark - deeplink
-(void) appWillOpenUrl {
    // no implementation
}

-(void) handleNotificationOpened {
    if (![self isAttachedToHost]) {
        return;
    }
    
    NSDictionary *payload = (NSDictionary *)[_coldStartNotificationResult valueForKey:@"message"];
    if (payload) {
        NSString *messageId = [PushClientManager.defaultManager getMessageIdFromPayload:payload];
        if (_coldStartNotificationResult && messageId && (!_lastNotificationId || ![_lastNotificationId isEqualToString:messageId])) {
            _lastNotificationId = messageId;
            if (self.channel) {
                NSString *json = [self dictionaryToJson:_coldStartNotificationResult];
                [self.channel invokeMethod:@"onNotificationOpenedHandler" arguments:json];
            }
            _coldStartNotificationResult = nil;
        }
    }
}

-(void) handleNotificationShown {
    if (![self isAttachedToHost]) {
        return;
    }
    
    if (self.channel && _coldStartNotificationResult) {
        NSString *json = [self dictionaryToJson:_coldStartNotificationResult];
        [self.channel invokeMethod:@"onShowNotificationHandler" arguments:json];
    }
}

+(NSDictionary *) notificationOpened:(NSDictionary *) payload actionId:(NSString *) actionId {
    NSString *actionType;
    NSString *actionUrl;
    NSString *actionIdStr = actionId;
    NSArray *actions = [payload valueForKey:@"actions"];
    NSString *clickUrl = [payload valueForKey:@"clickUrl"];
    
    if (@available(iOS 10.0, *)) {
        if ([actionId containsString:UNNotificationDismissActionIdentifier]) {
            actionType = @"dismissed";
            actionIdStr = nil;
        } else if ([actionId containsString:UNNotificationDefaultActionIdentifier]) {
            actionType = @"opend";
            actionIdStr = nil;
        } else if (actionId) {
            actionType = @"action_taken";
            actionIdStr = actionId;
            if (actionIdStr || !actions) {
                actionUrl = [ChabokpushPlugin getActionUrlFrom:actionIdStr actions:actions];
            }
        } else {
            actionType = @"shown";
        }
    } else {
        actionType = @"opened";
        actionIdStr = nil;
    }
    
    NSMutableDictionary *notificationData = [NSMutableDictionary new];
    
    if (actionType) {
        [notificationData setObject:actionType forKey:@"actionType"];
    }
    
    if (actionIdStr) {
        [notificationData setObject:actionIdStr forKey:@"actionId"];
    }
    
    if (actionUrl) {
        [notificationData setObject:actionUrl forKey:@"actionUrl"];
    } else if (clickUrl) {
        [notificationData setObject:clickUrl forKey:@"actionUrl"];
    }
    
    if (!payload) {
        _coldStartNotificationResult = nil;
        return notificationData;
    }
    
    [notificationData setObject:payload forKey:@"message"];
    
    _coldStartNotificationResult = notificationData;
    
    return notificationData;
}

+(NSString *) getActionUrlFrom:(NSString *)actionId actions:(NSArray *)actions {
    NSString *actionUrl;
    for (NSDictionary *action in actions) {
        NSString *acId = [action valueForKey:@"id"];
        if ([acId containsString:actionId]) {
            actionUrl = [action valueForKey:@"url"];
        }
    }
    return actionUrl;
}

-(void) sendConnectionStatus {
    if (![self isAttachedToHost]) {
        return;
    }
    
    NSString *connectionState = @"";
    if (PushClientManager.defaultManager.connectionState == PushClientServerConnectedState) {
        connectionState = @"CONNECTED";
    } else if (PushClientManager.defaultManager.connectionState == PushClientServerConnectingState ||
               PushClientManager.defaultManager.connectionState == PushClientServerConnectingStartState) {
        connectionState = @"CONNECTING";
    } else if (PushClientManager.defaultManager.connectionState == PushClientServerDisconnectedState ||
               PushClientManager.defaultManager.connectionState == PushClientServerDisconnectedErrorState) {
        connectionState = @"DISCONNECTED";
    } else  if (PushClientManager.defaultManager.connectionState == PushClientServerSocketTimeoutState) {
        connectionState = @"SocketTimeout";
    } else {
        connectionState = @"NOT_INITIALIZED";
    }
    
    NSLog(@"connectionState = %@", connectionState);
    
    if (self.channel) {
        [self.channel invokeMethod:@"onConnectionHandler" arguments:connectionState];
    }
}

-(void) sendLastChabokMessage {
    if ([self isAttachedToHost] && self.channel && _lastMessage) {
        [self.channel invokeMethod:@"onMessageHandler" arguments:_lastMessage];
    }
}

#pragma mark - delegate method
-(void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0)) {
    NSLog(@"------------ %@ cid", @(__PRETTY_FUNCTION__));
    
    [ChabokpushPlugin notificationOpened:response.notification.request.content.userInfo actionId:response.actionIdentifier];
    
    [self handleNotificationOpened];
    
    if (completionHandler) {
        completionHandler();
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler API_AVAILABLE(ios(10.0)) {
    NSLog(@"------------ %@ cid", @(__PRETTY_FUNCTION__));
    
    [ChabokpushPlugin notificationOpened:notification.request.content.userInfo actionId:nil];
    
    [self handleNotificationShown];
    
    if (completionHandler) {
        completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionAlert);
    }
}

-(void) pushClientManagerDidChangedServerConnectionState {
    NSLog(@"------------ %@ cid", @(__PRETTY_FUNCTION__));
    
    [self sendConnectionStatus];
}

-(void) pushClientManagerDidReceivedMessage:(PushClientMessage *)message {
    NSLog(@"------------ %@ cid", @(__PRETTY_FUNCTION__));
    
    NSMutableDictionary *messageDict = [NSMutableDictionary.alloc initWithDictionary:[message toDict]];
    [messageDict setObject:message.channel forKey:@"channel"];
    
    _lastMessage = [self dictionaryToJson:messageDict];
    
    [self sendLastChabokMessage];
}

// called when PushClientManager Register User Successfully
- (void)pushClientManagerDidRegisterUser:(BOOL)registration {
    NSLog(@"------------ %@ cid = %@", @(__PRETTY_FUNCTION__), @(registration));
    
    //    NSDictionary *successDic = @{@"regisered":@(registration)};
}

// called when PushClientManager Register User failed
- (void)pushClientManagerDidFailRegisterUser:(NSError *)error {
    NSLog(@"------------ %@ cid = %@", @(__PRETTY_FUNCTION__), error);
    
    //    NSDictionary *errorDic = @{@"error":error.localizedDescription};
}

- (void)pushClientManagerDidSubscribed:(NSString *)channel {
    NSLog(@"------------ %@ cid = %@", @(__PRETTY_FUNCTION__), channel);
    
    if (_subscriptionResult) {
        _subscriptionResult(channel);
        _subscriptionResult = nil;
    }
}

- (void)pushClientManagerDidFailInSubscribe:(NSError *)error {
    NSLog(@"------------ %@ cid = %@", @(__PRETTY_FUNCTION__), error);
    
    if (_subscriptionResult) {
        _subscriptionResult([FlutterError errorWithCode:@"-1"
                                                message:@"subscription failed"
                                                details:[error userInfo]]);
        _subscriptionResult = nil;
    }
}

- (void)pushClientManagerDidUnsubscribed:(NSString *)channel {
    NSLog(@"------------ %@ cid = %@", @(__PRETTY_FUNCTION__), channel);
    
    if (_unsubscriptionResult) {
        _unsubscriptionResult(channel);
        _unsubscriptionResult = nil;
    }
}

- (void)pushClientManagerDidFailInUnsubscribe:(NSError *)error {
    NSLog(@"------------ %@ cid = %@", @(__PRETTY_FUNCTION__), error);
    
    if (_unsubscriptionResult) {
        _unsubscriptionResult([FlutterError errorWithCode:@"-1"
                                                  message:@"unsubscription failed"
                                                  details:[error userInfo]]);
        _unsubscriptionResult = nil;
    }
}

#pragma mark - json
-(NSString *) dictionaryToJson:(NSDictionary *)dic {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+(NSDictionary *) getFormattedData:(NSDictionary *)data {
    NSMutableDictionary *mutableData = [NSMutableDictionary.alloc init];
    for (NSString *key in [data allKeys]) {
        // check datetime type
        if ([key hasPrefix:@"@CHKDATE_"]) {
            NSString *actualKey = [key substringFromIndex:9];
            mutableData[actualKey] = [[Datetime alloc] initWithTimestamp:[data[key] longLongValue]];
        } else {
            mutableData[key] = data[key];
        }
    }
    return mutableData;
}

@end
