//
// ViewController.m
// Copyright (c) 2015 Dmitry Lizin (sdkdimon@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublIcense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notIce and this permission notIce shall be included in
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

#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCMediaConstraints.h>
//#import <WebRTC/RTCPair.h>
#import <WebRTC/RTCAVFoundationVideoSource.h>
#import <WebRTC/RTCVideoTrack.h>
#import <WebRTC/RTCMediaStream.h>

#import "CallViewController.h"

#import <ReactiveObjC/ReactiveObjC.h>
#import <KMSClient/KMSSession.h>
#import <KMSClient/KMSMediaPipeline.h>
#import <KMSClient/KMSWebRTCEndpoint.h>
#import <KMSClient/KMSRequestMessageFactory.h>
#import <KMSClient/KMSIceCandidate.h>
#import <KMSClient/KMSLog.h>
#import <KMSClient/KMSMediaPipeline.h>
#import <KMSWebRTC/KMSWebRTCCall.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import <AVFoundation/AVCaptureSession.h>
#import <AVFoundation/AVCaptureOutput.h>
#import <AVFoundation/AVMediaFormat.h>


@interface KurentoLogger : NSObject <KMSLogger>

@end


@implementation KurentoLogger

- (void)logMessage:(NSString *)message level:(KMSLogMessageLevel)level{
   NSLog(@"%@",message);
}

@end

static NSString * const KMS_URL = @"ws://192.168.0.89:8888/kurento";


@interface RootViewController () <CallViewControllerDelegate,KMSWebRTCCallDataSource,KMSWebRTCCallDelegate>
@property (weak, nonatomic) IBOutlet UIButton *callButton;

@property(strong,nonatomic,readwrite) KMSWebRTCCall *webRTCCall;
@property(strong,nonatomic,readwrite) CallViewController *callViewController;
@property(strong,nonatomic,readwrite) KMSMediaPipeline *mediaPipeline;
@property(strong,nonatomic,readwrite) KMSSession *kmsAPIServIce;

@end

@implementation RootViewController

#pragma mark Initialization

