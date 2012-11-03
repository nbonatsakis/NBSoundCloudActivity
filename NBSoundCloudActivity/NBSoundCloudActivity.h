//
//  NBSoundCloudActivity.h
//  NBSoundCloudActivity
//
//  Created by Nick Bonatsakis on 10/23/12.
//  Copyright (c) 2012 Atlantia Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^NBSoundCloudActivityBlock)(BOOL canceled, NSDictionary* trackInfo, NSError* error);

@interface NBSoundCloudActivity : UIActivity

- (id) initWithClientId:(NSString*)clientId secret:(NSString*)secret redirectURL:(NSURL*)redirectURL;

@property (nonatomic, copy) NBSoundCloudActivityBlock completionBlock;
@property (nonatomic, copy) NSString* foursquareClientId;
@property (nonatomic, copy) NSString* foursquareClientSecret;
@property (nonatomic, copy) NSString* title;
@property (nonatomic) BOOL isPrivate;

@end
