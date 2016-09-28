// KMSMediaPipeline.m
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

#import "KMSMediaPipeline.h"
#import "KMSSession.h"
#import "KMSMessageFactoryMediaPipeline.h"
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACSignal.h>

@interface KMSMediaPipeline () 
@property(strong,nonatomic,readwrite) NSString *identifier;
@end


@implementation KMSMediaPipeline

+(instancetype)pipelineWithKurentoSession:(KMSSession *)kurentoSession messageFactory:(KMSMessageFactoryMediaPipeline *)messageFactory identifier:(NSString *)identifier{
    return [[self alloc] initWithKurentoSession:kurentoSession messageFactory:messageFactory identifier:identifier];
}

+(instancetype)pipelineWithKurentoSession:(KMSSession *)kurentoSession messageFactory:(KMSMessageFactoryMediaPipeline *)messageFactory{
    return [[self alloc] initWithKurentoSession:kurentoSession messageFactory:messageFactory];
}

-(instancetype)initWithKurentoSession:(KMSSession *)kurentoSession messageFactory:(KMSMessageFactoryMediaPipeline *)messageFactory identifier:(NSString *)identifier{
    if((self = [super init]) != nil){
        _kurentoSession = kurentoSession;
        _messageFactory = messageFactory;
        _identifier = identifier;
    }
    return self;
}

-(instancetype)initWithKurentoSession:(KMSSession *)kurentoSession messageFactory:(KMSMessageFactoryMediaPipeline *)messageFactory{
    return [self initWithKurentoSession:kurentoSession messageFactory:messageFactory identifier:nil];
}

-(RACSignal *)create{
    @weakify(self);
    return _identifier == nil ? [[_kurentoSession sendMessage:[_messageFactory create]] doNext:^void(NSString *identifier) {
                                    @strongify(self);
                                    [self setIdentifier:identifier];
                                }] : [RACSignal return:_identifier];
}

-(RACSignal *)dispose{
    @weakify(self);
    return _identifier != nil ? [[_kurentoSession sendMessage:[_messageFactory disposeObject:_identifier]] doCompleted:^{
                                    @strongify(self);
                                    [self setIdentifier:nil];
                                }] : [RACSignal return:nil];
}

#pragma mark KMSRequestMessageFactoryDataSource

-(NSString *)messageFactory:(KMSRequestMessageFactory *)messageFactory sessionIdForMessage:(KMSRequestMessage *)message{
    return [_kurentoSession sessionId];
}




@end
