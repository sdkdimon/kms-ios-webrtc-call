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
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACCompoundDisposable.h>
#import <RACSRWebSocket/RACSRWebSocket.h>
#import <KMSClient/KMSSession.h>
#import <KMSClient/KMSMessageFactoryWebRTCEndpoint.h>
#import <KMSClient/KMSLog.h>

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
@property(strong,nonatomic,readwrite) RACCompoundDisposable *subscriptionDisposables;
@property(strong,nonatomic,readwrite) KMSSession *kurentoSession;

@property(strong,nonatomic,readwrite) KMSWebRTCEndpoint *webRTCEndpoint;

@property(strong,nonatomic,readwrite) NSString *webRTCEndpointId;
@property(strong,nonatomic,readwrite) NSString *mediaPipelineId;

@end

@implementation KMSWebRTCCall
@synthesize webRTCEndpointSubscriptions = _webRTCEndpointSubscriptions;
@synthesize webRTCEndpointConnections = _webRTCEndpointConnections;

+(NSDictionary *)rtcSignalingStateMap{
    return @{@(RTCSignalingStable) : @"RTCSignalingStable",
             @(RTCSignalingHaveLocalOffer) : @"RTCSignalingHaveLocalOffer",
             @(RTCSignalingHaveLocalPrAnswer) : @"RTCSignalingHaveLocalPrAnswer",
             @(RTCSignalingHaveRemoteOffer) : @"RTCSignalingHaveRemoteOffer",
             @(RTCSignalingHaveRemotePrAnswer) : @"RTCSignalingHaveRemotePrAnswer",
             @(RTCSignalingClosed) : @"RTCSignalingClosed"};
}

+(instancetype)callWithServerURL:(NSURL *)serverURL peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory webRTCEndpointId:(NSString *)webRTCEndpointId{
    return [[self alloc] initWithServerURL:serverURL peerConnectionFactory:peerConnecitonFactory webRTCEndpointId:webRTCEndpointId];
}

+(instancetype)callWithServerURL:(NSURL *)serverURL peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory mediaPipelineId:(NSString *)mediaPipelineId;{
    return [[self alloc] initWithServerURL:serverURL peerConnectionFactory:peerConnecitonFactory mediaPipelineId:mediaPipelineId];
}

-(instancetype)initWithServerURL:(NSURL *)serverURL peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory webRTCEndpointId:(NSString *)webRTCEndpointId{
    self = [super init];
    if(self != nil){
        _webRTCEndpointId = webRTCEndpointId;
        _serverURL = serverURL;
        _peerConnectionFactory = peerConnecitonFactory;
        _kurentoSession = [KMSSession sessionWithWebSocketClient:[[RACSRWebSocket alloc] initWithURL:_serverURL]];
        KMSMessageFactoryWebRTCEndpoint *webRTCEndpointMessageFactory = [[KMSMessageFactoryWebRTCEndpoint alloc] init];
        _webRTCEndpoint = [KMSWebRTCEndpoint endpointWithKurentoSession:_kurentoSession messageFactory:webRTCEndpointMessageFactory identifier:webRTCEndpointId];
        [webRTCEndpointMessageFactory setDataSource:_webRTCEndpoint];
        _mediaPipelineId = [_webRTCEndpoint mediaPipelineId];
        [self initialize];
    }
    return self;
}

-(instancetype)initWithServerURL:(NSURL *)serverURL peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory mediaPipelineId:(NSString *)mediaPipelineId{
    self = [super init];
    if(self != nil){
        _mediaPipelineId = mediaPipelineId;
        _serverURL = serverURL;
        _peerConnectionFactory = peerConnecitonFactory;
        _kurentoSession = [KMSSession sessionWithWebSocketClient:[[RACSRWebSocket alloc] initWithURL:_serverURL]];
        KMSMessageFactoryWebRTCEndpoint *webRTCEndpointMessageFactory = [[KMSMessageFactoryWebRTCEndpoint alloc] init];
        _webRTCEndpoint = [KMSWebRTCEndpoint endpointWithKurentoSession:_kurentoSession messageFactory:webRTCEndpointMessageFactory mediaPipelineId:mediaPipelineId];
        [webRTCEndpointMessageFactory setDataSource:_webRTCEndpoint];
        [self initialize];
    }
    return self;
}

