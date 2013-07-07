//
//  NBSoundCloudActivity.m
//  NBSoundCloudActivity
//
//  Created by Nick Bonatsakis on 10/23/12.
//  Copyright (c) 2012 Atlantia Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "NBSoundCloudActivity.h"
#import "SCSoundCloud.h"
#import "SCUI.h"
#import "SCShareViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface NBSoundCloudActivity ()

@property (nonatomic, strong) AVURLAsset* asset;

+ (Class) soundCloudClass;

@end

@implementation NBSoundCloudActivity

- (id) initWithClientId:(NSString*)clientId secret:(NSString*)secret redirectURL:(NSURL*)redirectURL
{
    self = [super init];
    if (self) {
        [[[self class] soundCloudClass] setClientID:clientId
                           secret:secret
                      redirectURL:redirectURL];
    }
    return self;
}

+ (Class) soundCloudClass
{
    return [SCSoundCloud class];
}

- (NSString*) activityType
{
    return @"SoundCloud";
}

- (NSString*) activityTitle
{
    return @"SoundCloud";
}

- (UIImage*) activityImage
{
    return [UIImage imageNamed:@"soundcloud_activity"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    // make sure we have an instance of AVURLAsset that contains an audio track. 
    for (id item in activityItems) {
        AVURLAsset *asset = [self assetFromObject:item];
        if (asset) {
            NSArray* audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            if ([audioTracks count] > 0) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (void) prepareWithActivityItems:(NSArray *)activityItems
{
    // fetch the instance of AVURLAsset and store it for use when constructing the activityViewController.
    for (id item in activityItems) {
        AVURLAsset *asset = [self assetFromObject:item];
        if (asset) {
            self.asset = asset;
        }
    }
}

- (AVURLAsset *)assetFromObject:(id)object
{
    if ([object isKindOfClass:[AVURLAsset class]]) {
        return (AVURLAsset *)object;
    }

    if ([object isKindOfClass:[NSURL class]]) {
        return [AVURLAsset assetWithURL:(NSURL *)object];
    }

    return nil;
}

- (UIViewController*) activityViewController
{
    NSURL *trackURL = self.asset.URL;
    
    SCShareViewController* shareViewController = [self createSCShareViewController:trackURL];
    
    if (self.foursquareClientId && self.foursquareClientSecret) {
        [shareViewController setFoursquareClientID:self.foursquareClientId
                                      clientSecret:self.foursquareClientSecret];
    }
    
    [shareViewController setTitle:self.title];
    [shareViewController setPrivate:self.isPrivate];
    
    return shareViewController;
}

- (SCShareViewController*) createSCShareViewController:(NSURL*)trackURL
{
    return [SCShareViewController shareViewControllerWithFileURL:trackURL
                                        completionHandler:^(NSDictionary *trackInfo, NSError *error){
                                            [self handleSCShareViewCompletion:trackInfo error:error];
                                        }];
}

- (void) handleSCShareViewCompletion:(NSDictionary*)trackInfo error:(NSError*)error
{
    if (SC_CANCELED(error)) {
        [self activityDidFinish:NO];
        if (self.completionBlock) {
            self.completionBlock(YES, nil, error);
        }
    } else if (error) {
        [self activityDidFinish:NO];
        if (self.completionBlock) {
            self.completionBlock(NO, nil, error);
        }
    } else {
        [self activityDidFinish:YES];
        if (self.completionBlock) {
            self.completionBlock(NO, trackInfo, error);
        }
    }
}

@end
