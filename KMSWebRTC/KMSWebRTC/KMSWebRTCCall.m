// KMSWebRTCCall.m
// Copyright (c) 2015 Dmitry Lizin (sdkdimon@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublIcense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notIce and this permission notIce shall be included in
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

#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCPeerConnection.h>

#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCAVFoundationVideoSource.h>
#import <WebRTC/RTCVideoTrack.h>
#import <WebRTC/RTCDispatcher.h>
#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCConfiguration.h>

#import <KMSClient/KMSWebRTCEndpoint.h>
#import <KMSClient/KMSEvent.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <KMSClient/KMSSession.h>
#import <KMSClient/KMSLog.h>

@interface RTCIceCandidate (KMSIceCandidate)
- (KMSICECandidate *)kmsIceCandidate;
@end

@implementation RTCIceCandidate (KMSIceCandidate)

- (KMSICECandidate *)kmsIceCandidate{
    KMSICECandidate *IceCandidate = [[KMSICECandidate alloc] init];
    [IceCandidate setCandidate:[self sdp]];
    [IceCandidate setSdpMid:[self sdpMid]];
    [IceCandidate setSdpMLineIndex:[self sdpMLineIndex]];
    
    return IceCandidate;
}

@end

@interface KMSICECandidate (RTCIceCandidate)
- (RTCIceCandidate *)rtcIceCandidate;
@end

@implementation KMSICECandidate (RTCIceCandidate)

- (RTCIceCandidate *)rtcIceCandidate{
    return [[RTCIceCandidate alloc] initWithSdp:[self candidate] sdpMLineIndex:(int)[self sdpMLineIndex] sdpMid:[self sdpMid]];
}

@end



@interface KMSWebRTCCall () <RTCPeerConnectionDelegate>

@property(strong,nonatomic,readwrite) RTCPeerConnection *peerConnection;
@property(strong,nonatomic,readwrite) RACCompoundDisposable *subscriptionDisposables;
@property(strong,nonatomic,readwrite) KMSSession *kurentoSession;

@property(strong,nonatomic,readwrite) KMSWebRTCEndpoint *webRTCEndpoint;

@property(strong,nonatomic,readwrite) NSString *webRTCEndpointId;
@property(strong,nonatomic,readwrite) NSString *mediaPipelineId;

@property (strong, nonatomic, readwrite) RACSubject *peerConnectionSignalingStateChangeSubject;

@end

@implementation KMSWebRTCCall
@synthesize webRTCEndpointSubscriptions = _webRTCEndpointSubscriptions;
@synthesize webRTCEndpointConnections = _webRTCEndpointConnections;

+(NSDictionary *)rtcSignalingStateMap{
    return @{@(RTCSignalingStateStable) : @"RTCSignalingStable",
             @(RTCSignalingStateHaveLocalOffer) : @"RTCSignalingHaveLocalOffer",
             @(RTCSignalingStateHaveLocalPrAnswer) : @"RTCSignalingHaveLocalPrAnswer",
             @(RTCSignalingStateHaveRemoteOffer) : @"RTCSignalingHaveRemoteOffer",
             @(RTCSignalingStateHaveRemotePrAnswer) : @"RTCSignalingHaveRemotePrAnswer",
             @(RTCSignalingStateClosed) : @"RTCSignalingClosed"};
}



+ (instancetype)callWithKurentoSession:(KMSSession *)kurentoSession peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory{
    return [[self alloc] initWithKurentoSession:kurentoSession peerConnectionFactory:peerConnecitonFactory];
}

- (instancetype)initWithKurentoSession:(KMSSession *)kurentoSession peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnecitonFactory{
    self = [super init];
    if(self != nil){
        _peerConnectionFactory = peerConnecitonFactory;
        _kurentoSession = kurentoSession;
        [self setup];
    }
    return self;
}

- (void)setup{
    _webRTCEndpointConnections = [[NSMutableArray alloc] init];
    _webRTCEndpointSubscriptions = [[NSMutableDictionary alloc] init];
    _subscriptionDisposables = [RACCompoundDisposable compoundDisposable];
    _peerConnectionSignalingStateChangeSubject = [RACSubject subject];
    
    RACSignal *connectionErrorSignal = [_kurentoSession errorSignal];
    @weakify(self);
    RACDisposable *connectionErrorSignalDisposable =
    [connectionErrorSignal subscribeNext:^(NSError *error) {
        @strongify(self);
        [self kurentoSession:[self kurentoSession] didFailWithError:error];
    }];
    
    [_subscriptionDisposables addDisposable:connectionErrorSignalDisposable];
}

- (void)setUpWebRTCEndpointId:(NSString *)webRTCEndpointId{
    [self setWebRTCEndpointId:webRTCEndpointId];
    if (webRTCEndpointId != nil){
        _webRTCEndpoint = [KMSWebRTCEndpoint endpointWithKurentoSession:_kurentoSession identifier:webRTCEndpointId];
        [self setMediaPipelineId:[_webRTCEndpoint mediaPipelineId]];
    }
}

- (void)setUpMediaPipelineId:(NSString *)mediaPipelineId{
    [self setMediaPipelineId:mediaPipelineId];
    if (mediaPipelineId != nil){
        _webRTCEndpoint = [KMSWebRTCEndpoint endpointWithKurentoSession:_kurentoSession mediaPipelineId:mediaPipelineId];
    }
}

