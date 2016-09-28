// KMSAPIService.m
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

#import "KMSSession.h"
#import "RACSRWebSocket.h"
#import "KMSResponseMessage.h"
#import "KMSRequestMessage.h"

#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACTuple.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACSubject.h>
#import <ReactiveCocoa/RACCompoundDisposable.h>
#import <ReactiveCocoa/RACCommand.h>
#import "KMSLog.h"


@interface KMSSession () <RACSRWebSocketMessageTransformer>
@property(strong,nonatomic,readwrite) NSString *sessionId;
@property(assign,nonatomic,readwrite) KMSSessionState state;
@property(strong,nonatomic,readwrite) RACCompoundDisposable *subscriptionDisposables;
@end

@implementation KMSSession

+(instancetype)sessionWithWebSocketClient:(RACSRWebSocket *)wsClient{
    return [[self alloc] initWithWebSocketClient:wsClient];
}

-(instancetype)initWithWebSocketClient:(RACSRWebSocket *)wsClient{
    if((self = [super init]) != nil){
        _wsClient = wsClient;
        _state = KMSSessionStateConnecting;
        _subscriptionDisposables = [RACCompoundDisposable compoundDisposable];
        @weakify(self);
        [_subscriptionDisposables addDisposable:
        [[wsClient webSocketDidCloseSignal] subscribeNext:^(id x) {
            @strongify(self);
            [self setState:KMSSessionStateClosed];
        }]];
        
        [_subscriptionDisposables addDisposable:
        [[wsClient webSocketDidOpenSignal] subscribeNext:^(id x) {
            @strongify(self);
            [self setState:KMSSessionStateOpen];
        }]];
        
        _eventSignal =
        [[[wsClient webSocketDidReceiveMessageSignal] filter:^BOOL(RACTuple *args) {
            KMSMessage *message = [args second];
            return [message identifier] == nil;
        }] map:^id(RACTuple *args) {
            KMSRequestMessageEvent *message = [args second];
            return [[message params] value];
        }];
        
        [wsClient setMessageTransformer:self];
    }
    return self;
}

-(RACSignal *)sendMessage:(KMSRequestMessage *)requestMessage{
    @weakify(self);
    RACSignal *sendMessageSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        RACSignal *wsMessageSignal =
        [[[self wsClient] webSocketDidReceiveMessageSignal] filter:^BOOL(RACTuple *args) {
            KMSMessage *message = [args second];
            NSString *messageId = [message identifier];
            return (messageId != nil && [messageId isEqualToString:[requestMessage identifier]]);
        }];
        
        RACSignal *wsErrorSignal = [[self wsClient] webSocketDidFailSignal];
        
        RACDisposable *wsMessageSignalDisposable =
        [wsMessageSignal subscribeNext:^(RACTuple *args) {
            KMSResponseMessage *responseMessage = [args second];
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
        
        RACDisposable *wsErrorSignalDisposable =
        [wsErrorSignal subscribeNext:^(RACTuple *args) {
            [subscriber sendError:[args second]];
         }];
    
        [[[self wsClient] sendDataCommand] execute:requestMessage];
        
        return [RACCompoundDisposable compoundDisposableWithDisposables:@[wsMessageSignalDisposable,wsErrorSignalDisposable]];
    }];
    
    return sendMessageSignal;
    
}

-(RACSignal *)close{
    return [[self wsClient] closeConnectionSignal];
}

-(void)dealloc{
    [[self subscriptionDisposables] dispose];
}

#pragma mark RACSRWebSocketMessageTransformer

-(id)websocket:(RACSRWebSocket *)websocket transformRequestMessage:(KMSRequestMessage *)message{
    NSDictionary *jsonObject = [MTLJSONAdapter JSONDictionaryFromModel:message error:nil];
    KMSLog(KMSLogMessageLevelVerbose,@"Kurento API client will send message \n%@",jsonObject);
    return [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
}

-(id)websocket:(RACSRWebSocket *)websocket transformResponseMessage:(NSString *)message{
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    KMSLog(KMSLogMessageLevelVerbose,@"Kurento API client did receive message \n%@",jsonObject);
    return [MTLJSONAdapter modelOfClass:[KMSMessage class] fromJSONDictionary:jsonObject error:nil];
}



@end
