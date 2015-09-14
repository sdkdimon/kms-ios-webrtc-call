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
@class KMSWebRTCEndpoint;
@class KMSWebRTCCall;
@class RTCMediaStream;
@class RTCMediaConstraints;

@protocol KMSWebRTCCallDataSource <NSObject>
@required
-(RTCMediaStream *)localMediaSteamForWebRTCCall:(KMSWebRTCCall *)webRTCCall;
-(RTCMediaConstraints *)localMediaSteamConstraintsForWebRTCCall:(KMSWebRTCCall *)webRTCCall;
-(RTCMediaConstraints *)peerConnetionMediaConstraintsForWebRTCCall:(KMSWebRTCCall *)webRTCCall;
@optional
-(NSArray *)sinkEndpointsForWebRTCCall:(KMSWebRTCCall *)webRTCCall;

@end


@protocol KMSWebRTCCallDelegate <NSObject>
@required
-(void)webRTCCall:(KMSWebRTCCall *)webRTCCall didCreateLocalMediaStream:(RTCMediaStream *)localMediaStream;
-(void)webRTCCall:(KMSWebRTCCall *)webRTCCall didCreateRemoteMediaStream:(RTCMediaStream *)remoteMediaStream;
-(void)webRTCCallDidEndCall:(KMSWebRTCCall *)webRTCCall;

-(void)webRTCCall:(KMSWebRTCCall *)webRTCCall didFailWithError:(NSError *)error;

@end


@interface KMSWebRTCCall : NSObject{
    NSMutableDictionary *_webRTCEndpointSubscriptions;
    NSMutableArray *_webRTCEndpointConnections;
}

+(instancetype)callWithWebRTCEndpoint:(KMSWebRTCEndpoint *)webRTCEndpoint peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory;
-(instancetype)initWithWebRTCEndpoint:(KMSWebRTCEndpoint *)webRTCEndpoint peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory;


@property(strong,nonatomic,readonly) KMSWebRTCEndpoint *webRTCEndpoint;
@property(strong,nonatomic,readonly) RTCPeerConnectionFactory *peerConnectionFactory;

@property(weak,nonatomic,readwrite) id <KMSWebRTCCallDelegate> delegate;
@property(weak,nonatomic,readwrite) id <KMSWebRTCCallDataSource> dataSource;

@property(strong,nonatomic,readonly) NSDictionary *webRTCEndpointSubscriptions;
@property(strong,nonatomic,readonly) NSArray *webRTCEndpointConnections;


-(void)startCall;
-(void)endCall;




@end
