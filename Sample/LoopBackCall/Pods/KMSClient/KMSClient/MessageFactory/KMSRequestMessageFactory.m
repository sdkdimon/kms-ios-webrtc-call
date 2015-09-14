// KMSRequestMessageFactory.m
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

#import "KMSRequestMessageFactory.h"
#import "KMSRequestMessage.h"
#import "UUID.h"

static NSString * const JSONRPC = @"2.0";

@implementation KMSRequestMessageFactory

-(void)authorizeMessage:(KMSRequestMessage *)message{
    
    @try {
        if(_dataSource == nil){
            @throw [NSException
                    exceptionWithName:@"KMSMessageFactoryDataSource"
                    reason:@"No data source presented"
                    userInfo:nil];
        }
        if(![_dataSource respondsToSelector:@selector(messageFactory:sessionIdForMessage:)]){
            @throw [NSException
                    exceptionWithName:@"KMSMessageFactoryDataSource"
                    reason:@"Data source does not implement required methods"
                    userInfo:nil];

        }
    }
    @catch (NSException *exception) {
        [exception raise];
    }
    
   [[message params] setSessionId:[_dataSource messageFactory:self sessionIdForMessage:message]];
    
}

-(KMSRequestMessage *)messageWithParams:(KMSMessageParams *)params method:(KMSMethod)method{
    KMSRequestMessage *message = [KMSRequestMessage messageWithMethod:method];
    [message setJsonrpc:JSONRPC];
    [message setIdentifier:[UUID uuid]];
    [message setParams:params];
    [self authorizeMessage:message];
    return message;
    
}



@end
