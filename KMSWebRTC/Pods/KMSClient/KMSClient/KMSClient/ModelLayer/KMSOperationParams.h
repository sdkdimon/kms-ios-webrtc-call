// KMSOperationParams.h
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

#import <Mantle/MTLModel.h>
#import <Mantle/MTLJSONAdapter.h>
#import "KMSICECandidate.h"

@interface KMSOperationParams : MTLModel <MTLJSONSerializing>

@end


@interface KMSOperationParamsAddICECandidate : KMSOperationParams

@property(strong,nonatomic,readwrite) KMSICECandidate *candidate;

@end

@interface KMSOperationParamsConnect : KMSOperationParams

+ (instancetype)modelWithSink:(NSString *)sink;
- (instancetype)initWithSink:(NSString *)sink;

@property(strong,nonatomic,readwrite) NSString *sink;

@end

@interface KMSOperationParamsProcessOffer : KMSOperationParams
+ (instancetype)paramsWithOffer:(NSString *)offer;
- (instancetype)initWithOffer:(NSString *)offer;

@property(strong,nonatomic,readwrite) NSString *offer;
@end
