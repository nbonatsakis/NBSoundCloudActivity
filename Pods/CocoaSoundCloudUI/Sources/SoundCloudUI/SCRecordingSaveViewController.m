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

#import "UIViewController+SoundCloudUI.h"

#import "JSONKit.h"
#import "SCAPI.h"
#import "SCAccount+Private.h"

#import "UIDevice+SoundCloudUI.h"
#import "UIColor+SoundCloudUI.h"
#import "UIImage+SoundCloudUI.h"
#import "QuartzCore+SoundCloudUI.h"

#import "SCUIErrors.h"

#import "SCBundle.h"

#import "SCSwitch.h"

#import "SCShareToSoundCloudTitleView.h"
#import "SCRecordingSaveViewControllerHeaderView.h"
#import "SCRecordingUploadProgressView.h"
#import "SCLoginView.h"
#import "SCTableCellBackgroundView.h"

#import "SCSharingMailPickerController.h"
#import "SCFoursquarePlacePickerController.h"
#import "SCAddConnectionViewController.h"

#import "SCRecordingSaveViewController.h"


#define COVER_WIDTH 600.0


@interface SCRecordingSaveViewController () <UIPopoverControllerDelegate>

#pragma mark Accessors
@property (nonatomic, retain) NSArray *availableConnections;
@property (nonatomic, retain) NSArray *unconnectedServices;
@property (nonatomic, retain) NSArray *sharingConnections;
@property (nonatomic, retain) NSArray *sharingMailAddresses;
@property (nonatomic, assign) BOOL loadingConnections;

@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSData *fileData;
@property (nonatomic, assign) BOOL isPrivate;
@property (nonatomic, assign) BOOL isDownloadable;
@property (nonatomic, retain) UIImage *coverImage;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate *trackCreationDate;
@property (nonatomic, retain) NSArray *customTags;
@property (nonatomic, retain) NSString *customSharingNote;

@property (nonatomic, retain) CLLocation *location;
@property (nonatomic, copy) NSString *locationTitle;
@property (nonatomic, copy) NSString *foursquareID;

@property (nonatomic, readwrite, retain) SCAccount *account;

@property (nonatomic, retain) SCFoursquarePlacePickerController *foursquareController;
@property (nonatomic, retain) UIPopoverController *imagePickerPopoverController;

@property (nonatomic, assign) SCRecordingSaveViewControllerHeaderView *headerView;
@property (nonatomic, assign) SCRecordingUploadProgressView *uploadProgressView;
@property (nonatomic, assign) UITableView *tableView;
@property (nonatomic, assign) UIToolbar *toolBar;
@property (nonatomic, assign) SCLoginView *loginView;

@property (nonatomic, copy) SCRecordingSaveViewControllerCompletionHandler completionHandler;

@property (nonatomic, retain) id uploadRequestHandler;


#pragma mark UI
- (void)updateInterface;


#pragma mark Actions
- (IBAction)shareConnectionSwitchToggled:(id)sender;
- (IBAction)openCameraPicker;
- (IBAction)openImageLibraryPicker;
- (IBAction)openPlacePicker;
- (IBAction)closePlacePicker;
- (IBAction)privacyChanged:(id)sender;
- (IBAction)selectImage;
- (IBAction)resetImage;
- (IBAction)upload;
- (IBAction)cancel;
- (IBAction)relogin;
- (IBAction)close;


#pragma mark Notification Handling
- (void)accountDidChange:(NSNotification *)aNotification;
- (void)didFailToRequestAccess:(NSNotification *)aNotification;
- (void)keyboardWillChangeVisibility:(NSNotification *)notification;
- (void)keyboardDidChangeVisibility:(NSNotification *)notification;


#pragma mark Tool Bar Animation
- (void)hideToolBar;
- (void)showToolBar;


#pragma mark Login View
- (void)showLoginView:(BOOL)animated;
- (void)hideLoginView:(BOOL)animated;


#pragma mark Helpers
- (NSString *)generatedTitle;
- (NSString *)dateString;
- (float)cellMargin;

- (UIImage *)cropImage:(NSDictionary*)assets;
@end


NSString * const SCDefaultsKeyRecordingIsPrivate = @"SCRecordingIsPrivate";


@implementation SCRecordingSaveViewController


#pragma mark Class methods

const NSArray *allServices = nil;

+ (void)initialize;
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithBool:NO], SCDefaultsKeyRecordingIsPrivate,
															 nil]];
    allServices = [[NSArray alloc] initWithObjects:
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    SCLocalizedString(@"service_twitter", @"Twitter"), @"displayName",
                    @"twitter", @"service",
                    nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    SCLocalizedString(@"service_facebook", @"Facebook"), @"displayName",
                    @"facebook_profile", @"service",
                    nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    SCLocalizedString(@"service_tumblr", @"Tumblr"), @"displayName",
                    @"tumblr", @"service",
                    nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    SCLocalizedString(@"service_foursquare", @"Foursquare"), @"displayName",
                    @"foursquare", @"service",
                    nil],
                   nil];
}


@synthesize availableConnections;
@synthesize unconnectedServices;
@synthesize sharingConnections;
@synthesize sharingMailAddresses;
@synthesize loadingConnections;

@synthesize fileURL;
@synthesize fileData;
@synthesize isPrivate;
@synthesize isDownloadable;
@synthesize coverImage;
@synthesize title;
@synthesize trackCreationDate;
@synthesize customTags;
@synthesize customSharingNote;

@synthesize location;
@synthesize locationTitle;
@synthesize foursquareID;

@synthesize account;

@synthesize foursquareController;
@synthesize imagePickerPopoverController;

@synthesize headerView;
@synthesize uploadProgressView;
@synthesize tableView;
@synthesize toolBar;
@synthesize loginView;

@synthesize completionHandler;

@synthesize uploadRequestHandler;


#pragma mark Lifecycle

