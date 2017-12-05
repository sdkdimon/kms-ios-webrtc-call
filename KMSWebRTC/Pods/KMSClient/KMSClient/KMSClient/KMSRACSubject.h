//
//  KMSRACSubject.h
//  KMSClient
//
//  Created by dimon on 09/02/2017.
//  Copyright © 2017 dimon. All rights reserved.
//

#import <ReactiveObjC/RACSignal.h>
#import <ReactiveObjC/RACSubscriber.h>

NS_ASSUME_NONNULL_BEGIN

@interface KMSRACSubject<ValueType> : RACSignal<ValueType> <RACSubscriber>

/// Returns a new subject.
+ (instancetype)subject;

// Redeclaration of the RACSubscriber method. Made in order to specify a generic type.
- (void)sendNext:(nullable ValueType)value;

- (NSUInteger)subscribersCount;

@end

NS_ASSUME_NONNULL_END
