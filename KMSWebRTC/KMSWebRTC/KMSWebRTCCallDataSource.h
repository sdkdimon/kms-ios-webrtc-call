//
//  KMSWebRTCCallDataSource.h
//  LoopBackCall
//
//  Created by dimon on 11/08/16.
//  Copyright © 2016 CSLtd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KMSWebRTCCall;
@class RTCMediaStream;
@class RTCMediaConstraints;

@protocol KMSWebRTCCallDataSource <NSObject>

@required
- (nonnull RTCMediaStream *)localMediaSteamForWebRTCCall:(nonnull KMSWebRTCCall *)webRTCCall;
- (nonnull RTCMediaConstraints *)localMediaSteamConstraintsForWebRTCCall:(nonnull KMSWebRTCCall *)webRTCCall;
- (nonnull RTCMediaConstraints *)peerConnetionMediaConstraintsForWebRTCCall:(nonnull KMSWebRTCCall *)webRTCCall;

@optional
- (nonnull NSArray *)sinkEndpointsForWebRTCCall:(nonnull KMSWebRTCCall *)webRTCCall;

@end