- (id)init;
{
    self = [super init];
    if (self) {
        unconnectedServices = [[NSArray alloc] init];
        availableConnections = [[NSArray alloc] init];
        sharingConnections = [[NSArray alloc] init];
        sharingMailAddresses = [[NSArray alloc] init];
        
        isPrivate = [[NSUserDefaults standardUserDefaults] boolForKey:SCDefaultsKeyRecordingIsPrivate];
        isDownloadable = YES;
        location = nil;
        locationTitle = nil;
        foursquareID = nil;
        
        coverImage = nil;
        title = nil;
        
        trackCreationDate = [[NSDate date] retain];
        
        completionHandler = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidChange:)
                                                     name:SCSoundCloudAccountDidChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didFailToRequestAccess:)
                                                     name:SCSoundCloudDidFailToRequestAccessNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillChangeVisibility:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidChangeVisibility:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillChangeVisibility:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidChangeVisibility:)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [availableConnections release];
    [unconnectedServices release];
    [sharingConnections release];
    [sharingMailAddresses release];
    [account release];
    [coverImage release];
    [title release];
    [trackCreationDate release];
    [location release];
    [locationTitle release];
    [foursquareID release];
    [foursquareController release];
    [completionHandler release];
    [imagePickerPopoverController release];
    
    [super dealloc];
}


#pragma mark Accessors

- (void)setFileURL:(NSURL *)aFileURL;
{
    if (fileURL != aFileURL) {
        [fileURL release];
        [aFileURL retain];
        fileURL = aFileURL;
    }
}

- (void)setFileData:(NSData *)someFileData;
{
    if (fileData != someFileData) {
        [fileData release];
        [someFileData retain];
        fileData = someFileData;
    }
}

- (void)setAccount:(SCAccount *)anAccount;
{   
    if (account != anAccount) {
        [account release];
        [anAccount retain];
        account = anAccount;
 
        if (self.account) {
            
            loadingConnections = YES;
            [self.tableView reloadData];
            
            [SCRequest performMethod:SCRequestMethodGET
                          onResource:[NSURL URLWithString:@"https://api.soundcloud.com/me/connections.json"]
                     usingParameters:nil
                         withAccount:anAccount
              sendingProgressHandler:nil
                     responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                         if (data) {
                             NSError *jsonError = nil;
                             NSArray *result = [data objectFromJSONData];
                             if (result) {
                                 loadingConnections = NO;
                                 [self setAvailableConnections:result];
                             } else {
                                 NSLog(@"%s json error: %@", __FUNCTION__, [jsonError localizedDescription]);
                             }
                         } else {
                             NSLog(@"%s error: %@", __FUNCTION__, [error localizedDescription]);
                         }
                     }];
            
            [SCRequest performMethod:SCRequestMethodGET
                          onResource:[NSURL URLWithString:@"https://api.soundcloud.com/me.json"]
                     usingParameters:nil
                         withAccount:anAccount
              sendingProgressHandler:nil
                     responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                         if (data) {
                             NSError *jsonError = nil;
                             id result = [data objectFromJSONData];
                             if (result) {
                                 
                                 anAccount.userInfo = result;
                                 
                                 NSURL *avatarURL = [NSURL URLWithString:[result objectForKey:@"avatar_url"]];
                                 NSData *avatarData = [NSData dataWithContentsOfURL:avatarURL];
                                 [self.headerView setAvatarImage:[UIImage imageWithData:avatarData]];
                                 [self.headerView setUserName:[result objectForKey:@"username"]];
                                 
                             } else {
                                 NSLog(@"%s json error: %@", __FUNCTION__, [jsonError localizedDescription]);
                             }
                         } else {
                             NSLog(@"%s error: %@", __FUNCTION__, [error localizedDescription]);
                         }
                     }];
        } else {
            [self.headerView setAvatarImage:nil];
            [self.headerView setUserName:nil];
        }
    }
}

- (void)setPrivate:(BOOL)p;
{
    isPrivate = p;
}

- (void)setDownloadable:(BOOL)value;
{
    isDownloadable = value;
}

- (void)setCoverImage:(UIImage *)aCoverImage;
{
    if (coverImage != aCoverImage) {
        [coverImage release];
        [aCoverImage retain];
        coverImage = aCoverImage;
        [self.headerView setCoverImage:aCoverImage];
    }
}

- (void)setTitle:(NSString *)aTitle;
{
    if (title != aTitle) {
        [title release];
        [aTitle retain];
        title = aTitle;
    }
}

- (void)setCreationDate:(NSDate *)aCreationDate;
{
    self.trackCreationDate = aCreationDate;
}

- (void)setTags:(NSArray *)someTags;
{
    self.customTags = someTags;
}

- (void)setSharingNote:(NSString *)aSharingNote;
{
    self.customSharingNote = aSharingNote;
}

- (void)setAvailableConnections:(NSArray *)value;
{
    [value retain]; [availableConnections release]; availableConnections = value;
    
    NSMutableArray *newUnconnectedServices = [allServices mutableCopy];
    
    //Set the unconnected Services
    for (NSDictionary *connection in availableConnections) {
        NSDictionary *connectedService = nil;
        for (NSDictionary *unconnectedService in newUnconnectedServices) {
            if ([[connection objectForKey:@"service"] isEqualToString:[unconnectedService objectForKey:@"service"]]) {
                connectedService = unconnectedService;
            }
        }
        if (connectedService) [newUnconnectedServices removeObject:connectedService];
    }
    
    self.unconnectedServices = newUnconnectedServices;
    [newUnconnectedServices release];
    [self.tableView reloadData];
}


#pragma mark Foursquare

