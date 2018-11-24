//
//  JFHTTPRequest.h
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


/**
 HTTP 成功回调

 @param response 响应结果
 */
typedef void (^JFHTTPSuccessBlock)(NSDictionary *response);

/**
 HTTP 失败回调

 @param error 响应错误，Error 中的 userInfo 中包含服务器自定义控制参数
 */
typedef void (^JFHTTPFailureBlock)(NSError *error);

/**
 HTTP 进度回调

 @param progress 当前进度数据
 */
typedef void (^JFHTTPProgressBlock)(NSProgress *progress);

/**
 框架支持的 content-type 类型

 - JFHTTPContentTypeJSON: JSON 格式
 */
typedef NS_ENUM(NSInteger, JFHTTPContentType) {
    JFHTTPContentTypeJSON = 0,
};

/**
 为 JFHTTPClient 封装的请求类，除默认值外无任何业务逻辑
 */
@interface JFHTTPRequest : NSObject

/**
 请求接口地址，相对 baseURL 后的 relativeURL
 */
@property (nonatomic, strong) NSString *api;

/**
 请求方法，支持 get，set
 默认值为 get
 */
@property (nonatomic, strong) NSString *method;

/**
 请求附带业务参数
 */
@property (nonatomic, strong) NSDictionary *params;

/**
 请求内容编码类型
 默认值为 JFHTTPContentTypeJSON
 */
@property (nonatomic, assign) JFHTTPContentType contentType;

/**
 是否在请求中混入基本参数
 基本参数是在 HTTPClient 的默认参数中设置
 默认值为 YES
 */
@property (nonatomic, assign) BOOL mixDefaultParams;

/**
 该请求是否需要加密，如果请求加密，那么默认处理为响应内容需要加密，加解密过程框架已经处理
 默认值为 NO
 */
@property (nonatomic, assign) BOOL encrypt;

/**
 dns 反劫持开关
 默认值为 YES
 */
@property (nonatomic, assign) BOOL dnsDefend;

/**
 签名开关
 默认值为 YES
 */
@property (nonatomic, assign) BOOL sign;

/**
 mock开关
 默认值为 NO
 */
@property (nonatomic, assign) BOOL mock;

/**
 请求超时时间
 默认值为 30
 */
@property (nonatomic, assign) NSInteger timeout;

/**
 成功回调
 */
@property (nonatomic, copy) JFHTTPSuccessBlock success;

/**
 失败回调
 */
@property (nonatomic, copy) JFHTTPFailureBlock failure;

/**
 进度回调
 */
@property (nonatomic, copy) JFHTTPProgressBlock progress;

@end
