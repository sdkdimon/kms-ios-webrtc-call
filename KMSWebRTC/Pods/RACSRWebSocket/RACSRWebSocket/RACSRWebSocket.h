// RACSRWebSocket.h
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


#import <SocketRocket/SRWebSocket.h>
@class RACSignal;
@class RACCommand;
@class RACSRWebSocket;


@protocol RACSRWebSocketMessageTransformer <NSObject>

- (id)websocket:(RACSRWebSocket *)websocket transformResponseMessage:(id)message;
- (id)websocket:(RACSRWebSocket *)websocket transformRequestMessage:(id)message;

@end


@interface RACSRWebSocket : SRWebSocket

@property(weak,nonatomic,readonly) RACSignal *webSocketDidOpenSignal;
@property(weak,nonatomic,readonly) RACSignal *webSocketDidReceiveMessageSignal;
@property(weak,nonatomic,readonly) RACSignal *webSocketDidFailSignal;
@property(weak,nonatomic,readonly) RACSignal *webSocketDidCloseSignal;
@property(weak,nonatomic,readonly) RACSignal *webSocketDidReceivePongSignal;

@property(weak,nonatomic,readwrite) id <RACSRWebSocketMessageTransformer> messageTransformer;

@property(strong,nonatomic,readonly) RACCommand *sendDataCommand;

- (RACSignal *)openConnectionSignal;
- (RACSignal *)closeConnectionSignal;

@end
