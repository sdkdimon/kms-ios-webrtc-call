//
//  RTCPeerConnection+RAC.m
//  KMSWebRTC
//
//  Created by dimon on 27/02/2017.
//  Copyright © 2017 dimon. All rights reserved.
//

#import "RTCPeerConnection+RAC.h"
#import <ReactiveObjC/RACEXTScope.h>
#import <ReactiveObjC/RACSubscriber.h>

@implementation RTCPeerConnection (RAC)

- (RACSignal *)offerSignalForConstraints:(RTCMediaConstraints *)constraints
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        [self offerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
                if (error == nil)
                {
                    [subscriber sendNext:sdp];
                    [subscriber sendCompleted];
                }
                else
                {
                    [subscriber sendError:error];
                }
            }];
            
        }];
        
        return nil;
    }];
}
- (RACSignal *)answerSignalForConstraints:(RTCMediaConstraints *)constraints
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        [self answerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
                if (error == nil)
                {
                    [subscriber sendNext:sdp];
                    [subscriber sendCompleted];
                }
                else
                {
                    [subscriber sendError:error];
                }
            }];
        }];
        return nil;
    }];
}


- (RACSignal *)setLocalDescriptionSignal:(RTCSessionDescription *)sdp
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        [self setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
                if (error == nil)
                {
                    [subscriber sendNext:nil];
                    [subscriber sendCompleted];
                }
                else
                {
                    [subscriber sendError:error];
                }
            }];
        }];
        
        return nil;
    }];
}
- (RACSignal *)setRemoteDescriptionSignal:(RTCSessionDescription *)sdp
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        [self setRemoteDescription:sdp completionHandler:^(NSError * _Nullable error) {
            [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
                if (error == nil)
                {
                    [subscriber sendNext:nil];
                    [subscriber sendCompleted];
                }
                else
                {
                    [subscriber sendError:error];
                }
            }];
        }];
        
        return nil;
    }];
}

@end
