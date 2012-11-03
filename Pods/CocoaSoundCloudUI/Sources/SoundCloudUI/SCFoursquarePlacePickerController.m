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

#import <CoreLocation/CoreLocation.h>

#import "NSData+SoundCloudUI.h"
#import "UIColor+SoundCloudUI.h"
#import "UIDevice+SoundCloudUI.h"

#import "SCConstants.h"
#import "SCBundle.h"

#import "SCFoursquarePlacePickerController.h"

@interface SCFoursquarePlacePickerController () <CLLocationManagerDelegate>
@property (nonatomic, retain) NSArray *venues;
@property (nonatomic, retain) SCRequest *request;
@property (nonatomic, retain) NSString *clientID;
@property (nonatomic, retain) NSString *clientSecret;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, assign) id<SCFoursquarePlacePickerControllerDelegate> delegate;

- (IBAction)finishWithReset;
@end


@implementation SCFoursquarePlacePickerController

@synthesize venues;
@synthesize request;
@synthesize clientID;
@synthesize clientSecret;
@synthesize locationManager;
@synthesize delegate;

#pragma mark Lifecycle

- (id)initWithDelegate:(id<SCFoursquarePlacePickerControllerDelegate>)aDelegate
              clientID:(NSString *)aClientID
          clientSecret:(NSString *)aClientSecret;
{
    if ((self = [super init])) {
        
        self.title = SCLocalizedString(@"place_picker_title", @"Where?");
        
        delegate = aDelegate;
        
        clientID = [aClientID retain];
        clientSecret = [aClientSecret retain];
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        locationManager.distanceFilter = 30.0;
        locationManager.delegate = self;
        [locationManager startUpdatingLocation];
        
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:SCLocalizedString(@"place_picker_reset", @"Reset")
                                                                                   style:UIBarButtonItemStyleBordered
                                                                                  target:self
                                                                                  action:@selector(finishWithReset)] autorelease];
    }
    return self;
}

- (void)dealloc;
{
    [locationManager stopUpdatingLocation];
    [locationManager release];
    [venues release];
    [clientSecret release];
    [clientID release];
    [request release];
    [super dealloc];
}


#pragma mark Accessors

- (void)setVenues:(NSArray *)value;
{
    [value retain]; [venues release]; venues = value;
    self.tableView.separatorStyle = (venues.count > 0) ? UITableViewCellSeparatorStyleSingleLine : UITableViewCellSeparatorStyleNone;
    [self.tableView reloadData];
}


#pragma mark ViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    UIToolbar *customTitleBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
    customTitleBar.tintColor = [UIColor colorWithWhite:0.66 alpha:1.0];
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 300, 26.0)];
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.placeholder = SCLocalizedString(@"place_picker_placeholder", @"Add Your Place");
    textField.returnKeyType = UIReturnKeyDone;
    textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    textField.delegate = self;
    
    [customTitleBar setItems:[NSArray arrayWithObjects:
                              [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                              [[[UIBarButtonItem alloc] initWithCustomView:textField] autorelease],
                              [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                              nil]];
    
    [textField release];
    
    self.tableView.tableHeaderView = customTitleBar;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [customTitleBar release];
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidAppear:(BOOL)animated;
{
	[super viewDidAppear:animated];
    if (self.locationManager && self.locationManager.location) {
        [self locationManager:self.locationManager didUpdateToLocation:self.locationManager.location fromLocation:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
    if ([UIDevice isIPad]) {
        return YES;
        
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}


#pragma mark TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return venues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"venueCell"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"venueCell"] autorelease];
    }
    NSDictionary *venue = [self.venues objectAtIndex:indexPath.row];
    cell.textLabel.text = [venue objectForKey:@"name"];
    cell.detailTextLabel.text = [[venue objectForKey:@"location"] objectForKey:@"address"];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    return SCLocalizedString(@"place_picker_nearby", @"Nearby");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSDictionary *venue = [self.venues objectAtIndex:indexPath.row];
    [self.delegate foursquarePlacePicker:self
                 didFinishWithTitle:[venue objectForKey:@"name"]
                       foursquareID:([venue objectForKey:@"id"]) ? [NSString stringWithFormat:@"%@", [venue objectForKey:@"id"]] : nil //it might be a number
                           location:self.locationManager.location];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark Location delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
{
    [self.request cancel];

    NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSString stringWithFormat:@"%f,%f", newLocation.coordinate.latitude, newLocation.coordinate.longitude], @"ll",
                               [NSString stringWithFormat:@"%f", newLocation.horizontalAccuracy], @"llAcc",
                               [NSString stringWithFormat:@"%.0f", newLocation.altitude], @"alt",
                               @"50", @"limit", 
                               self.clientID, @"client_id",
                               self.clientSecret, @"client_secret",
                               @"20110622", @"v",
                               nil];
    
    self.request = [[[SCRequest alloc] initWithMethod:SCRequestMethodGET resource:[NSURL URLWithString:@"https://api.foursquare.com/v2/venues/search"]] autorelease];
    self.request.parameters = arguments;
    
    [self.request performRequestWithSendingProgressHandler:nil
                                           responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                                               if (error) {
                                                   NSLog(@"Location Request failed: %@", [error localizedDescription]);
                                               } else {
                                                   id results = [responseData JSONObject];
                                                   
                                                   if (![results isKindOfClass:[NSDictionary class]])
                                                       return;
                                                   
                                                   self.venues = [[results objectForKey:@"response"] objectForKey:@"venues"];
                                               }
                                           }];
    
    NSTimeInterval age = -[newLocation.timestamp timeIntervalSinceNow];
    
    if (age < 60.0 //if it is not older than a minute
        && newLocation.horizontalAccuracy <= 50.0) { //and more precise than 5app0 meters
        [manager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
{
	NSLog(@"locationManager:didFailWithError: %@", error);
}


#pragma mark TextField

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [self.delegate foursquarePlacePicker:self
                 didFinishWithTitle:textField.text
                       foursquareID:nil
                           location:nil];
    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField;
{
    [textField performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0];
    return YES;
}

#pragma mark Actions

- (IBAction)finishWithReset;
{
    [self.delegate foursquarePlacePicker:self
                 didFinishWithTitle:nil
                       foursquareID:nil
                           location:nil];
}

@end
