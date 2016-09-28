// AudioOutputManager.m
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

#import "AudioOutputManager.h"

///* output port types */
//AVF_EXPORT NSString *const AVAudioSessionPortLineOut          NS_AVAILABLE_IOS(6_0); /* Line level output on a dock connector */
//AVF_EXPORT NSString *const AVAudioSessionPortHeadphones       NS_AVAILABLE_IOS(6_0); /* Headphone or headset output */
//AVF_EXPORT NSString *const AVAudioSessionPortBluetoothA2DP    NS_AVAILABLE_IOS(6_0); /* Output on a Bluetooth A2DP devIce */
//AVF_EXPORT NSString *const AVAudioSessionPortBuiltInReceiver  NS_AVAILABLE_IOS(6_0); /* The speaker you hold to your ear when on a phone call */
//AVF_EXPORT NSString *const AVAudioSessionPortBuiltInSpeaker   NS_AVAILABLE_IOS(6_0); /* Built-in speaker on an iOS devIce */
//AVF_EXPORT NSString *const AVAudioSessionPortHDMI             NS_AVAILABLE_IOS(6_0); /* Output via High-Definition Multimedia Interface */
//AVF_EXPORT NSString *const AVAudioSessionPortAirPlay          NS_AVAILABLE_IOS(6_0); /* Output on a remote Air Play devIce */
//AVF_EXPORT NSString *const AVAudioSessionPortBluetoothLE	  NS_AVAILABLE_IOS(7_0); /* Output on a Bluetooth Low Energy devIce */
//
///* port types that refer to either input or output */
//AVF_EXPORT NSString *const AVAudioSessionPortBluetoothHFP NS_AVAILABLE_IOS(6_0); /* Input or output on a Bluetooth Hands-Free Profile devIce */
//AVF_EXPORT NSString *const AVAudioSessionPortUSBAudio     NS_AVAILABLE_IOS(6_0); /* Input or output on a Universal Serial Bus devIce */
//AVF_EXPORT NSString *const AVAudioSessionPortCarAudio     NS_AVAILABLE_IOS(7_0); /* Input or output via Car Audio */

@interface AudioOutputManager ()

@property(strong,nonatomic,readwrite) NSDictionary *audioOutputPorts;
@property(strong,nonatomic,readwrite) NSNotificationCenter *defaultNotificationCenter;


@end

@implementation AudioOutputManager

- (instancetype)initWithAudioSession:(AVAudioSession *)audioSession{
    self = [super init];
    if(self != nil){
        _audioSession = audioSession;
        _audioOutputPorts = @{AVAudioSessionPortBuiltInReceiver : @(AudioOutputPortBuiltInReceiver),
                               AVAudioSessionPortBuiltInSpeaker : @(AudioOutputPortBuiltInSpeaker),
                               AVAudioSessionPortHeadphones : @(AudioOutputPortHeadphones)};
        _outputPort = [self audioSessionAudioOutputType];
        _canUseBuiltInReceiverPort = _outputPort == AudioOutputPortBuiltInReceiver;
        _defaultNotificationCenter = [NSNotificationCenter defaultCenter];
        [self setup];
    }
    return self;
}

- (void)setup{
    [_defaultNotificationCenter addObserver:self selector:@selector(audioSessionDidChangeRoute:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)setOutputType:(AudioOutputPort)outputType error:(NSError *__autoreleasing *)error{
    
    AVAudioSessionPortOverride portOverride = -1;
    
    switch (outputType) {
        case AudioOutputPortBuiltInReceiver:
            if(_canUseBuiltInReceiverPort){
                portOverride = AVAudioSessionPortOverrideNone;
                 break;
            }
            return;
       case AudioOutputPortBuiltInSpeaker:
            portOverride = AVAudioSessionPortOverrideSpeaker;
            break;
        default:
            return;
    }
  
    [_audioSession overrideOutputAudioPort:portOverride error:error];
    
}


- (AudioOutputPort)audioSessionAudioOutputType{
    AVAudioSessionRouteDescription *routeDescription = [_audioSession currentRoute];
    AVAudioSessionPortDescription *outputPortDescription = [[routeDescription outputs] firstObject];
    NSNumber *audioPortNum = _audioOutputPorts[[outputPortDescription portType]];
    return [audioPortNum integerValue];
}

- (void)audioSessionDidChangeRoute:(NSNotification *)notification
{
    NSDictionary *interuptionDict = [notification userInfo];
    
    NSUInteger reason = [interuptionDict[AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (reason) {
        case AVAudioSessionRouteChangeReasonUnknown:
            NSLog(@"Reason:Unknown");
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"Reason:NewDevIceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"Reason:OldDevIceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"Reason:CategoryChange");
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"Reason:Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"Reason:WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"Reason:NoSuitableRouteForCategory");
            break;
        case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
            NSLog(@"Reason:RouteConfigurationChange");
            break;
        default:
            break;
    }
    
    AVAudioSessionRouteDescription *prevRoute  =  interuptionDict[AVAudioSessionRouteChangePreviousRouteKey];
    
    AVAudioSessionRouteDescription *currRoute = [_audioSession currentRoute];
    
    NSLog(@"didSessionRouteChange\nprevRoute%@\ncurrRoute%@",prevRoute,currRoute);
    NSLog(@"category: %@",[_audioSession category]);
    
}


@end