- (void)setFoursquareClientID:(NSString *)aClientID clientSecret:(NSString *)aClientSecret;
{
    self.foursquareController = [[[SCFoursquarePlacePickerController alloc] initWithDelegate:self
                                                                                    clientID:aClientID
                                                                                clientSecret:aClientSecret] autorelease];
    
    if (self.foursquareController) {
        self.headerView.disclosureButton.hidden = NO;
        [self.headerView.disclosureButton addTarget:self
                                             action:@selector(openPlacePicker)
                                   forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.headerView.disclosureButton.hidden = YES;
        [self.headerView.disclosureButton removeTarget:self
                                                action:@selector(openPlacePicker)
                                      forControlEvents:UIControlEventTouchUpInside];
    }
}


#pragma mark ViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
        
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);

    
    // Background
    UIImage *bg = [SCBundle imageWithName:@"darkTexturedBackgroundPattern"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:bg];
    
    
    // Navigation Bar
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    
    // Toolbar
    self.toolBar = [[[UIToolbar alloc] init] autorelease];
    self.toolBar.barStyle = UIBarStyleBlack;
    self.toolBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleTopMargin);
    [self.view addSubview:self.toolBar];
    
    
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:3];
    
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithTitle:SCLocalizedString(@"cancel", @"Cancel")
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(cancel)] autorelease]];
    
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    
    [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithTitle:SCLocalizedString(@"upload_and_share", @"Upload & Share")
                                                            style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(upload)] autorelease]];
    
    [self.toolBar setItems:toolbarItems];
    
    
    // Table View
    self.tableView = [[[UITableView alloc] initWithFrame:CGRectZero
                                                   style:UITableViewStyleGrouped] autorelease];
    
    self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.opaque = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view insertSubview:self.tableView belowSubview:self.toolBar];
    
    
    // Header
    self.headerView = [[[SCRecordingSaveViewControllerHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 0)] autorelease];
    
    self.headerView.whatTextField.delegate = self;
    self.headerView.whereTextField.delegate = self;
    
    [self.headerView.coverImageButton addTarget:self
                                         action:@selector(selectImage)
                               forControlEvents:UIControlEventTouchUpInside];
    
    [self.headerView.privateSwitch addTarget:self
                                      action:@selector(privacyChanged:)
                            forControlEvents:UIControlEventValueChanged];
    
    if (self.foursquareController) {
        self.headerView.disclosureButton.hidden = NO;
        [self.headerView.disclosureButton addTarget:self
                                             action:@selector(openPlacePicker)
                                   forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.headerView.disclosureButton.hidden = YES;
        [self.headerView.disclosureButton removeTarget:self
                                                action:@selector(openPlacePicker)
                                      forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.headerView.logoutButton addTarget:self
                                     action:@selector(relogin)
                           forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView.tableHeaderView = self.headerView;

    
    [self updateInterface];
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    
    [self.view addSubview:[[[SCShareToSoundCloudTitleView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 28.0)] autorelease]];
    
    [self.toolBar setFrame:CGRectMake(0.0,
                                      CGRectGetHeight(self.view.bounds) - 44.0, 
                                      CGRectGetWidth(self.view.bounds),
                                      44.0)];
    
    CGRect tableViewFrame = self.view.bounds;
    tableViewFrame.origin.y += 28.0;        // Banner
    tableViewFrame.size.height -= 28.0;     // Banner
    tableViewFrame.size.height -= CGRectGetHeight(self.toolBar.frame); // Toolbar
    
    self.tableView.frame = tableViewFrame;
    
    self.account = [SCSoundCloud account];
    
    [tableView reloadData];
    [self updateInterface];
    
    if (self.account) {
        NSDictionary *userInfo = self.account.userInfo;
        if (userInfo) {
            NSURL *avatarURL = [NSURL URLWithString:[userInfo objectForKey:@"avatar_url"]];
            NSData *avatarData = [NSData dataWithContentsOfURL:avatarURL];
            [self.headerView setAvatarImage:[UIImage imageWithData:avatarData]];
            [self.headerView setUserName:[userInfo objectForKey:@"username"]];
        }
    } else {
        [self showLoginView:NO];
        [self relogin];
    }
}

- (void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    self.title = self.headerView.whatTextField.text;
    self.locationTitle = self.headerView.whereTextField.text;
}

- (void)updateInterface;
{
    self.headerView.whatTextField.text = self.title;
    self.headerView.whereTextField.text = self.locationTitle;
    self.headerView.privateSwitch.on = !isPrivate;
    [self.headerView setCoverImage:self.coverImage];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration;
{
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:NO];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController presentPopoverFromRect:self.headerView.coverImageButton.bounds
                                                           inView:self.headerView.coverImageButton
                                         permittedArrowDirections:UIPopoverArrowDirectionAny
                                                         animated:YES];
    }
}


