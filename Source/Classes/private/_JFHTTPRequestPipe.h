//
//  _JFHTTPRequestPipe.h
//  JFHTTP
//
//  Created by jumpingfrog0 on 2018/11/23.
//
//
//  Copyright (c) 2018 Donghong Huang <jumpingfrog0@gmail.com>
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
//

#import <Foundation/Foundation.h>
#import "JFHTTPRequest.h"


/**
 HTTP request 请求生成管道，负责将 JFHTTPRequest 根据配置对请求参数进行封装
 */
@interface _JFHTTPRequestPipe : NSObject

/**
 来自 JFHTTPClient 的 token
 */
@property (nonatomic, copy) NSString *token;

/**
 来自 JFHTTPClient 的 authtype
 */
@property (nonatomic, copy) NSString *type;

/**
 来自 JFHTTPClient 的 sskey
 */
@property (nonatomic, copy) NSString *sskey;

/**
 来自 JFHTTPClient 的 defaultParamsBlock
 */
@property (nonatomic, copy) NSDictionary* (^defaultParamsBlock)(void);

/**
 处理 baseURL 的 relative path，构造完整的 request api
 
 @param request 请求对象
 @param url baseURL
 @return request api 有变化则返回YES, 否则返回NO
 */
- (BOOL)resolve:(JFHTTPRequest *)request baseURL:(NSURL *)url;

/**
 将 JFHTTPRequest 参数进行初步封装处理，比如加密，签名等

 @param request 请求参数对象
 */
- (void)pipe:(JFHTTPRequest *)request;

@end
