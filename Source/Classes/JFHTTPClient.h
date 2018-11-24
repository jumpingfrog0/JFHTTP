//
//  JFHTTPClient.h
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

FOUNDATION_EXTERN NSString *const JFHTTPLoggerDataNotification;
FOUNDATION_EXTERN NSString *const JFHTTPLoggerEncryptDataNotification;

FOUNDATION_EXTERN NSString *const JFHTTPLoggerRequestInfoKey;
FOUNDATION_EXTERN NSString *const JFHTTPLoggerResponseInfoKey;
FOUNDATION_EXTERN NSString *const JFHTTPLoggerResultInfoKey;
FOUNDATION_EXTERN NSString *const JFHTTPLoggerEncryptParameterInfoKey;
FOUNDATION_EXTERN NSString *const JFHTTPLoggerEncryptResultInfoKey;

/**
 HTTP Client, 每一个 Client 代表一种类型的请求，负责管理请求的处理逻辑
 基于 AFNetworking 的 AFHTTPSessionManager
 */
@interface JFHTTPClient : NSObject


/**
 AFHTTPSessionManager 的 baseURL
 每一个 AFHTTPSessionManager 只能在初始化时指定 baseURL
 为了达到随时可以改变，调用 setter 时，会新生成一个 AFHTTPSessionManager 对象
 */
@property (nonatomic, strong) NSURL *baseURL;

/**
 mock 服务器 的 URL, 会初始化 AFHTTPSessionManager 的 baseURL
 每一个 AFHTTPSessionManager 只能在初始化时指定 baseURL
 为了达到随时可以改变，调用 setter 时，会新生成一个 AFHTTPSessionManager 对象
 */
@property (nonatomic, strong) NSURL *mockBaseURL;

/**
 设置请求 header 的 userAgent
 */
@property (nonatomic, copy) NSString *userAgent;

/**
 设置 tp-micro 框架协议中用来区分应用的 authtype, 需要跟后端协商
 */
@property (nonatomic, copy) NSString *type;

/**
 设置请求令牌，请求签名需要的参数
 */
@property (nonatomic, copy) NSString *token;

/**
 设置请求签名安全字符串，请求签名需要的参数
 */
@property (nonatomic, copy) NSString *sskey;

/**
 默认参数回调，需要带到请求中的基本参数
 */
@property (nonatomic, copy) NSDictionary* (^defaultParamsBlock)(void);

/**
 单例，目前配置为 JSON request, JSON response
 
 @return 单例对象
 */
+ (instancetype)sharedInstance;

/**
 发送请求

 @param request 封装装的请求类
 */
+ (void)send:(JFHTTPRequest *)request;

/**
 是否开启日志打印功能
 
 @param enabled 默认关闭 NO
 */
+ (void)enableLog:(BOOL)enabled;

/**
 是否允许将请求回话的详细信息以通知的形式广播

 @param allow YES 开启，NO 关闭，默认为 NO
 */
+ (void)allowNotifyTaskDetail:(BOOL)allow;

@end
