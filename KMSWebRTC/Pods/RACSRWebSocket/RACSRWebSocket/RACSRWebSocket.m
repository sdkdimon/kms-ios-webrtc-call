// RACSRWebSocket.m
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

#import "RACSRWebSocket.h"
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACCommand.h>
#import <ReactiveCocoa/RACSubject.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACCompoundDisposable.h>
#import <ReactiveCocoa/RACTuple.h>

@interface RACSRWebSocket() <SRWebSocketDelegate>

@property(strong,nonatomic,readwrite) RACSubject *webSocketDidOpenSubject;
@property(strong,nonatomic,readwrite) RACSubject *webSocketDidReceiveMessageSubject;
@property(strong,nonatomic,readwrite) RACSubject *webSocketDidFailSubject;
@property(strong,nonatomic,readwrite) RACSubject *webSocketDidCloseSubject;
@property(strong,nonatomic,readwrite) RACSubject *webSocketDidReceivePongSubject;

@end


@implementation RACSRWebSocket

- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols{
    self = [super initWithURLRequest:request protocols:protocols];
    if(self != nil){
        [self initialize];
    }
    return self;
}
- (id)initWithURLRequest:(NSURLRequest *)request{
    self = [super initWithURLRequest:request];
    if(self != nil){
        [self initialize];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols{
    self = [super initWithURL:url protocols:protocols];
    if(self != nil){
        [self initialize];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url{
    self = [super initWithURL:url];
    if(self != nil){
        [self initialize];
    }
    return self;
}




- (void)initialize{
     [self setDelegate:self];
    _webSocketDidOpenSignal = _webSocketDidOpenSubject = [RACSubject subject];
    _webSocketDidReceiveMessageSignal = _webSocketDidReceiveMessageSubject = [RACSubject subject];
    _webSocketDidFailSignal = _webSocketDidFailSubject = [RACSubject subject];
    _webSocketDidCloseSignal = _webSocketDidCloseSubject = [RACSubject subject];
    _webSocketDidReceivePongSignal = _webSocketDidReceivePongSubject = [RACSubject subject];
    
    @weakify(self);
    _sendDataCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id data) {
       @strongify(self);
        RACSignal *sendDataSignal = [[self openConnectionSignal] flattenMap:^RACStream *(id value) {
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                [self send:data];
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
                return nil;
            }];
        }];
        return sendDataSignal;
    }];
    [_sendDataCommand setAllowsConcurrentExecution:YES];
}

- (RACSignal *)openConnectionSignal{
    
    switch ([self readyState]) {
        case SR_OPEN:
            return [RACSignal return:nil];
        case SR_CONNECTING:{
            @weakify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                        @strongify(self);
                        RACDisposable *openSignalDisposable = [[self webSocketDidOpenSignal] subscribeNext:^(id x) {
                            [subscriber sendNext:nil];
                            [subscriber sendCompleted];
                        }];
                        RACDisposable *failSignalDisposable = [[self webSocketDidFailSignal] subscribeNext:^(RACTuple *args) {
                            [subscriber sendError:[args second]];
                        }];
                        [self open];
                        return [RACCompoundDisposable compoundDisposableWithDisposables:@[openSignalDisposable,failSignalDisposable]];
                    }];
            
        }
        case SR_CLOSED:
        case SR_CLOSING:
            return [RACSignal error:nil];
    }
}

- (RACSignal *)closeConnectionSignal{
    switch ([self readyState]) {
        case SR_OPEN:{
            @weakify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                @strongify(self);
                RACDisposable *closeSignalDisposable = [[self webSocketDidCloseSignal] subscribeNext:^(id x) {
                    [subscriber sendNext:nil];
                    [subscriber sendCompleted];
                }];
                RACDisposable *failSignalDisposable = [[self webSocketDidFailSignal] subscribeNext:^(RACTuple *args) {
                    [subscriber sendError:[args second]];
                }];
                [self close];
                return [RACCompoundDisposable compoundDisposableWithDisposables:@[closeSignalDisposable,failSignalDisposable]];
            }];
            
        }
        case SR_CLOSED:
            return [RACSignal return:nil];
        case SR_CONNECTING:
        case SR_CLOSING:
            return [RACSignal error:nil];
    }
}


- (void)send:(id)data{
    if(_messageTransformer && [_messageTransformer respondsToSelector:@selector(websocket:transformRequestMessage:)]){
        data = [_messageTransformer websocket:self transformRequestMessage:data];
    }
    [super send:data];
}


#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    if(_messageTransformer && [_messageTransformer respondsToSelector:@selector(websocket:transformResponseMessage:)]){
        message = [_messageTransformer websocket:self transformResponseMessage:message];
    }
    RACTuple *args = [RACTuple tupleWithObjects:webSocket,message,nil];
    [_webSocketDidReceiveMessageSubject sendNext:args];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    RACTuple *args = [RACTuple tupleWithObjects:webSocket,nil];
    [_webSocketDidOpenSubject sendNext:args];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    RACTuple *args = [RACTuple tupleWithObjects:webSocket,@(code),reason,@(wasClean),nil];
    [_webSocketDidCloseSubject sendNext:args];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    RACTuple *args = [RACTuple tupleWithObjects:webSocket,error,nil];
    [_webSocketDidFailSubject sendNext:args];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload{
    RACTuple *args = [RACTuple tupleWithObjects:webSocket,pongPayload,nil];
    [_webSocketDidReceivePongSubject sendNext:args];
}





@end
