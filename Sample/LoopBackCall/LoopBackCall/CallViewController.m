//
// CallViewController.m
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

#import "CallViewController.h"
#import "CallView.h"
#import <libjingle_peerconnection/RTCEAGLVideoView.h>
#import <libjingle_peerconnection/RTCVideoTrack.h>
#import <libjingle_peerconnection/RTCAudioTrack.h>
#import <libjingle_peerconnection/RTCMediaStream.h>


#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/NSObject+RACPropertySubscribing.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACTuple.h>
#import <ReactiveCocoa/UIControl+RACSignalSupport.h>


@interface CallViewController () <RTCEAGLVideoViewDelegate>

@property (weak, nonatomic) RTCEAGLVideoView *remoteVideoView;
@property (weak, nonatomic) RTCEAGLVideoView *localVideoView;
@property (weak, nonatomic) UIButton *hangupButton;
@property (weak,nonatomic,readwrite) UIButton *camSwitchButton;
@property (weak,nonatomic,readwrite) UIButton *micSwitchButton;
@property(strong,nonatomic,readwrite) RACSignal *localMediaSreamObserver;
@property(strong,nonatomic,readwrite) RACSignal *remoteMediaSreamObserver;

@end

@implementation CallViewController


-(instancetype)init{
    if((self = [super init]) != nil){
        [self initialize];
    }
    return self;
}


-(void)initialize{
    _localMediaSreamObserver =
    [[[self rac_valuesAndChangesForKeyPath:@keypath(self, localMediaStream) options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) observer:self] map:^id(RACTuple *args) {
        return [args first];
    }] filter:^BOOL(RTCMediaStream *mediaStream) {
        return mediaStream != nil;
    }];
    _remoteMediaSreamObserver =
    [[[self rac_valuesAndChangesForKeyPath:@keypath(self, remoteMediaStream) options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) observer:self] map:^id(RACTuple *args) {
        return [args first];
    }] filter:^BOOL(RTCMediaStream *mediaStream) {
        return mediaStream != nil;
    }];
}

-(void)loadView{
    CallView *callView = [[CallView alloc] init];
    [self setLocalVideoView:[callView localVideoView]];
    [self setRemoteVideoView:[callView remoteVideoView]];
    [self setHangupButton:[callView hangUpButton]];
    [self setCamSwitchButton:[callView camSwitchButton]];
    [self setMicSwitchButton:[callView micSwitchButton]];
    [callView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_localVideoView setDelegate:self];
    [_remoteVideoView setDelegate:self];
    [self setView:callView];
    
}

-(BOOL)updateSwitchButtonState:(UIButton *)switchButton{
    BOOL newState = ![switchButton tag];
    [switchButton setTag:newState];
    return newState;
}

-(void)setupControls{
    @weakify(self);
    RACSignal *camSwitchButtonTapSignal = [_camSwitchButton rac_signalForControlEvents:UIControlEventTouchUpInside];
    [camSwitchButtonTapSignal subscribeNext:^(UIButton *sender) {
        @strongify(self);
        BOOL newButtonState = [self updateSwitchButtonState:sender];
        RTCVideoTrack *localVideoTrack = [[[self localMediaStream] videoTracks] firstObject];
        [localVideoTrack setEnabled:newButtonState];
    }];
    
    RACSignal *micSwitchButtonTapSignal = [_micSwitchButton rac_signalForControlEvents:UIControlEventTouchUpInside];
    [micSwitchButtonTapSignal subscribeNext:^(UIButton *sender) {
        @strongify(self);
        BOOL newButtonState = [self updateSwitchButtonState:sender];
        RTCAudioTrack *localAudioTrack = [[[self localMediaStream] audioTracks] firstObject];
        [localAudioTrack setEnabled:newButtonState];
    }];
    
    
    [_camSwitchButton setTitle:@"TurnOffCam" forState:UIControlStateNormal];
    [_micSwitchButton setTitle:@"TurnOffMic" forState:UIControlStateNormal];
    
    [_hangupButton setTitle:@"Hang up" forState:UIControlStateNormal];
    [_hangupButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [[_hangupButton titleLabel] setFont:[UIFont systemFontOfSize:25]];
    [_hangupButton setBackgroundColor:[UIColor redColor]];
    ////    _hangupButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [_hangupButton setBackgroundColor:[UIColor redColor]];
    ////    CALayer *hangupButtonLayer = [_hangupButton layer];
    ////    [hangupButtonLayer setCornerRadius:50/2];
    ////    [hangupButtonLayer setMasksToBounds:YES];
    //    UIImage *buttonImage = [[UIImage imageNamed:@"ic_call_end_black"] add_tintedImageWithColor:[UIColor whiteColor] style:ADDImageTintStyleOverAlpha];
    //    [_hangupButton setImage:buttonImage forState:UIControlStateNormal];
    [_hangupButton addTarget:self
                      action:@selector(onHangup:)
            forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupControls];
    @weakify(self);
    [_localMediaSreamObserver subscribeNext:^(RTCMediaStream *localMediaStream) {
        @strongify(self);
        RTCVideoTrack *localVideoTrack = [[localMediaStream videoTracks] firstObject];
        [localVideoTrack addRenderer:[self localVideoView]];
    }];
    
    
    [_remoteMediaSreamObserver subscribeNext:^(RTCMediaStream *remoteMediaStream) {
        @strongify(self);
        if(remoteMediaStream){
            RTCVideoTrack *remoteVideoTrack = [[remoteMediaStream videoTracks] firstObject];
            [remoteVideoTrack addRenderer:[self remoteVideoView]];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)onHangup:(UIButton *)button{
    [_delegate callViewControllerDidHangup:self];
}

-(void)removeFromParentViewController{
    _localMediaStream = nil;
    _remoteMediaStream = nil;
    [_remoteVideoView setDelegate:nil];
    [_localVideoView setDelegate:nil];
    
    RTCVideoTrack *localVideoTrack = [[_localMediaStream videoTracks] firstObject];
    [localVideoTrack removeRenderer:_localVideoView];
    
    RTCVideoTrack *remoteVideoTrack = [[_remoteMediaStream videoTracks] firstObject];
    [remoteVideoTrack removeRenderer:_remoteVideoView];
    
    
    [super removeFromParentViewController];
}

-(void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size{
    NSLog(@"videoView didChangeVideoSize %@",NSStringFromCGSize(size));
}

@end