#pragma mark MutableGetters

- (NSMutableDictionary *)mutableWebRTCEndpointSubscriptions{
    return _webRTCEndpointSubscriptions;
}

- (NSMutableArray *)mutableWebRTCEndpointConnections{
    return _webRTCEndpointConnections;
}


- (void)makeCall{
    NSAssert(_webRTCEndpoint != nil, @"webRTCEndpointId or mediaPipelineId can not be nil");
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
        [[self peerConnection] offerForConstraints:[[self dataSource] localMediaSteamConstraintsForWebRTCCall:self] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
                @weakify(self);
                if(error != nil){
                    [[self delegate] webRTCCall:self didFailWithError:error];
                    return;
                }
                
                [[self peerConnection] setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
                        KMSWebRTCEndpoint *webRTCSession = [self webRTCEndpoint];
                        RACSignal *processOfferSignal =
                        [[[webRTCSession processOffer:[sdp sdp]] flattenMap:^RACSignal *(NSString *remoteSDP) {
                            @strongify(self);
                            RACSignal *remoteDescriptionSetSignal =
                            [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                                RTCSessionDescription *remoteDesc = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:remoteSDP];
                                [[self peerConnection] setRemoteDescription:remoteDesc completionHandler:^(NSError * _Nullable error) {
                                    if (error == nil){
                                        [subscriber sendNext:nil];
                                        [subscriber sendCompleted];
                                    } else{
                                        [subscriber sendError:error];
                                    }
                                }];
                                return nil;
                            }];
                            
                            
                            return remoteDescriptionSetSignal;
                        }] flattenMap:^RACSignal *(id value) {
                            return [webRTCSession gatherICECandidates];
                        }];
                        [processOfferSignal subscribeError:^(NSError *error) {
                            @strongify(self);
                            [[self delegate] webRTCCall:self didFailWithError:error];
                        }];

                    }];
                }];
                
                
            }];
        }];
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
    RACSignal *webRTCEndpointEventOnIceCandidateSignal =
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
    
    return [[RACSignal concat:@[webRTCEndpointEventOnIceCandidateSignal,
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
       [[self peerConnection] addIceCandidate:[[iceCandidateEvent candidate] rtcIceCandidate]];
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
            [self hangupFromInitiator:KMSWebRTCCallInitiatorCallee];
        }
    }]];
}

- (void)createPeerConnection{
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    [config setIceTransportPolicy:RTCIceTransportPolicyAll];
    [config setBundlePolicy:RTCBundlePolicyBalanced];
    [config setRtcpMuxPolicy:RTCRtcpMuxPolicyNegotiate];
    [config setContinualGatheringPolicy:RTCContinualGatheringPolicyGatherOnce];
    [config setShouldPruneTurnPorts:YES];
    [config setShouldPresumeWritableWhenFullyRelayed:YES];
    _peerConnection = [[self peerConnectionFactory] peerConnectionWithConfiguration:config constraints:[[self dataSource] peerConnetionMediaConstraintsForWebRTCCall:self] delegate:self];
}

- (void)disposePeerConnection
{
    _peerConnection = nil;
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
                return [[self kurentoSession] closeSignal];
           }] ignoreValues];
}

- (RACSignal *)closePeerConnectionSignal{
    @weakify(self);
    return _peerConnection != nil ?
    [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
            RACSignal *peerConnectionSignalingStateChanged =
            [[[self peerConnectionSignalingStateChangeSubject] filter:^BOOL(NSNumber *state) {
                RTCSignalingState signalingState = (RTCSignalingState)[state integerValue];
                return signalingState == RTCSignalingStateClosed;
            }] deliverOn:[RACScheduler mainThreadScheduler]];
            
            
            RACDisposable *disposable =
            [peerConnectionSignalingStateChanged subscribeNext:^(RACTuple *args) {
                [self disposePeerConnection];
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }];
            [[self peerConnection] close];
            
            return disposable;
        
    }] : [RACSignal empty];
    
}


#pragma mark RTCPeerConnectionDelegate


/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged{
    [_peerConnectionSignalingStateChangeSubject sendNext:@(stateChanged)];
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
          didAddStream:(RTCMediaStream *)stream{
        [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
            [[self delegate] webRTCCall:self didAddRemoteMediaStream:stream];
        }];
}

/** Called when a remote peer closes a stream. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream{
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection{
    
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState{
    
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState{
    
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate{
        [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
            @weakify(self);
            [[[self webRTCEndpoint] addICECandidate:[candidate kmsIceCandidate]]
             subscribeError:^(NSError *error) {
                 @strongify(self);
                 [[self delegate] webRTCCall:self didFailWithError:error];
             }];
        }];
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates{

}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel{
    
}

#pragma mark KMSSessionErrorHandling

- (void)kurentoSession:(KMSSession *)session didFailWithError:(NSError *)error
{
    @weakify(self);
    [[self closePeerConnectionSignal] subscribeCompleted:^{
        @strongify(self);
        [[self delegate] webRTCCall:self didFailWithError:error];
    }];
}



@end
