//
//  RTCPeerConnection+RAC.h
//  KMSWebRTC
//
//  Created by dimon on 27/02/2017.
//  Copyright © 2017 dimon. All rights reserved.
//

#import <WebRTC/WebRTC.h>
#import <ReactiveObjC/RACSignal.h>

@interface RTCPeerConnection (RAC)

- (RACSignal *)offerSignalForConstraints:(RTCMediaConstraints *)constraints;
- (RACSignal *)answerSignalForConstraints:(RTCMediaConstraints *)constraints;

- (RACSignal *)setLocalDescriptionSignal:(RTCSessionDescription *)sdp;
- (RACSignal *)setRemoteDescriptionSignal:(RTCSessionDescription *)sdp;

@end
