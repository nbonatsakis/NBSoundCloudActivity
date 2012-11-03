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

#import "NSString+SoundCloudUI.h"

#import "NSData+SoundCloudUI.h"


@implementation NSData (SoundCloudUI)

- (id)JSONObject;
{
	NSString *jsonString = [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
	id jsonObject = [[jsonString JSONObject] retain];
	[jsonString release];
	return [jsonObject autorelease];
}

- (NSString *)errorMessageFrom422Error;
{
    NSDictionary *result = [self JSONObject];
    if (![result isKindOfClass:[NSDictionary class]]) return nil;
    NSArray *errors = [result objectForKey:@"errors"];
    if (![errors isKindOfClass:[NSArray class]]) return nil;
    if (errors.count == 0) return nil;
    NSDictionary *errorDict = [errors objectAtIndex:0];
    if (![errorDict isKindOfClass:[NSDictionary class]]) return nil;
    NSString *message = [errorDict objectForKey:@"error_message"];
    if (![message isKindOfClass:[NSString class]]) return nil;
    return message;
}

@end
