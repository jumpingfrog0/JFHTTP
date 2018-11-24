//
//  _JFHTTPRequestPipe.m
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

#import "_JFHTTPRequestPipe.h"
#import <JFFoundation/NSURL+JF.h>
#import <JFFoundation/NSString+JF.h>
#import "NSDictionary+_JFHTTP.h"

@implementation _JFHTTPRequestPipe

- (void)pipe:(JFHTTPRequest *)request {
    // 参数加密
    [self _encrypt:request];

    // 添加默认参数
    [self _mixRequest:request];
    
    // 签名，需要增加 access_token_ 和 auth_type_ 两个参数
    [self _sign:request];
}

#pragma mark -- pipes
- (void)_encrypt:(JFHTTPRequest *)request {
    if (request.encrypt) {
        // TODO: AES crypto
        if (request.params.count > 0) {
            if ([request.method.lowercaseString isEqualToString:@"post"]) {
//                request.params = [request.params jf_x_encrypt];
            } else {
                // get 请求将参数按照 query 格式拼接后加密
                // key=key，value=array 参数按照 key=item1&key=item2方式拼接
                NSMutableString *s = [NSMutableString string];
                [request.params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:NSArray.class]) {
                        [obj enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSString *p = [NSString stringWithFormat:@"&%@=%@", key, obj1];
                            [s appendString:p];
                        }];
                    }
                    else {
                        NSString *p = [NSString stringWithFormat:@"&%@=%@", key, obj];
                        [s appendString:p];
                    }
                }];
                [s deleteCharactersInRange:NSMakeRange(0, 1)];
//                request.params = [[s jf_x_encrypt] jf_JSONObject];
            }
        }
    }
}

- (void)_mixRequest:(JFHTTPRequest *)request {
    if (request.mixDefaultParams && self.defaultParamsBlock) {
        NSDictionary *defaultParams = self.defaultParamsBlock();
        NSURL *url = [NSURL URLWithString:request.api];
        request.api = [[url jf_URLByAddQueriesFromDictionary:defaultParams] absoluteString];
    }
}

- (void)_sign:(JFHTTPRequest *)request {
    if (request.sign) {
        NSString *query = self.token;
        if (query.length > 0) {
            query = [NSString stringWithFormat:@"access_token_=%@", query];
            request.api = [request.api jf_URLStringByAppendingQueryString:query];
            
            query = self.type;
            if (query.length > 0) {
                query = [NSString stringWithFormat:@"auth_type_=%@", query];
                request.api = [request.api jf_URLStringByAppendingQueryString:query];
            }
        }
        
        // 生成 sign_ 算法需要 signsecret 字符串
        NSURL *url = [NSURL URLWithString:request.api];
        NSMutableDictionary *allParams = [NSMutableDictionary dictionary];
        [allParams addEntriesFromDictionary:url.jf_parameters];
        
        if ([request.method.lowercaseString isEqualToString:@"get"]) {
            [allParams addEntriesFromDictionary:request.params];
        }
        else if ([request.method.lowercaseString isEqualToString:@"post"]) {
            if (request.params.count > 0) {
                NSError *error   = nil;
                // 与 AFJSONRequestSerializer 中 post 参数编码方式一致，option 用 0
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:request.params options:0 error:&error];
                NSString *body = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [allParams setObject:body forKey:@"_body"];
            }
        }
        
        NSString *sign = [allParams jf_httpgk:self.sskey];
        url = [url jf_URLByAddQueriesFromDictionary:@{ @"sign_" : sign }];
        request.api = url.absoluteString;
    }
}

@end
