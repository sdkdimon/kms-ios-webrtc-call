//
//  KMSRACSubject.m
//  KMSClient
//
//  Created by dimon on 09/02/2017.
//  Copyright © 2017 dimon. All rights reserved.
//

#import "KMSRACSubject.h"

@interface KMSRACSubject ()

- (NSMutableArray *)subscribers;

@end

@implementation KMSRACSubject

- (NSUInteger)subscribersCount
{
    return [[self subscribers] count];
}

@end