#pragma mark TableView

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section;
{    
    if (isPrivate){
        return 1;
    } else if (self.loadingConnections) {
        return 1;
    } else {
        return self.availableConnections.count + self.unconnectedServices.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (isPrivate) {
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"mailShare"];
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"mailShare"] autorelease];
            SCTableCellBackgroundView *backgroundView = [[[SCTableCellBackgroundView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), 44.0)] autorelease];
            backgroundView.opaque = NO;
            backgroundView.backgroundColor = [UIColor transparentBlack];
            backgroundView.borderColor = [UIColor blackColor];
            cell.backgroundView = backgroundView;
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.textLabel.font = [UIFont systemFontOfSize:15.0];
            cell.textLabel.textColor = [UIColor listSubtitleColor];
            cell.textLabel.highlightedTextColor = [UIColor whiteColor];
            cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:15.0];
            cell.detailTextLabel.textColor = [UIColor whiteColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
                
        cell.textLabel.text = SCLocalizedString(@"sc_upload_with_access", @"With access");
        if (self.sharingMailAddresses.count == 0) {
            cell.detailTextLabel.text = SCLocalizedString(@"sc_upload_only_you", @"Only you");
        } else {
            cell.detailTextLabel.text = [self.sharingMailAddresses componentsJoinedByString:@", "];
        }

        [(SCTableCellBackgroundView *)cell.backgroundView setPosition:[aTableView cellPositionForIndexPath:indexPath]];
        
        return cell;
        
    } else if (self.loadingConnections) {
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"loading"];
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"loading"] autorelease];
            SCTableCellBackgroundView *backgroundView = [[[SCTableCellBackgroundView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), 44.0)] autorelease];
            backgroundView.opaque = NO;
            backgroundView.backgroundColor = [UIColor clearColor];
            backgroundView.borderColor = [UIColor clearColor];
            
            UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
            activityIndicatorView.center = CGPointMake(backgroundView.bounds.size.width / 2.0, backgroundView.bounds.size.height / 2.0);
            [activityIndicatorView startAnimating];
            [backgroundView addSubview:activityIndicatorView];
            [activityIndicatorView release];

            cell.backgroundView = backgroundView;
            cell.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        return cell;
        
    } else {
        
        if (indexPath.row < self.availableConnections.count) {
            UITableViewCell *cell = nil;  // WORKAROUND: Reusing cells causes a problem with the boarder
                                          //[aTableView dequeueReusableCellWithIdentifier:@"connection"];
            if (!cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"connection"] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.opaque = NO;
                SCTableCellBackgroundView *backgroundView = [[[SCTableCellBackgroundView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), 44.0)] autorelease];
                backgroundView.opaque = NO;
                backgroundView.backgroundColor = [UIColor transparentBlack];
                backgroundView.borderColor = [UIColor blackColor];
                cell.backgroundView = backgroundView;
                cell.textLabel.backgroundColor = [UIColor clearColor];
                cell.textLabel.font = [UIFont systemFontOfSize:15.0];
                cell.textLabel.textColor = [UIColor whiteColor];
            }
            
            
            NSDictionary *connection = [self.availableConnections objectAtIndex:indexPath.row];
            
            cell.textLabel.text = [connection objectForKey:@"display_name"];
            
            SCSwitch *accessorySwitch = [[[SCSwitch alloc] init] autorelease];
            accessorySwitch.offBackgroundImage = [[SCBundle imageWithName:@"switch_gray"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
            
            accessorySwitch.on = NO;
            [self.sharingConnections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
                if ([[obj objectForKey:@"id"] isEqual:[connection objectForKey:@"id"]]) {
                    if (self.foursquareID || ![[connection objectForKey:@"service"] isEqualToString:@"foursquare"]) {
                        accessorySwitch.on = YES;
                    }
                    *stop = YES;
                }
            }];
            
            [accessorySwitch addTarget:self action:@selector(shareConnectionSwitchToggled:) forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = accessorySwitch;
            
            cell.imageView.image = [SCBundle imageWithName:[NSString stringWithFormat:@"service_%@", [connection objectForKey:@"service"]]];
            
            [(SCTableCellBackgroundView *)cell.backgroundView setPosition:[aTableView cellPositionForIndexPath:indexPath]];
            
            return cell;
        } else {
            UITableViewCell *cell = nil; // WORKAROUND: Reusing cells causes a problem with the boarder
                                         // [aTableView dequeueReusableCellWithIdentifier:@"newConnection"];
            if (!cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"newConnection"] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                SCTableCellBackgroundView *backgroundView = [[[SCTableCellBackgroundView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), 44.0)] autorelease];
                backgroundView.opaque = NO;
                backgroundView.backgroundColor = [UIColor transparentBlack];
                backgroundView.borderColor = [UIColor blackColor];
                cell.backgroundView = backgroundView;
                cell.textLabel.backgroundColor = [UIColor clearColor];
                cell.textLabel.font = [UIFont systemFontOfSize:15.0];
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.accessoryView = [[[UIImageView alloc] initWithImage:[SCBundle imageWithName:@"DisclosureIndicator"]] autorelease];
                cell.detailTextLabel.text = SCLocalizedString(@"configure", @"Configure");
                cell.detailTextLabel.textColor = [UIColor whiteColor];
                cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            }
            
            NSDictionary *service = [self.unconnectedServices objectAtIndex:indexPath.row - self.availableConnections.count];
            cell.textLabel.text = [service objectForKey:@"displayName"];
            cell.imageView.image = [SCBundle imageWithName:[NSString stringWithFormat:@"service_%@", [service objectForKey:@"service"]]];
            
            [(SCTableCellBackgroundView *)cell.backgroundView setPosition:[aTableView cellPositionForIndexPath:indexPath]];
            return cell;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    if (self.isPrivate) {
        // TODO: Insert correct text describing the private options
        return SCLocalizedString(@"sc_upload_sharing_options_private", @"Your track will be private after the upload. You want to share it with others?");
    } else if (loadingConnections) {
        return nil;
    } else {
        return SCLocalizedString(@"sc_upload_sharing_options_public", @"Your sound will be shared to SoundCloud. Where else would you like to share it?");
    }
}

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section;
{
    NSString *text = [self tableView:aTableView titleForHeaderInSection:section];
    
    if (!text)
        return nil;
    
    CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:15.0]
                       constrainedToSize:CGSizeMake(CGRectGetWidth(self.tableView.bounds) - 2 * [self cellMargin], CGFLOAT_MAX)
                           lineBreakMode:UILineBreakModeWordWrap];
    
    UIView *sectionHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds) - 2 * [self cellMargin], textSize.height + 2 * 10.0)] autorelease];
    sectionHeaderView.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(sectionHeaderView.bounds, [self cellMargin], 0.0)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor listSubtitleColor];
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:15.0];
    label.text = text;
    [sectionHeaderView addSubview:label];
    [label release];
    return sectionHeaderView;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section;
{
    NSString *text = [self tableView:aTableView titleForHeaderInSection:section];
    
    if (!text)
        return 0;
    
    CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:15.0]
                       constrainedToSize:CGSizeMake(CGRectGetWidth(self.tableView.bounds) - 2 * [self cellMargin], CGFLOAT_MAX)
                           lineBreakMode:UILineBreakModeWordWrap];
    
    return textSize.height + 2 * 10.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section;
{
    if (isPrivate) {
        return nil;
    } else if (loadingConnections) {
        return nil;
    } else {
        if (availableConnections.count == 0) {
            return nil; // @"To add sharing options, go to your settings on SoundCloud.com and select 'Connections'";
        } else {
            return SCLocalizedString(@"connection_list_footer", @"To change your default sharing options, go to your settings on SoundCloud and select 'Connections'");
        }
    }
}

