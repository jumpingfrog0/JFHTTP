//
//  JFHTTPClient.m
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

#import "JFHTTPClient.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "_JFHTTPRequestPipe.h"
#import "_JFHTTPResponsePipe.h"
#import "_JFHTTPLogger.h"

@interface JFHTTPClient ()

@property (nonatomic, strong) AFHTTPSessionManager *session;
@property (nonatomic, strong) AFHTTPSessionManager *mockSession;
@property (nonatomic, strong) _JFHTTPRequestPipe *requestPipe;
@property (nonatomic, strong) _JFHTTPResponsePipe *responsePipe;

@end

@implementation JFHTTPClient
+ (instancetype)sharedInstance {
    static JFHTTPClient *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[JFHTTPClient alloc] init];
    });
    return sharedInstance;
}

+ (void)send:(JFHTTPRequest *)request {
    [self _resolveRequest:request];
    [self _sendRequest:request];
}

+ (void)enableLog:(BOOL)enabled {
    [_JFHTTPLogger defaultLogger].enabled = enabled;
}

+ (void)allowNotifyTaskDetail:(BOOL)allow {
    [_JFHTTPLogger defaultLogger].allowNotify = allow;
}

#pragma mark -
+ (void)_resolveRequest:(JFHTTPRequest *)request {
    JFHTTPClient *client = [JFHTTPClient sharedInstance];

    // 重置 base URL
    void (^block)(NSURL *, BOOL) = ^(NSURL *url, BOOL mock) {
        NSURLComponents *comp = [[NSURLComponents alloc] init];
        comp.scheme = url.scheme;
        comp.host = url.host;
        comp.port = url.port;
        
        if (mock) {
            [client setMockBaseURL:comp.URL];
        } else {
            [client setBaseURL:comp.URL];
        }
    };
    
    // 处理 relative URL
    if (request.mock) {
        BOOL resolving = [client.requestPipe resolve:request baseURL:client.mockBaseURL];
        if (resolving) {
            block(client.mockBaseURL, YES);
        }
    } else {
        BOOL resolving = [client.requestPipe resolve:request baseURL:client.baseURL];
        if (resolving) {
            block(client.baseURL, NO);
        }
    }
    
    // 处理请求参数
    [client.requestPipe pipe:request];
}

+ (void)_sendRequest:(JFHTTPRequest *)request {
    JFHTTPClient *client = [JFHTTPClient sharedInstance];
    
    AFHTTPSessionManager *session;
    if (request.mock) {
        session = client.mockSession;
    } else {
        session = client.session;
    }
    
    JFHTTPRespSuccessBlock success = [client.responsePipe pipeSuccessForRequest:request];
    JFHTTPRespFailureBlock failure = [client.responsePipe pipeFailureForRequest:request];
    
    if ([request.method.lowercaseString isEqualToString:@"post"]) {
        [session POST:request.api
           parameters:request
             progress:request.progress
              success:success
              failure:failure];
    } else {
        [session GET:request.api
          parameters:request
            progress:request.progress
             success:success
             failure:failure];
    }
}

#pragma mark --
- (instancetype)init {
    if (self = [super init]) {
        [self resetSession];
        [self resetMockSession];
        self.requestPipe = [[_JFHTTPRequestPipe alloc] init];
        self.responsePipe = [[_JFHTTPResponsePipe alloc] init];
    }
    return self;
}

- (void)resetSession {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [[AFHTTPSessionManager alloc] initWithBaseURL:_baseURL sessionConfiguration:config];
    
    self.session.requestSerializer = [AFJSONRequestSerializer serializer];
    [self.session.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    self.session.responseSerializer = [AFJSONResponseSerializer serializer];
    
    self.session.securityPolicy.allowInvalidCertificates = YES;
    self.session.securityPolicy.validatesDomainName = NO;
}

- (void)resetMockSession {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.mockSession = [[AFHTTPSessionManager alloc] initWithBaseURL:_mockBaseURL sessionConfiguration:config];
    
    self.mockSession.requestSerializer = [AFJSONRequestSerializer serializer];
    self.mockSession.responseSerializer = [AFJSONResponseSerializer serializer];
    
    self.mockSession.securityPolicy.allowInvalidCertificates = YES;
    self.mockSession.securityPolicy.validatesDomainName = NO;
}

- (void)setBaseURL:(NSURL *)baseURL {
    if (![_baseURL.absoluteString isEqualToString:baseURL.absoluteString]) {
        _baseURL = baseURL;
    
        [self resetSession];
    }
}

- (void)setMockBaseURL:(NSURL *)mockBaseURL {
    if (![_mockBaseURL.absoluteString isEqualToString:mockBaseURL.absoluteString]) {
        _mockBaseURL = mockBaseURL;
        
        [self resetMockSession];
    }
}

- (void)setUserAgent:(NSString *)userAgent {
    if ([_userAgent isEqualToString:userAgent]) {
        _userAgent = userAgent;
        
        NSString *value = [self.session.requestSerializer valueForHTTPHeaderField:@"User-Agent"];
        value = [value stringByAppendingFormat:@" %@", _userAgent];
        [self.session.requestSerializer setValue:value forHTTPHeaderField:@"User-Agent"];
    }
}

- (void)setAuthType:(NSString *)type {
    self.requestPipe.type = type;
}

- (void)setToken:(NSString *)token {
    self.requestPipe.token = token;
}

- (void)setSskey:(NSString *)sskey {
    self.requestPipe.sskey = sskey;
}

- (void)setDefaultParamsBlock:(NSDictionary *(^)(void))defaultParamsBlock {
    self.requestPipe.defaultParamsBlock = defaultParamsBlock;
}

@end
