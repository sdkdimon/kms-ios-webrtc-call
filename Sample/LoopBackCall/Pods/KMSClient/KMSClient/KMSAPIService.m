// KMSAPIService.m
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

#import "KMSAPIService.h"
#import "RACSRWebSocket.h"
#import "KMSResponseMessage.h"
#import "KMSRequestMessage.h"
#import "MTLJSONAdapterWithoutNil.h"
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACTuple.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACSubject.h>
#import <ReactiveCocoa/RACCompoundDisposable.h>
#import "KMSLog.h"





@interface WebSocketResponseJSONTransformer : NSValueTransformer

@end

@implementation WebSocketResponseJSONTransformer

+ (Class)transformedValueClass { return [KMSMessage class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    KMSLog(KMSLogMessageLevelVerbose,@"Kurento API client did receive message \n%@",jsonObject);
    return [MTLJSONAdapterWithoutNil modelOfClass:[KMSMessage class] fromJSONDictionary:jsonObject error:nil];
}

@end

@interface WebSocketRequestJSONTransformer : NSValueTransformer

@end

@implementation WebSocketRequestJSONTransformer

+ (Class)transformedValueClass { return [NSData class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
    NSDictionary *jsonObject = [MTLJSONAdapterWithoutNil JSONDictionaryFromModel:value error:nil];
    KMSLog(KMSLogMessageLevelVerbose,@"Kurento API client will send message \n%@",jsonObject);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
    return jsonData;
}


@end

@interface KMSAPIService ()
@property(strong,nonatomic,readwrite) NSString *sessionId;
@end

@implementation KMSAPIService

+(instancetype)serviceWithWebSocketClient:(RACSRWebSocket *)wsClient{
    return [[self alloc] initWithWebSocketClient:wsClient];
}

-(instancetype)initWithWebSocketClient:(RACSRWebSocket *)wsClient{
    if((self = [super init]) != nil){
        _wsClient = wsClient;
        
        [_wsClient setRequestMessageTransformer:[[WebSocketRequestJSONTransformer alloc] init]];
        [_wsClient setResponseMessageTransformer:[[WebSocketResponseJSONTransformer alloc] init]];
        
        _eventSignal =
        [[[_wsClient webSocketDidReceiveMessageSignal] filter:^BOOL(RACTuple *args) {
            KMSMessage *value = [args second];
            return [value identifier] == nil;
        }] map:^id(RACTuple *args) {
            KMSRequestMessageEvent *value = [args second];
            return [[value params] value];
        }];
    }
    return self;
}

-(RACSignal *)sendMessage:(KMSRequestMessage *)requestMessage{
    @weakify(self);
    RACSignal *sendMessageSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        RACSignal *wsMessageSignal = [[[[self wsClient] webSocketDidReceiveMessageSignal] map:^id(RACTuple *args) {
            return [args second];
        }] filter:^BOOL(KMSMessage *message) {
            NSString *messageId = [message identifier];
            return (messageId != nil && [messageId isEqualToString:[requestMessage identifier]]);
        }];
        RACSignal *wsErrorSignal = [[self wsClient] webSocketDidFailSignal];
        
        RACDisposable *wsMessageSignalDisposable = [wsMessageSignal subscribeNext:^(KMSResponseMessage *responseMessage) {
            NSError *responseError = [responseMessage error];
            if(responseError == nil){
                KMSResponseMessageResult *responseMessageResult = [responseMessage result];
                [self setSessionId:[responseMessageResult sessionId]];
                [subscriber sendNext:[responseMessageResult value]];
                [subscriber sendCompleted];
            } else{
                [subscriber sendError:responseError];
            }
        }];
        
        RACDisposable *wsErrorSignalDisposable = [wsErrorSignal subscribeNext:^(id x) {
            [subscriber sendError:nil];
         
        }];
        [[[self wsClient] sendDataCommand] execute:requestMessage];
        return [RACCompoundDisposable compoundDisposableWithDisposables:@[wsMessageSignalDisposable,wsErrorSignalDisposable]];
    }];
    
    return sendMessageSignal;
    
}

@end
