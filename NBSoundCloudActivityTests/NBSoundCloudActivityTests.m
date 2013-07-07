//
//  NBSoundCloudActivityTests.m
//  NBSoundCloudActivityTests
//
//  Created by nbonatsakis on 10/23/12.
//  Copyright (c) 2012 Atlantia Software. All rights reserved.
//

#import "NBSoundCloudActivityTests.h"
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#import "NBSoundCloudActivity.h"
#import "SCSoundCloud.h"
#import "SCUI.h"
#import <AVFoundation/AVFoundation.h>

#define kSCId @"testId"
#define kSCSecret @"testSecret"
#define kRefUrl @"tests://foo"

@interface NBSoundCloudActivity (ExposePublic)
- (void) handleSCShareViewCompletion:(NSDictionary*)trackInfo error:(NSError*)error;
@end

@interface TestingNBSoundCloudActivity : NBSoundCloudActivity
+ (Class) soundCloudClass;
+ (void) resetSCClassMock;
- (SCShareViewController*) createSCShareViewController:(NSURL*)trackURL;
@property (nonatomic, strong) AVURLAsset* asset;
@property (nonatomic, strong) SCShareViewController* svcMock;
@property (nonatomic) BOOL activityFinished;
@end

@implementation TestingNBSoundCloudActivity

static Class mockSC;

+ (void) resetSCClassMock
{
    mockSC = mockClass([SCSoundCloud class]);
}

+ (Class) soundCloudClass
{
    return mockSC;
}

- (SCShareViewController*) createSCShareViewController:(NSURL*)trackURL
{
    self.svcMock = mock([SCShareViewController class]);
    return self.svcMock;
}

- (void) activityDidFinish:(BOOL)completed
{
    self.activityFinished = completed;
}

@end

@interface NBSoundCloudActivityTests ()

@property (nonatomic, strong) TestingNBSoundCloudActivity* activity;

@end

@implementation NBSoundCloudActivityTests

- (void)setUp
{
    [super setUp];
    [TestingNBSoundCloudActivity resetSCClassMock];
    self.activity = [[TestingNBSoundCloudActivity alloc] initWithClientId:kSCId secret:kSCSecret redirectURL:[NSURL URLWithString:kRefUrl]];
}

- (void)tearDown
{
    self.activity = nil;
    
    [super tearDown];
}

- (void) testInit
{
    Class scClassMock = [TestingNBSoundCloudActivity soundCloudClass];
    [verify(scClassMock) setClientID:kSCId
                              secret:kSCSecret
                         redirectURL:[NSURL URLWithString:kRefUrl]];
}

- (void) testCanPerformWithActivityItems_audio_asset
{
    NSURL* sampleURL = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"caf"];
    AVURLAsset* asset = [AVURLAsset assetWithURL:sampleURL];
    STAssertTrue([self.activity canPerformWithActivityItems:@[asset]], nil);
}

- (void) testCanPerformWithActivityItems_ns_url_of_audio_file
{
    NSURL* sampleURL = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"caf"];
    STAssertTrue([self.activity canPerformWithActivityItems:@[sampleURL]], nil);
}

- (void) testCanPerformWithActivityItems_non_audio_asset
{
    NSURL* sampleURL = [[NSBundle mainBundle] URLForResource:@"soundcloud_activity" withExtension:@"png"];
    AVURLAsset* asset = [AVURLAsset assetWithURL:sampleURL];
    STAssertFalse([self.activity canPerformWithActivityItems:@[asset]], nil);
    STAssertFalse([self.activity canPerformWithActivityItems:@[sampleURL]], nil);
}

- (void) testCanPerformWithActivityItems_non_asset
{
    STAssertFalse([self.activity canPerformWithActivityItems:@[@"foo"]], nil);
}

- (void) testPrepareWithActivityItems
{
    NSURL* sampleURL = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"caf"];
    AVURLAsset* asset = [AVURLAsset assetWithURL:sampleURL];
    [self.activity prepareWithActivityItems:@[asset]];
    STAssertEqualObjects(self.activity.asset, asset, nil);
}

- (void) testPrepareWithActivityItems_non_asset
{
    [self.activity prepareWithActivityItems:@[@"foo"]];
    STAssertNil(self.activity.asset, nil);
}