- (instancetype)init{
    if((self = [super init]) != nil){
        [self initialize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil){
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if((self = [super initWithCoder:aDecoder]) != nil){
        [self initialize];
    }
    return self;
}


- (void)initialize{
    [[KMSLog sharedInstance] setLogger:[[KurentoLogger alloc] init]];
}

- (void)setupControls{
   
}

- (void)setupBindings{
    
}

- (void)initializeMediaPipeline{
    [_callButton setEnabled:NO];
    _kmsAPIServIce = [[KMSSession alloc] initWithURL:[NSURL URLWithString:KMS_URL]];
    _mediaPipeline = [KMSMediaPipeline pipelineWithKurentoSession:_kmsAPIServIce];
    @weakify(self);
    [[_mediaPipeline create] subscribeError:^(NSError *error) {
        @strongify(self);
        NSLog(@"error creating meda pipeline object %@",error);
        [[self callButton] setEnabled:YES];
    } completed:^{
        @strongify(self);
        [self call:[_mediaPipeline identifier]];
        [[self callButton] setEnabled:YES];
        
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupControls];
    [self setupBindings];
 
}

- (IBAction)makeCall:(UIButton *)sender {
    [self initializeMediaPipeline];
}

- (void)call:(NSString *)webRTCEndpointId{
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[self view] animated:YES];
    [hud setLabelText:@"Calling...."];
    [hud setBackgroundColor:[UIColor colorWithWhite:.0f alpha:.5f]];
    
    CallViewController *callViewController = [[CallViewController alloc] init];
    [callViewController setVideoEnabled:YES];
    [callViewController setDelegate:self];
   
    [self setCallViewController:callViewController];
    
    _webRTCCall = [KMSWebRTCCall callWithKurentoSession:_kmsAPIServIce peerConnectionFactory:[[RTCPeerConnectionFactory alloc] init]];
    [_webRTCCall setUpMediaPipelineId:webRTCEndpointId];
    [_webRTCCall setDelegate:self];
    [_webRTCCall setDataSource:self];
    [_webRTCCall makeCall];
}

- (void)callViewControllerDidHangup:(CallViewController *)callViewController{
    [_webRTCCall hangup];
}

#pragma mark KMSWebRTCCallDataSource

- (RTCMediaStream *)localMediaSteamForWebRTCCall:(KMSWebRTCCall *)webRTCCall{
    RTCPeerConnectionFactory *peerConnectionFactory = [webRTCCall peerConnectionFactory];
    RTCMediaStream *localStream = [peerConnectionFactory mediaStreamWithStreamId:@"ARDAMS"];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCAVFoundationVideoSource *source = [peerConnectionFactory avFoundationVideoSourceWithConstraints:mediaConstraints];
    
//    AVCaptureSession *sourceCaptureSession = [source captureSession];
//    
//    NSArray <AVCaptureOutput *> *sourceCaptureSessionInputs = [sourceCaptureSession outputs];
//    for (AVCaptureOutput *input in sourceCaptureSessionInputs)
//    {
//        AVCaptureConnection *connection = [input connectionWithMediaType:AVMediaTypeVideo];
//        if ([connection isVideoOrientationSupported])
//        {
//            [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
//        }
//        
//    }
    
    RTCVideoTrack *localVideoTrack = [peerConnectionFactory videoTrackWithSource:source trackId:@"ARDAMSv0"];
    if(localVideoTrack){
        [localStream addVideoTrack:localVideoTrack];
    }
    [localStream addAudioTrack:[peerConnectionFactory audioTrackWithTrackId:@"ARDAMSa0"]];
    
    return localStream;
    
}
- (RTCMediaConstraints *)localMediaSteamConstraintsForWebRTCCall:(KMSWebRTCCall *)webRTCCall{
    return [self defaultOfferConstraints];
}
- (RTCMediaConstraints *)peerConnetionMediaConstraintsForWebRTCCall:(KMSWebRTCCall *)webRTCCall{
    return [self defaultPeerConnectionConstraints];
}

- (NSArray *)sinkEndpointsForWebRTCCall:(KMSWebRTCCall *)webRTCCall{
    return @[[webRTCCall webRTCEndpointId]];
}

#pragma mark KMSWebRTCCallDelegate

- (void)webRTCCall:(KMSWebRTCCall *)webRTCCall didAddLocalMediaStream:(RTCMediaStream *)localMediaStream{
    [_callViewController setLocalMediaStream:localMediaStream];
}

- (void)webRTCCall:(KMSWebRTCCall *)webRTCCall didAddRemoteMediaStream:(RTCMediaStream *)remoteMediaStream{
    [_callViewController setRemoteMediaStream:remoteMediaStream];
}

- (void)webRTCCall:(KMSWebRTCCall *)webRTCCall hangupFromInitiator:(KMSWebRTCCallInitiator)inititator{
    [_callViewController dismissViewControllerAnimated:NO completion:nil];
    [self setCallViewController:nil];
    [self setWebRTCCall:nil];
}

- (void)webRTCCall:(KMSWebRTCCall *)webRTCCall didFailWithError:(NSError *)error{
//    if ([error code] == 57){
//        [_callViewController dismissViewControllerAnimated:NO completion:nil];
//        [self setCallViewController:nil];
//        [self setWebRTCCall:nil];
//    } else{
    
    [_callViewController dismissViewControllerAnimated:NO completion:^{
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[self view] animated:YES];
        [hud setLabelText:@"Error"];
        [hud setDetailsLabelText:[error localizedDescription]];
        
        [self setCallViewController:nil];
        [hud show:YES];
        [hud hide:YES afterDelay:3.0f];
    }];
    
    
//    }
    
}

- (void)webRTCCallDidStart:(KMSWebRTCCall *)webRTCCall{
    [self presentViewController:_callViewController animated:NO completion:nil];
    [MBProgressHUD hideHUDForView:[self view] animated:YES];
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
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:@{@"OfferToReceiveAudio" : @"ture",
                                    @"OfferToReceiveVideo" : @"true" }
     optionalConstraints:nil];
    return constraints;
}


- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    
    return  [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
              optionalConstraints: @{@"DtlsSrtpKeyAgreement" : @"true"}];

}

@end
