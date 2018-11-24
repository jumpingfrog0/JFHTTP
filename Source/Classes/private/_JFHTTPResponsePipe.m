//
//  _JFHTTPResponsePipe.m
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

#import <UIKit/UIKit.h>
#import <JFFoundation/NSString+JF.h>
#import <JFFoundation/NSDictionary+JF.h>
#import <AFNetworking/AFURLResponseSerialization.h>
#import "_JFHTTPResponsePipe.h"
#import "_JFHTTPLogger.h"
#import "JFNetworkDefines.h"
#import "JFDns.h"

@implementation _JFHTTPResponsePipe

- (JFHTTPRespSuccessBlock)pipeSuccessForRequest:(JFHTTPRequest *)request {
    return ^(NSURLSessionDataTask *task, id respObj) {
        
        // 在控制台打印请求日志
        if ([_JFHTTPLogger defaultLogger].isEnabled) {
            [_JFHTTPLogger printWithTask:task response:respObj encrypt:request.encrypt];
        }
        
        NSHTTPURLResponse *resp = (NSHTTPURLResponse *)task.response;
        NSInteger code = resp.statusCode;
        NSString *host = task.originalRequest.URL.host;
        
        if (code == 200) {
            if (request.success) {
                id result = respObj;
                
                if ([result isKindOfClass:NSDictionary.class]) {
                    BOOL encrypt = NO;
                    
                    id encryptField = resp.allHeaderFields[@"X-Secure"];
                    if (encryptField) {
                        encrypt = [encryptField boolValue];
                    }
                    
                    if (request.encrypt && encrypt) {
                        // TODO: AES decrypt
//                        result = [result jf_x_decrypt];
                    }
                    
                    // 过滤空值
                    result = [result jf_filterEmptyData];
                    request.success(result);
                    
                } else if ([result isKindOfClass:[NSNull class]]) {
                    request.success(@{ @"data" : @{}});
                } else {
                    if (!result) {
                        request.success(@{ @"data" : @{}});
                    } else {
                        request.success(@{ @"data" : result });
                    }
                }
            }
        } else if (code == 299) { // 200 中的业务错误
            if (request.failure) {
                NSString *message = [self _handle299Error:respObj];

                NSMutableDictionary *resp = [respObj mutableCopy];
                resp[@"message"] = message;
                NSError *e = [self _errorWithhost:host
                                             code:code
                                         response:resp];
                request.failure(e);
            }
        } else {
            if (request.success) {
                request.success(respObj);
            }
        }
    };
}

- (JFHTTPRespFailureBlock)pipeFailureForRequest:(JFHTTPRequest *)request {
    
    return ^(NSURLSessionDataTask *task, NSError *error) {
        // NSError URL Loading System Error Codes 判定走 dns 解析
        NSInteger code = error.code;
        if (code < 0) {
            [[JFDns shared] invalidateURL:task.originalRequest.URL];
        }
        else if ([task.response isKindOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            code = response.statusCode;
            if (code >= 400 && code < 500) {
                // 401 服务器权限失败
                if (code == 401) {
                    [self _throwAuthFailed];
                }
                else {
                    [[JFDns shared] invalidateURL:task.originalRequest.URL];
                }
            }
        } // 400 错误走 dns 解析
        
        NSData *respData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        if (respData) {
            NSDictionary *respObj;
            respObj = [NSJSONSerialization JSONObjectWithData:respData
                                                      options:NSJSONReadingAllowFragments
                                                        error:nil];
            if (!respObj) { // 非标准json字符串
                NSString *desc = [[NSString alloc] initWithData:respData encoding:NSUTF8StringEncoding];
                respObj = @{ @"message" : desc };
            }
            
            if ([_JFHTTPLogger defaultLogger].isEnabled) {
                [_JFHTTPLogger printWithTask:task response:respObj encrypt:request.encrypt];
            }
            
            if (request.failure) {
                NSError *e = [self _errorWithhost:task.originalRequest.URL.host
                                             code:code
                                         response:respObj];
                request.failure(e);
            }
        }
        else {
            if (request.failure) {
                request.failure(nil);
            }
        }
    };
}

#pragma mark -- pipes
- (NSString *)_handle299Error:(NSDictionary *)response {
    /*
     code > 10000 时, message 是 json string
     code < 10000 时, message 是 string
     
     message 完整结构:
     {
     "title":"这是一条标题",
     "display":1,
     "content": "这是一条内容"
     }
     
     display 字段解释:
     DISPLAY_Hint = 1 // 弹出后一段时间消息
     DISPLAY_Alert = 2 // 有 “我知道了” 确认按钮
     */
    
    NSString *message = @"";
    if (response[@"message"]) {
        if ([response[@"code"] integerValue] > 100000) { // json string
            NSDictionary *dic = nil;
            @try {
                dic = [response[@"message"] jf_JSONObject];
            }
            @catch(NSException *e) {
#ifdef DEBUG
                NSLog(@"[JFHTTP]: %@", e);
#endif
            }
            @finally {
                message = dic[@"content"];
                
                NSInteger display = [dic[@"display"] integerValue];
                if (display > 1) {
                    NSString *title = dic[@"title"];
                    [self _showAlert:message withTitle:title];
                }
            }
        } else { // string
            message = response[@"message"];
        }
        
    }
    return message;
}

- (NSError *)_errorWithhost:(NSString *)host
                       code:(NSInteger)code
                   response:(NSDictionary *)response
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    NSString *message = kJFNetworkDefaultErrorMessage;
    
    if (response[@"code"]) {
        code = [response[@"code"] integerValue];
    }
    
    if ([response[@"message"] length] > 0) {
        message = response[@"message"];
    }
    
    if (response[@"msg"]) {
        // todo msg 参数解析
    }

    [userInfo setObject:message forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:host code:code userInfo:userInfo];
}

#pragma mark --
- (void)_throwAuthFailed {
    [[NSNotificationCenter defaultCenter] postNotificationName:kJFNetworkAuthFailedError
                                                        object:nil];
}

#pragma mark --
- (void)_showAlert:(NSString *)alert withTitle:(NSString *)title {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title
                                                                   message:alert
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ac = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:nil];
    [a addAction:ac];

    [self._topVC presentViewController:a animated:YES completion:nil];
}

- (UIViewController *)_topVC {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *vc = keyWindow.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
        
        if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = [(UINavigationController *)vc visibleViewController];
        } else if ([vc isKindOfClass:[UITabBarController class]]) {
            vc = [(UITabBarController *)vc selectedViewController];
        }
    }
    return vc;
}

@end
