//
//  JFDns.m
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

#import "JFDns.h"
#import <HappyDNS/HappyDNS.h>

@interface JFDns ()

@property (nonatomic, strong) QNDnsManager *manager;
@property (nonatomic, strong) NSMutableDictionary *domainBlackList;
@property (nonatomic, strong) NSMutableDictionary *ipWhiteList;
@property (nonatomic, strong) dispatch_queue_t processQueue;

@end

@implementation JFDns

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *dnsResolvers = @[
                [[QNDnspodFree alloc] init],
                [[QNResolver alloc] initWithAddress:@"114.114.114.114"],
                [[QNResolver alloc] initWithAddress:@"223.5.5.5"],
                [QNResolver systemResolver],
        ];
        self.manager = [[QNDnsManager alloc] init:dnsResolvers networkInfo:nil];
        self.processQueue = dispatch_queue_create("com.JF.dns-queue", NULL);

        [self loadCache];
    }
    return self;
}

+ (JFDns *)shared {
    static JFDns  *_dnsManager = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _dnsManager = [[JFDns  alloc] init];
    });
    return _dnsManager;
}

- (void)loadCache {
    NSDictionary *dictionary = [[NSKeyedUnarchiver unarchiveObjectWithFile:self.cachePath] mutableCopy];
    self.domainBlackList = dictionary[@"black_list"];
    self.ipWhiteList = dictionary[@"white_list"];
    if (!self.domainBlackList) {
        self.domainBlackList = [NSMutableDictionary dictionary];
    }
    if (!self.ipWhiteList) {
        self.ipWhiteList = [NSMutableDictionary dictionary];
    }
}

- (NSString *)cachePath {
    NSString *fileName = @"com.JF.dns-cache";
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [directories[0] stringByAppendingPathComponent:fileName];
}

- (BOOL)saveToDisk {
    NSDictionary *dictionary = @{
            @"black_list" : self.domainBlackList,
            @"white_list" : self.ipWhiteList,
    };
    return [NSKeyedArchiver archiveRootObject:dictionary toFile:self.cachePath];
}

- (NSMutableURLRequest *)transformRequest:(NSURLRequest *)req {
    NSMutableURLRequest *request = [req mutableCopy];
    [self transformMutableRequest:request];
    return request;
}

- (void)transformMutableRequest:(NSMutableURLRequest *)req {
    NSString *ip = self.domainBlackList[req.URL.host];

    // 在黑名单，但已有可用 ip 时, 直接用可用 ip 访问
    if (ip.length > 0) {
        NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:req.URL resolvingAgainstBaseURL:YES];
        if (!urlComponents) {
            return;
        }

        urlComponents.host = ip;
        NSURL *transformedURL = urlComponents.URL;

        if (!transformedURL) {
            return;
        }

        [req setValue:req.URL.host forHTTPHeaderField:@"Host"];
        [req setURL:transformedURL];
        return;
    }
    
    // 不在黑名单，则正常请求
}

- (void)invalidateURL:(NSURL *)URL {
    if (URL.host.length > 0) {
        NSMutableArray *domains = self.ipWhiteList[URL.host];
        // domain 存在则 URL.host 为 ip, 说明 ip 不可用，取消该 ip 对应的域名
        if (domains && domains.count > 0) {
            NSMutableArray *tempDomains = [domains mutableCopy];
            [domains removeAllObjects];

            [tempDomains enumerateObjectsUsingBlock:^(NSString *domain, NSUInteger idx, BOOL *stop) {
                self.domainBlackList[domain] = @"";
            }];
            [self saveToDisk];
        } else {
            // domain 不存在则 URL.host 为域名, 将该域名放入黑名单，并获取 ip
//            self.domainBlackList[URL.host] = @"";
//            [self saveToDisk];

            [self resolveURL:URL completion:nil];
        }
    }
}

- (void)resolveURL:(NSURL *)URL completion:(void (^)(NSURL *resolvedURL))completion {
    dispatch_async(self.processQueue, ^{
        // 没有可用 ip 时，请求 ip 并访问
        // 在获取不了 ip 的时候，queryAndReplaceWithIP 会将传入的 URL 返回
        NSURL *transformedURL = [self.manager queryAndReplaceWithIP:URL];
        if (!transformedURL) {
            if (completion) {
                completion(URL);
            }
            return;
        }

        // 找到可用 ip
        if (![transformedURL.host isEqualToString:URL.host]) {
            // 删除旧域名，添加新的
            [self removeDomainFromWhiteList:URL.host];

            self.domainBlackList[URL.host] = transformedURL.host;
            [self addWhiteListIP:transformedURL.host withDomain:URL.host];

            [self saveToDisk];
        }
    });
}

- (void)removeDomainFromWhiteList:(NSString *)domain {
    // clear domain-ip 旧的关联数据，针对相同 domain 连续触发 resolve 的时候，会连续返回两个 ip 的情况
    // 负载均衡同一域名可能会解析成不同的 ip
    NSString *ip = self.domainBlackList[domain];
    if (ip.length > 0) {
        NSMutableArray *domains = self.ipWhiteList[ip];
        NSUInteger index = [domains indexOfObjectPassingTest:^BOOL(NSString *obj, NSUInteger idx, BOOL *stop) {
            if ([obj isEqualToString:domain]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        if (index != NSNotFound) {
            [domains removeObjectAtIndex:index];
        }
    }
}

- (void)addWhiteListIP:(NSString *)ip withDomain:(NSString *)domain {
    // 将新 ip 与 domain 关联
    NSMutableArray *list = self.ipWhiteList[ip];
    if (!list) {
        list = [NSMutableArray array];
    }
    else if (![list isKindOfClass:NSMutableArray.class]) {
        list = [list mutableCopy];
    }

    NSUInteger index = [list indexOfObjectPassingTest:^BOOL(NSString *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqualToString:domain]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (index == NSNotFound) {
        [list addObject:domain];
        self.ipWhiteList[ip] = list;
    }
}

@end
