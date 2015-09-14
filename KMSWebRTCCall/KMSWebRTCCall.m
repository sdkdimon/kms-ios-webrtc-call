// KMSWebRTCCall.m
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

#import "KMSWebRTCCall.h"

#import <libjingle_peerconnection/RTCPeerConnectionFactory.h>
#import <libjingle_peerconnection/RTCPeerConnection.h>
#import <libjingle_peerconnection/RTCPeerConnectionInterface.h>
#import <libjingle_peerconnection/RTCSessionDescriptionDelegate.h>
#import <libjingle_peerconnection/RTCMediaConstraints.h>
#import <libjingle_peerconnection/RTCMediaStream.h>
#import <libjingle_peerconnection/RTCAVFoundationVideoSource.h>
#import <libjingle_peerconnection/RTCVideoTrack.h>
#import <libjingle_peerconnection/RTCPair.h>
#import <libjingle_peerconnection/RTCICECandidate.h>
#import <libjingle_peerconnection/RTCSessionDescription.h>


#import <KMSClient/KMSWebRTCEndpoint.h>
#import <KMSClient/KMSEvent.h>
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACDisposable.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACEXTScope.h>

@interface RTCICECandidate (KMSICECandidate)
-(KMSICECandidate *)kmsICECandidate;
@end

@implementation RTCICECandidate (KMSICECandidate)

-(KMSICECandidate *)kmsICECandidate{
    KMSICECandidate *iceCandidate = [[KMSICECandidate alloc] init];
    [iceCandidate setCandidate:[self sdp]];
    [iceCandidate setSdpMid:[self sdpMid]];
    [iceCandidate setSdpMLineIndex:[self sdpMLineIndex]];
    
    return iceCandidate;
}

@end

@interface KMSICECandidate (RTCICECandidate)
-(RTCICECandidate *)rtcICECandidate;
@end

@implementation KMSICECandidate (RTCICECandidate)

-(RTCICECandidate *)rtcICECandidate{
    return [[RTCICECandidate alloc] initWithMid:[self sdpMid] index:[self sdpMLineIndex] sdp:[self candidate]];
}

@end



@interface KMSWebRTCCall () <RTCPeerConnectionDelegate,RTCSessionDescriptionDelegate>

@property(strong,nonatomic,readwrite) RTCPeerConnection *peerConnection;
@property(strong,nonatomic,readwrite) NSMutableArray *subscriptionDisposables;

@end

@implementation KMSWebRTCCall
@synthesize webRTCEndpointSubscriptions = _webRTCEndpointSubscriptions;
@synthesize webRTCEndpointConnections = _webRTCEndpointConnections;

+(instancetype)callWithWebRTCEndpoint:(KMSWebRTCEndpoint *)webRTCEndpoint peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory{
    return [[self alloc] initWithWebRTCEndpoint:webRTCEndpoint peerConnectionFactory:peerConnecitonFactory];
}

-(instancetype)initWithWebRTCEndpoint:(KMSWebRTCEndpoint *)webRTCEndpoint peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory{
    self = [super init];
    if(self != nil){
        _webRTCEndpoint = webRTCEndpoint;
        _peerConnectionFactory = peerConnecitonFactory;
        _webRTCEndpointConnections = [[NSMutableArray alloc] init];
        _webRTCEndpointSubscriptions = [[NSMutableDictionary alloc] init];
        _subscriptionDisposables = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark MutableGetters

-(NSMutableDictionary *)mutableWebRTCEndpointSubscriptions{
    return _webRTCEndpointSubscriptions;
}

-(NSMutableArray *)mutableWebRTCEndpointConnections{
    return _webRTCEndpointConnections;
}




-(void)startCall{
    @weakify(self);
    NSArray *webRTCEndpointSubscripitons =
    @[[[_webRTCEndpoint subscribe:KMSEventTypeOnICECandidate] doNext:^(NSString *subscriptionId) {
            @strongify(self);
            [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeOnICECandidate)];
        }],
      [[_webRTCEndpoint subscribe:KMSEventTypeMediaElementConnected] doNext:^(NSString *subscriptionId) {
          @strongify(self);
          [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeMediaElementConnected)];
      }],
      [[_webRTCEndpoint subscribe:KMSEventTypeMediaElementDisconnected] doNext:^(NSString *subscriptionId) {
          @strongify(self);
          [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeMediaElementDisconnected)];
      }]
      ];

    RACSignal *webRTCEndpointConnectionSignal =  [[_webRTCEndpoint getSinkConnections] doNext:^(NSArray *connections) {
        [[self mutableWebRTCEndpointConnections] addObjectsFromArray:connections];
    }];
    RACSignal *webRTCEndpointSubscriptionsSignal = [RACSignal concat:webRTCEndpointSubscripitons];
    
    
    RACSignal *webRTCEndpointInitialSignal = [webRTCEndpointConnectionSignal then:^RACSignal *{
        return webRTCEndpointSubscriptionsSignal;
    }];
    
    
    
    [webRTCEndpointInitialSignal subscribeError:^(NSError *error) {
        @strongify(self);
        [[self delegate] webRTCCall:self didFailWithError:error];
    } completed:^{
        @strongify(self);
        [self subscribeWebRTCEndpointEvents];
        [self createPeerConnection];
        RTCMediaStream *localMediaStream = [[self dataSource] localMediaSteamForWebRTCCall:self];
        [[self peerConnection] addStream:localMediaStream];
        [[self delegate] webRTCCall:self didCreateLocalMediaStream:localMediaStream];
        [[self peerConnection] createOfferWithDelegate:self constraints:[[self dataSource] localMediaSteamConstraintsForWebRTCCall:self]];
    }];
    
}

