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

#import "SCAccount.h"
#import "SCAccount+Private.h"
#import "SCRequest.h"
#import "SCConstants.h"

#import "SCSoundCloud+Private.h"
#import "SCSoundCloud.h"


#pragma mark Notifications

NSString * const SCSoundCloudAccountsDidChangeNotification = @"SCSoundCloudAccountsDidChangeNotification";
NSString * const SCSoundCloudAccountDidChangeNotification = @"SCSoundCloudAccountDidChangeNotification";
NSString * const SCSoundCloudDidFailToRequestAccessNotification = @"SCSoundCloudDidFailToRequestAccessNotification";

#pragma mark -


@interface SCSoundCloud ()

#pragma mark Notification Observer
- (void)accountStoreAccountsDidChange:(NSNotification *)aNotification;
- (void)accountStoreDidFailToRequestAccess:(NSNotification *)aNotification;
- (void)accountDidFailToGetAccessToken:(NSNotification *)aNotification;
@end

@implementation SCSoundCloud

+ (void)initialize;
{
    [SCSoundCloud shared];
}

- (id)init;
{
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountStoreAccountsDidChange:)
                                                     name:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountStoreDidFailToRequestAccess:)
                                                     name:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidFailToGetAccessToken:)
                                                     name:NXOAuth2AccountDidFailToGetAccessTokenNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark Accessors

+ (SCAccount *)account;
{    
    NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:kSCAccountType];
    if ([oauthAccounts count] > 0) {
        return [[[SCAccount alloc] initWithOAuthAccount:[oauthAccounts objectAtIndex:0]] autorelease];
    } else {
        return nil;
    }
}


#pragma mark Manage Accounts

+ (void)requestAccessWithPreparedAuthorizationURLHandler:(SCPreparedAuthorizationURLHandler)aPreparedAuthorizationURLHandler;
{
    [self removeAccess];
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:kSCAccountType
                                   withPreparedAuthorizationURLHandler:(SCPreparedAuthorizationURLHandler)aPreparedAuthorizationURLHandler];
}

+ (void)removeAccess;
{
    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:kSCAccountType];
    for (NXOAuth2Account *account in accounts) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];        
    }
}


#pragma mark Configuration

+ (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
        redirectURL:(NSURL *)aRedirectURL;
{
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    
    [config setObject:aClientID forKey:kNXOAuth2AccountStoreConfigurationClientID];
    [config setObject:aSecret forKey:kNXOAuth2AccountStoreConfigurationSecret];
    [config setObject:aRedirectURL forKey:kNXOAuth2AccountStoreConfigurationRedirectURL];

    [config setObject:[NSURL URLWithString:kSCSoundCloudAuthURL] forKey:kNXOAuth2AccountStoreConfigurationAuthorizeURL];
    [config setObject:[NSURL URLWithString:kSCSoundCloudAccessTokenURL] forKey:kNXOAuth2AccountStoreConfigurationTokenURL];
    [config setObject:[NSURL URLWithString:kSCSoundCloudAPIURL] forKey:kSCConfigurationAPIURL];
    
    [[NXOAuth2AccountStore sharedStore] setConfiguration:config forAccountType:kSCAccountType];
}


#pragma mark OAuth2 Flow

+ (BOOL)handleRedirectURL:(NSURL *)URL;
{
    return [[NXOAuth2AccountStore sharedStore] handleRedirectURL:URL];
}

#pragma mark Notification Observer

- (void)accountStoreAccountsDidChange:(NSNotification *)aNotification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SCSoundCloudAccountDidChangeNotification
                                                        object:self];
}

- (void)accountStoreDidFailToRequestAccess:(NSNotification *)aNotification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SCSoundCloudDidFailToRequestAccessNotification
                                                        object:self
                                                      userInfo:aNotification.userInfo];
}

- (void)accountDidFailToGetAccessToken:(NSNotification *)aNotification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SCAccountDidFailToGetAccessToken
                                                        object:aNotification.object];
}

@end
