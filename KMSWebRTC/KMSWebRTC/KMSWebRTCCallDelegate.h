//
//  KMSWebRTCCallDelegate.h
//  LoopBackCall
//
//  Created by dimon on 11/08/16.
//  Copyright © 2016 CSLtd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KMSWebRTCCallInitiator.h"

@class KMSWebRTCCall;
@class RTCMediaStream;

@protocol KMSWebRTCCallDelegate <NSObject>

@required
- (void)webRTCCall:(nonnull KMSWebRTCCall *)webRTCCall didAddLocalMediaStream:(nonnull RTCMediaStream *)localMediaStream;
- (void)webRTCCall:(nonnull KMSWebRTCCall *)webRTCCall didAddRemoteMediaStream:(nonnull RTCMediaStream *)remoteMediaStream;
- (void)webRTCCallDidStart:(nonnull KMSWebRTCCall *)webRTCCall;
- (void)webRTCCall:(nonnull KMSWebRTCCall *)webRTCCall hangupFromInitiator:(KMSWebRTCCallInitiator)inititator;
- (void)webRTCCall:(nonnull KMSWebRTCCall *)webRTCCall didFailWithError:(nonnull NSError *)error;
@end
