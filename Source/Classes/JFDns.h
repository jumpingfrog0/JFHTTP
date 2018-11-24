//
//  JFDns.h
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
 DNS 转换管理，对于需要管理的 URL 采用黑白名单记录，黑名单转换 ip
 */
@interface JFDns : NSObject

+ (JFDns *)shared;

/**
 转换 Request 对象，如果该请求的域名在黑名单中，则将域名转换为 ip，并在 header 中增加 host 没有进入黑名单，则不生效

 @param req 待转换请求
 */
- (void)transformMutableRequest:(NSMutableURLRequest *)req;

/**
 转换 Request 对象，如果该请求的域名在黑名单中，则将域名转换为 ip，并在 header 中增加 host
 没有进入黑名单，则只将原请求转换为 mutableURLRequest，参数不变
 此方法为 transformMutableRequest: 方法的封装

 @param req 待转换请求
 @return 转换后的对象，url host 为 ip，header 中包含原域名 host
 */
- (NSMutableURLRequest *)transformRequest:(NSURLRequest *)req;


/**
 标记无效 URL，被标记的 URL 会根据一定策略被就到黑名单中，再访问相同域名下的地址时，调用 transformRequest 会生效

 @param URL 被劫持或者 DNS 解析有问题的 URL 地址
 */
- (void)invalidateURL:(NSURL *)URL;

@end
