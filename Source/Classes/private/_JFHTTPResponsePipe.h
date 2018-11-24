//
//  _JFHTTPResponsePipe.h
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
 匹配 AFNetworking 中的响应回调参数，目的是与 JFHTTPRequest 中响应回调参数进行对接

 @param task 请求会话任务
 @param responseObject 服务器返回结果
 */
typedef void (^JFHTTPRespSuccessBlock)(NSURLSessionDataTask *task, id responseObject);

/**
 匹配 AFNetworking 中的响应回调参数，目的是与 JFHTTPRequest 中响应回调参数进行对接
 
 @param task 请求会话任务
 @param error 服务器返回错误信息
 */
typedef void (^JFHTTPRespFailureBlock)(NSURLSessionDataTask *task, NSError *error);

/**
 HTTP response 响应生成管道，负责将 JFHTTPRequest 根据配置对请求参数进行封装
 */
@interface _JFHTTPResponsePipe : NSObject

/**
 封装服务器返回的成功结果，将服务器返回的 AFNetworking 下的结果结构，经过框架逻辑处理以后，回调到业务层的结果回调中

 @param request 业务层的请求配置
 @return AFNetworking 的返回结构，服务器返回数据回到
 */
- (JFHTTPRespSuccessBlock)pipeSuccessForRequest:(JFHTTPRequest *)request;

/**
 封装服务器返回的成功结果，将服务器返回的 AFNetworking 下的结果结构，经过框架逻辑处理以后，回调到业务层的结果回调中
 
 @param request 业务层的请求配置
 @return AFNetworking 的返回结构，服务器返回数据回到
 */
- (JFHTTPRespFailureBlock)pipeFailureForRequest:(JFHTTPRequest *)request;

@end