-(void)initialize{
    _webRTCEndpointConnections = [[NSMutableArray alloc] init];
    _webRTCEndpointSubscriptions = [[NSMutableDictionary alloc] init];
    _subscriptionDisposables = [RACCompoundDisposable compoundDisposable];
}

#pragma mark MutableGetters

-(NSMutableDictionary *)mutableWebRTCEndpointSubscriptions{
    return _webRTCEndpointSubscriptions;
}

-(NSMutableArray *)mutableWebRTCEndpointConnections{
    return _webRTCEndpointConnections;
}


-(void)makeCall{
    @weakify(self);
    //Create WebRTCEndpoint signal if it has not created yet;
    RACSignal *createWebRTCEndpointSignal =
    [[_webRTCEndpoint create] doNext:^(NSString *webRTCEndpointId) {
        @strongify(self);
        [self setWebRTCEndpointId:webRTCEndpointId];
        [self subscribeWebRTCEndpointEvents];
    }];
    
    RACSignal *webRTCEndpointInitialSignal = [createWebRTCEndpointSignal then:^RACSignal *{
         @strongify(self);
        return [self webRTCEndpointInitialSignal];
    }];
    
    [webRTCEndpointInitialSignal subscribeError:^(NSError *error) {
        @strongify(self);
        [[self delegate] webRTCCall:self didFailWithError:error];
    } completed:^{
        @strongify(self);
        [self createPeerConnection];
        RTCMediaStream *localMediaStream = [[self dataSource] localMediaSteamForWebRTCCall:self];
        [[self peerConnection] addStream:localMediaStream];
        [[self delegate] webRTCCall:self didAddLocalMediaStream:localMediaStream];
        [[self peerConnection] createOfferWithDelegate:self constraints:[[self dataSource] localMediaSteamConstraintsForWebRTCCall:self]];
    }];
    
}

-(void)hangup{
    _peerConnection != nil ? [_peerConnection close] : [self disposeWebRTCEndpoint];
}

-(RACSignal *)connectWebRTCEndpointSignal{
    NSArray *sinkEndpoints = [[self dataSource] sinkEndpointsForWebRTCCall:self];
    RACSignal *connectWebRTCEndpointSignal = [RACSignal empty];
    
    for(NSString *sinkEndpoint in sinkEndpoints){
        connectWebRTCEndpointSignal = [connectWebRTCEndpointSignal concat:[_webRTCEndpoint connect:sinkEndpoint]];
    }
    return connectWebRTCEndpointSignal;
}

-(RACSignal *)webRTCEndpointInitialSignal{
    @weakify(self)
    //Subscribe onEvents signals
    RACSignal *webRTCEndpointEventOnICECandidateSignal =
    [[_webRTCEndpoint subscribe:KMSEventTypeOnICECandidate] doNext:^(NSString *subscriptionId) {
        @strongify(self);
        [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeOnICECandidate)];
    }];
    
    RACSignal *webRTCEndpointEventMediaElementConnectedSignal =
    [[_webRTCEndpoint subscribe:KMSEventTypeMediaElementConnected] doNext:^(NSString *subscriptionId) {
        @strongify(self);
        [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeMediaElementConnected)];
    }];
    
    RACSignal *webRTCEndpointEventMediaElementDisconnectedSignal =
    [[_webRTCEndpoint subscribe:KMSEventTypeMediaElementDisconnected] doNext:^(NSString *subscriptionId) {
        @strongify(self);
        [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeMediaElementDisconnected)];
    }];
    
    //Connect WebRTCEndpoint if needed
    RACSignal *webRTCEndpointGetSinkConnectionsSignal =
    [[_webRTCEndpoint getSinkConnections] doNext:^(NSArray *connections) {
        @strongify(self);
        [[self mutableWebRTCEndpointConnections] addObjectsFromArray:connections];
    }];
    
    RACSignal *connectWebRTCEndpointIfNeededSignal =
    [RACSignal if:[webRTCEndpointGetSinkConnectionsSignal map:^id(NSArray *connections) {
        return @([connections count] > 0);
    }] then:[RACSignal empty] else:[self connectWebRTCEndpointSignal]];
    
    return [RACSignal concat:@[webRTCEndpointEventOnICECandidateSignal,
                               webRTCEndpointEventMediaElementConnectedSignal,
                               webRTCEndpointEventMediaElementDisconnectedSignal,
                               connectWebRTCEndpointIfNeededSignal]];
}

