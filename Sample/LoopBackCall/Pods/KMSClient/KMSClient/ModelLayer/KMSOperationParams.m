// KMSOperationParams.m
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

#import "KMSOperationParams.h"
#import "MTLJSONAdapterWithoutNil.h"

@implementation KMSOperationParams
+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return nil;
}

@end

@implementation KMSOperationParamsAddICECandidate
+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{@"candidate" : @"candidate" };
}

+(NSValueTransformer *)candidateJSONTransformer{
    return [MTLJSONAdapterWithoutNil dictionaryTransformerWithModelClass:[KMSICECandidate class]];
}

@end

@implementation KMSOperationParamsConnect
+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{@"sink" : @"sink"};
}

+(instancetype)modelWithSink:(NSString *)sink{
    return [[self alloc] initWithSink:sink];
}

-(instancetype)initWithSink:(NSString *)sink{
    if((self = [super init]) != nil){
        _sink = sink;
    }
    return self;
}

@end


@implementation KMSOperationParamsProcessOffer

+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{@"offer" : @"offer"};
}


+(instancetype)paramsWithOffer:(NSString *)offer{
    return [[self alloc] initWithOffer:offer];
}

-(instancetype)initWithOffer:(NSString *)offer{
    if((self = [super init]) != nil){
        _offer = offer;
    }
    return self;
}
@end
