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

#import <ReactiveObjC/ReactiveObjC.h>
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
#import <KMSClient/KMSSession.h>
#import <KMSClient/KMSLog.h>
#import "RTCPeerConnection+RAC.h"

@interface KMSWebRTCEndpoint (SubscriptionSignal)

- (RACSignal *)ss_subscribe:(KMSEventType)event;

@end

@implementation KMSWebRTCEndpoint (SubscriptionSignal)

- (RACSignal *)ss_subscribe:(KMSEventType)event
{
  @weakify(self);
  return [[self subscribe:event] map:^id _Nullable(NSString *subscriptionId) {
      @strongify(self);
      return RACTuplePack(subscriptionId, [self eventSignalForEvent:event]);
  }];
}

@end


@interface RTCIceCandidate (KMSIceCandidate)

- (KMSICECandidate *)kmsIceCandidate;

@end

@implementation RTCIceCandidate (KMSIceCandidate)

- (KMSICECandidate *)kmsIceCandidate
{
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

- (RTCIceCandidate *)rtcIceCandidate
{
    return [[RTCIceCandidate alloc] initWithSdp:[self candidate] sdpMLineIndex:(int)[self sdpMLineIndex] sdpMid:[self sdpMid]];
}

@end

@interface KMSWebRTCCall () <RTCPeerConnectionDelegate>

@property(strong,nonatomic,readwrite) RTCPeerConnection *peerConnection;
@property(strong,nonatomic,readwrite) RACCompoundDisposable *subscriptionDisposables;
@property(strong,nonatomic,readwrite) KMSSession *kurentoSession;
@property(strong,nonatomic,readwrite) KMSWebRTCEndpoint *webRTCEndpoint;
@property (strong, nonatomic, readwrite) RACSubject *peerConnectionSignalingStateChangeSubject;

@end

@implementation KMSWebRTCCall
@synthesize webRTCEndpointSubscriptions = _webRTCEndpointSubscriptions;
@synthesize webRTCEndpointConnections = _webRTCEndpointConnections;

+ (NSDictionary *)rtcSignalingStateMap{
    return @{@(RTCSignalingStateStable) : @"RTCSignalingStable",
             @(RTCSignalingStateHaveLocalOffer) : @"RTCSignalingHaveLocalOffer",
             @(RTCSignalingStateHaveLocalPrAnswer) : @"RTCSignalingHaveLocalPrAnswer",
             @(RTCSignalingStateHaveRemoteOffer) : @"RTCSignalingHaveRemoteOffer",
             @(RTCSignalingStateHaveRemotePrAnswer) : @"RTCSignalingHaveRemotePrAnswer",
             @(RTCSignalingStateClosed) : @"RTCSignalingClosed"};
}



+ (instancetype)callWithKurentoSession:(KMSSession *)kurentoSession
{
    return [[self alloc] initWithKurentoSession:kurentoSession];
}

- (instancetype)initWithKurentoSession:(KMSSession *)kurentoSession
{
    self = [super init];
    if(self != nil){
        _kurentoSession = kurentoSession;
        [self setup];
    }
    return self;
}

- (void)setup
{
    _peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
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

#pragma mark MutableGetters

- (NSMutableDictionary *)mutableWebRTCEndpointSubscriptions
{
    return _webRTCEndpointSubscriptions;
}

- (NSMutableArray *)mutableWebRTCEndpointConnections
{
    return _webRTCEndpointConnections;
}

- (NSString *)webRTCEndpointId
{
    return [_webRTCEndpoint identifier];
}

- (RACSignal *)callSignalWithWebRTCEndpointId:(NSString *)webRTCEndpointId
{
    _webRTCEndpoint = [KMSWebRTCEndpoint endpointWithKurentoSession:_kurentoSession identifier:webRTCEndpointId];
    return [self callSignal];
}

- (RACSignal *)callSignalWithMediaPipelineId:(NSString *)mediaPipelineEndpointId
{
    _webRTCEndpoint = [KMSWebRTCEndpoint endpointWithKurentoSession:_kurentoSession mediaPipelineId:mediaPipelineEndpointId];
    return [self callSignal];
}

- (RACSignal *)callSignal
{
    @weakify(self);
    return [[self prepareWebRTCEndpointSignal] then:^RACSignal * _Nonnull{
        @strongify(self);
        [self createPeerConnection];
        RTCMediaStream *localMediaStream = [[self dataSource] localMediaSteamForWebRTCCall:self];
        [[self peerConnection] addStream:localMediaStream];
        [[self delegate] webRTCCall:self didAddLocalMediaStream:localMediaStream];
        return [[[self peerConnection] offerSignalForConstraints:[[self dataSource] localMediaSteamConstraintsForWebRTCCall:self]] flattenMap:^__kindof RACSignal * _Nullable(RTCSessionDescription  *localSessionDescription) {
            @strongify(self);
            return [[[self peerConnection] setLocalDescriptionSignal:localSessionDescription] then:^RACSignal * _Nonnull{
                @strongify(self);
                return [[[self webRTCEndpoint] processOffer:[localSessionDescription sdp]] flattenMap:^__kindof RACSignal * _Nullable(NSString *remoteSessionDescription) {
                    @strongify(self);
                    RTCSessionDescription *remoteDesc = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:remoteSessionDescription];
                    return [[[self peerConnection] setRemoteDescriptionSignal:remoteDesc] then:^RACSignal * _Nonnull{
                        @strongify(self);
                        return [[[self webRTCEndpoint] gatherICECandidates] then:^RACSignal * _Nonnull{
                            @strongify(self);
                            return [self callBeginSignal];
                        }];
                    }];
                }];
            }];
        }];
    }];
}

- (RACSignal *)callBeginSignal
{
    RACSignal *mediaStateChangedSignal =
    [[[[[self webRTCEndpoint] eventSignalForEvent:KMSEventTypeMediaStateChanged] filter:^BOOL(KMSEventDataMediaStateChanged *mediaStateChangedEvent) {
        return [mediaStateChangedEvent state] == KMSMediaStateConnected;
    }] take:1] map:^id _Nullable(id  _Nullable value) {
        return nil;
    }];
    
    @weakify(self);
    return [mediaStateChangedSignal doCompleted:^{
        @strongify(self);
        [[self delegate] webRTCCallDidStart:self];
    }];
}

- (RACSignal *)prepareWebRTCEndpointSignal
{
    NSAssert(_webRTCEndpoint != nil, @"webRTCEndpointId or mediaPipelineId can not be nil");
    @weakify(self);
    //Create WebRTCEndpoint signal if it has not created yet;
    RACSignal *createWebRTCEndpointSignal = [_webRTCEndpoint create];
    return [[createWebRTCEndpointSignal then:^RACSignal * _Nonnull{
        @strongify(self);
        return [self subscribeWebRTCEvents];
    }] then:^RACSignal * _Nonnull{
        @strongify(self);
        return [self connectWebRTCEndpointSignal];
    }];
}


- (RACSignal *)hangupSignalFromInitiator:(KMSWebRTCCallInitiator)initiator
{
    @weakify(self);
    RACSignal *hangupSignal =
    [[[RACSignal concat:@[[self unsubscribeWebRTCEventsSignal],[self closePeerConnectionSignal],[self disposeWebRTCEndpointSignal]]]
    doCompleted:^{
        @strongify(self);
        [[self delegate] webRTCCall:self hangupFromInitiator:initiator];
    }]
    doError:^(NSError * _Nonnull error) {
        @strongify(self);
        [[self delegate] webRTCCall:self didFailWithError:error];

    }];
    return hangupSignal;
}

- (RACSignal *)hangupSignal
{
    return [self hangupSignalFromInitiator:KMSWebRTCCallInitiatorCaller];
}

- (RACSignal *)loadWebRTCEndpointSinkConnections
{
    @weakify(self);
    return [[_webRTCEndpoint getSinkConnections] doNext:^(NSArray *connections) {
        @strongify(self);
        //add only Audio and Video connections.
        NSPredicate *connectionsFilter = [NSPredicate predicateWithFormat:@"self.mediaType==%d || self.mediaType==%d",KMSMediaTypeAudio,KMSMediaTypeVideo];
        NSArray *connectionsToAdd = [connections filteredArrayUsingPredicate:connectionsFilter];
        [[self mutableWebRTCEndpointConnections] addObjectsFromArray:connectionsToAdd];
    }];

}

- (RACSignal *)connectWebRTCEndpointToDataSourceSinkEndpoints
{
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

- (RACSignal *)connectWebRTCEndpointSignal
{
    return [RACSignal if:[[self loadWebRTCEndpointSinkConnections] map:^id(NSArray *connections) {
        return @([connections count] > 0);
    }] then:[RACSignal empty] else:[self connectWebRTCEndpointToDataSourceSinkEndpoints]];
}

- (RACSignal *)subscribeWebRTCEvents
{
    @weakify(self);
    //Subscribe onEvents signals
    RACSignal *webRTCEndpointEventOnIceCandidateSignal =
    [[_webRTCEndpoint ss_subscribe:KMSEventTypeOnICECandidate] doNext:^(RACTuple *values) {
        @strongify(self);
        NSString *subscriptionId = [values first];
        RACSignal *eventSignal = [values second];
        [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeOnICECandidate)];
        [[self subscriptionDisposables] addDisposable:
        [eventSignal subscribeNext:^(KMSEventDataICECandidate *iceCandidateEvent) {
            @strongify(self);
            [[self peerConnection] addIceCandidate:[[iceCandidateEvent candidate] rtcIceCandidate]];
        }]];
    }];
    
    RACSignal *webRTCEndpointEventMediaElementConnectedSignal =
    [[_webRTCEndpoint ss_subscribe:KMSEventTypeMediaElementConnected] doNext:^(RACTuple *values) {
        @strongify(self);
        NSString *subscriptionId = [values first];
        RACSignal *eventSignal = [values second];
        [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeMediaElementConnected)];
        [[self subscriptionDisposables] addDisposable:
         [eventSignal subscribeNext:^(KMSEventDataElementConnection *elementConnectionEvent) {
            @strongify(self);
            [[self mutableWebRTCEndpointConnections] addObject:[elementConnectionEvent elementConnection]];
        }]];
    }];
    
    RACSignal *webRTCEndpointEventMediaElementDisconnectedSignal =
    [[_webRTCEndpoint ss_subscribe:KMSEventTypeMediaElementDisconnected] doNext:^(RACTuple *values) {
        @strongify(self);
        NSString *subscriptionId = [values first];
        RACSignal *eventSignal = [values second];
        [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeMediaElementDisconnected)];
        [[self subscriptionDisposables] addDisposable:
         [eventSignal subscribeNext:^(KMSEventDataElementConnection *elementConnectionEvent) {
            @strongify(self);
            KMSElementConnection *connectionToRemove = [elementConnectionEvent elementConnection];
            NSPredicate *connectionsFilter = [NSPredicate predicateWithFormat:@"self.source == %@ && self.mediaType == %d",[connectionToRemove source],[connectionToRemove mediaType]];
            NSArray *connectionsToRemove = [[self webRTCEndpointConnections] filteredArrayUsingPredicate:connectionsFilter];
            [[self mutableWebRTCEndpointConnections] removeObjectsInArray:connectionsToRemove];
            NSUInteger connectionCount = [[self webRTCEndpointConnections] count];
            if(connectionCount == 0){
                [[self hangupSignalFromInitiator:KMSWebRTCCallInitiatorCallee] subscribeCompleted:^{}];
            }
        }]];
    }];
    
    RACSignal *webRTCEndpointEventMediaStateChangedSignal =
    [[_webRTCEndpoint ss_subscribe:KMSEventTypeMediaStateChanged] doNext:^(RACTuple *values) {
        @strongify(self);
        NSString *subscriptionId = [values first];
        RACSignal *eventSignal = [values second];
        [[self mutableWebRTCEndpointSubscriptions] setObject:subscriptionId forKey:@(KMSEventTypeMediaStateChanged)];
        [[self subscriptionDisposables] addDisposable:
         [eventSignal subscribeNext:^(KMSEventDataMediaStateChanged *event) {
            @strongify(self);
            switch ([event state]) {
                case KMSMediaStateConnected:
                    NSLog(@"KMSMediaStateConnected");
                    break;
                case KMSMediaStateDisconnected:
                    NSLog(@"KMSMediaStateDisconnected");
                    break;
                    
                default:
                    break;
            }
        }]];

        
    }];
    
    return [RACSignal concat:@[webRTCEndpointEventOnIceCandidateSignal,
                               webRTCEndpointEventMediaElementConnectedSignal,
                               webRTCEndpointEventMediaElementDisconnectedSignal,
                               webRTCEndpointEventMediaStateChangedSignal]];
}