-(void)subscribeWebRTCEndpointEvents{
    @weakify(self);
    [_subscriptionDisposables addDisposable:
    [[_webRTCEndpoint eventSignalForEvent:KMSEventTypeOnICECandidate] subscribeNext:^(KMSEventDataICECandidate *iceCandidateEvent) {
       @strongify(self);
       [[self peerConnection] addICECandidate:[[iceCandidateEvent candidate] rtcICECandidate]];
   }]];
    [_subscriptionDisposables addDisposable:
    [[_webRTCEndpoint eventSignalForEvent:KMSEventTypeMediaElementConnected] subscribeNext:^(KMSEventDataElementConnection *elementConnectionEvent) {
        @strongify(self);
        [[self mutableWebRTCEndpointConnections] addObject:[elementConnectionEvent elementConnection]];
    }]];
    [_subscriptionDisposables addDisposable:
    [[_webRTCEndpoint eventSignalForEvent:KMSEventTypeMediaElementDisconnected] subscribeNext:^(KMSEventDataElementConnection *elementConnectionEvent) {
        @strongify(self);
        [[self mutableWebRTCEndpointConnections] removeObject:[elementConnectionEvent elementConnection]];
        NSUInteger connectionCount = [[self webRTCEndpointConnections] count];
        if(connectionCount == 0){
            [self hangup];
        }
    }]];
}

-(void)createPeerConnection{
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    _peerConnection = [[self peerConnectionFactory] peerConnectionWithConfiguration:config constraints:[[self dataSource] peerConnetionMediaConstraintsForWebRTCCall:self] delegate:self];
    
}

-(void)disposeWebRTCEndpoint{
    RACSignal *unsubscribeSignal = [RACSignal empty];
    for(NSNumber *subscriptionType in _webRTCEndpointSubscriptions){
        NSString *subscriptionId = _webRTCEndpointSubscriptions[subscriptionType];
        unsubscribeSignal = [unsubscribeSignal concat:[_webRTCEndpoint unsubscribeSubscriptionId:subscriptionId]];
    }
    
    @weakify(self);
    RACSignal *endCallSignal =
    [[unsubscribeSignal  doCompleted:^{
        @strongify(self);
        [[self subscriptionDisposables] dispose];
        [[self mutableWebRTCEndpointSubscriptions] removeAllObjects];
    }] then:^RACSignal *{
        @strongify(self);
        return [RACSignal concat:@[[[self webRTCEndpoint] dispose],[[self kurentoSession] close]]];
    }];
    
    [endCallSignal subscribeError:^(NSError *error) {
        @strongify(self);
        [[self delegate] webRTCCall:self didFailWithError:error];
    } completed:^{
        @strongify(self);
        [[self delegate] webRTCCallDidHangup:self];
    }];
}

#pragma mark RTCPeerConnectionDelegate

// Triggered when the SignalingState changed.
-(void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged{
    dispatch_async(dispatch_get_main_queue(), ^{
        KMSLog(KMSLogMessageLevelVerbose,@"RTCPeerConnection signalingStateChanged %@",[[self class] rtcSignalingStateMap][@(stateChanged)]);
        switch (stateChanged) {
            case RTCSignalingClosed:
                [self disposeWebRTCEndpoint];
                break;
                
            default:
                break;
        }
        
        
    });
}

// Triggered when media is received on a new stream from remote peer.
-(void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self delegate] webRTCCall:self didAddRemoteMediaStream:stream];
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
        @weakify(self);
        [[[self webRTCEndpoint] addICECandidate:[candidate kmsICECandidate]]
         subscribeError:^(NSError *error) {
             @strongify(self);
             [[self delegate] webRTCCall:self didFailWithError:error];
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
        if(error != nil){
            [[self delegate] webRTCCall:self didFailWithError:error];
            return;
        }
        
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
            @strongify(self);
            [[self delegate] webRTCCall:self didFailWithError:error];
        }];

        
    });
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(error != nil){
            [[self delegate] webRTCCall:self didFailWithError:error];
        }
    });
}



@end
