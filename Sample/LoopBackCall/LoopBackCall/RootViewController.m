//
// ViewController.m
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

#import "RootViewController.h"

#import <libjingle_peerconnection/RTCPeerConnectionFactory.h>
#import <libjingle_peerconnection/RTCMediaConstraints.h>
#import <libjingle_peerconnection/RTCPair.h>
#import <libjingle_peerconnection/RTCAVFoundationVideoSource.h>
#import <libjingle_peerconnection/RTCVideoTrack.h>
#import <libjingle_peerconnection/RTCMediaStream.h>

#import "CallViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <RACSRWebSocket/RACSRWebSocket.h>
#import <KMSClient/KMSAPIService.h>
#import <KMSClient/KMSMediaPipeline.h>
#import <KMSClient/KMSWebRTCEndpoint.h>
#import <KMSClient/KMSRequestMessageFactory.h>
#import <KMSClient/KMSICECandidate.h>
#import <KMSClient/KMSLog.h>
#import "KMSWebRTCCall.h"


@interface KurentoLogger : NSObject <KMSLogger>

@end


@implementation KurentoLogger

-(void)logMessage:(NSString *)message level:(KMSLogMessageLevel)level{
    NSLog(@"%@",message);
}

@end


static NSString * const KMS_URL = @"KURENTO_URL";


@interface RootViewController () <CallViewControllerDelegate,KMSWebRTCCallDataSource,KMSWebRTCCallDelegate>

@property(strong,nonatomic,readwrite) KMSWebRTCCall *webRTCCall;
@property(weak,nonatomic,readwrite) CallViewController *callViewController;

@end

@implementation RootViewController

#pragma mark Initialization

-(instancetype)init{
    if((self = [super init]) != nil){
        [self initialize];
    }
    return self;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil){
        [self initialize];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if((self = [super initWithCoder:aDecoder]) != nil){
        [self initialize];
    }
    return self;
}


-(void)initialize{
    [[KMSLog sharedInstance] setLogger:[[KurentoLogger alloc] init]];
}

-(void)setupControls{
   
}

-(void)setupBindings{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupControls];
    [self setupBindings];
}

-(void)call:(NSString *)webRTCEndpointId{
    CallViewController *callViewController = [[CallViewController alloc] init];
    [callViewController setDelegate:self];
    [self showCallViewController:callViewController];
    [self setCallViewController:callViewController];
    
    RACSRWebSocket *wsClient = [[RACSRWebSocket alloc] initWithURL:[NSURL URLWithString:KMS_URL]];
    KMSAPIService *apiService = [KMSAPIService serviceWithWebSocketClient:wsClient];
    KMSMessageFactoryWebRTCEndpoint *webRTCEndpointMessageFactory = [[KMSMessageFactoryWebRTCEndpoint alloc] init];
    KMSWebRTCEndpoint  *webRTCEndpoint = [KMSWebRTCEndpoint endpointWithAPIService:apiService messageFactory:webRTCEndpointMessageFactory identifier:webRTCEndpointId];
    [webRTCEndpointMessageFactory setDataSource:webRTCEndpoint];
    _webRTCCall = [KMSWebRTCCall callWithWebRTCEndpoint:webRTCEndpoint peerConnectionFactory:[[RTCPeerConnectionFactory alloc] init]];
    [_webRTCCall setDelegate:self];
    [_webRTCCall setDataSource:self];
    [_webRTCCall startCall];
}


-(void)showCallViewController:(CallViewController *)callViewController{
    [self addChildViewController:callViewController];
    UIView *selfView = [self view];
    UIView *callViewControllerView = [callViewController view];
    [callViewControllerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [selfView addSubview:callViewControllerView];
    
    NSLayoutConstraint *topCallViewConstraint = [NSLayoutConstraint constraintWithItem:callViewControllerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:selfView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0];
    NSLayoutConstraint *leadingCallViewConstraint = [NSLayoutConstraint constraintWithItem:callViewControllerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:selfView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0];
    NSLayoutConstraint *trailingCallViewConstraint = [NSLayoutConstraint constraintWithItem:callViewControllerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:selfView attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0];
    NSLayoutConstraint *bottomCallViewConstraint = [NSLayoutConstraint constraintWithItem:callViewControllerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:selfView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0];
    [selfView addConstraints:@[topCallViewConstraint,leadingCallViewConstraint,trailingCallViewConstraint,bottomCallViewConstraint]];
    
    
    [callViewController didMoveToParentViewController:self];
}

-(void)removeCallViewController{
    [_callViewController willMoveToParentViewController:nil];
    [[_callViewController view] removeFromSuperview];
    [_callViewController removeFromParentViewController];
}

-(void)callViewControllerDidHangup:(CallViewController *)callViewController{
    [_webRTCCall endCall];
}

#pragma mark KMSWebRTCCallDataSource

-(RTCMediaStream *)localMediaSteamForWebRTCCall:(KMSWebRTCCall *)webRTCCall{
    RTCPeerConnectionFactory *peerConnectionFactory = [webRTCCall peerConnectionFactory];
    RTCMediaStream *localStream = [peerConnectionFactory mediaStreamWithLabel:@"ARDAMS"];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCAVFoundationVideoSource *source = [[RTCAVFoundationVideoSource alloc] initWithFactory:peerConnectionFactory constraints:mediaConstraints];
    RTCVideoTrack *localVideoTrack = [[RTCVideoTrack alloc] initWithFactory:peerConnectionFactory source:source trackId:@"ARDAMSv0"];
    if(localVideoTrack){
        [localStream addVideoTrack:localVideoTrack];
    }
    [localStream addAudioTrack:[peerConnectionFactory audioTrackWithID:@"ARDAMSa0"]];
    
    return localStream;
    
}
-(RTCMediaConstraints *)localMediaSteamConstraintsForWebRTCCall:(KMSWebRTCCall *)webRTCCall{
    return [self defaultOfferConstraints];
}
-(RTCMediaConstraints *)peerConnetionMediaConstraintsForWebRTCCall:(KMSWebRTCCall *)webRTCCall{
    return [self defaultPeerConnectionConstraints];
}

#pragma mark KMSWebRTCCallDelegate

-(void)webRTCCall:(KMSWebRTCCall *)webRTCCall didCreateLocalMediaStream:(RTCMediaStream *)localMediaStream{
    [_callViewController setLocalMediaStream:localMediaStream];
}

-(void)webRTCCall:(KMSWebRTCCall *)webRTCCall didCreateRemoteMediaStream:(RTCMediaStream *)remoteMediaStream{
    [_callViewController setRemoteMediaStream:remoteMediaStream];
}

-(void)webRTCCallDidEndCall:(KMSWebRTCCall *)webRTCCall{
    [self removeCallViewController];
    [self setWebRTCCall:nil];
}

-(void)webRTCCall:(KMSWebRTCCall *)webRTCCall didFailWithError:(NSError *)error{
    
}


#pragma mark Defaults

- (RTCMediaConstraints *)defaultMediaStreamConstraints {
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints *)defaultAnswerConstraints {
    return [self defaultOfferConstraints];
}


- (RTCMediaConstraints *)defaultOfferConstraints {
    NSArray *mandatoryConstraints = @[
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]
                                      ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
}


- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    
    
  return  [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:
     @[
       [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement"
                              value:@"true"]
       ]];

}

#pragma mark UITextFieldDelegate


-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}


@end