- (UIView *)tableView:(UITableView *)aTableView viewForFooterInSection:(NSInteger)section;
{
    if (isPrivate) {
        return nil;
    } else if (self.loadingConnections) {
        return nil;
    } else {
        UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), 20.0)] autorelease];
        footerView.backgroundColor = [UIColor clearColor];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(footerView.bounds, [self cellMargin], 0.0)];
        label.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor listSubtitleColor];
        label.font = [UIFont systemFontOfSize:13.0];
        label.text = [self tableView:aTableView titleForFooterInSection:section];
        label.numberOfLines = 2;
        [footerView addSubview:label];
        [label release];
        return footerView;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
{
    return 48.0;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (isPrivate) {
        if (indexPath.section == 0 && indexPath.row == 0) {
            SCSharingMailPickerController  *controller = [[SCSharingMailPickerController alloc] initWithDelegate:self];
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
			controller.title = SCLocalizedString(@"sc_upload_with_access", @"With Access");
			controller.result = self.sharingMailAddresses;
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentModalViewController:navController animated:YES];
			[controller release];
			[navController release];
            
            [aTableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    } else if (self.loadingConnections) {
        // ...
    } else {
        if (indexPath.row >= availableConnections.count) {
            NSDictionary *service = [unconnectedServices objectAtIndex:indexPath.row - availableConnections.count];
            SCAddConnectionViewController *controller = [[SCAddConnectionViewController alloc] initWithService:[service objectForKey:@"service"] account:account delegate:self];
            controller.title = [NSString stringWithFormat:SCLocalizedString(@"sc_upload_connect_to", @"Connect %@"), [service objectForKey:@"displayName"]];
            
            controller.modalPresentationStyle = UIModalPresentationFormSheet;
            [self.navigationController pushViewController:controller animated:YES];
            [controller release];
            [aTableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}


#pragma mark SCSharingMailPickerControllerDelegate

- (void)sharingMailPickerController:(SCSharingMailPickerController *)controller didFinishWithResult:(NSArray *)emailAdresses;
{
    self.sharingMailAddresses = emailAdresses;
    [self.tableView reloadData];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)sharingMailPickerControllerDidCancel:(SCSharingMailPickerController *)controller;
{
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{    
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField == self.headerView.whatTextField) {
        self.title = text;
    } else if (textField == self.headerView.whereTextField) {
        self.locationTitle = text;
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField;
{
    if (textField == self.headerView.whatTextField) {
        self.title = textField.text;
    } else if (textField == self.headerView.whereTextField) {
        self.locationTitle = textField.text;
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;
{
    if (self.foursquareController && textField == self.headerView.whereTextField) {
        [self.headerView.whatTextField resignFirstResponder]; //So we don't get the keyboard when coming back
        [self openPlacePicker];
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [textField resignFirstResponder];
    return NO;
}


#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)aPopoverController;
{
    if (aPopoverController == self.imagePickerPopoverController) {
        self.imagePickerPopoverController = nil;
    }
}

#pragma mark ActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;
{
    if (buttonIndex == actionSheet.firstOtherButtonIndex) {
        [self openImageLibraryPicker];  
    } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1
               && [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera].count > 0) {
        [self openCameraPicker];
    } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self resetImage];
    }
    
    [self updateInterface];
}


#pragma mark Image Picker Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{     
    self.coverImage = [self cropImage:info];
    
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}


#pragma mark Place Picker Delegate

- (void)foursquarePlacePicker:(SCFoursquarePlacePickerController *)aPicker
           didFinishWithTitle:(NSString *)aTitle
                 foursquareID:(NSString *)aFoursquareID
                     location:(CLLocation *)aLocation;
{
    self.headerView.whereTextField.text = aTitle;
    self.locationTitle = aTitle;
    self.location = aLocation;
    self.foursquareID = aFoursquareID;
    
    [self.navigationController popViewControllerAnimated:YES];
    
}


#pragma mark Add Connection Delegate

- (void)addConnectionController:(SCAddConnectionViewController *)controller didFinishWithService:(NSString *)service success:(BOOL)success;
{
    if (success) {
        
        // Update the sharing connections of this user and set the new connection to "on".
        // Dismiss the connection view controller after the connections where updated.
        
        [SCRequest performMethod:SCRequestMethodGET
                      onResource:[NSURL URLWithString:@"https://api.soundcloud.com/me/connections.json"]
                 usingParameters:nil
                     withAccount:account
          sendingProgressHandler:nil
                 responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                     if (data) {
                         NSError *jsonError = nil;
                         NSArray *result = [data objectFromJSONData];
                         if (result) {
                             [self setAvailableConnections:result];
                         } else {
                             NSLog(@"%s json error: %@", __FUNCTION__, [jsonError localizedDescription]);
                         }
                     } else {
                         NSLog(@"%s error: %@", __FUNCTION__, [error localizedDescription]);
                     }
                     
                     NSIndexSet *idxs = [availableConnections indexesOfObjectsPassingTest:^(id obj, NSUInteger i, BOOL *stop){
                         if ([[obj objectForKey:@"service"] isEqual:service]) {
                             *stop = YES;
                             return YES;
                         } else {
                             return NO;
                         }
                     }];
                     
                     NSMutableArray *newSharingConnections = [self.sharingConnections mutableCopy];
                     [newSharingConnections addObject:[availableConnections objectAtIndex:[idxs firstIndex]]];
                     self.sharingConnections = newSharingConnections;
                     
                     if (self.navigationController.topViewController == controller) {
                         [self.navigationController popViewControllerAnimated:YES];
                     }
                     
                     [newSharingConnections release];
                 }];
    }
}


#pragma mark Actions

- (IBAction)shareConnectionSwitchToggled:(SCSwitch *)sender
{
    UITableViewCell *cell = (UITableViewCell *)[(UIView *)sender superview];
    NSIndexPath *indexPath = [tableView indexPathForCell:cell];
    
    NSDictionary *connection = [availableConnections objectAtIndex:indexPath.row];
    
    //If this is a foursquare switch, we don't have a venue and want to switch it on, display place picker
    if ([[connection objectForKey:@"service"] isEqualToString:@"foursquare"] && !self.foursquareID && [sender isOn]) {
        [self openPlacePicker];
    }
    
    NSMutableArray *newSharingConnections = [self.sharingConnections mutableCopy];
    if ([sender isOn]) {
        [newSharingConnections addObject:connection];
    } else {
        NSIndexSet *idxs = [newSharingConnections indexesOfObjectsPassingTest:^(id obj, NSUInteger i, BOOL *stop){
            if ([[obj objectForKey:@"id"] isEqual:[connection objectForKey:@"id"]]) {
                *stop = YES;
                return YES;
            } else {
                return NO;
            }
        }];
        [newSharingConnections removeObjectsAtIndexes:idxs];
    }
    
    self.sharingConnections = newSharingConnections;
    [newSharingConnections release];
}

- (IBAction)privacyChanged:(id)sender;
{
    if (sender == self.headerView.privateSwitch) {
		isPrivate = !self.headerView.privateSwitch.on;
        [[NSUserDefaults standardUserDefaults] setBool:!self.headerView.privateSwitch.on forKey:SCDefaultsKeyRecordingIsPrivate];
        [self.tableView reloadData];
    }
}

- (IBAction)selectImage;
{
    if ([UIDevice isIPad] && [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary].count > 0) {
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        self.imagePickerPopoverController = [[[UIPopoverController alloc] initWithContentViewController:picker] autorelease];
        self.imagePickerPopoverController.delegate = self;
        
        [self.imagePickerPopoverController presentPopoverFromRect:self.headerView.coverImageButton.bounds
                                                inView:self.headerView.coverImageButton
                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                              animated:YES];
        
        if (self.coverImage) {
            UIBarButtonItem *resetButton = [[UIBarButtonItem alloc] initWithTitle:SCLocalizedString(@"artwork_reset", @"Reset")
                                                                            style:UIBarButtonItemStyleBordered
                                                                           target:self
                                                                           action:@selector(resetImage)];
            picker.navigationBar.topItem.leftBarButtonItem = resetButton;
            [resetButton release];
        }
        
        if ([UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera].count > 0) {
            UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(openCameraPicker)];
            picker.navigationBar.topItem.rightBarButtonItem = cameraButton;
            [cameraButton release];
        }
        
        [picker release];
        
    } else {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:SCLocalizedString(@"recording_image", @"Cover Image")
                                                           delegate:self
                                                  cancelButtonTitle:SCLocalizedString(@"cancel", @"Cancel")
                                             destructiveButtonTitle:self.coverImage ? SCLocalizedString(@"artwork_reset", @"Reset") : nil
                                                  otherButtonTitles:
                                ([UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary].count > 0) ? SCLocalizedString(@"use_existing_image", @"Photo Library") : nil,
                                ([UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera].count > 0) ? SCLocalizedString(@"take_new_picture", @"Camera") : nil,
                                nil];
        [sheet showInView:self.view];
        [sheet release];
    }
}

- (IBAction)openCameraPicker;
{
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.allowsEditing = YES;
    [self presentModalViewController:picker animated:YES];
    [picker release];
}

- (IBAction)openImageLibraryPicker;
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentModalViewController:picker animated:YES];
    [picker release];
}

