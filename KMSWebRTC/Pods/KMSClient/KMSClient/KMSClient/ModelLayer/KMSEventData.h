// KMSEventData.h
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

#import "KMSEventType.h"
#import "KMSElementConnection.h"
#import "KMSICECandidate.h"
#import "KMSMediaState.h"

@interface KMSEventData : MTLModel <MTLJSONSerializing>
@property(assign,nonatomic,readwrite) KMSEventType type;
@property(strong,nonatomic,readwrite) NSString *source;
@end

@interface KMSEventDataICECandidate : KMSEventData
@property(strong,nonatomic,readwrite) KMSICECandidate *candidate;
@end

@interface KMSEventDataElementConnection : KMSEventData

@property(strong,nonatomic,readwrite) NSString *sink;
@property(assign,nonatomic,readwrite) KMSMediaType mediaType;
@property(strong,nonatomic,readwrite) KMSElementConnection *elementConnection;

@end


@interface KMSEventDataMediaStateChanged : KMSEventData

@property(assign,nonatomic,readwrite) KMSMediaState state;
@property(assign,nonatomic,readwrite) KMSMediaState oldState;

@end
