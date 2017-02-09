// KMSMediaPipeline.h
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

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

@class RACSignal;
@class KMSSession;

@interface KMSMediaPipeline : NSObject 

+ (instancetype)pipelineWithKurentoSession:(KMSSession *)kurentoSession identifier:(NSString *)identifier;
- (instancetype)initWithKurentoSession:(KMSSession *)kurentoSession identifier:(NSString *)identifier;

+ (instancetype)pipelineWithKurentoSession:(KMSSession *)kurentoSession;
- (instancetype)initWithKurentoSession:(KMSSession *)kurentoSession;

@property(strong,nonatomic,readonly) NSString *identifier;
@property(strong,nonatomic,readonly) KMSSession *kurentoSession;



- (RACSignal *)create;
- (RACSignal *)dispose;



#ifndef DOXYGEN_SHOULD_SKIP_THIS
// Disallow init and don't add to documentation
- (instancetype)init __attribute__(
                         (unavailable("init is not a supported initializer for this class.")));
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

@end
