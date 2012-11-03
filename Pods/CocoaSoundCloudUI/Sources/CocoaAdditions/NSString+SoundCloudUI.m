/*
 * Copyright 2010, 2011 nxtbgthng for SoundCloud Ltd.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 *
 * For more information and documentation refer to
 * http://soundcloud.com/api
 * 
 */

#include <CommonCrypto/CommonDigest.h>

#if TARGET_OS_IPHONE
#import "JSONKit.h"
#else
#import <JSONKit/JSONKit.h>
#endif



#import "NSString+SoundCloudUI.h"


@implementation NSString (SoundCloudUI)


#pragma mark UUID

+ (NSString *)stringWithUUID;
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	
    return [(NSString *)string autorelease];
}

#pragma mark NSTimeInterval

+ (NSString *)stringWithSeconds:(NSTimeInterval)seconds;
{
	return [NSString stringWithMilliseconds:(NSInteger)(seconds * 1000.0)];
}


#pragma mark NSInteger

+ (NSString *)stringWithMilliseconds:(NSInteger)seconds;
{
	seconds = seconds / 1000;
	NSInteger hours = seconds / 60 / 60;
	seconds -= hours * 60 * 60;
	NSInteger minutes = seconds / 60;
	seconds -= minutes * 60;
	
	
	NSMutableString *string = [NSMutableString string];
	
	if (hours > 0) {
		[string appendFormat:@"%u.", hours];
	}
	
	if (minutes >= 10 || hours == 0) {
		[string appendFormat:@"%u.", minutes];
	} else {
		[string appendFormat:@"0%u.", minutes];
	}
	
	if (seconds >= 10) {
		[string appendFormat:@"%u", seconds];
	} else {
		[string appendFormat:@"0%u", seconds];
	}
	
	return string;
}

+ (NSString *)stringWithInteger:(NSInteger)integer upperRange:(NSInteger)upperRange;
{
	if (integer <= upperRange) {
		return [[self class] stringWithFormat:@"%d", integer];
	} else {
		return [[self class] stringWithFormat:@"%d+", upperRange];
	}
}


#pragma mark Whitespace

- (NSArray *)componentsSeparatedByWhitespacePreservingQuotations;
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSMutableArray *result = [NSMutableArray array];
    while (![scanner isAtEnd]) {
        NSString *tag = nil;
        NSString *beginning = [self substringWithRange:NSMakeRange([scanner scanLocation], 1)];
        if ([beginning isEqualToString:@"\""]) {
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanUpToString:@"\"" intoString:&tag];
            [scanner setScanLocation:[scanner scanLocation] + 1];
        } else {
            [scanner scanUpToString:@" " intoString:&tag];
        }
        if (![scanner isAtEnd]) {
            [scanner setScanLocation:[scanner scanLocation] + 1];
        }
        if (tag) [result addObject:tag];
    }
    return result;
}


#pragma mark JSON

- (id)JSONObject;
{
	return [self objectFromJSONString];
}


#pragma mark Escaping

- (NSString *)stringByUnescapingXMLEntities;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *returnValue = [self stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"auml;" withString:@"ä"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&Auml;" withString:@"Ä"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&ouml;" withString:@"ö"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&Ouml;" withString:@"Ö"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&uuml;" withString:@"ü"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&Üuml;" withString:@"Ü"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&szlig;" withString:@"ß"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];	
	
	[returnValue retain];
	[pool release];
	[returnValue autorelease];
	return returnValue;
}

- (NSString *)stringByEscapingXMLEntities;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *returnValue = [self stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"'" withString:@"&#39;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"ä" withString:@"auml;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"Ä" withString:@"&Auml;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"ö" withString:@"&ouml;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"Ö" withString:@"&Ouml;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"ü" withString:@"&uuml;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"Ü" withString:@"&Üuml;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@"ß" withString:@"&szlig;"];
	returnValue = [returnValue stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp;"];	
	
	[returnValue retain];
	[pool release];
	[returnValue autorelease];
	return returnValue;
}

- (NSString *)stringByAddingURLEncoding;
{
	CFStringRef returnValue = CFURLCreateStringByAddingPercentEscapes (kCFAllocatorDefault, //Allocator
																	   (CFStringRef)self, //Original String
																	   NULL, //Characters to leave unescaped
																	   (CFStringRef)@"!*'();:@&=+$,/?%#[]", //Legal Characters to be escaped
																	   kCFStringEncodingUTF8); //Encoding
	return [(NSString *)returnValue autorelease];
}

- (NSString *)stringByRemovingURLEncoding;
{
	CFStringRef returnValue = CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, //Allocator
																		 (CFStringRef)self,
																		 nil);
	return [(NSString *)returnValue autorelease];
}


#pragma mark MD5

- (NSString *)md5Value
{
	//from http://www.tomdalling.com/cocoa/md5-hashes-in-cocoa
	NSData* inputData = [self dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char outputData[CC_MD5_DIGEST_LENGTH];
	CC_MD5([inputData bytes], [inputData length], outputData);
	
	NSMutableString* hashStr = [NSMutableString string];
	int i = 0;
	for (i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
		[hashStr appendFormat:@"%02x", outputData[i]];
	
	return hashStr;
}


#pragma mark Query String Helpers

- (NSDictionary *)dictionaryFromQuery;
{
	NSArray *encodedParameterPairs = [self componentsSeparatedByString:@"&"];
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];
    
    for (NSString *encodedPair in encodedParameterPairs) {
        NSArray *encodedPairElements = [encodedPair componentsSeparatedByString:@"="];
		if (encodedPairElements.count == 2) {
			[requestParameters setValue:[[encodedPairElements objectAtIndex:1] stringByRemovingURLEncoding]
								 forKey:[[encodedPairElements objectAtIndex:0] stringByRemovingURLEncoding]];
		}
    }
	return requestParameters;
}

@end