-(void)endCall{
    [[self peerConnection] close];
}

-(void)subscribeWebRTCEndpointEvents{
    @weakify(self);
    [_subscriptionDisposables addObject:
    [[_webRTCEndpoint eventSignalForEvent:KMSEventTypeOnICECandidate] subscribeNext:^(KMSEventDataICECandidate *iceCandidateEvent) {
       @strongify(self);
       [[self peerConnection] addICECandidate:[[iceCandidateEvent candidate] rtcICECandidate]];
   }]];
    [_subscriptionDisposables addObject:
    [[_webRTCEndpoint eventSignalForEvent:KMSEventTypeMediaElementConnected] subscribeNext:^(KMSEventDataElementConnection *elementConnectionEvent) {
        @strongify(self);
        [[self mutableWebRTCEndpointConnections] addObject:[elementConnectionEvent elementConnection]];
    }]];
    [_subscriptionDisposables addObject:
    [[_webRTCEndpoint eventSignalForEvent:KMSEventTypeMediaElementDisconnected] subscribeNext:^(KMSEventDataElementConnection *elementConnectionEvent) {
        @strongify(self);
        [[self mutableWebRTCEndpointConnections] removeObject:[elementConnectionEvent elementConnection]];
        NSUInteger connectionCount = [[self webRTCEndpointConnections] count];
        if(connectionCount == 0){
            [self endCall];
        }
    }]];
}

-(void)unsubscribeWebRTCEndpointEvents{
    for(RACDisposable *d in _subscriptionDisposables){
        if(![d isDisposed]) [d dispose];
    }
    [_subscriptionDisposables removeAllObjects];
}

-(void)createPeerConnection{
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    _peerConnection = [[self peerConnectionFactory] peerConnectionWithConfiguration:config constraints:[[self dataSource] peerConnetionMediaConstraintsForWebRTCCall:self] delegate:self];
}

-(void)peerConnectionDidClose{
    RACSignal *unsubscribeSignal = [RACSignal empty];
    for(NSNumber *subscriptionType in _webRTCEndpointSubscriptions){
        NSString *subscriptionId = _webRTCEndpointSubscriptions[subscriptionType];
        unsubscribeSignal = [unsubscribeSignal concat:[_webRTCEndpoint unsubscribeSubscriptionId:subscriptionId]];
    }
    [_webRTCEndpointSubscriptions removeAllObjects];
    
    @weakify(self);
    RACSignal *endCallSignal = [unsubscribeSignal then:^RACSignal *{
        @strongify(self);
        [self unsubscribeWebRTCEndpointEvents];
        return [[self webRTCEndpoint] dispose];
    }];
    
    [endCallSignal subscribeError:^(NSError *error) {
        NSLog(@"");
    } completed:^{
        @strongify(self);
        [[self delegate] webRTCCallDidEndCall:self];
    }];
}

#pragma mark RTCPeerConnectionDelegate

// Triggered when the SignalingState changed.
-(void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%d",stateChanged);
        switch (stateChanged) {
            case RTCSignalingClosed:
                [self peerConnectionDidClose];
                break;
                
            default:
                break;
        }
        
    });
}

// Triggered when media is received on a new stream from remote peer.
-(void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self delegate] webRTCCall:self didCreateRemoteMediaStream:stream];
    });
}

// Triggered when a remote peer close a stream.
-(void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream{
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

// Triggered when renegotiation is needed, for example the ICE has restarted.
-(void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection{
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

// Called any time the ICEConnectionState changes.
-(void)peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState{
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

// Called any time the ICEGatheringState changes.
-(void)peerConnection:(RTCPeerConnection *)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState{
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

// New Ice candidate have been found.
-(void)peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self webRTCEndpoint] addICECandidate:[candidate kmsICECandidate]]
         subscribeError:^(NSError *error) {
             NSLog(@"error add ice candidate %@",error);
         }completed:^{
             NSLog(@"ice candidate added");
         }];
    });
}

// New data channel has been opened.
-(void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel{
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

#pragma mark RTCSessionDescriptionDelegate


// Called when creating a session.
- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        @weakify(self);
        NSString *sdpDescription = [sdp description];
        NSString *sdpFixDescription = [sdpDescription stringByReplacingOccurrencesOfString:@"UDP/TLS/RTP/SAVPF" withString:@"RTP/SAVPF"];
        RTCSessionDescription *fixedDescription = [[RTCSessionDescription alloc] initWithType:[sdp type] sdp:sdpFixDescription];
        [[self peerConnection] setLocalDescriptionWithDelegate:self sessionDescription:fixedDescription];
        KMSWebRTCEndpoint *webRTCSession = [self webRTCEndpoint];
        
        RACSignal *processSDPOfferAndGatherICECandidates =
        [[webRTCSession processOffer:sdpFixDescription]
         flattenMap:^RACStream *(NSString *remoteSDP) {
             @strongify(self);
             RTCSessionDescription *remoteDesc = [[RTCSessionDescription alloc] initWithType:@"answer" sdp:remoteSDP];
             [[self peerConnection] setRemoteDescriptionWithDelegate:self sessionDescription:remoteDesc];
             return [webRTCSession gatherICECandidates];
         }];
        
        [processSDPOfferAndGatherICECandidates subscribeError:^(NSError *error) {
            NSLog(@"error process sdp offer %@",error);
        }completed:^{
            NSLog(@"complete processs offer. Started gathering ICE candidates....");
        }];

        
    });
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}



@end
