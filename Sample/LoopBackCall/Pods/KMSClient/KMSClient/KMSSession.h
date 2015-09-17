// KMSAPIService.h
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

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/RACSignal.h>
#import "KMSEventType.h"

@class RACSRWebSocket;
@class KMSRequestMessageFactory;
@class KMSRequestMessage;
@class KMSICECandidate;

typedef enum {
    KMSSessionStateConnecting = 0,
    KMSSessionStateOpen,
    KMSSessionStateClosed
}KMSSessionState;

@interface KMSSession : NSObject

+(instancetype)sessionWithWebSocketClient:(RACSRWebSocket *)wsClient;
-(instancetype)initWithWebSocketClient:(RACSRWebSocket *)wsClient;


@property(strong,nonatomic,readonly) RACSRWebSocket *wsClient;
@property(strong,nonatomic,readonly) RACSignal *eventSignal;

@property(assign,nonatomic,readonly) KMSSessionState state;

@property(strong,nonatomic,readonly) NSString *sessionId;

-(RACSignal *)sendMessage:(KMSRequestMessage *)requestMessage;
-(RACSignal *)close;

@end
