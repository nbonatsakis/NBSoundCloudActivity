//
//  ViewController.m
//  NBSoundCloudActivity
//
//  Created by nbonatsakis on 10/23/12.
//  Copyright (c) 2012 Atlantia Software. All rights reserved.
//

#import "ViewController.h"
#import "NBSoundCloudActivity.h"
#import <AVFoundation/AVFoundation.h>

#define kSoundCloudClientId @"1cad14bf97b98769a495713448f669b4"
#define kSoundCloudClientSecret @"86886ad2b60e3a2ce656ef8e37c83235"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)shareAudioTouched:(id)sender
{
    NSURL* sampleURL = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"caf"];
    AVURLAsset* asset = [AVURLAsset assetWithURL:sampleURL];
    
    NBSoundCloudActivity* scActivity = [[NBSoundCloudActivity alloc] initWithClientId:kSoundCloudClientId secret:kSoundCloudClientSecret
                                                                          redirectURL:[NSURL URLWithString:@"simplemic://soundcloudlogin"]];
    
    UIActivityViewController* avc = [[UIActivityViewController alloc] initWithActivityItems:@[asset]
                                                                      applicationActivities:@[scActivity]];
    avc.excludedActivityTypes = @[ UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeCopyToPasteboard ];
    [self presentViewController:avc animated:YES completion:nil];
}

@end