- (IBAction)openPlacePicker;
{
    if (self.foursquareController) {
        [self.navigationController pushViewController:self.foursquareController animated:YES];
    }
}

- (IBAction)closePlacePicker;
{
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (IBAction)resetImage;
{
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    }
    self.coverImage = nil;
}

- (IBAction)upload;
{   
    NSMutableArray *toolbarItems = [self.toolBar.items mutableCopy];
    [toolbarItems removeLastObject];
    self.toolBar.items = toolbarItems;
    [toolbarItems release];
    
    // setup progress view
    self.tableView.hidden = YES;
    [self.navigationController setToolbarHidden:YES animated:YES];

    if (self.uploadProgressView) {
        [self.uploadProgressView removeFromSuperview];
    }
    
    // Create new Upload Progress View and set Artwork and Title
    
    CGRect progressViewRect = self.view.bounds;
    progressViewRect.size.height -= CGRectGetHeight(self.toolBar.frame) + 28;
    progressViewRect.origin.y += 28;
    
    self.uploadProgressView = [[[SCRecordingUploadProgressView alloc] initWithFrame:progressViewRect] autorelease];
    
    self.uploadProgressView.artwork = self.coverImage;
    self.uploadProgressView.title.text = [self generatedTitle];
    
    [self.uploadProgressView setNeedsLayout];
    [self.view insertSubview:self.uploadProgressView belowSubview:self.toolBar];
    
    // set up request
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    // track
    if (self.fileURL) {
        [parameters setObject:self.fileURL forKey:@"track[asset_data]"];
    } else {
        [parameters setObject:self.fileData forKey:@"track[asset_data]"];
    }
    
    // metadata
    [parameters setObject:[self generatedTitle] forKey:@"track[title]"];
    [parameters setObject:(self.isPrivate) ? @"private" : @"public" forKey: @"track[sharing]"];
    [parameters setObject:(self.isDownloadable) ? @"1" : @"0" forKey: @"track[downloadable]"];
    [parameters setObject:@"recording" forKey:@"track[track_type]"];

    // sharing
    if (self.isPrivate) {
        if (self.sharingMailAddresses.count > 0) {
            [parameters setObject:self.sharingMailAddresses forKey:@"track[shared_to][emails][][address]"];
        }
    } else {
        if (self.sharingConnections.count > 0) {
            NSMutableArray *idArray = [NSMutableArray arrayWithCapacity:self.sharingConnections.count];
            for (NSDictionary *sharingConnection in sharingConnections) {
                if ([[sharingConnection objectForKey:@"service"] isEqualToString:@"foursquare"] && !self.foursquareID) {
                    //Ignore Foursquare sharing when there is no venue ID set.
                } else {
                    [idArray addObject:[NSString stringWithFormat:@"%@", [sharingConnection objectForKey:@"id"]]];
                }
            }
            [parameters setObject:idArray forKey:@"track[post_to][][id]"];
        } else {
            [parameters setObject:@"" forKey:@"track[post_to][]"];
        }
    }
    
    // artwork
    if (self.coverImage) {
        NSData *coverData = UIImageJPEGRepresentation(self.coverImage, 0.8);
        [parameters setObject:coverData forKey:@"track[artwork_data]"];
    }
    
    // App name
    NSString * appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    
    // tags (location)
    NSMutableArray *tags = [NSMutableArray array];
    [tags addObject:[NSString stringWithFormat:@"\"soundcloud:source=%@\"", appName]];
    if (self.location) {
        [tags addObject:[NSString stringWithFormat:@"geo:lat=%f", self.location.coordinate.latitude]];
        [tags addObject:[NSString stringWithFormat:@"geo:lon=%f", self.location.coordinate.longitude]];
    }
    if (self.foursquareID) {
        [tags addObject:[NSString stringWithFormat:@"foursquare:venue=%@", self.foursquareID]];
    }
    
    // tags (custom)
    for (NSString *tag in self.customTags) {
        // TODO: Should the tags be checked?
        [tags addObject:tag];
    }
    
    [parameters setObject:[tags componentsJoinedByString:@" "] forKey:@"track[tag_list]"];
    
    // perform request
    self.uploadRequestHandler = [SCRequest performMethod:SCRequestMethodPOST
                                              onResource:[NSURL URLWithString:@"https://api.soundcloud.com/tracks.json"]
                                         usingParameters:parameters
                                             withAccount:self.account
                                  sendingProgressHandler:^(unsigned long long bytesSend, unsigned long long bytesTotal){self.uploadProgressView.progress.progress = (float)bytesSend / bytesTotal;}
                                         responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                             
                                             self.uploadRequestHandler = nil;
                                             
                                             NSError *jsonError = nil;
                                             id result = [data objectFromJSONData]; //[NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                             
                                             if (error || jsonError || result == nil) {
                                                 
                                                 // Handle Error
                                                 
                                                 if (error)
                                                     NSLog(@"Upload failed with error: %@", [error localizedDescription]);
                                                 
                                                 if (jsonError)
                                                     NSLog(@"Upload failed with json error: %@", [jsonError localizedDescription]);
                                                 
                                                 self.uploadProgressView.state = SCRecordingUploadProgressViewStateFailed;
                                                 [self.uploadProgressView setNeedsLayout];
                                                 
                                                 // update tool bar
                                                 NSMutableArray *toolbarItems = [self.toolBar.items mutableCopy];
                                                 [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithTitle:SCLocalizedString(@"retry_upload", @"Retry")
                                                                                                           style:UIBarButtonItemStyleBordered
                                                                                                          target:self
                                                                                                          action:@selector(upload)] autorelease]];
                                                 self.toolBar.items = toolbarItems;
                                                 [toolbarItems release];

                                             } else {
                                                 
                                                 // Call the completion handler
                                                 if (self.completionHandler) {
                                                     self.completionHandler(result, nil);
                                                 }
                                                 
                                                 // update upload progress view
                                                 [self.uploadProgressView setTrackInfo:result];
                                                 self.uploadProgressView.state = SCRecordingUploadProgressViewStateSuccess;
                                                 [self.uploadProgressView setNeedsLayout];

                                                 // update tool bar
                                                 NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:2];
                                                 [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
                                                 [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithTitle:SCLocalizedString(@"done", @"Done") style:UIBarButtonItemStyleBordered target:self action:@selector(close)] autorelease]];
                                                 [self.toolBar setItems:toolbarItems animated:YES];
                                            }
                                         }];
}

