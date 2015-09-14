//
// CallView.m
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

#import "CallView.h"
#import <libjingle_peerconnection/RTCEAGLVideoView.h>


@implementation CallView

-(instancetype)init{
    if((self = [super init]) != nil){
        _localVideoView = [[RTCEAGLVideoView alloc] init];
        _remoteVideoView = [[RTCEAGLVideoView alloc] init];
        _hangUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _camSwitchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _micSwitchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [_localVideoView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_remoteVideoView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_hangUpButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_camSwitchButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_micSwitchButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        
        [self addSubview:_remoteVideoView];
        [self addSubview:_localVideoView];
        [self addSubview:_hangUpButton];
        [self addSubview:_camSwitchButton];
        [self addSubview:_micSwitchButton];
        
    }
    return self;
}

-(void)updateConstraints{
    
    NSLayoutConstraint *topRemoteVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_remoteVideoView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:0];
    NSLayoutConstraint *bottomRemoteVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_remoteVideoView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0];
    NSLayoutConstraint *leadingRemoteVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_remoteVideoView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0];
    NSLayoutConstraint *trailingRemoteVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_remoteVideoView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0];
    
    
    NSLayoutConstraint *topLocalVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_localVideoView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:0];
    NSLayoutConstraint *bottomLocalVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_localVideoView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0];
    NSLayoutConstraint *leadingLocalVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_localVideoView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0];
    NSLayoutConstraint *trailingLocalVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_localVideoView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0];
    
    NSLayoutConstraint *heightLocalVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_localVideoView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:200];
    NSLayoutConstraint *widthLocalVideoViewConstraint = [NSLayoutConstraint constraintWithItem:_localVideoView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:200];
    
    NSLayoutConstraint *topHangUpButtonConstraint = [NSLayoutConstraint constraintWithItem:_hangUpButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:0];
    NSLayoutConstraint *bottomHangUpButtonConstraint = [NSLayoutConstraint constraintWithItem:_hangUpButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0];
    NSLayoutConstraint *leadingHangUpButtonConstraint = [NSLayoutConstraint constraintWithItem:_hangUpButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0];
    NSLayoutConstraint *trailingHangUpButtonConstraint = [NSLayoutConstraint constraintWithItem:_hangUpButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0];
    
    
    NSLayoutConstraint *centerYCamSwitchButtonConstraint = [NSLayoutConstraint constraintWithItem:_camSwitchButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_hangUpButton attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0];
    NSLayoutConstraint *leadingCamSwitchButtonConstraint = [NSLayoutConstraint constraintWithItem:_camSwitchButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_hangUpButton attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:20];
    
    NSLayoutConstraint *centerYMicSwitchButtonConstraint = [NSLayoutConstraint constraintWithItem:_micSwitchButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_hangUpButton attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0];
    NSLayoutConstraint *leadingMicSwitchButtonConstraint = [NSLayoutConstraint constraintWithItem:_micSwitchButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_camSwitchButton attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:20];
    
    
    
    //    NSLayoutConstraint *heightHangUpButtonConstraint = [NSLayoutConstraint constraintWithItem:_hangUpButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:200];
    //    NSLayoutConstraint *widthHangUpButtonConstraint = [NSLayoutConstraint constraintWithItem:_hangUpButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:200];
    //    [_hangUpButton addConstraints:@[heightHangUpButtonConstraint,widthHangUpButtonConstraint]];
    
    [_localVideoView addConstraints:@[heightLocalVideoViewConstraint,widthLocalVideoViewConstraint]];
    
    
    
    [self addConstraints:@[topLocalVideoViewConstraint,
                           bottomLocalVideoViewConstraint,
                           leadingLocalVideoViewConstraint,
                           trailingLocalVideoViewConstraint,
                           topRemoteVideoViewConstraint,
                           bottomRemoteVideoViewConstraint,
                           leadingRemoteVideoViewConstraint,
                           trailingRemoteVideoViewConstraint,
                           topHangUpButtonConstraint,
                           bottomHangUpButtonConstraint,
                           leadingHangUpButtonConstraint,
                           trailingHangUpButtonConstraint,
                           centerYCamSwitchButtonConstraint,
                           leadingCamSwitchButtonConstraint,
                           centerYMicSwitchButtonConstraint,
                           leadingMicSwitchButtonConstraint]];
    
    [super updateConstraints];
    
    
}

@end
