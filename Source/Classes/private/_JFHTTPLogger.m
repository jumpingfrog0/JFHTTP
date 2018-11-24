//
//  _JFHTTPLogger.m
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

#import "_JFHTTPLogger.h"
#import <JFFoundation/NSString+JF.h>

NSString *const JFHTTPLoggerDataNotification        = @"JFHTTPLoggerDataNotification";
NSString *const JFHTTPLoggerEncryptDataNotification = @"JFHTTPLoggerEncryptDataNotification";

NSString *const JFHTTPLoggerRequestInfoKey          = @"request_info";
NSString *const JFHTTPLoggerResponseInfoKey         = @"response_info";
NSString *const JFHTTPLoggerResultInfoKey           = @"result_info";
NSString *const JFHTTPLoggerEncryptParameterInfoKey = @"encrypt_param_info";
NSString *const JFHTTPLoggerEncryptResultInfoKey    = @"encrypt_result_info";

@implementation _JFHTTPLogger

+ (instancetype)defaultLogger {
    static _JFHTTPLogger  *_instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _instance = [[_JFHTTPLogger alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.enabled     = NO;
        self.allowNotify = NO;
    }
    return self;
}

+ (void)printWithTask:(NSURLSessionDataTask *)task response:(id)responseObject encrypt:(BOOL)encrypt {
#ifdef DEBUG
    BOOL     success    = NO;
    BOOL     statusOK   = NO;
    NSString *errorType = @"HTTP Error";

    NSHTTPURLResponse *resp = (NSHTTPURLResponse *) task.response;
    statusOK = (resp.statusCode == 200);
    success  = statusOK;

    if (!statusOK) {
        if (resp.statusCode == 299) {
            errorType = @"Business Logic Error";
        }
    }

    JFLogHttp(@"=================================== HTTP REQUEST %@ BEGIN ===================================", success ? @"SUCCESS" : @"FAIL");
    NSString *reqDescription    = [self requestDebugDescription:task.originalRequest];
    NSString *respDescription   = [self responseDebugDescription:task.response];
    NSString *resultDescription = [self resultDebugDescription:responseObject];
    JFLogHttp(@"REQUEST = %@", reqDescription);
    if (!success) {
        if (statusOK) {
            JFLogHttp(@"FAILED REASON: %@", errorType);
        } else {
            JFLogHttp(@"FAILED REASON: %@, status code = %ld", errorType, (long) resp.statusCode);
        }
    }
    JFLogHttp(@"RESPONSE = %@", respDescription);
    JFLogHttp(@"RESULT = %@", resultDescription);
    JFLogHttp(@"=================================== HTTP REQUEST %@ END ===================================", success ? @"SUCCESS" : @"FAIL");

    [self notifyForTask:task response:responseObject encrypt:encrypt];

#endif
}

+ (void)notifyForTask:(NSURLSessionTask *)task response:(id)responseObject encrypt:(BOOL)encrypt {
    if ([_JFHTTPLogger defaultLogger].allowNotify) {
        NSDictionary *dataInfo = @{
                JFHTTPLoggerRequestInfoKey: [self requestDebugDescription:task.originalRequest],
                JFHTTPLoggerResponseInfoKey: [self responseDebugDescription:task.response] ?: @"{}",
                JFHTTPLoggerResultInfoKey: [self resultDebugDescription:responseObject] ?: @"{}"
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:JFHTTPLoggerDataNotification object:nil userInfo:dataInfo];

        if (encrypt) {
            NSURLRequest *request  = task.originalRequest;
            NSString     *httpBody = @"";
            if (request.HTTPBody) {
                httpBody = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
                if (!httpBody) {
                    httpBody = @"<null>";
                } else {
                    // convert to json format
                    httpBody = [NSString jf_stringWithJSONObject:httpBody];
                }
            }

            NSDictionary *userInfo = @{
                    JFHTTPLoggerEncryptParameterInfoKey: httpBody ?: @"",
                    JFHTTPLoggerEncryptResultInfoKey: [self resultDebugDescription:responseObject] ?: @"{}"
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:JFHTTPLoggerEncryptDataNotification object:nil userInfo:userInfo];
        }
    }
}

+ (NSString *)responseDebugDescription:(NSURLResponse *)response {
    if (!response.debugDescription) {
        return nil;
    }
    NSData *responseData = [response.debugDescription dataUsingEncoding:NSUTF8StringEncoding];
    return [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
}

+ (NSString *)resultDebugDescription:(id)resultObject {
    if (!resultObject) {
        return nil;
    }
    NSData *resultData = [NSJSONSerialization dataWithJSONObject:resultObject options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}

+ (NSString *)requestDebugDescription:(NSURLRequest *)request {
    NSMutableArray *reqComponents = [NSMutableArray array];
    [reqComponents addObject:@"$ curl -i"];
    [reqComponents addObject:[NSString stringWithFormat:@"Request URL: %@", request.URL.absoluteString]];
    [reqComponents addObject:[NSString stringWithFormat:@"-X %@", request.HTTPMethod]];

    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *h = [NSString stringWithFormat:@"-H %@ : %@", key, obj];
        [reqComponents addObject:h];
    }];
    [reqComponents componentsJoinedByString:@" \n\t"];

    if (request.HTTPBody) {
        NSString *httpBody = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        if (!httpBody) {
            httpBody = @"<null>";
        }
        [reqComponents addObject:[NSString stringWithFormat:@"-d %@", httpBody]];
    }

    return [NSString jf_stringWithJSONObject:reqComponents];
}

@end