- (IBAction)cancel;
{
    // Cancel running upload request
    [SCRequest cancelRequest:self.uploadRequestHandler];
    self.uploadRequestHandler = nil;
    
    // Call complettion handler
    if (self.completionHandler) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Canceled by user." forKey:NSLocalizedDescriptionKey];
        self.completionHandler(nil, [NSError errorWithDomain:SCUIErrorDomain code:SCUICanceledErrorCode userInfo:userInfo]);
    }
    
    // Dismiss modal view
    [[self modalPresentingViewController] dismissModalViewControllerAnimated:YES];
}

- (IBAction)relogin;
{
    self.account = nil;
    [self showLoginView:YES];
    [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
        [self.loginView loadURL:preparedURL];
    }];
}

- (IBAction)close;
{
    [[self modalPresentingViewController] dismissModalViewControllerAnimated:YES];
}

#pragma mark Notification Handling

- (void)accountDidChange:(NSNotification *)aNotification;
{
    self.account = [SCSoundCloud account];
    if (self.account){
        [self hideLoginView:YES];
    }
}

- (void)didFailToRequestAccess:(NSNotification *)aNotification;
{
    [self cancel];
}

- (void)keyboardWillChangeVisibility:(NSNotification *)notification;
{
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:NO];
    }
}

- (void)keyboardDidChangeVisibility:(NSNotification *)notification;
{
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController presentPopoverFromRect:self.headerView.coverImageButton.bounds
                                                           inView:self.headerView.coverImageButton
                                         permittedArrowDirections:UIPopoverArrowDirectionAny
                                                         animated:YES];
    }
}


#pragma mark Tool Bar Animation

- (void)hideToolBar;
{
    [UIView animateWithDuration:0.2
                     animations:^{
                         CGPoint center = self.toolBar.center;
                         self.toolBar.center = CGPointMake(center.x, center.y + CGRectGetHeight(self.toolBar.frame));
                     }];
}

- (void)showToolBar;
{
    [UIView animateWithDuration:0.2
                     animations:^{
                         CGPoint center = self.toolBar.center;
                         self.toolBar.center = CGPointMake(center.x, center.y - CGRectGetHeight(self.toolBar.frame));
                     }];
}


#pragma mark Login View

- (void)showLoginView:(BOOL)animated;
{
    if (self.loginView)
        return;
    
    CGRect loginViewFrame = CGRectMake(0,
                                       28.0,
                                       CGRectGetWidth(self.view.bounds),
                                       CGRectGetHeight(self.view.bounds) - 28.0 - CGRectGetHeight(self.toolBar.frame));
    
    self.loginView = [[[SCLoginView alloc] initWithFrame:loginViewFrame] autorelease];
    self.loginView.delegate = self;
    [self.view insertSubview:self.loginView belowSubview:self.toolBar];
    
    
    NSMutableArray *toolBarItems = [NSMutableArray arrayWithArray:self.toolBar.items];
    [toolBarItems removeLastObject];
    [self.toolBar setItems:toolBarItems animated:animated];
    
    if (animated) {
        self.loginView.center = CGPointMake(self.loginView.center.x, self.loginView.center.y + CGRectGetHeight(self.loginView.frame));
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.loginView.center = self.tableView.center;
                         }];
    }
}

- (void)hideLoginView:(BOOL)animated;
{
    if (!self.loginView)
        return;
    
    NSMutableArray *toolBarItems = [NSMutableArray arrayWithArray:self.toolBar.items];
    [toolBarItems addObject:[[[UIBarButtonItem alloc] initWithTitle:SCLocalizedString(@"upload_and_share", @"Upload & Share")
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(upload)] autorelease]];
    [self.toolBar setItems:toolBarItems animated:animated];
    
    if (!animated) {
        [self.loginView removeFromSuperview];
        self.loginView = nil;
    } else {
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.loginView.center = CGPointMake(self.loginView.center.x, self.loginView.center.y + CGRectGetHeight(self.loginView.frame));
                         }
                         completion:^(BOOL finished){
                             [self.loginView removeFromSuperview];
                             self.loginView = nil;
                         }];
    }
}

