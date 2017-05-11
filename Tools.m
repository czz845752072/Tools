//
//  Tools.m
//
//  Created by Chuzhaozhi on 16/7/12.
//  Copyright © 2016年 Chuzhaozhi. All rights reserved.
//

#import "Tools.h"
#import <CommonCrypto/CommonCrypto.h>
#import "GHNSData+Base64.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

#define StringFormat(str,value) [NSString stringWithFormat:str,value]

@implementation Tools

+ (NSString *)deleteWhitespace:(NSString *)str{
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (CGSize)caculateSizeWithFont:(UIFont *)font maxWidth:(float)maxWidth maxHeight:(float)maxHeight withStr:(NSString *)str{
    CGSize size;
    if ([str respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        size=[str boundingRectWithSize:CGSizeMake(maxWidth, maxHeight) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
    }
    //    //由于支持到 iOS7+，因此该方法注释
    //    else{//为ios6做的准备
    //        size=[self sizeWithFont:font constrainedToSize:CGSizeMake(maxWidth, maxHeight) lineBreakMode:NSLineBreakByCharWrapping];
    //    }
    return size;
}

+ (NSString *)getCurrentStrIncludeUrlLink:(NSString *)str{
    NSString *urlStr;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *linkMatchArr = [detector matchesInString:self options:0 range:NSMakeRange(0, [str length])];
    for (NSTextCheckingResult *result in linkMatchArr) {
        if ([result resultType] == NSTextCheckingTypeLink) {
            NSURL *url = [result URL];
            urlStr=url.absoluteString;
        }
    }
    return urlStr;
    
}

+ (BOOL)inputStrRuleIsneed:(NSString *)str{
    NSString *regex = @"^[\u4e00-\u9fa5a-zA-Z0-9]+$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:self]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isHasEmobj:(NSString *)str{
    __block BOOL result=NO;
    [str enumerateSubstringsInRange:NSMakeRange(0, str.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if (substring.length>1) {
            result=YES;
            *stop=YES;
        }
    }];
    return result;
}

#pragma mark - check Dictionary is contain key
+(BOOL)dicContain:(NSDictionary *)dic withKey:(NSString *)key{
    
    if(![dic isKindOfClass:[NSDictionary class]]){
        return NO;
    }
    
    if(nil == dic[key]){
        return NO;
    }
    return ![Tools isEmpty:dic[key]];
}

#pragma mark - check String is Empty
+ (BOOL)isEmpty:(NSString *)string
{
    if (![string isKindOfClass:[NSString class]])
        string = [string description];
    if (string == nil || string == NULL)
        return YES;
    if ([string isKindOfClass:[NSNull class]])
        return YES;
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]==0)
        return YES;
    if ([string isEqualToString:@"(null)"])
        return YES;
    if ([string isEqualToString:@"(null)(null)"])
        return YES;
    if ([string isEqualToString:@"<null>"])
        return YES;
    
    // return Default
    return NO;
}

+(NSString*)md5Base64:(NSString*)originalStr{
    
    const char *cStr = [originalStr UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    return [NSData gh_base64EncodeWithBytes:digest length:CC_MD5_DIGEST_LENGTH];
    
}

#pragma mark -md5
+ (NSString *)md5:(NSString *)originalStr
{
    
    const char *cStr = [originalStr UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [result appendFormat:@"%02x", digest[i]];
    
    result = [[result uppercaseString] mutableCopy];
    return result;
}

+(NSString*)base64:(NSString *)originalStr{
    
    NSData *nsdata = [originalStr dataUsingEncoding:NSUTF8StringEncoding];
    
    return [nsdata gh_base64];
    
}

#pragma mark -calculate CharacterLength
+ (NSUInteger)calculateCharacterLength:(NSString *)str
{
    // apply a via to accept characterLength
    NSUInteger asciiLength = 0;
    // RunLoop to get Length
    for (NSUInteger i = 0; i < [str length]; i++)
    {
        unichar uc   = [str characterAtIndex:i];
        asciiLength += isascii(uc) ? 1 : 2;
    }
    // return
    return asciiLength;
}

+ (BOOL)stringContainsEmoji:(NSString *)string
{
    __block BOOL returnValue = NO;
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                const unichar hs = [substring characterAtIndex:0];
                                if (0xd800 <= hs && hs <= 0xdbff) {
                                    if (substring.length > 1) {
                                        const unichar ls = [substring characterAtIndex:1];
                                        const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                                        if (0x1d000 <= uc && uc <= 0x1f77f) {
                                            returnValue = YES;
                                        }
                                    }
                                } else if (substring.length > 1) {
                                    const unichar ls = [substring characterAtIndex:1];
                                    if (ls == 0x20e3) {
                                        returnValue = YES;
                                    }
                                } else {
                                    if (0x2100 <= hs && hs <= 0x27ff) {
                                        returnValue = YES;
                                    } else if (0x2B05 <= hs && hs <= 0x2b07) {
                                        returnValue = YES;
                                    } else if (0x2934 <= hs && hs <= 0x2935) {
                                        returnValue = YES;
                                    } else if (0x3297 <= hs && hs <= 0x3299) {
                                        returnValue = YES;
                                    } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                                        returnValue = YES;
                                    }
                                }
                            }];
    
    return returnValue;
}


