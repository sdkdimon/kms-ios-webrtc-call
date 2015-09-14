// KMSMessageFactoryWebRTCEndpoint.m
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

#import "KMSMessageFactoryWebRTCEndpoint.h"
#import "KMSRequestMessage.h"

@implementation KMSMessageFactoryWebRTCEndpoint

-(KMSRequestMessage *)createWithMediaPipeline:(NSString *)mediaPipeline{
    KMSMessageParamsCreateWebRTC *messageParams = [[KMSMessageParamsCreateWebRTC alloc] init];
    [messageParams setType:KMSCreationTypeWebRTCEndpoint];
    KMSConstructorParamsWebRTC *messageConstructorParams = [[KMSConstructorParamsWebRTC alloc] init];
    [messageConstructorParams setMediaPipeline:mediaPipeline];
    [messageParams setConstructorParams:messageConstructorParams];
    return [self messageWithParams:messageParams method:KMSMethodCreate];
}
-(KMSRequestMessage *)disposeObject:(NSString *)object{
    KMSMessageParamsRelease *messageParams = [[KMSMessageParamsRelease alloc] init];
    [messageParams setObject:object];
    return [self messageWithParams:messageParams method:KMSMethodRelease];
}

-(KMSRequestMessage *)connectSourceEndpoint:(NSString *)sourceEndpoint sinkEndpoint:(NSString *)sinkEndpoint{
    KMSOperationParamsConnect *operationParams = [[KMSOperationParamsConnect alloc] init];
    [operationParams setSink:sinkEndpoint];
    
    KMSMessageParamsConnect *messageParams =[[KMSMessageParamsConnect alloc] init];
    [messageParams setOperationParams:operationParams];
    [messageParams setOperation:KMSInvocationOperationConnect];
    [messageParams setObject:sourceEndpoint];
    
    return [self messageWithParams:messageParams method:KMSMethodInvoke];
}
-(KMSRequestMessage *)disconnectSourceEndpoint:(NSString *)sourceEndpoint sinkEndpoint:(NSString *)sinkEndpoint{
    KMSOperationParamsConnect *operationParams = [[KMSOperationParamsConnect alloc] init];
    [operationParams setSink:sinkEndpoint];
    
    KMSMessageParamsConnect *messageParams = [[KMSMessageParamsConnect alloc] init];
    [messageParams setOperationParams:operationParams];
    [messageParams setOperation:KMSInvocationOperationDisconnect];
    [messageParams setObject:sourceEndpoint];
    
    return [self messageWithParams:messageParams method:KMSMethodInvoke];
}
-(KMSRequestMessage *)getSourceConnectionsForEndpoint:(NSString *)endpoint{
    KMSMessageParamsInvoke *messageParams = [[KMSMessageParamsInvoke alloc] init];
    [messageParams setOperation:KMSInvocationOperationGetSourceConnections];
    [messageParams setObject:endpoint];
    return [self messageWithParams:messageParams method:KMSMethodInvoke];;
}
-(KMSRequestMessage *)getSinkConnectionsForEndpoint:(NSString *)endpoint{
    KMSMessageParamsInvoke *messageParams = [[KMSMessageParamsInvoke alloc] init];
    [messageParams setOperation:KMSInvocationOperationGetSinkConnections];
    [messageParams setObject:endpoint];
    return [self messageWithParams:messageParams method:KMSMethodInvoke];

}
-(KMSRequestMessage *)processOffer:(NSString *)offer endpoint:(NSString *)endpoint{
    KMSMessageParamsProcessOffer *messageParams = [[KMSMessageParamsProcessOffer alloc] init];
    [messageParams setOperation:KMSInvocationOperationProcessOffer];
    [messageParams setObject:endpoint];
    [messageParams setOperationParams:[KMSOperationParamsProcessOffer paramsWithOffer:offer]];
    
    return [self messageWithParams:messageParams method:KMSMethodInvoke];;
}
-(KMSRequestMessage *)gatherICECandidatesForEndpoint:(NSString *)endpoint{
    KMSMessageParamsInvoke *messageParams = [[KMSMessageParamsInvoke alloc] init];
    [messageParams setObject:endpoint];
    [messageParams setOperation:KMSInvocationOperationGatherCandidates];
    [messageParams setOperationParams:nil];
    
    return [self messageWithParams:messageParams method:KMSMethodInvoke];
}
-(KMSRequestMessage *)addICECandidate:(KMSICECandidate *)candidate endpoint:(NSString *)endpoint{
    KMSMessageParamsAddICECandidate *messageParams = [[KMSMessageParamsAddICECandidate alloc] init];
    
    KMSOperationParamsAddICECandidate *messageOperationParams = [[KMSOperationParamsAddICECandidate alloc] init];
    [messageOperationParams setCandidate:candidate];
    [messageParams setOperation:KMSInvocationOperationAddICECandidate];
    [messageParams setOperationParams:messageOperationParams];
    [messageParams setObject:endpoint];
    
    return [self messageWithParams:messageParams method:KMSMethodInvoke];
}
-(KMSRequestMessage *)subscribeEndpoint:(NSString *)endpoint event:(KMSEventType)event{
    KMSMessageParamsSubscribe *messageParams =[[KMSMessageParamsSubscribe alloc] init];
    [messageParams setObject:endpoint];
    [messageParams setType:event];
    return [self messageWithParams:messageParams method:KMSMethodSubscribe];
}
-(KMSRequestMessage *)unsubscribeEndpoint:(NSString *)endpoint subscription:(NSString *)subscription{
    KMSMessageParamsUnsubscribe *messageParams = [[KMSMessageParamsUnsubscribe alloc] init];
    [messageParams setSubscription:subscription];
    [messageParams setObject:endpoint];
    return [self messageWithParams:messageParams method:KMSMethodUnsubscribe];
}


@end
