// KMSWebRTCCall.h
// Copyright (c) 2015 Dmitry Lizin (sdkdimon@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@class RTCPeerConnectionFactory;
@class KMSWebRTCCall;
@class RTCMediaStream;
@class RTCMediaConstraints;
@class KMSSession;

typedef enum{
    KMSWebRTCCallInitiatorCaller,
    KMSWebRTCCallInitiatorCallee
}KMSWebRTCCallInitiator;

@protocol KMSWebRTCCallDataSource <NSObject>
@required
- (nonnull RTCMediaStream *)localMediaSteamForWebRTCCall:(nonnull KMSWebRTCCall *)webRTCCall;
- (nonnull RTCMediaConstraints *)localMediaSteamConstraintsForWebRTCCall:(nonnull KMSWebRTCCall *)webRTCCall;
- (nonnull RTCMediaConstraints *)peerConnetionMediaConstraintsForWebRTCCall:(nonnull KMSWebRTCCall *)webRTCCall;
@optional
- (nonnull NSArray *)sinkEndpointsForWebRTCCall:(nonnull KMSWebRTCCall *)webRTCCall;

@end


@protocol KMSWebRTCCallDelegate <NSObject>
@required
- (void)webRTCCall:(nonnull KMSWebRTCCall *)webRTCCall didAddLocalMediaStream:(nonnull RTCMediaStream *)localMediaStream;
- (void)webRTCCall:(nonnull KMSWebRTCCall *)webRTCCall didAddRemoteMediaStream:(nonnull RTCMediaStream *)remoteMediaStream;
- (void)webRTCCallDidStart:(nonnull KMSWebRTCCall *)webRTCCall;
- (void)webRTCCall:(nonnull KMSWebRTCCall *)webRTCCall hangupFromInitiator:(KMSWebRTCCallInitiator)inititator;
- (void)webRTCCall:(nonnull KMSWebRTCCall *)webRTCCall didFailWithError:(nonnull NSError *)error;
@end


@interface KMSWebRTCCall : NSObject{
    NSMutableDictionary *_webRTCEndpointSubscriptions;
    NSMutableArray *_webRTCEndpointConnections;
}

+ (nonnull instancetype)callWithKurentoSession:(nonnull KMSSession *)kurentoSession peerConnectionFactory:(nonnull RTCPeerConnectionFactory *)peerConnecitonFactory;
- (nonnull instancetype)initWithKurentoSession:(nonnull KMSSession *)kurentoSession peerConnectionFactory:(nonnull RTCPeerConnectionFactory *)peerConnecitonFactory;

@property(nonnull,strong,nonatomic,readonly) NSString *webRTCEndpointId;
@property(nonnull,strong,nonatomic,readonly) NSString *mediaPipelineId;
@property(nonnull,strong,nonatomic,readonly) RTCPeerConnectionFactory *peerConnectionFactory;
@property(nonnull,strong,nonatomic,readonly) KMSSession *kurentoSession;

- (void)setUpWebRTCEndpointId:(nullable NSString *)webRTCEndpointId;
- (void)setUpMediaPipelineId:(nullable NSString *)mediaPipelineId;



@property(nullable,weak,nonatomic,readwrite) id <KMSWebRTCCallDelegate> delegate;
@property(nullable,weak,nonatomic,readwrite) id <KMSWebRTCCallDataSource> dataSource;

@property(nonnull,strong,nonatomic,readonly) NSDictionary *webRTCEndpointSubscriptions;
@property(nonnull,strong,nonatomic,readonly) NSArray *webRTCEndpointConnections;


- (void)makeCall;
- (void)hangup;


#ifndef DOXYGEN_SHOULD_SKIP_THIS
// Disallow init and don't add to documentation
- (nonnull instancetype)init __attribute__(
                         (unavailable("init is not a supported initializer for this class.")));
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

@end
