//
//  PushClientMessage.h
//  AdpPushClient
//
//  Created by Farshad Mousalou on 6/14/15.
//  Copyright (c) 2015 Farshad Mousalou. All rights reserved.
//

//--------------------------Move all method to ChabokClientMessage class---------------------
#import <Foundation/Foundation.h>

@interface PushClientMessage : NSObject

/**
 The message id, Helps to find your message in the Chabok panel of Chabok REST API.
 */
@property (nonatomic, readonly) NSString *id;

/**
 The message body is required and should has value.
 */
@property (nonatomic, readonly) NSString *messageBody;

/**
 The notification payload. By add these keys can customize notification.
 
 title : Show title in push notification.
 body: Show body in push notification.
 subtitle: Show substitle in push notification.
 sound: Sound of push notification
 badge: Badge of application launcher, Note: Chabok by default handle applying badge count.
 
 Usage: [pushMessageInstance setValue:@"YOUR_TITLE" forKey:@"title"]
 */
@property (nonatomic, readonly) NSDictionary *notification;

/**
 Put your custem data here.
 */
@property (nonatomic, readonly) NSDictionary *data;

/**
 Channel of users will get message.
 
 Note: For public channel set userId to '*' (wildcard) and for private channel set userId to user should get the Chabok message.
 */
@property (nonatomic, readonly) NSString *channel;

/**
 This message will sent to which user.
 
 Note: For public channel set userId to '*' (wildcard) and for private channel set userId to user should get the Chabok message.
 */
@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSDate *serverTime;
@property (nonatomic, readonly) NSDate *expireTime;
@property (nonatomic, readonly) NSDate *receivedTime;
@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *sentId;
@property (nonatomic, readwrite) BOOL inApp;
@property (nonatomic, readwrite) BOOL live;
@property (nonatomic, readwrite) BOOL stateful;
@property (nonatomic, readwrite) BOOL useAsAlert;
@property (nonatomic, readwrite) BOOL silent;
@property (nonatomic, readwrite) NSString *alertText;

- (instancetype)initWithData:(NSData *)data channel:(NSString *)channel;
- (instancetype)initWithData:(NSData *)data toUserId:(NSString *)userId channel:(NSString *)channel;

- (instancetype)initWithJson:(NSDictionary *)json toUserId:(NSString *)userId channel:(NSString *)channel;
- (instancetype)initWithJson:(NSDictionary *)json channel:(NSString *)channel;

- (instancetype)initWithMessage:(NSString *)content channel:(NSString *)channel;
- (instancetype)initWithMessage:(NSString *)content toUserId:(NSString *)userId channel:(NSString *) channel;
- (instancetype)initWithMessage:(NSString *)content withData:(NSDictionary *)data channel:(NSString *)channel;
- (instancetype)initWithMessage:(NSString *)content withData:(NSDictionary *)data toUserId:(NSString *)userId channel:(NSString *)channel;

- (NSDictionary *)toDict;

- (NSData *)toData;

@end