- (void)loginView:(SCLoginView *)aLoginView didFailWithError:(NSError *)anError;
{
    if (self.completionHandler) {
        self.completionHandler(nil, anError);
    }
    [[self modalPresentingViewController] dismissModalViewControllerAnimated:YES];
}

#pragma mark Helpers


- (NSString *)generatedTitle;
{
    if (self.title.length > 0) {
        if (self.locationTitle.length > 0) {
            return [NSString stringWithFormat:SCLocalizedString(@"recording_title_at_location_name", @"%@ at %@"), self.title, self.locationTitle];
        } else {
            return self.title;
        }
    } else {
        if (self.locationTitle.length > 0) {
            return [NSString stringWithFormat:SCLocalizedString(@"recording_at_location", @"Sounds at %@"), self.locationTitle];
        } else {
            return [NSString stringWithFormat:SCLocalizedString(@"recording_from_data", @"Sounds from %@"), [self dateString]];
        }
    }
}

- (NSString *)dateString;
{
    NSString *weekday = nil;
    NSString *time = nil;
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:(NSWeekdayCalendarUnit | NSHourCalendarUnit) fromDate:self.trackCreationDate];
    [gregorian release];
    
    switch ([components weekday]) {
        case 1:
            weekday = SCLocalizedString(@"weekday_sunday", @"Sunday");
            break;
        case 2:
            weekday = SCLocalizedString(@"weekday_monday", @"Monday");
            break;
        case 3:
            weekday = SCLocalizedString(@"weekday_tuesday", @"Tuesday");
            break;
        case 4:
            weekday = SCLocalizedString(@"weekday_wednesday", @"Wednesday");
            break;
        case 5:
            weekday = SCLocalizedString(@"weekday_thursday", @"Thursday");
            break;
        case 6:
            weekday = SCLocalizedString(@"weekday_friday", @"Friday");
            break;
        case 7:
            weekday = SCLocalizedString(@"weekday_saturday", @"Saturday");
            break;
    }
    
    if ([components hour] <= 12) {
        time = SCLocalizedString(@"timeframe_morning", @"morning");
    } else if ([components hour] <= 17) {
        time = SCLocalizedString(@"timeframe_afternoon", @"afternoon");
    } else if ([components hour] <= 21) {
        time = SCLocalizedString(@"timeframe_evening", @"evening");
    } else {
        time = SCLocalizedString(@"timeframe_night", @"night");
    }
    
    return [NSString stringWithFormat:@"%@ %@", weekday, time];
}

- (float)cellMargin;
{
    if ([UIDevice isIPad]) {
        return 30.0;
    } else {
        return 9.0;
    }
}

// Inspired by http://www.gotow.net/creative/wordpress/?p=64

- (UIImage *)cropImage:(NSDictionary*)editInfo;
{
    CGRect editCropRect = [[editInfo valueForKey:UIImagePickerControllerCropRect] CGRectValue]; 
    
    // Determine original image orientation and size
    UIImage *originalImage = [editInfo valueForKey:UIImagePickerControllerOriginalImage];
    UIImageOrientation originalOrientation = originalImage.imageOrientation;

    CGImageRef ref = originalImage.CGImage;
    CGSize refImageSize = CGSizeMake(CGImageGetWidth(ref), CGImageGetHeight(ref));
    
    
    CGRect newEditCropRect = editCropRect;
    
    // Modify crop rect to reflect image orientation
    switch (originalOrientation) {
        case UIImageOrientationDown:
            newEditCropRect.origin.x = refImageSize.width - (editCropRect.size.width + editCropRect.origin.x);
            newEditCropRect.origin.y = refImageSize.height - (editCropRect.size.height + editCropRect.origin.y);
            break;
            
        case UIImageOrientationRight:
            newEditCropRect.origin.x = editCropRect.origin.y;
            newEditCropRect.origin.y = refImageSize.height - (editCropRect.origin.x + editCropRect.size.width);
            newEditCropRect.size.width = editCropRect.size.height;
            newEditCropRect.size.height = editCropRect.size.width;
            break;
            
        case UIImageOrientationLeft:
            newEditCropRect.origin.x = refImageSize.width - (editCropRect.origin.y + editCropRect.size.height);
            newEditCropRect.origin.y = editCropRect.origin.x;
            newEditCropRect.size.width = editCropRect.size.height;
            newEditCropRect.size.height = editCropRect.size.width;
            break;
            
        default:
            break;
    }
    
    // Make the damn thing square if it's ALMOST square
    CGFloat maxSize = MIN(refImageSize.width, refImageSize.height);
    CGFloat width = MIN(CGRectGetWidth(newEditCropRect), CGRectGetHeight(newEditCropRect));
    width = MIN(maxSize, width);
    
    editCropRect = CGRectMake(CGRectGetMidX(newEditCropRect), CGRectGetMidY(newEditCropRect), 0, 0);
    editCropRect = CGRectInset(editCropRect, -1 * (width / 2.0), -1 * (width / 2.0));
    
    
    // Make sure the edit crop rect is in the bounds of the image.
    if (CGRectGetMinX(editCropRect) < 0) {
        editCropRect.origin.x = 0;
    } else if (CGRectGetMaxX(editCropRect) - refImageSize.width > 0) {
        editCropRect.origin.x -= CGRectGetMaxX(editCropRect) - refImageSize.width;
    }
    
    if (CGRectGetMinY(editCropRect) < 0) {
        editCropRect.origin.y = 0;
    } else if (CGRectGetMaxY(editCropRect) - refImageSize.height > 0) {
        editCropRect.origin.y -= CGRectGetMaxY(editCropRect) - refImageSize.height;
    }
    
    // Crop image using crop rect
    CGImageRef image = CGImageCreateWithImageInRect(ref, editCropRect);
    UIImage* cropedImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    
    // Perform image rotation
    UIImage *scaledImage = [cropedImage imageByResizingTo:CGSizeMake(COVER_WIDTH, COVER_WIDTH)];
    UIImage *finalImage = [scaledImage imagebyRotationToOrientation:originalOrientation];
    
    return finalImage;
}

@end

