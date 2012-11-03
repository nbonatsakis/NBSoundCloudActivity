//
//  SCSoundCloudAPI-Private.h
//  SoundCloudAPI
//
//  Created by Ullrich Schäfer on 05.01.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "SCSoundCloudAPI.h"
#else
#import <SoundCloudAPI/SCSoundCloudAPI.h>
#endif


@class SCSoundCloudAPIAuthentication;


@interface SCSoundCloudAPI (Private)

@property (nonatomic, readonly) SCSoundCloudAPIAuthentication *authentication;

@end
