// AppDelegate.m
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

#import "AppDelegate.h"
#import "RootViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
//    RACSubject *subject = [RACSubject subject];
//    
//    RACSignal *signal = [[subject filter:^BOOL(NSString *value) {
//        return [value isEqualToString:@"value"];
//    }] take:1];
//    
//    RACDisposable *d = [signal subscribeNext:^(id x) {
//        NSLog(@"on next %@",x);
//    } completed:^{
//        NSLog(@"on complete");
//    }];
//    
//    [subject sendNext:@"next"];
//    [subject sendNext:@"value"];
//    
//    NSLog(@"is disposed %@", [d isDisposed] ? @"YES" : @"NO");
    
    
//    RACSignal *s_0 = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            //[subscriber sendNext:@"s_0"];
//            [subscriber sendCompleted];
//
//        });
//        
//        return nil;
//    }] logAll];
//    [s_0 setName:@"s_0"];
//    
//    RACSignal *s_1 = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        
//        //[subscriber sendNext:@"s_1"];
//        [subscriber sendCompleted];
//        
//        return nil;
//    }] logAll];
//    [s_1 setName:@"s_1"];
//    
//    RACSignal *s_2 = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        
//        //[subscriber sendNext:@"s_2"];
//        [subscriber sendCompleted];
//        
//        return nil;
//    }] logAll];
//    [s_2 setName:@"s_2"];
//    
//    
//    RACSignal *concat = [RACSignal concat:@[s_0,s_1,s_2]];
//    
//    [concat setName:@"concat"];
//    
//    
//    [[concat logAll] subscribeNext:^(id x) {
//        NSLog(@"");
//    } completed:^{
//        NSLog(@"");
//    }];
    
    
    
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [_window setRootViewController:[[RootViewController alloc] initWithNibName:@"RootView" bundle:nil]];
    [_window makeKeyAndVisible];
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
