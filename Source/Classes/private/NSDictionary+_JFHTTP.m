//
//  NSDictionary+JFHTTP.m
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

#import "NSDictionary+_JFHTTP.h"
#import <JFFoundation/NSString+JF.h>

@implementation NSDictionary (_JFHTTP)

- (NSString *)jf_httpgk:(NSString *)ss {

    NSMutableDictionary *allParams = [self mutableCopy];
    NSString *body = self[@"_body"];
    [allParams removeObjectForKey:@"_body"];
    
    NSArray *keysArray = [[allParams allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString * obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSMutableString *encodedParams = [[NSMutableString alloc] init];
    __block NSString *encodedKey = nil;
    __block NSString *encodedValue = nil;
    [keysArray enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL *stop) {
        encodedKey = [obj jf_urlEncode];
        id value = allParams[obj];
        if ([value isKindOfClass:NSDictionary.class] || [value isKindOfClass:NSArray.class]) {
            encodedValue = [NSString jf_stringWithJSONObject:value];
        }
        else {
            encodedValue = [NSString stringWithFormat:@"%@", value];
        }
        // 参数中可能会有&等符号，所以需要先decode一次再encode
        encodedValue = [[encodedValue jf_urlDecode] jf_urlEncode];
        [encodedParams appendFormat:@"&%@=%@", encodedKey, encodedValue];
    }];
    
    [encodedParams appendFormat:@"&%@", ss];
    if (body) {
        [encodedParams appendString:body];
    }
    
    [encodedParams deleteCharactersInRange:NSMakeRange(0, 1)];
    return [[encodedParams jf_md5] uppercaseString];
}

@end
