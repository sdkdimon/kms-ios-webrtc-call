//
//  KMSRACSubject.h
//  KMSClient
//
//  Created by dimon on 09/02/2017.
//  Copyright © 2017 dimon. All rights reserved.
//

#import <ReactiveObjC/ReactiveObjC.h>

@interface KMSRACSubject : RACSubject

- (NSUInteger)subscribersCount;

@end
