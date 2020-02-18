//
//  Datetime.h
//  AdpPushClient
//
//  Created by Farbod on 9/27/1398 AP.
//  Copyright © 1398 Chabok Realtime Solution. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Datetime: NSObject <NSCoding>

@property (nonatomic) long timestamp;

-(instancetype) initWithDate:(NSDate *) date;
-(instancetype) initWithIntervalSince1970:(NSTimeInterval) timeInterval;
-(instancetype) initWithTimestamp:(long) timestamp;

-(NSTimeInterval) getIntervalSince1970;
-(NSDate *) getDate;

+(NSDate *) now;

@end
