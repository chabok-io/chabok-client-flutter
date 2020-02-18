//
//  ChabokEvent.h
//  AdpPushClient
//
//  Created by Hussein Habibi Juybari on 6/23/19.
//  Copyright © 2019 Chabok Realtime Solution. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChabokEvent : NSObject

@property (nonatomic) double revenue;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSDictionary *data;

-(instancetype) initWithRevenue:(double) revenue;
-(instancetype) initWithRevenue:(double) revenue currency:(NSString *) currency;

-(void) setCurrency:(NSString *) currency;
-(void) setData:(NSDictionary *) data;

@end
