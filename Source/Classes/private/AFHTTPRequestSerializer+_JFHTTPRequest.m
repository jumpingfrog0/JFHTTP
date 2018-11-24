//
//  AFHTTPRequestSerializer+_JFHTTPRequest.m
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

#import "AFHTTPRequestSerializer+_JFHTTPRequest.h"
#import "JFHTTPRequest.h"
#import <JFFoundation/NSObject+JF.h>
#import "JFDns.h"


@implementation AFHTTPRequestSerializer (_JFHTTPRequest)

+ (void)load {
    SEL srcSel = @selector(requestWithMethod:URLString:parameters:error:);
    SEL desSel = @selector(jf_http_requestWithMethod:URLString:parameters:error:);
    [self jf_changeSelector:srcSel withSelector:desSel];
}

- (NSMutableURLRequest *)jf_http_requestWithMethod:(NSString *)method
                                           URLString:(NSString *)URLString
                                          parameters:(nullable id)parameters
                                               error:(NSError * _Nullable __autoreleasing *)error {

    JFHTTPRequest *httpRequest = parameters;

    // 约定参数
    if (![httpRequest isKindOfClass:JFHTTPRequest.class]) {
        return [self jf_http_requestWithMethod:method
                                      URLString:URLString
                                     parameters:parameters
                                          error:error];
    }
    
    NSMutableURLRequest *req = [self jf_http_requestWithMethod:method
                                                      URLString:URLString
                                                     parameters:httpRequest.params
                                                          error:error];
    req.timeoutInterval = httpRequest.timeout;

    // 参数加密需要在 header 中标识
    if (httpRequest.encrypt) {
        if (httpRequest.params) {
            [req setValue:@"true" forHTTPHeaderField:@"X-Secure"];
        }
        [req setValue:@"true" forHTTPHeaderField:@"X-Accept-Secure"];
    }

    if (httpRequest.dnsDefend) {
        [JFDns.shared transformMutableRequest:req];
    }
    return req;
}

@end
