// KMSRequestMessage.h
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

#import "KMSMessage.h"
#import "KMSMethod.h"
#import "KMSMessageParams.h"

@interface KMSRequestMessage : KMSMessage{
    @protected KMSMethod _method;
}

/**
 *  Creates request message
 *
 *  @param method kurento method
 *
 *  @return message instance with pre generated UUID identifier and jsonrpc properties.
 */
+(instancetype)messageWithMethod:(KMSMethod)method;

+(Class)classForParamsJSONTransformer;

/**
 *  Request parameters.
 */
@property(strong,nonatomic,readwrite) KMSMessageParams *params;
/**
 *  Kurento method when it is equals KMSMethodOnEvent means that is request from KMS.
 */
@property(assign,nonatomic,readonly) KMSMethod method;

@end

#pragma mark CreateMessages

@interface KMSRequestMessageCreate : KMSRequestMessage
@property(strong,nonatomic,readwrite) KMSMessageParamsCreate *params;
@end

@interface KMSRequestMessageCreateWebRTC : KMSRequestMessageCreate
@property(strong,nonatomic,readwrite) KMSMessageParamsCreateWebRTC *params;
@end

#pragma mark InvokeMessages

@interface KMSRequestMessageInvoke : KMSRequestMessage
@property(strong,nonatomic,readwrite) KMSMessageParamsInvoke *params;
@end

@interface KMSRequestMessageProcessOffer : KMSRequestMessageInvoke
@property(strong,nonatomic,readwrite) KMSMessageParamsProcessOffer *params;
@end

@interface KMSRequestMessageConnect : KMSRequestMessageInvoke

@property(strong,nonatomic,readwrite) KMSMessageParamsConnect *params;

@end

@interface KMSRequestMessageAddICECandidate : KMSRequestMessageInvoke
@property(strong,nonatomic,readwrite) KMSMessageParamsAddICECandidate *params;
@end

#pragma mark SubscribeMessages

@interface KMSRequestMessageSubscribe : KMSRequestMessage
@property(strong,nonatomic,readwrite) KMSMessageParamsSubscribe *params;
@end

#pragma mark UnsubscribeMessages

@interface KMSRequestMessageUnsubscribe : KMSRequestMessage

@property(strong,nonatomic,readwrite) KMSMessageParamsUnsubscribe *params;

@end

#pragma mark ReleaseMessages

@interface KMSRequestMessageRelease : KMSRequestMessage

@property(strong,nonatomic,readwrite) KMSMessageParamsRelease *params;

@end

#pragma mark EventMessages

@interface KMSRequestMessageEvent : KMSRequestMessage
@property(strong,nonatomic,readwrite) KMSMessageParamsEvent *params;
@end