- (void) testActivityViewcontroller
{
    self.activity.asset = mock([AVURLAsset class]);
    NSURL* trackURL = [NSURL URLWithString:@"http://foo"];
    [given([self.activity.asset URL]) willReturn:trackURL];

    id viewController = [self.activity activityViewController];

    [verify(self.activity.svcMock) setTitle:nil];
    [verify(self.activity.svcMock) setPrivate:NO];
    STAssertEqualObjects(viewController, self.activity.svcMock, nil);
}

- (void) testActivityViewcontroller_with_params
{
    self.activity.isPrivate = YES;
    self.activity.title = @"My Title";
    self.activity.foursquareClientId = @"fsId";
    self.activity.foursquareClientSecret = @"fsS";
    
    self.activity.asset = mock([AVURLAsset class]);
    NSURL* trackURL = [NSURL URLWithString:@"http://foo"];
    [given([self.activity.asset URL]) willReturn:trackURL];
    
    id viewController = [self.activity activityViewController];
    
    [verify(self.activity.svcMock) setTitle:@"My Title"];
    [verify(self.activity.svcMock) setPrivate:YES];
    [verify(self.activity.svcMock) setFoursquareClientID:@"fsId" clientSecret:@"fsS"];
    STAssertEqualObjects(viewController, self.activity.svcMock, nil);
}


- (void) testHandleSCShareViewCompletion_cancel
{
    NSDictionary* trackInfo = @{};
    NSError* error = mock([NSError class]);
    
    __block BOOL called = NO;
    __block BOOL retCanceled = NO;
    __block NSError* retErr = nil;
    __block NSDictionary* retTrackInfo = nil;
    
    self.activity.completionBlock = ^(BOOL canceled, NSDictionary* trackInfoParam, NSError* errorParam) {
        called = YES;
        retCanceled = canceled;
        retTrackInfo = trackInfoParam;
        retErr = errorParam;
    };
    
    [given([error domain]) willReturn:SCUIErrorDomain];
    [given([error code]) willReturnInteger:SCUICanceledErrorCode];
    
    [self.activity handleSCShareViewCompletion:trackInfo error:error];
    STAssertTrue(called, nil);
    STAssertFalse(self.activity.activityFinished, nil);
    STAssertTrue(retCanceled, nil);
    STAssertNil(retTrackInfo, nil);
    STAssertEqualObjects(retErr, error, nil);
}

- (void) testHandleSCShareViewCompletion_error
{
    NSDictionary* trackInfo = @{};
    NSError* error = mock([NSError class]);
    
    __block BOOL called = NO;
    __block BOOL retCanceled = NO;
    __block NSError* retErr = nil;
    __block NSDictionary* retTrackInfo = nil;
    
    self.activity.completionBlock = ^(BOOL canceled, NSDictionary* trackInfoParam, NSError* errorParam) {
        called = YES;
        retCanceled = canceled;
        retTrackInfo = trackInfoParam;
        retErr = errorParam;
    };
    
    [given([error domain]) willReturn:@"fooDomain"];
    [given([error code]) willReturnInteger:150];
    
    [self.activity handleSCShareViewCompletion:trackInfo error:error];
    STAssertTrue(called, nil);
    STAssertFalse(self.activity.activityFinished, nil);
    STAssertFalse(retCanceled, nil);
    STAssertNil(retTrackInfo, nil);
    STAssertEqualObjects(retErr, error, nil);
}

- (void) testHandleSCShareViewCompletion_success
{
    NSDictionary* trackInfo = @{};
    
    __block BOOL called = NO;
    __block BOOL retCanceled = NO;
    __block NSError* retErr = nil;
    __block NSDictionary* retTrackInfo = nil;
    
    self.activity.completionBlock = ^(BOOL canceled, NSDictionary* trackInfoParam, NSError* errorParam) {
        called = YES;
        retCanceled = canceled;
        retTrackInfo = trackInfoParam;
        retErr = errorParam;
    };
        
    [self.activity handleSCShareViewCompletion:trackInfo error:nil];
    STAssertTrue(called, nil);
    STAssertTrue(self.activity.activityFinished, nil);
    STAssertFalse(retCanceled, nil);
    STAssertEqualObjects(retTrackInfo, trackInfo, nil);
    STAssertNil(retErr, nil);
}

@end
