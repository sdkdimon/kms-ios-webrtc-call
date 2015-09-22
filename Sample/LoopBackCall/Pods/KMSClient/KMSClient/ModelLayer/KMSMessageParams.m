// KMSMessageParams.m
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

#import "KMSMessageParams.h"
#import "NSDictionary+Merge.h"
#import <Mantle/NSValueTransformer+MTLPredefinedTransformerAdditions.h>
#import "MTLJSONAdapterWithoutNil.h"

@implementation KMSMessageParams

+(Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary{
    if([JSONDictionary[@"method"] isEqualToString:@"onEvent"]){
        return [KMSMessageParamsEvent class];
    }
    return self;
}

+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{@"sessionId" : @"sessionId"};
}


@end


@implementation KMSMessageParamsCreate

+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return [[super JSONKeyPathsByPropertyKey] dictionaryByMergingDictionary:@{@"type" : @"type",
                                                                                @"constructorParams" : @"constructorParams"}];
}

+(NSValueTransformer *)typeJSONTransformer{
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{@"WebRtcEndpoint" : @(KMSCreationTypeWebRTCEndpoint),
                                                                           @"MediaPipeline" : @(KMSCreationTypeMediaPipeline)}];
}



@end

@implementation KMSMessageParamsCreateWebRTC
@dynamic constructorParams;

+(NSValueTransformer *)constructorParamsJSONTransformer{
    return [MTLJSONAdapterWithoutNil dictionaryTransformerWithModelClass:[KMSConstructorParamsWebRTC class]];
}

@end


@implementation KMSMessageParamsInvoke
@synthesize operationParams;
+(NSDictionary *)JSONKeyPathsByPropertyKey{
    
    return [[super JSONKeyPathsByPropertyKey] dictionaryByMergingDictionary:@{@"object" : @"object",
                                                                                @"operation" : @"operation",
                                                                                @"operationParams" : @"operationParams"}];
    
}

+(NSValueTransformer *)operationJSONTransformer{
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{@"connect" : @(KMSInvocationOperationConnect),
                                                                           @"disconnect" : @(KMSInvocationOperationDisconnect),
                                                                           @"processOffer" : @(KMSInvocationOperationProcessOffer),
                                                                           @"gatherCandidates" : @(KMSInvocationOperationGatherCandidates),
                                                                           @"addIceCandidate" : @(KMSInvocationOperationAddICECandidate),
                                                                           @"getSourceConnections" : @(KMSInvocationOperationGetSourceConnections),
                                                                           @"getSinkConnections" : @(KMSInvocationOperationGetSinkConnections)}];
}

@end

@implementation KMSMessageParamsAddICECandidate
@dynamic operationParams;

+(NSValueTransformer *)operationParamsJSONTransformer{
    return [MTLJSONAdapterWithoutNil dictionaryTransformerWithModelClass:[KMSOperationParamsAddICECandidate class]];
}

@end

@implementation KMSMessageParamsConnect
@dynamic operationParams;


+(NSValueTransformer *)operationParamsJSONTransformer{
    return [MTLJSONAdapterWithoutNil dictionaryTransformerWithModelClass:[KMSOperationParamsConnect class]];
}

@end

@implementation KMSMessageParamsProcessOffer
@dynamic operationParams;

+(NSValueTransformer *)operationParamsJSONTransformer{
    return [MTLJSONAdapterWithoutNil dictionaryTransformerWithModelClass:[KMSOperationParamsProcessOffer class]];
}

@end

@implementation KMSMessageParamsEvent

+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return [[super JSONKeyPathsByPropertyKey] dictionaryByMergingDictionary:@{@"value" : @"value"}];
}

+(NSValueTransformer *)valueJSONTransformer{
    return [MTLJSONAdapterWithoutNil dictionaryTransformerWithModelClass:[KMSEvent class]];
}


@end

@implementation KMSMessageParamsRelease

+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return [[super JSONKeyPathsByPropertyKey] dictionaryByMergingDictionary:@{@"object" : @"object"}];
}

@end


@implementation KMSMessageParamsSubscribe
+(NSDictionary *)JSONKeyPathsByPropertyKey{
    
    return [[super JSONKeyPathsByPropertyKey] dictionaryByMergingDictionary:@{@"object" : @"object",
                                                                                @"type" : @"type"}];
}

+(NSValueTransformer *)typeJSONTransformer{
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{@"OnIceGatheringDone" :@(KMSEventTypeOnICEGatheringDone),
                                                                           @"OnIceCandidate" : @(KMSEventTypeOnICECandidate),
                                                                           @"ElementConnected" : @(KMSEventTypeMediaElementConnected),
                                                                           @"ElementDisconnected" : @(KMSEventTypeMediaElementDisconnected),
                                                                           @"MediaStateChanged" : @(KMSEventTypeMediaStateChanged)}];
}

@end


@implementation KMSMessageParamsUnsubscribe

+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return [[super JSONKeyPathsByPropertyKey] dictionaryByMergingDictionary:@{@"object" : @"object",
                                                                                @"subscription" : @"subscription"}];
}


@end