#pragma -- 正则监测邮箱

+ (BOOL)checkEmail:(NSString *)email{
    
    NSString *emailRegex = @"[\\w!#$%&'*+/=?^_`{|}~-]+(?:\\.[\\w!#$%&'*+/=?^_`{|}~-]+)*@(?:[\\w](?:[\\w-]*[\\w])?\\.)+[\\w](?:[\\w-]*[\\w])?";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    BOOL isMatch = [emailPredicate evaluateWithObject:email];
    
    return isMatch;
    
}

#pragma -- 正则检测密码
+ (BOOL)checkPassword:(NSString *)password
{
    NSString *passWordRegex = @"/^[^\\s]{8,16}$/";
    NSPredicate *passWordPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passWordRegex];
    
    BOOL isMatch = [passWordPredicate evaluateWithObject:password];
    
    if (!isMatch) {
        return NO;
    }
    
    return YES;
}

#pragma -- 正则检测手机号
+ (BOOL)checkPhone:(NSString *)phone
{
    
    NSString *regex = @"^1[3,4,5,8,7][0-9]{9}$";
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    BOOL isMatch = [pred evaluateWithObject:phone];
    
    return isMatch;
    
}
#pragma -- 正则检测价格
+ (BOOL)checkPrice:(NSString*)price{
    
    NSString *regex = @"^(0|[1-9][0-9]{0,3})(\\.[0-9]{1,2})?$";
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    BOOL isMatch = [pred evaluateWithObject:price];
    
    return isMatch;
    
}

#pragma -- 正则检测价格
+ (BOOL)checkPriceNoLimit:(NSString*)price withLength:(NSInteger)length{
    
    NSString *regex = StringFormat(@"^(0|[1-9][0-9]{0,%ld})(\\.[0-9]{1,2})?$", (long)length) ;
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    BOOL isMatch = [pred evaluateWithObject:price];
    
    return isMatch;
    
}

+(BOOL)checkIdentityCardNo:(NSString*)cardNo
{
    if (cardNo.length != 18) {
        return  NO;
    }
    NSArray* codeArray = [NSArray arrayWithObjects:@"7",@"9",@"10",@"5",@"8",@"4",@"2",@"1",@"6",@"3",@"7",@"9",@"10",@"5",@"8",@"4",@"2", nil];
    NSDictionary* checkCodeDic = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"1",@"0",@"X",@"9",@"8",@"7",@"6",@"5",@"4",@"3",@"2", nil]  forKeys:[NSArray arrayWithObjects:@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10", nil]];
    
    NSScanner* scan = [NSScanner scannerWithString:[cardNo substringToIndex:17]];
    
    int val;
    BOOL isNum = [scan scanInt:&val] && [scan isAtEnd];
    if (!isNum) {
        return NO;
    }
    int sumValue = 0;
    
    for (int i =0; i<17; i++) {
        sumValue+=[[cardNo substringWithRange:NSMakeRange(i , 1) ] intValue]* [[codeArray objectAtIndex:i] intValue];
    }
    
    NSString* strlast = [checkCodeDic objectForKey:[NSString stringWithFormat:@"%d",sumValue%11]];
    
    if ([strlast isEqualToString: [[cardNo substringWithRange:NSMakeRange(17, 1)]uppercaseString]]) {
        return YES;
    }
    return  NO;
}

