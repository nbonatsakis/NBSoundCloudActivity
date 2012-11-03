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

#if TARGET_OS_IPHONE
#import "NXOAuth2.h"
#else
#import <OAuth2Client/NXOAuth2.h>
#endif

#import "SCSoundCloud.h"
#import "SCRequest.h"
#import "SCConstants.h"

#import "SCAccount+Private.h"

#pragma mark Notifications

NSString * const SCAccountDidChangeUserInfo = @"SCAccountDidChangeUserInfo";

#pragma mark -

@implementation SCAccount (Private)

- (id)initWithOAuthAccount:(NXOAuth2Account *)anAccount;
{
    self = [super init];
    if (self) {
        oauthAccount = [anAccount retain];
    }
    return self;
}

- (NXOAuth2Account *)oauthAccount;
{
    return oauthAccount;
}

- (void)setOauthAccount:(NXOAuth2Account *)anOAuthAccount;
{
    [anOAuthAccount retain];
    [oauthAccount release];
    oauthAccount = anOAuthAccount;
}

- (NSDictionary *)userInfo;
{
    return (NSDictionary *)self.oauthAccount.userData;
}

- (void)setUserInfo:(NSDictionary *)userInfo;
{
    self.oauthAccount.userData = userInfo;
}

@end
