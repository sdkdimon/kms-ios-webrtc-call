// KMSRequestMessage.m
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

#import "KMSRequestMessage.h"
#import "NSDictionary+Merge.h"

#import <Mantle/NSValueTransformer+MTLPredefinedTransformerAdditions.h>


@interface KMSRequestMessage ()
 @property(assign,nonatomic,readwrite) KMSMethod method;
@end


@implementation KMSRequestMessage
@synthesize method = _method;
@synthesize params = _params;

+ (Class)classForMessageMethod:(KMSMethod)method{
    switch (method) {
        case KMSMethodCreate:
            return [KMSRequestMessageCreate class];
            
        case KMSMethodInvoke:
            return [KMSRequestMessageInvoke class];
            
        case KMSMethodSubscribe:
            return [KMSRequestMessageSubscribe class];
            
        case KMSMethodUnsubscribe:
           return [KMSRequestMessageUnsubscribe class];
        
        case KMSMethodRelease:
           return [KMSRequestMessageRelease class];
            
        default:
            return NULL;
    }

}

+ (instancetype)messageWithMethod:(KMSMethod)method{
    return [[[self classForMessageMethod:method] alloc] init];
}

+ (Class)classForParamsJSONTransformer{
    return [KMSMessageParams class];
}


#pragma mark JSONKeyPathsByPropertyKey

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return [[super JSONKeyPathsByPropertyKey] dictionaryByMergingDictionary:@{@"method" : @"method",
                                                                                @"params" : @"params"}];
}

#pragma mark MTLJSONSerializing
+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary{
    return [KMSRequestMessageEvent class];
}

+ (NSValueTransformer *)paramsJSONTransformer{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[self classForParamsJSONTransformer]];
}

+ (NSValueTransformer *)methodJSONTransformer{
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:[self kmsMehtodMap]];
}

+ (NSDictionary *)kmsMehtodMap{
    return @{@"create" :@(KMSMethodCreate),
             @"invoke" :@(KMSMethodInvoke),
             @"subscribe" :@(KMSMethodSubscribe),
             @"unsubscribe" :@(KMSMethodUnsubscribe),
             @"release" :@(KMSMethodRelease),
             @"onEvent" :@(KMSMethodOnEvent)};
}

@end


@implementation KMSRequestMessageCreate
@dynamic params;

- (instancetype)init{
    if((self = [super init]) != nil){
        _method = KMSMethodCreate;
    }
    return self;
}

+ (Class)classForParamsJSONTransformer{
    return [KMSMessageParamsCreate class];
}

@end

@implementation KMSRequestMessageCreateWebRTC
@dynamic params;

+ (Class)classForParamsJSONTransformer{
    return [KMSMessageParamsCreateWebRTC class];
}

@end

@implementation KMSRequestMessageInvoke
@dynamic params;

- (instancetype)init{
    if((self = [super init]) != nil){
        
        _method = KMSMethodInvoke;
    }
    return self;
}

+ (Class)classForParamsJSONTransformer{
    return [KMSMessageParamsInvoke class];
}

@end

@implementation KMSRequestMessageProcessOffer
@dynamic params;

+ (Class)classForParamsJSONTransformer{
    return [KMSRequestMessageProcessOffer class];
}
@end

@implementation KMSRequestMessageConnect
@dynamic params;

+ (Class)classForParamsJSONTransformer{
    return [KMSRequestMessageConnect class];
}

@end

@implementation KMSRequestMessageAddICECandidate
@dynamic params;

+ (Class)classForParamsJSONTransformer{
    return [KMSMessageParamsAddICECandidate class];
}

@end

@implementation KMSRequestMessageSubscribe
@dynamic params;

- (instancetype)init{
    if((self = [super init]) != nil){
        _method = KMSMethodSubscribe;
    }
    return self;
}

+ (Class)classForParamsJSONTransformer{
    return [KMSMessageParamsSubscribe class];
}

@end

@implementation KMSRequestMessageUnsubscribe
@dynamic params;

- (instancetype)init{
    if((self = [super init]) != nil){
        _method = KMSMethodUnsubscribe;
    }
    return self;
}

+ (Class)classForParamsJSONTransformer{
    return [KMSMessageParamsUnsubscribe class];
}

@end


@implementation KMSRequestMessageRelease
@dynamic params;

- (instancetype)init{
    if((self = [super init]) != nil){
        _method = KMSMethodRelease;
    }
    return self;
}

+ (Class)classForParamsJSONTransformer{
    return [KMSMessageParamsRelease class];
}


@end

@implementation KMSRequestMessageEvent
@dynamic params;

+ (Class)classForParamsJSONTransformer{
    return [KMSMessageParamsEvent class];
}

@end





