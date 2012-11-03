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

#import "SCSoundCloud.h"
#import "SCSoundCloud+Private.h"
#import "SCConstants.h"
#import "SCBundle.h"

#import "SCLoginView.h"


@interface SCLoginView () <UIWebViewDelegate>
@property (nonatomic, readwrite, assign) UIWebView *webView;
@property (nonatomic, readwrite, assign) UIActivityIndicatorView *activityIndicator;
- (void)commonAwake;
@end

@implementation SCLoginView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonAwake];
    }
    return self;
}

- (void)commonAwake;
{    
    self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
    self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	self.activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin |UIViewAutoresizingFlexibleBottomMargin);
	self.activityIndicator.hidesWhenStopped = YES;
	[self addSubview:self.activityIndicator];
 
    self.webView = [[[UIWebView alloc] initWithFrame:self.bounds] autorelease];
    self.webView.delegate = self;
    self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.webView.backgroundColor = nil;
    self.webView.opaque = NO;
    [self addSubview:self.webView];
    
    self.backgroundColor = [UIColor colorWithPatternImage:[SCBundle imageWithName:@"darkTexturedBackgroundPattern"]];
}

- (void)dealloc;
{
    [super dealloc];
}

#pragma mark View

- (void)layoutSubviews;
{
    self.webView.frame = self.bounds;
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

#pragma mark Accessors

@synthesize delegate;
@synthesize webView;
@synthesize activityIndicator;

- (void)loadURL:(NSURL *)anURL;
{
    // WORKAROUD: Remove all Cookies to enable the use of facebook user accounts
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    NSURL *URLToOpen = [NSURL URLWithString:[[anURL absoluteString] stringByAppendingString:@"&display_bar=false"]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:URLToOpen]];
}

#pragma mark WebView Delegate

- (void)webViewDidStartLoad:(UIWebView *)webView;
{
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    [self.activityIndicator stopAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{    
    switch (navigationType) {
        case UIWebViewNavigationTypeLinkClicked:
        {
            [[UIApplication sharedApplication] openURL:request.URL];
            return NO;
        }
            
        default:
        {
            if ([SCSoundCloud handleRedirectURL:request.URL]) {
                return NO;
            }
            return YES;
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
{
    if ([[error domain] isEqualToString:NSURLErrorDomain]) {
        
        if ([error code] == NSURLErrorCancelled)
            return;
        
    } else if ([[error domain] isEqualToString:@"WebKitErrorDomain"]) {
        
        if ([error code] == 101)
            return;
        
        if ([error code] == 102)
            return;
    }
    
    if ([self.delegate respondsToSelector:@selector(loginView:didFailWithError:)]) {
        [self.delegate loginView:self didFailWithError:error];
    }
}

@end
