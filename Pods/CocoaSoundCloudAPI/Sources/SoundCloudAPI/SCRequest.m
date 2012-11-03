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
#import "SCConstants.h"

#import "SCRequest.h"

@interface SCRequest ()
@property (nonatomic, retain) NXOAuth2Request *oauthRequest;
@end

@implementation SCRequest

#pragma mark Class Methods

+ (id)   performMethod:(SCRequestMethod)aMethod
            onResource:(NSURL *)aResource
       usingParameters:(NSDictionary *)someParameters
           withAccount:(SCAccount *)anAccount
sendingProgressHandler:(SCRequestSendingProgressHandler)aProgressHandler
       responseHandler:(SCRequestResponseHandler)aResponseHandler;
{
    NSString *theMethod;
    switch (aMethod) {
        case SCRequestMethodPOST:
            theMethod = @"POST";
            break;
            
        case SCRequestMethodPUT:
            theMethod = @"PUT";
            break;
            
        case SCRequestMethodDELETE:
            theMethod = @"DELETE";
            break;
            
        case SCRequestMethodHEAD:
            theMethod = @"HEAD";
            break;
            
        default:
            theMethod = @"GET";
            break;
    }
    
    NSAssert1([[aResource scheme] isEqualToString:@"https"], @"Resource '%@' is invalid because the scheme is not 'https'.", aResource);
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:aResource method:theMethod parameters:someParameters];
    request.account = anAccount.oauthAccount;
    [request performRequestWithSendingProgressHandler:aProgressHandler
                                      responseHandler:aResponseHandler];
    return [request autorelease];
}

+ (void)cancelRequest:(id)request;
{
    if ([request isKindOfClass:[NXOAuth2Request class]] ||
        [request isKindOfClass:[SCRequest class]]) {
        [request cancel];
    }
}


#pragma mark Lifecycle

- (id)init;
{
    NSAssert(NO, @"Please use the designated initializer");
    return nil;
}

- (id)initWithMethod:(SCRequestMethod)aMethod resource:(NSURL *)aResource;
{
    self = [super init];
    if (self) {
        
        NSString *theMethod;
        switch (aMethod) {
            case SCRequestMethodPOST:
                theMethod = @"POST";
                break;
                
            case SCRequestMethodPUT:
                theMethod = @"PUT";
                break;
                
            case SCRequestMethodDELETE:
                theMethod = @"DELETE";
                break;
                
            case SCRequestMethodHEAD:
                theMethod = @"HEAD";
                break;
                
            default:
                theMethod = @"GET";
                break;
        }
        
        oauthRequest = [[NXOAuth2Request alloc] initWithResource:aResource method:theMethod parameters:nil];
    }
    return self;
}


#pragma mark Accessors

@synthesize oauthRequest;

- (SCAccount *)account;
{
    if (self.oauthRequest.account) {
        return [[[SCAccount alloc] initWithOAuthAccount:self.oauthRequest.account] autorelease];
    } else {
        return nil;
    }
}

- (void)setAccount:(SCAccount *)account;
{
    self.oauthRequest.account = account.oauthAccount;
}

- (SCRequestMethod)requestMethod;
{
    NSString *aMethod = self.oauthRequest.requestMethod;
    
    if ([aMethod caseInsensitiveCompare:@"POST"]) {
        return SCRequestMethodPOST;
    } else if ([aMethod caseInsensitiveCompare:@"PUT"]) {
        return SCRequestMethodPUT;
    } else if ([aMethod caseInsensitiveCompare:@"DELETE"]) {
        return SCRequestMethodDELETE;
    } else if ([aMethod caseInsensitiveCompare:@"HEAD"]) {
        return SCRequestMethodHEAD;
    } else {
        NSAssert1([aMethod caseInsensitiveCompare:@"GET"], @"SCRequest only supports 'GET', 'PUT', 'POST' and 'DELETE' as request method. Underlying NXOAuth2Accound uses the request method 'l%'.", aMethod);
        return SCRequestMethodGET;
    }
}

- (void)setRequestMethod:(SCRequestMethod)requestMethod;
{
    NSString *theMethod;
    switch (requestMethod) {
        case SCRequestMethodPOST:
            theMethod = @"POST";
            break;
            
        case SCRequestMethodPUT:
            theMethod = @"PUT";
            break;
            
        case SCRequestMethodDELETE:
            theMethod = @"DELETE";
            break;
            
        case SCRequestMethodHEAD:
            theMethod = @"HEAD";
            break;
            
        default:
            theMethod = @"GET";
            break;
    }
    self.oauthRequest.requestMethod = theMethod;
}

- (NSURL *)resource;
{
    return self.oauthRequest.resource;
}

- (void)setResource:(NSURL *)resource;
{
    self.oauthRequest.resource = resource;
}

- (NSDictionary *)parameters;
{
    return self.oauthRequest.parameters;
}

- (void)setParameters:(NSDictionary *)parameters;
{
    self.oauthRequest.parameters = parameters;
}


#pragma mark Signed NSURLRequest

- (NSURLRequest *)signedURLRequest;
{
    return [self.oauthRequest signedURLRequest];
}


#pragma mark Perform Request

- (void)performRequestWithSendingProgressHandler:(SCRequestSendingProgressHandler)aSendingProgressHandler
                                 responseHandler:(SCRequestResponseHandler)aResponseHandler;
{
    [self.oauthRequest performRequestWithSendingProgressHandler:aSendingProgressHandler
                                                responseHandler:aResponseHandler];
}

- (void)cancel;
{
    [self.oauthRequest cancel];
}

@end
