// KMSMessage.h
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

/**
 *  KMSMessage is a shared request/response model.
 */
@interface KMSMessage : MTLModel <MTLJSONSerializing>
/**
 *  jsonrpc: a string specifying the version of the JSON-RPC protocol. It must be exactly “2.0”.
 */
@property(strong,nonatomic,readwrite) NSString *jsonrpc;
/**
 * identifier: an unique identifier established by the client that contains a string or number.
 * The server must reply with the same value in the Response message. This member is used to correlate the context between both messages.
 * Generated when initialize object.
 */

@property(strong,nonatomic,readwrite) NSString *identifier;

@end