#pragma mark -- 16进制颜色值转化 rgb
+ (UIColor *) colorWithHexString: (NSString *) stringToConvert
{
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 charactersif ([cString length] < 6) return [UIColor blackColor];
    // strip 0X if it appearsif ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    if ([cString length] != 6) return [UIColor blackColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    // Scan values
    unsigned int r, g, b;
    
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:0.6f];
}

+ (NSString *)checkImgTypeWithata: (NSData *)data{
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"jpeg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
        case 0x52:
            if ([data length] < 12) {
                return nil;
            }
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return @"webp";
            }
            return nil;
    }
    return nil;
}

//根据身份证号获取生日
+(NSString *)birthdayStrFromIdentityCard:(NSString *)numberStr
{
    NSMutableString *result = [NSMutableString stringWithCapacity:0];
    NSString *year = nil;
    NSString *month = nil;
    
    BOOL isAllNumber = YES;
    NSString *day = nil;
    if([numberStr length]<14)
        return result;
    
    //**截取前14位
    NSString *fontNumer = [numberStr substringWithRange:NSMakeRange(0, 13)];
    
    //**检测前14位否全都是数字;
    const char *str = [fontNumer UTF8String];
    const char *p = str;
    while (*p!='\0') {
        if(!(*p>='0'&&*p<='9'))
            isAllNumber = NO;
        p++;
    }
    if(!isAllNumber)
        return result;
    
    year = [numberStr substringWithRange:NSMakeRange(6, 4)];
    month = [numberStr substringWithRange:NSMakeRange(10, 2)];
    day = [numberStr substringWithRange:NSMakeRange(12,2)];
    
    [result appendString:year];
    [result appendString:@"-"];
    [result appendString:month];
    [result appendString:@"-"];
    [result appendString:day];
    return result;
}
//根据身份证号性别
+(BOOL)getIdentityCardSex:(NSString *)numberStr
{
    int sexInt=[[numberStr substringWithRange:NSMakeRange(16,1)] intValue];
    
    if(sexInt%2!=0)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

#pragma mark - 获取设备当前网络IP地址
+ (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         //筛选出IP地址格式
         if([self isValidatIP:address]) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

+ (BOOL)isValidatIP:(NSString *)ipAddress {
    if (ipAddress.length == 0) {
        return NO;
    }
    NSString *urlRegEx = @"^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:urlRegEx options:0 error:&error];
    
    if (regex != nil) {
        NSTextCheckingResult *firstMatch=[regex firstMatchInString:ipAddress options:0 range:NSMakeRange(0, [ipAddress length])];
        
        if (firstMatch) {
            NSRange resultRange = [firstMatch rangeAtIndex:0];
            NSString *result=[ipAddress substringWithRange:resultRange];
            //输出结果
            NSLog(@"%@",result);
            return YES;
        }
    }
    return NO;
}

+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

+(NSString *)getCurrentNetIp{
    NSString  *address = @"error";
    struct  ifaddrs *interfaces = NULL;
    struct  ifaddrs *temp_addr = NULL;
    int  success = 0;
    success = getifaddrs(&interfaces);
    if(success==0){
        temp_addr = interfaces;
        while (temp_addr !=NULL ) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
    
}
/**
 *  check if user allow local notification of system setting
 *
 *  @return YES-allowed,otherwise,NO.
 */
+ (BOOL)isAllowedNotification {
    //iOS8 check if user allow notification
    if ([Tools isSystemVersioniOS8]) {// system is iOS8
        UIUserNotificationSettings *setting = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (UIUserNotificationTypeNone != setting.types) {
            return YES;
        }
    } else {//iOS7
        UIRemoteNotificationType type = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if(UIRemoteNotificationTypeNone != type)
            return YES;
    }
    
    return NO;
}

/**
 *  check if the system version is iOS8
 *
 *  @return YES-is iOS8,otherwise,below iOS8
 */
+ (BOOL)isSystemVersioniOS8 {
    //check systemVerson of device
    UIDevice *device = [UIDevice currentDevice];
    float sysVersion = [device.systemVersion floatValue];
    
    if (sysVersion >= 8.0f) {
        return YES;
    }
    return NO;
}

@end
