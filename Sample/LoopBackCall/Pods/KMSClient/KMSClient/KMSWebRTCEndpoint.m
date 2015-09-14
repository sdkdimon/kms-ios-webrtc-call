// KMSWebRTCEndpoint.m
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

#import "KMSWebRTCEndpoint.h"
#import "KMSAPIService.h"
#import "KMSResponseMessageResult.h"
#import "KMSEvent.h"
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACSignal.h>
#import "MTLJSONAdapterWithoutNil.h"
#import "KMSElementConnection.h"


@interface KMSWebRTCEndpoint ()

@property(strong,nonatomic,readwrite) KMSAPIService *apiService;

@property(strong,nonatomic,readwrite) NSString *identifier;
@property(strong,nonatomic,readwrite) NSString *mediaPipelineId;
@property(strong,nonatomic,readwrite) RACSignal *eventSignal;

@end

@implementation KMSWebRTCEndpoint

+(instancetype)endpointWithAPIService:(KMSAPIService *)apiService messageFactory:(KMSMessageFactoryWebRTCEndpoint *)messageFactory identifier:(NSString *)identifier{
    return [[self alloc] initWithAPIService:apiService messageFactory:messageFactory identifier:identifier];
}

+(instancetype)endpointWithAPIService:(KMSAPIService *)apiService messageFactory:(KMSMessageFactoryWebRTCEndpoint *)messageFactory{
    return [[self alloc] initWithAPIService:apiService messageFactory:messageFactory];
}

-(instancetype)initWithAPIService:(KMSAPIService *)apiService messageFactory:(KMSMessageFactoryWebRTCEndpoint *)messageFactory identifier:(NSString *)identifier{
     if((self = [super init]) != nil){
         _apiService = apiService;
         _messageFactory = messageFactory;
         _identifier = identifier;
         _mediaPipelineId = identifier == nil ? nil : [[identifier pathComponents] firstObject];
         @weakify(self);
         _eventSignal = [[apiService eventSignal] filter:^BOOL(KMSEvent *event) {
             @strongify(self);
             return [[event object] isEqualToString:[self identifier]];
         }];
     }
    return self;
}

-(instancetype)initWithAPIService:(KMSAPIService *)apiService messageFactory:(KMSMessageFactoryWebRTCEndpoint *)messageFactory{
    return [self initWithAPIService:apiService messageFactory:messageFactory identifier:nil];

}


-(RACSignal *)createWithMediaPipelineId:(NSString *)mediaPipelineId{
    @weakify(self);
    return _identifier == nil ? [[_apiService sendMessage:[_messageFactory createWithMediaPipeline:mediaPipelineId]] doNext:^(NSString *webRTCEndpointId) {
                                    @strongify(self);
                                    [self setIdentifier:webRTCEndpointId];
                                    [self setMediaPipelineId:mediaPipelineId];
                                }] : [RACSignal return:_identifier];
    }

-(RACSignal *)connect:(NSString *)endpointId{
    return [_apiService sendMessage:[_messageFactory connectSourceEndpoint:_identifier sinkEndpoint:endpointId]];
}

-(RACSignal *)disconnect:(NSString *)endpointId{
    return [_apiService sendMessage:[_messageFactory disconnectSourceEndpoint:_identifier sinkEndpoint:endpointId]];
}

-(RACSignal *)getSinkConnections{
   return [[_apiService sendMessage:[_messageFactory getSinkConnectionsForEndpoint:_identifier]] map:^id(NSArray *jsonArray) {
        return [MTLJSONAdapterWithoutNil modelsOfClass:[KMSElementConnection class] fromJSONArray:jsonArray error:nil];
    }];
}

-(RACSignal *)getSourceConnections{
    return [[_apiService sendMessage:[_messageFactory getSourceConnectionsForEndpoint:_identifier]] map:^id(NSArray *jsonArray) {
        return [MTLJSONAdapterWithoutNil modelsOfClass:[KMSElementConnection class] fromJSONArray:jsonArray error:nil];
    }];
}


-(RACSignal *)processOffer:(NSString *)offer{
    return [_apiService sendMessage:[_messageFactory processOffer:offer endpoint:_identifier]];
}

-(RACSignal *)gatherICECandidates{
    return [_apiService sendMessage:[_messageFactory gatherICECandidatesForEndpoint:_identifier]];
}

-(RACSignal *)addICECandidate:(KMSICECandidate *)candidate{
    return [_apiService sendMessage:[_messageFactory addICECandidate:candidate endpoint:_identifier]];
}

-(RACSignal *)subscribe:(KMSEventType)event{
    return [_apiService sendMessage:[_messageFactory subscribeEndpoint:_identifier event:event]];
}

-(RACSignal *)unsubscribeSubscriptionId:(NSString *)subscriptionId{
    return [_apiService sendMessage:[_messageFactory unsubscribeEndpoint:_identifier subscription:subscriptionId]];
}

-(RACSignal *)dispose{
    @weakify(self);
    RACSignal *disposeSignal = [[_apiService sendMessage:[_messageFactory disposeObject:_identifier]] doCompleted:^{
        @strongify(self);
        [self setIdentifier:nil];
        [self setMediaPipelineId:nil];
    }];
    
    return disposeSignal;
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
    return [_apiService sessionId];
}

@end

















