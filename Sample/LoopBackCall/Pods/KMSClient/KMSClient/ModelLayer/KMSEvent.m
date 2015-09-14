// KMSEvent.m
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

#import "KMSEvent.h"
#import <Mantle/NSValueTransformer+MTLPredefinedTransformerAdditions.h>
#import "MTLJSONAdapterWithoutNil.h"

@implementation KMSEvent

+(Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary{
    NSString *eventTypeString = JSONDictionary[@"type"];
    
    KMSEventType eventType = (KMSEventType)[[self typePropertyMap][eventTypeString] integerValue];
    
    switch (eventType) {
        case KMSEventTypeOnICECandidate:
            return [KMSEventICECandidate class];
        
        case KMSEventTypeMediaElementConnected:
        case KMSEventTypeMediaElementDisconnected:
            return [KMSEventElementConnection class];
        
        default:
            return self;
    }
    
}

+(NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{@"data" : @"data",
             @"object" : @"object",
             @"type" : @"type"};
}

+(NSDictionary *)typePropertyMap{
    return @{@"OnIceGatheringDone" :@(KMSEventTypeOnICEGatheringDone),
             @"OnIceCandidate" : @(KMSEventTypeOnICECandidate),
             @"ElementConnected" : @(KMSEventTypeMediaElementConnected),
             @"ElementDisconnected" : @(KMSEventTypeMediaElementDisconnected),
             @"MediaSessionStarted" : @(KMSEventTypeMediaSessionStarted),
             @"MediaSessionTerminated" : @(KMSEventTypeMediaSessionTerminated),
             @"ConnectionStateChanged" : @(KMSEventTypeConnectionStateChanged)};
}

+(NSValueTransformer *)typeJSONTransformer{
    
   return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:[self typePropertyMap]];
}

+(NSValueTransformer *)dataJSONTransformer{
    return [MTLJSONAdapterWithoutNil dictionaryTransformerWithModelClass:[KMSEventData class]];
}

@end

@implementation KMSEventICECandidate
@dynamic data;


@end


@implementation KMSEventElementConnection
@dynamic data;


@end