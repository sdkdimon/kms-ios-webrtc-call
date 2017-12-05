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

#import <SocketRocket/SRWebSocket.h>
#import "KMSResponseMessage.h"
#import "KMSRequestMessage.h"
#import "KMSLog.h"
#import "KMSRACSubject.h"
#import "KMSSessionConnectionMonitor.h"

@interface KMSSession () <SRWebSocketDelegate, KMSSessionPing>

@property (strong, nonatomic, readwrite) NSString *sessionId;
@property (strong, nonatomic, readwrite) RACCompoundDisposable *subscriptionDisposables;
@property (strong, nonatomic, readwrite) SRWebSocket *webSocket;
@property (assign, nonatomic, readwrite) KMSSessionState state;
@property (strong, nonatomic, readwrite) RACSubject *websocketDidReceiveMessageSubject;
@property (strong, nonatomic, readwrite) RACSubject *websocketDidOpenSubject;
@property (strong, nonatomic, readwrite) RACSubject *websocketDidCloseSubject;
@property (strong, nonatomic, readwrite) KMSRACSubject *websocketDidFailWithErrorSubject;
@property (strong, nonatomic, readwrite) RACSubject *websocketDidFailWithErrorExternalSubject;

@end

@implementation KMSSession

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self != nil)
    {
        _url = url;
        _websocketDidReceiveMessageSubject = [RACSubject subject];
        _websocketDidOpenSubject = [RACSubject subject];
        _websocketDidCloseSubject = [RACSubject subject];
        _websocketDidFailWithErrorSubject = [KMSRACSubject subject];
        _errorSignal = _websocketDidFailWithErrorExternalSubject = [RACSubject subject];
        _connectionMonitor = [[KMSSessionConnectionMonitor alloc] initWithPingTimeInterval:3.0f pingFailCount:3];
        _connectionMonitor.ping = self;
        _eventSignal =
        [[_websocketDidReceiveMessageSubject filter:^BOOL(RACTuple *args) {
            KMSMessage *message = [args second];
            return [message identifier] == nil;
        }] map:^id(RACTuple *args) {
            KMSRequestMessageEvent *message = [args second];
            return [[message params] value];
        }];
    }
    return self;
}

- (SRWebSocket *)createWebSocket
{
    SRWebSocket *webSocket = [[SRWebSocket alloc] initWithURL:_url];
    [webSocket setDelegate:self];
    [self setWebSocket:webSocket];
    return webSocket;
}

- (void)disposeWebsocket
{
    _webSocket = nil;
}

- (RACSignal *)openIfNeededSignal
{
    @weakify(self);
    return [RACSignal defer:^RACSignal * _Nonnull{
        @strongify(self);
        switch ([self state]) {
                
            case KMSSessioStateClosed:
            {
                return [self openSignal];
            }
                
            case KMSSessioStateClosing:
            {
                return [RACSignal error:nil];
            }
                
            case KMSSessioStateOpen:
            {
                return [RACSignal return:nil];
            }
                
            case KMSSessioStateOpening:
            {
                return [RACSignal error:nil];
            }
                
            default:
            {
                return [RACSignal error:nil];
            }
        }
    }];
}


- (RACSignal *)sendMessageSignal:(KMSRequestMessage *)message
{
    @weakify(self);
    RACSignal *sendMesageSignal =
    [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        if ([self state] == KMSSessioStateOpen)
        {
            RACSignal *webSocketDidReceiveMessageSignal = [self websocketDidReceiveMessageSubject];
            RACSignal *webSocketDidFailWithErrorSignal = [self websocketDidFailWithErrorSubject];
            
            RACCompoundDisposable *signalDisposable = [RACCompoundDisposable compoundDisposable];
            
            RACDisposable *webSocketDidReceiveMessageSignalDisposable =
            [webSocketDidReceiveMessageSignal subscribeNext:^(RACTuple *args) {
                KMSResponseMessage *responseMessage = [args second];
                NSString *responseMessageId = [responseMessage identifier];
                if (responseMessageId != nil  && [responseMessageId isEqualToString:[message identifier]])
                {
                    NSError *responseMessageError = [responseMessage error];
                    if (responseMessageError == nil)
                    {
                        KMSResponseMessageResult *responseMessageResult = [responseMessage result];
                        [self setSessionId:[responseMessageResult sessionId]];
                        [subscriber sendNext:[responseMessageResult value]];
                        [subscriber sendCompleted];
                    }
                    else
                    {
                        [subscriber sendError:responseMessageError];
                    }
                }
            }];
            RACDisposable *webSocketDidFailWithErrorSignalDisposable =
            [webSocketDidFailWithErrorSignal subscribeNext:^(RACTuple *args) {
                NSError *error = [args second];
                [subscriber sendError:error];
            }];
            
            [signalDisposable addDisposable:webSocketDidReceiveMessageSignalDisposable];
            [signalDisposable addDisposable:webSocketDidFailWithErrorSignalDisposable];
            
            NSData *messageData = [self transformRequestMessage:message];
            [[self webSocket] send:messageData];
            
            return signalDisposable;
        }
        else
        {
            [subscriber sendError:nil];
            return nil;
        }
    }];
    
    return [[[self openIfNeededSignal] ignoreValues] concat:sendMesageSignal];
}


