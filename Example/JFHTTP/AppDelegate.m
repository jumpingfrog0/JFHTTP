//
//  AppDelegate.m
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

#import "AppDelegate.h"
#import <JFHTTP/JFHTTP.h>
#import <JFUIKit/JFUIKit.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    JFHTTPClient *client = [JFHTTPClient sharedInstance];
    client.baseURL = [NSURL URLWithString:@"https://easy-mock.com/mock/5a151fd5b2301a1fb73f74f6/example"];
    client.mockBaseURL = [NSURL URLWithString:@"https://easy-mock.com/mock/5a151fd5b2301a1fb73f74f6/example"];
    client.userAgent = @"JFHTTP/1.0";
    client.authType = @"JFHTTP.example";
    client.sskey = @"test-sskey";
    client.defaultParamsBlock = ^NSDictionary *{
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"device_mod_"] = @((NSInteger)[[NSDate date] timeIntervalSince1970]);
        params[@"device_platform_"] = @"ios";
        params[@"device_ver_"] = [[UIDevice currentDevice] systemVersion];
        params[@"app_ver_"] = [UIDevice jf_appVersion];
        return params;
    };
    [JFHTTPClient enableLog:YES];
    [JFHTTPClient allowNotifyTaskDetail:YES];
    
    [self testGetRequest];
    [self testPostRequest];
    
    return YES;
}

- (void)testGetRequest {
    JFHTTPRequest *request = [[JFHTTPRequest alloc] init];
    request.api = @"/users/1";
    request.mock = YES;
    request.sign = NO;
    request.params = @{
        @"uid": @"1",
    };
    
    request.success = ^(NSDictionary *response) {
        // you can convert json to model here.
        NSLog(@"%@", response);
    };
    request.failure = ^(NSError *error) {
        NSLog(@"%@", error);
    };
    
    [JFHTTPClient send:request];
}

- (void)testPostRequest {
    JFHTTPRequest *request = [[JFHTTPRequest alloc] init];
    request.api = @"/user/new";
    request.sign = NO;
    request.method = @"post";
    request.params = @{
        @"test": @"test",
    };
    
    request.success = ^(NSDictionary *response) {
        // you can convert json to model here.
        NSLog(@"%@", response);
    };
    request.failure = ^(NSError *error) {
        NSLog(@"%@", error);
    };
    
    [JFHTTPClient send:request];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
