//
//  MTLJSONAdapter+NullValuesOmit.m
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

#import "MTLJSONAdapter+NullValuesOmit.h"
#import "MTLModel+NullValuesOmit.h"
#import <objc/runtime.h>

@implementation MTLJSONAdapter (NullValuesOmit)

+ (void)load{
    Method method = class_getInstanceMethod(self, @selector(JSONDictionaryFromModel:error:));
    Method override_Method = class_getInstanceMethod(self, @selector(override_JSONDictionaryFromModel:error:));
    method_exchangeImplementations(method, override_Method);
}


- (NSDictionary *)override_JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError *__autoreleasing *)error{
    if ([model respondsToSelector:@selector(isOmitNullValues)] && [(MTLModel *)model isOmitNullValues]){
        NSMutableDictionary *JSONDictionary = [[self override_JSONDictionaryFromModel:model error:error] mutableCopy];
        NSMutableArray *keysToRemove = [[NSMutableArray alloc] init];
        for(NSString *key in JSONDictionary){
            id value = JSONDictionary[key];
            if(value == [NSNull null]) {[keysToRemove addObject:key];}
        }
        [JSONDictionary removeObjectsForKeys:keysToRemove];
        return [JSONDictionary copy];
    }
    
    return [[self override_JSONDictionaryFromModel:model error:error] mutableCopy];
}


@end
