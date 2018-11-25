# JFHTTP

[![CI Status](https://img.shields.io/travis/jumpingfrog0/JFHTTP.svg?style=flat)](https://travis-ci.org/jumpingfrog0/JFHTTP)
[![Version](https://img.shields.io/cocoapods/v/JFHTTP.svg?style=flat&colorB=blue)](https://cocoapods.org/pods/JFHTTP)
[![License](https://img.shields.io/cocoapods/l/JFHTTP.svg?style=flat)](https://cocoapods.org/pods/JFHTTP)
[![Platform](https://img.shields.io/cocoapods/p/JFHTTP.svg?style=flat)](https://cocoapods.org/pods/JFHTTP)

## TODO

- [ ] pod
- [ ] default AES crypto algorithm
- [ ] custom AES crypto algorithm
- [ ] custom response serilization
- [ ] custom sign

## Requirements

* AFNetworking
* HappyDNS
* JFFoundation

## Usage

Initialize

```objective-c
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
```

Send Request

```objective-c
JFHTTPRequest *request = [[JFHTTPRequest alloc] init];
request.api = @"/users/1";
request.method = @"get";
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
```

## Author

jumpingfrog0, jumpingfrog0@gmail.com

## License

JFHTTP is available under the MIT license. See the LICENSE file for more info.
