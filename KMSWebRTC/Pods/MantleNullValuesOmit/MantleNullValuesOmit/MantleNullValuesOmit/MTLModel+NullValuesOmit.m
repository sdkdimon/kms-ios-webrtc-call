//
//  MTLModel+NullValuesOmit.m
//  Copyright (c) 2016 Dmitry Lizin (sdkdimon@gmail.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "MTLModel+NullValuesOmit.h"
#import <objc/runtime.h>

static void *ASSOCIATION_KEY_OMITNULLVALUES = &ASSOCIATION_KEY_OMITNULLVALUES;

@implementation MTLModel (NullValuesOmit)


+ (void)load{
    Method method = class_getInstanceMethod(self, @selector(init));
    Method override_Method = class_getInstanceMethod(self, @selector(override_init));
    method_exchangeImplementations(method, override_Method);
}

- (instancetype)override_init{
    [self setOmitNullValues:YES];
    return [self override_init];
}


- (void)setOmitNullValues:(BOOL)omitNullValues{
    objc_setAssociatedObject(self, &ASSOCIATION_KEY_OMITNULLVALUES, @(omitNullValues), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isOmitNullValues{
    return [objc_getAssociatedObject(self, &ASSOCIATION_KEY_OMITNULLVALUES) boolValue];
}



@end
