//
//  NBSoundCloudActivity.m
//  NBSoundCloudActivity
//
//  Created by Nick Bonatsakis on 10/23/12.
//  Copyright (c) 2012 Atlantia Software. All rights reserved.
//

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
        if ([item isKindOfClass:[AVURLAsset class]]) {
            AVURLAsset* asset = (AVURLAsset*) item;
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
        if ([item isKindOfClass:[AVURLAsset class]]) {
            self.asset = item;
            return;
        }
    }
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
