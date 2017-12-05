//
//  KMSSessionPingPong.h
//  KMSClient
//
//  Created by dimon on 01/12/2017.
//  Copyright © 2017 dimon. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KMSSessionPing <NSObject>

- (void)sendPing:(NSData *)data;
- (void)didFailReceivePong;

@end

@protocol KMSSessionPong <NSObject>

- (void)didReceivePong:(NSData *)pongPayload;

@end

@interface KMSSessionConnectionMonitor : NSObject <KMSSessionPong>


- (instancetype)initWithPingTimeInterval:(NSTimeInterval)pingTimeInterval pingFailCount:(NSUInteger)pingFailCount;

@property (assign, nonatomic, readonly) NSTimeInterval pingTimeInterval;
@property (assign, nonatomic, readonly) NSUInteger pingFailCount;



@property (weak, nonatomic, readwrite) id <KMSSessionPing> ping;

- (void)start;
- (void)stop;

@end