- (void)createPeerConnection
{
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

- (RACSignal *)unsubscribeWebRTCEventsSignal
{
    
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

- (RACSignal *)disposeWebRTCEndpointSignal
{
    @weakify(self);
    return [[[[self webRTCEndpoint] dispose] then:^RACSignal *{
                @strongify(self);
                return [[self kurentoSession] closeSignal];
           }] ignoreValues];
}

- (RACSignal *)closePeerConnectionSignal
{
    @weakify(self);
    return _peerConnection != nil ?
    [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        RACSignal *peerConnectionSignalingStateChanged =
        [[self peerConnectionSignalingStateChangeSubject] filter:^BOOL(NSNumber *state) {
            RTCSignalingState signalingState = (RTCSignalingState)[state integerValue];
            return signalingState == RTCSignalingStateClosed;
        }];
    
        RACDisposable *disposable =
        [peerConnectionSignalingStateChanged subscribeNext:^(RACTuple *args) {
            @strongify(self);
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
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged
{
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
        [[self peerConnectionSignalingStateChangeSubject] sendNext:@(stateChanged)];
    }];
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream
{
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
        [[self delegate] webRTCCall:self didAddRemoteMediaStream:stream];
    }];
}

/** Called when a remote peer closes a stream. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream
{
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{
    
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState
{
    
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState
{
    
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
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
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates
{

}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)dataChannel{
    
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
