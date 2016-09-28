// KMSWebRTCEndpoint.m
// Copyright (c) 2016 Dmitry Lizin (sdkdimon@gmail.com)
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

#import "KMSWebRTCEndpoint.h"
#import "KMSSession.h"
#import "KMSResponseMessageResult.h"
#import "KMSEvent.h"
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACSignal.h>

#import "KMSElementConnection.h"


@interface KMSWebRTCEndpoint ()

@property(strong,nonatomic,readwrite) KMSSession *kurentoSession;

@property(strong,nonatomic,readwrite) NSString *identifier;
@property(strong,nonatomic,readwrite) NSString *mediaPipelineId;
@property(strong,nonatomic,readwrite) RACSignal *eventSignal;

@end

@implementation KMSWebRTCEndpoint

+(instancetype)endpointWithKurentoSession:(KMSSession *)kurentoSession messageFactory:(KMSMessageFactoryWebRTCEndpoint *)messageFactory identifier:(NSString *)identifier{
    return [[self alloc] initWithKurentoSession:kurentoSession messageFactory:messageFactory identifier:identifier];
}

+(instancetype)endpointWithKurentoSession:(KMSSession *)kurentoSession messageFactory:(KMSMessageFactoryWebRTCEndpoint *)messageFactory mediaPipelineId:(NSString *)mediaPipelineId;{
    return [[self alloc] initWithKurentoSession:kurentoSession messageFactory:messageFactory mediaPipelineId:mediaPipelineId];
}

-(instancetype)initWithKurentoSession:(KMSSession *)kurentoSession messageFactory:(KMSMessageFactoryWebRTCEndpoint *)messageFactory identifier:(NSString *)identifier{
     if((self = [super init]) != nil){
         _kurentoSession = kurentoSession;
         _messageFactory = messageFactory;
         _identifier = identifier;
         _mediaPipelineId = [[identifier pathComponents] firstObject];
         [self initialize];
     }
    return self;
}

-(instancetype)initWithKurentoSession:(KMSSession *)kurentoSession messageFactory:(KMSMessageFactoryWebRTCEndpoint *)messageFactory mediaPipelineId:(NSString *)mediaPipelineId;{
    if((self = [super init]) != nil){
        _kurentoSession = kurentoSession;
        _messageFactory = messageFactory;
        _identifier = nil;
        _mediaPipelineId = mediaPipelineId;
        [self initialize];
    }
    return self;

}


-(void)initialize{
    @weakify(self);
    _eventSignal = [[_kurentoSession eventSignal] filter:^BOOL(KMSEvent *event) {
        @strongify(self);
        return [[event object] isEqualToString:[self identifier]];
    }];
}


-(RACSignal *)create{
    @weakify(self);
    return _identifier == nil ? [[_kurentoSession sendMessage:[_messageFactory createWithMediaPipeline:_mediaPipelineId]] doNext:^(NSString *webRTCEndpointId) {
                                    @strongify(self);
                                    [self setIdentifier:webRTCEndpointId];
                                }] : [RACSignal return:_identifier];
}

-(RACSignal *)dispose{
    @weakify(self);
    return _identifier != nil ? [[_kurentoSession sendMessage:[_messageFactory disposeObject:_identifier]] doCompleted:^{
        @strongify(self);
        [self setIdentifier:nil];
    }] : [RACSignal return:nil];
}

-(RACSignal *)connect:(NSString *)endpointId{
    return [_kurentoSession sendMessage:[_messageFactory connectSourceEndpoint:_identifier sinkEndpoint:endpointId]];
}

-(RACSignal *)disconnect:(NSString *)endpointId{
    return [_kurentoSession sendMessage:[_messageFactory disconnectSourceEndpoint:_identifier sinkEndpoint:endpointId]];
}

-(RACSignal *)getSinkConnections{
   return [[_kurentoSession sendMessage:[_messageFactory getSinkConnectionsForEndpoint:_identifier]] map:^id(NSArray *jsonArray) {
        return [MTLJSONAdapter modelsOfClass:[KMSElementConnection class] fromJSONArray:jsonArray error:nil];
    }];
}

-(RACSignal *)getSourceConnections{
    return [[_kurentoSession sendMessage:[_messageFactory getSourceConnectionsForEndpoint:_identifier]] map:^id(NSArray *jsonArray) {
        return [MTLJSONAdapter modelsOfClass:[KMSElementConnection class] fromJSONArray:jsonArray error:nil];
    }];
}

-(RACSignal *)processOffer:(NSString *)offer{
    return [_kurentoSession sendMessage:[_messageFactory processOffer:offer endpoint:_identifier]];
}

-(RACSignal *)gatherICECandidates{
    return [_kurentoSession sendMessage:[_messageFactory gatherICECandidatesForEndpoint:_identifier]];
}

-(RACSignal *)addICECandidate:(KMSICECandidate *)candidate{
    return [_kurentoSession sendMessage:[_messageFactory addICECandidate:candidate endpoint:_identifier]];
}

-(RACSignal *)subscribe:(KMSEventType)event{
    return [_kurentoSession sendMessage:[_messageFactory subscribeEndpoint:_identifier event:event]];
}

-(RACSignal *)unsubscribeSubscriptionId:(NSString *)subscriptionId{
    return [_kurentoSession sendMessage:[_messageFactory unsubscribeEndpoint:_identifier subscription:subscriptionId]];
}

-(RACSignal *)eventSignalForEvent:(KMSEventType)event{
    return [[_eventSignal filter:^BOOL(KMSEvent *value) {
        return [value type] == event;
    }] map:^id(KMSEvent *value) {
        return [value data];
    }];
}

#pragma mark KMSRequestMessageFactoryDataSource

-(NSString *)messageFactory:(KMSRequestMessageFactory *)messageFactory sessionIdForMessage:(KMSRequestMessage *)message{
    return [_kurentoSession sessionId];
}

@end

















