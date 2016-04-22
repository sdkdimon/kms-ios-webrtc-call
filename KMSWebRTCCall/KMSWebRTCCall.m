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
#import <ReactiveCocoa/NSObject+RACSelectorSignal.h>
#import <ReactiveCocoa/RACSubscriber.h>
#import <ReactiveCocoa/RACTuple.h>
#import <ReactiveCocoa/RACScheduler.h>

#import <RACSRWebSocket/RACSRWebSocket.h>
#import <KMSClient/KMSSession.h>
#import <KMSClient/KMSMessageFactoryWebRTCEndpoint.h>
#import <KMSClient/KMSLog.h>

@interface RTCICECandidate (KMSICECandidate)
- (KMSICECandidate *)kmsICECandidate;
@end

@implementation RTCICECandidate (KMSICECandidate)

- (KMSICECandidate *)kmsICECandidate{
    KMSICECandidate *iceCandidate = [[KMSICECandidate alloc] init];
    [iceCandidate setCandidate:[self sdp]];
    [iceCandidate setSdpMid:[self sdpMid]];
    [iceCandidate setSdpMLineIndex:[self sdpMLineIndex]];
    
    return iceCandidate;
}

@end

@interface KMSICECandidate (RTCICECandidate)
- (RTCICECandidate *)rtcICECandidate;
@end

@implementation KMSICECandidate (RTCICECandidate)

- (RTCICECandidate *)rtcICECandidate{
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

- (instancetype)initWithServerURL:(NSURL *)serverURL peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory webRTCEndpointId:(NSString *)webRTCEndpointId{
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

- (instancetype)initWithServerURL:(NSURL *)serverURL peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory mediaPipelineId:(NSString *)mediaPipelineId{
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

- (void)initialize{
    _webRTCEndpointConnections = [[NSMutableArray alloc] init];
    _webRTCEndpointSubscriptions = [[NSMutableDictionary alloc] init];
    _subscriptionDisposables = [RACCompoundDisposable compoundDisposable];
    
    
    RACSignal *connectionErrorSignal = [[_kurentoSession wsClient] webSocketDidFailSignal];
    @weakify(self);
    RACDisposable *connectionErrorSignalDisposable =
    [connectionErrorSignal subscribeNext:^(RACTuple *x) {
        @strongify(self);
        [[self delegate] webRTCCall:self didFailWithError:[x second]];
    }];
    
    [_subscriptionDisposables addDisposable:connectionErrorSignalDisposable];
    
    
    
}

#pragma mark MutableGetters

- (NSMutableDictionary *)mutableWebRTCEndpointSubscriptions{
    return _webRTCEndpointSubscriptions;
}

- (NSMutableArray *)mutableWebRTCEndpointConnections{
    return _webRTCEndpointConnections;
}


- (void)makeCall{
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
    
    [[[[_webRTCEndpoint eventSignalForEvent:KMSEventTypeMediaStateChanged] filter:^BOOL(KMSEventDataMediaStateChanged *mediaStateChangedEvent) {
        return [mediaStateChangedEvent newState] == KMSMediaStateConnected;
    }] take:1] subscribeNext:^(KMSEventDataMediaStateChanged *mediaStateChangedEvent) {
        @strongify(self);
        [[self delegate] webRTCCallDidStart:self];
    }];
    
}

- (void)hangupFromInitiator:(KMSWebRTCCallInitiator)initiator{
    @weakify(self);
    RACSignal *hangupSignal = [RACSignal concat:@[[self unsubscribeWebRTCEventsSignal],[self closePeerConnectionSignal],[self disposeWebRTCEndpointSignal]]];
    [hangupSignal subscribeError:^(NSError *error) {
        @strongify(self);
        [[self delegate] webRTCCall:self didFailWithError:error];
    } completed:^{
        @strongify(self);
        [[self delegate] webRTCCall:self hangupFromInitiator:initiator];
    }];
}

- (void)hangup{
    [self hangupFromInitiator:KMSWebRTCCallInitiatorCaller];
}

- (RACSignal *)connectWebRTCEndpointSignal{
    if([_dataSource respondsToSelector:@selector(sinkEndpointsForWebRTCCall:)]){
        NSArray *sinkEndpoints = [_dataSource sinkEndpointsForWebRTCCall:self];
        if([sinkEndpoints count] > 0){
            NSMutableArray *connectionSignals = [[NSMutableArray alloc] init];
            for(NSString *sinkEndpoint in sinkEndpoints){
                [connectionSignals addObject:[_webRTCEndpoint connect:sinkEndpoint]];
            }
            return [[RACSignal concat:connectionSignals] ignoreValues];
        }
    }
    return [RACSignal empty];
}

- (RACSignal *)webRTCEndpointInitialSignal{
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
    
    RACSignal *webRTCEndpointEventMediaStateChangedSignal =
    [[_webRTCEndpoint subscribe:KMSEventTypeMediaStateChanged] doNext:^(NSString *subscriptionId) {
        @strongify(self);
        [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeMediaStateChanged)];
    }];
    
    //Connect WebRTCEndpoint if needed
    RACSignal *webRTCEndpointGetSinkConnectionsSignal =
    [[_webRTCEndpoint getSinkConnections] doNext:^(NSArray *connections) {
        @strongify(self);
        //add only Audio and Video connections.
        NSPredicate *connectionsFilter = [NSPredicate predicateWithFormat:@"self.mediaType==%d || self.mediaType==%d",KMSMediaTypeAudio,KMSMediaTypeVideo];
        NSArray *connectionsToAdd = [connections filteredArrayUsingPredicate:connectionsFilter];
        [[self mutableWebRTCEndpointConnections] addObjectsFromArray:connectionsToAdd];
    }];
    
    
    
    RACSignal *connectWebRTCEndpointIfNeededSignal =
    [RACSignal if:[webRTCEndpointGetSinkConnectionsSignal map:^id(NSArray *connections) {
        return @([connections count] > 0);
    }] then:[RACSignal empty] else:[self connectWebRTCEndpointSignal]];
    
    return [[RACSignal concat:@[webRTCEndpointEventOnICECandidateSignal,
                               webRTCEndpointEventMediaElementConnectedSignal,
                               webRTCEndpointEventMediaElementDisconnectedSignal,
                               webRTCEndpointEventMediaStateChangedSignal,
                               connectWebRTCEndpointIfNeededSignal
                               ]] ignoreValues];
}

- (void)subscribeWebRTCEndpointEvents{
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
        
        KMSElementConnection *connectionToRemove = [elementConnectionEvent elementConnection];
        
        NSPredicate *connectionsFilter = [NSPredicate predicateWithFormat:@"self.source == %@ && self.mediaType == %d",[connectionToRemove source],[connectionToRemove mediaType]];
        NSArray *connectionsToRemove = [[self webRTCEndpointConnections] filteredArrayUsingPredicate:connectionsFilter];
        [[self mutableWebRTCEndpointConnections] removeObjectsInArray:connectionsToRemove];
        NSUInteger connectionCount = [[self webRTCEndpointConnections] count];
        if(connectionCount == 0){
            [self hangupFromInitiator:KMSWebRTCCallInitiatorOperator];
        }
    }]];
}