- (RACSignal *)closeSignal
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        if ([self state] == KMSSessioStateOpen)
        {
            [self setState:KMSSessioStateClosing];
            RACSignal *webSocketDidCloseSignal = [self websocketDidCloseSubject];
            RACSignal *webSocketDidFailWithErrorSignal = [self websocketDidFailWithErrorSubject];
            
            RACCompoundDisposable *signalDisposable = [RACCompoundDisposable compoundDisposable];
            RACDisposable *webSocketDidCloseSignalDisposable =
            [webSocketDidCloseSignal subscribeNext:^(RACTuple *args) {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }];
            
            RACDisposable *webSocketDidFailWithErrorSignalDisposable =
            [webSocketDidFailWithErrorSignal subscribeNext:^(RACTuple *args) {
                [subscriber sendError:[args second]];
            }];
            
            [signalDisposable addDisposable:webSocketDidCloseSignalDisposable];
            [signalDisposable addDisposable:webSocketDidFailWithErrorSignalDisposable];
            [[self webSocket] close];
            
            return signalDisposable;
        }
        else
        {
            [subscriber sendError:nil];
            return nil;
        }
    }];
}

- (RACSignal *)openSignal
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        if ([self state] == KMSSessioStateClosed)
        {
            [self setState:KMSSessioStateOpening];
            RACSignal *webSocketDidOpenSignal = [self websocketDidOpenSubject];
            RACSignal *webSocketDidFailWithErrorSignal = [self websocketDidFailWithErrorSubject];
            
            RACCompoundDisposable *signalDisposable = [RACCompoundDisposable compoundDisposable];
            
            RACDisposable *webSocketDidOpenSignalDisposable =
            [webSocketDidOpenSignal subscribeNext:^(RACTuple *args) {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }];
            
            RACDisposable *webSocketDidFailWithErrorSignalDisposable =
            [webSocketDidFailWithErrorSignal subscribeNext:^(RACTuple *args) {
                [subscriber sendError:[args second]];
            }];
            
            [signalDisposable addDisposable:webSocketDidOpenSignalDisposable];
            [signalDisposable addDisposable:webSocketDidFailWithErrorSignalDisposable];
            [[self createWebSocket] open];
            
            return signalDisposable;
        }
        else
        {
            [subscriber sendError:nil];
            return nil;
        }
    }];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSData *)message
{
    KMSMessage *messageModel = [self transformResponseMessage:message];
    [_websocketDidReceiveMessageSubject sendNext:RACTuplePack(webSocket, messageModel)];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    [self setState:KMSSessioStateOpen];
    [_websocketDidOpenSubject sendNext:RACTuplePack(webSocket)];
    [_connectionMonitor start];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    [self sessionDidFailWithError:error];
}

- (void)sessionDidFailWithError:(NSError *)error
{
    [_connectionMonitor stop];
    [self setState:KMSSessioStateClosed];
    
    if ([_websocketDidFailWithErrorSubject subscribersCount] > 0)
    {
        [_websocketDidFailWithErrorSubject sendNext:RACTuplePack(_webSocket, error)];
    }
    else
    {
        [_websocketDidFailWithErrorExternalSubject sendNext:error];
    }
    [self disposeWebsocket];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    [_connectionMonitor stop];
    [self disposeWebsocket];
    [self setState:KMSSessioStateClosed];
    [_websocketDidCloseSubject sendNext:RACTuplePack(webSocket, @(code), reason, @(wasClean))];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    [_connectionMonitor didReceivePong:pongPayload];
}

- (void)sendPing:(NSData *)data
{
    [_webSocket sendPing:data];
}

- (void)didFailReceivePong
{
    NSError *connectionError = [NSError errorWithDomain:@"org.sdkdimon.KMSClient" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Connection lost."}];
    [self sessionDidFailWithError:connectionError];
}

// Return YES to convert messages sent as Text to an NSString. Return NO to skip NSData -> NSString conversion for Text messages. Defaults to YES.
- (BOOL)webSocketShouldConvertTextFrameToString:(SRWebSocket *)webSocket
{
    return NO;
}

#pragma mark MessageTransformer

- (NSData *)transformRequestMessage:(KMSRequestMessage *)message
{
    NSDictionary *jsonObject = [MTLJSONAdapter JSONDictionaryFromModel:message error:nil];
    KMSLog(KMSLogMessageLevelVerbose,@"Kurento API client will send message \n%@",jsonObject);
    return [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil];
}

- (KMSMessage *)transformResponseMessage:(NSData *)message
{
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:message options:0 error:nil];
    KMSLog(KMSLogMessageLevelVerbose,@"Kurento API client did receive message \n%@",jsonObject);
    return [MTLJSONAdapter modelOfClass:[KMSMessage class] fromJSONDictionary:jsonObject error:nil];
}

@end
