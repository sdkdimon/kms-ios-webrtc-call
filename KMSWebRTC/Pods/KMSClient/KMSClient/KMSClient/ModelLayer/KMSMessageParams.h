// KMSMessageParams.h
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

#import <Mantle/Mantle.h>

#import "KMSCreationType.h"
#import "KMSConstructorParams.h"
#import "KMSInvocationOperation.h"
#import "KMSOperationParams.h"
#import "KMSEvent.h"

@interface KMSMessageParams : MTLModel <MTLJSONSerializing>
@property(strong,nonatomic,readwrite) NSString *sessionId;
@end

@interface KMSMessageParamsCreate : KMSMessageParams
/**
 *  The parameter type specifies the type of the object to be created
 */
@property(assign,nonatomic,readwrite) KMSCreationType type;
/**
 *  The parameter constructorParams contains all the information needed to create the object.
 *  Each message needs different constructorParams to create the object.
 *  These parameters are defined in Kurento API section.
 */
@property(strong,nonatomic,readwrite) KMSConstructorParams *constructorParams;

@end


@interface KMSMessageParamsCreateWebRTC : KMSMessageParamsCreate
@property(strong,nonatomic,readwrite) KMSConstructorParamsWebRTC *constructorParams;
@end

@interface KMSMessageParamsInvoke : KMSMessageParams

@property(strong,nonatomic,readwrite) NSString *object;
@property(assign,nonatomic,readwrite) KMSInvocationOperation operation;
@property(strong,nonatomic,readwrite) KMSOperationParams *operationParams;


@end

@interface KMSMessageParamsAddICECandidate : KMSMessageParamsInvoke

@property(strong,nonatomic,readwrite) KMSOperationParamsAddICECandidate *operationParams;

@end

@interface KMSMessageParamsConnect : KMSMessageParamsInvoke

@property(strong,nonatomic,readwrite) KMSOperationParamsConnect *operationParams;

@end

@interface KMSMessageParamsProcessOffer : KMSMessageParamsInvoke

@property(strong,nonatomic,readwrite) KMSOperationParamsProcessOffer *operationParams;

@end

@interface KMSMessageParamsEvent : KMSMessageParams

@property(strong,nonatomic,readwrite) KMSEvent *value;

@end

@interface KMSMessageParamsRelease : KMSMessageParams
@property(strong,nonatomic,readwrite) NSString *object;
@end

@interface KMSMessageParamsSubscribe : KMSMessageParams
@property(strong,nonatomic,readwrite) NSString *object;
@property(assign,nonatomic,readwrite) KMSEventType type;
@end

@interface KMSMessageParamsUnsubscribe : KMSMessageParams
@property(strong,nonatomic,readwrite) NSString *object;
@property(strong,nonatomic,readwrite) NSString *subscription;
@end