- (void)createPeerConnection{
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    _peerConnection = [[self peerConnectionFactory] peerConnectionWithConfiguration:config constraints:[[self dataSource] peerConnetionMediaConstraintsForWebRTCCall:self] delegate:self];
}

- (RACSignal *)unsubscribeWebRTCEventsSignal{
    
    if([_webRTCEndpointSubscriptions count] > 0){
        NSMutableArray *unsubscribeSignals = [[NSMutableArray alloc] init];
        for(NSNumber *subscriptionType in _webRTCEndpointSubscriptions){
            NSString *subscriptionId = _webRTCEndpointSubscriptions[subscriptionType];
            [unsubscribeSignals addObject:[_webRTCEndpoint unsubscribeSubscriptionId:subscriptionId]];
        }
        @weakify(self);
        return [[[RACSignal concat:unsubscribeSignals] doCompleted:^{
            @strongify(self);
            [[self subscriptionDisposables] dispose];
            [[self mutableWebRTCEndpointSubscriptions] removeAllObjects];
        }] ignoreValues];
    }
    
    return [RACSignal empty];

}

- (RACSignal *)disposeWebRTCEndpointSignal{
    @weakify(self);
   return [[[[self webRTCEndpoint] dispose] then:^RACSignal *{
                @strongify(self);
                return [[self kurentoSession] close];
           }] ignoreValues];
}

- (RACSignal *)closePeerConnectionSignal{
    @weakify(self);
    return _peerConnection != nil ?
    [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
            RACSignal *peerConnectionSignalingStateChanged =
            [[[self rac_signalForSelector:@selector(peerConnection:signalingStateChanged:) fromProtocol:@protocol(RTCPeerConnectionDelegate)] filter:^BOOL(RACTuple *args) {
                RTCSignalingState signalingState = (RTCSignalingState)[[args second] integerValue];
                return signalingState == RTCSignalingClosed;
            }] deliverOn:[RACScheduler mainThreadScheduler]];
            
            
            RACDisposable *disposable =
            [peerConnectionSignalingStateChanged subscribeNext:^(RACTuple *args) {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }];
            [[self peerConnection] close];
            
            return disposable;
        
    }] : [RACSignal empty];
    
}


#pragma mark RTCPeerConnectionDelegate

// Triggered when the SignalingState changed.
- (void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged{
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self delegate] webRTCCall:self didAddRemoteMediaStream:stream];
    });
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream{
}

// Triggered when renegotiation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection{
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState{
}

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState{
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate{
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
- (void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel{
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
        [[self peerConnection] setLocalDescriptionWithDelegate:self sessionDescription:sdp];
        KMSWebRTCEndpoint *webRTCSession = [self webRTCEndpoint];
        RACSignal *processOfferSignal =
        [[webRTCSession processOffer:[sdp description]] doNext:^(NSString *remoteSDP) {
            @strongify(self);
            RTCSessionDescription *remoteDesc = [[RTCSessionDescription alloc] initWithType:@"answer" sdp:remoteSDP];
            [[self peerConnection] setRemoteDescriptionWithDelegate:self sessionDescription:remoteDesc];
        }];
        RACSignal *processSDPOfferAndGatherICECandidates = [[RACSignal concat:@[processOfferSignal,[webRTCSession gatherICECandidates]]] ignoreValues];
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
