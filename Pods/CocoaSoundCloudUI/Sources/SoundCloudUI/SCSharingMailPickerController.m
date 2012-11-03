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


#import "SCNameAndEmailCell.h"
#import "SCBundle.h"
#import "UIDevice+SoundCloudUI.h"

#import "SCSharingMailPickerController.h"


@interface SCFetchAddressbookOperation : NSOperation
{
@private
	id	_target;
	SEL	_selector;
}
- (id)initWithTarget:(id)target
            selector:(SEL)selector;
@end


#pragma mark -

@interface SCDoAutocompleteionOperation : NSOperation
{
@private
	id		_target;
	SEL		_selector;
	NSDictionary	*_addressbookData;
	NSString		*_autocompleteString;
}

- (id)initWithTarget:(id)target
            selector:(SEL)selector
     addressbookData:(NSDictionary *)addressbookData
  autocompleteString:(NSString *)autocompleteString;

@end

#pragma mark -


@interface SCSharingMailPickerController ()

#pragma mark Accessors
@property (nonatomic, assign) UITextField *emailsField;
@property (nonatomic, assign) UIBarButtonItem *doneBarButton;
@property (nonatomic, assign) UIButton *addFromAddresbookButton;
@property (nonatomic, assign) UILabel *inputLabel;
@property (nonatomic, assign) UIView *inputView;

@property (nonatomic, retain) UITableViewController	*autocompleteTableViewController;

@property (nonatomic, retain) NSDictionary *addressBookData;
@property (nonatomic, retain) NSMutableArray *currentResult;
@property (nonatomic, retain) NSMutableArray *autocompleteData;

@property (nonatomic, retain) NSOperationQueue *autocompleteOperationQueue;
@property (nonatomic, retain) NSOperationQueue *fetchAddressbookDataOperationQueue;

@property (nonatomic, assign) id<SCSharingMailPickerControllerDelegate> delegate;

#pragma mark Helper
- (NSArray *)arrayOfEmailsInString:(NSString *)string unparsebleStrings:(NSArray **)unparsableRet;
- (void)updateAutocompletionWithInputFieldValue:(NSString *)textFieldValue;
- (void)setAutocompleteData:(NSMutableArray *)_autocompleteData;
- (void)updateResult;

@end


@implementation SCSharingMailPickerController

@synthesize addressBookData;
@synthesize userInfo;
@synthesize result;
@synthesize currentResult;
@synthesize emailsField;
@synthesize doneBarButton;
@synthesize addFromAddresbookButton;
@synthesize inputLabel;
@synthesize inputView;
@synthesize autocompleteTableViewController;
@synthesize autocompleteData;
@synthesize autocompleteOperationQueue;
@synthesize fetchAddressbookDataOperationQueue;
@synthesize delegate;

#pragma mark Lifecycle

- (id)initWithDelegate:(id<SCSharingMailPickerControllerDelegate>)aDelegate;
{
    self = [super initWithNibName:nil bundle:nil];
	if (self) {
		delegate = aDelegate;
        
		autocompleteOperationQueue = [[NSOperationQueue alloc] init];
		autocompleteData = [[NSMutableArray alloc] init];
        currentResult = [[NSMutableArray alloc] init];
        
		autocompleteTableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
		autocompleteTableViewController.tableView.delegate = self;
		autocompleteTableViewController.tableView.dataSource = self;
        
        // Notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
		
        
        // Operations
		fetchAddressbookDataOperationQueue = [[NSOperationQueue alloc] init];
		NSOperation *fetchAddressbookDataOperation = [[SCFetchAddressbookOperation alloc] initWithTarget:self selector:@selector(setAddressBookData:)];
		[fetchAddressbookDataOperationQueue addOperation:fetchAddressbookDataOperation];
		[fetchAddressbookDataOperation release];
	}
	return self;
}

- (void)dealloc;
{
    // Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    // Releasing Owenership
    [addressBookData release];
	[autocompleteOperationQueue cancelAllOperations];
	[autocompleteOperationQueue release];
	[autocompleteData release];
	[currentResult release];
	[autocompleteTableViewController release];
	
    [super dealloc];
}


#pragma mark Accessors

- (void)setAddressBookData:(NSDictionary *)value;
{
	[value retain]; [addressBookData release]; addressBookData = value;
	[self updateAutocompletionWithInputFieldValue:emailsField.text];
}

- (void)setAutocompleteData:(NSMutableArray *)_autocompleteData;
{
	[_autocompleteData retain]; [autocompleteData release]; autocompleteData = _autocompleteData;
	[self.autocompleteTableViewController.tableView reloadData];
}

- (NSArray *)result;
{
	[self updateResult];
	return self.currentResult;
}

- (void)setResult:(NSArray *)value;
{
	if (self.emailsField) {
		self.emailsField.text = [value componentsJoinedByString:@", "];
		[self updateResult];
	} else {
		[self.currentResult removeAllObjects];
		[self.currentResult addObjectsFromArray:value];
	}
}


#pragma mark View loading

- (void)viewDidLoad;
{
	[super viewDidLoad];
    
    self.title = SCLocalizedString(@"shared_to_email_adresses", @"Email Addresses");
    
	self.view.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    
    // Navigation Bar
    self.doneBarButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																        target:self
																        action:@selector(done:)] autorelease];
	self.doneBarButton.enabled = YES;
	self.navigationItem.rightBarButtonItem = self.doneBarButton;
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						   target:self
																						   action:@selector(cancel:)] autorelease];
    
    // Input View
	self.inputView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    self.inputView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth);
	self.inputView.opaque = NO;
    self.inputView.backgroundColor = [UIColor colorWithPatternImage:[SCBundle imageWithName:@"mailInputBackground"]];
    
    // Addresbook Button
    self.addFromAddresbookButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
	[self.addFromAddresbookButton addTarget:self action:@selector(addFromAB:) forControlEvents:UIControlEventTouchUpInside];
    self.addFromAddresbookButton.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin);
    self.addFromAddresbookButton.backgroundColor = [UIColor clearColor];
    
    
    // Input Label
	self.inputLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	self.inputLabel.text = SCLocalizedString(@"shared_to_to", @"To:");
	self.inputLabel.textColor = [UIColor darkGrayColor];
    self.inputLabel.backgroundColor = [UIColor clearColor];

	// Email Field
	self.emailsField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
	self.emailsField.delegate = self;
	self.emailsField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.emailsField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailsField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.emailsField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.emailsField.backgroundColor = [UIColor clearColor];
	[self.emailsField sizeToFit];
	self.emailsField.text = [self.currentResult componentsJoinedByString:@", "];

	
	[self.inputView addSubview:inputLabel];
    [self.inputView addSubview:emailsField];
    [self.inputView addSubview:addFromAddresbookButton];
	[self.view addSubview:self.inputView];
	

    self.autocompleteTableViewController.view.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth);
	self.autocompleteTableViewController.view.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
	[self.view addSubview:autocompleteTableViewController.view];
}

- (void)viewDidUnload;
{
	[super viewDidUnload];
	self.doneBarButton = nil;
	self.emailsField = nil;
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    
    self.inputView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44);
    
    self.inputLabel.frame = CGRectZero;
    [self.inputLabel sizeToFit];
    self.inputLabel.frame = CGRectMake(4,
    								  CGRectGetMidY(self.inputView.bounds) - CGRectGetMidY(self.inputLabel.frame),
    								  CGRectGetWidth(self.inputLabel.frame),
    								  CGRectGetHeight(self.inputLabel.frame));
    
    self.addFromAddresbookButton.frame = CGRectZero;
    [self.addFromAddresbookButton sizeToFit];
    self.addFromAddresbookButton.frame = CGRectMake(CGRectGetMaxX(self.inputView.frame) - CGRectGetWidth(self.addFromAddresbookButton.frame) - 4,
    											   CGRectGetMidY(self.inputView.frame) - CGRectGetMidY(self.addFromAddresbookButton.frame),
    											   CGRectGetWidth(self.addFromAddresbookButton.frame),
    											   CGRectGetHeight(self.addFromAddresbookButton.frame));

    self.emailsField.frame = CGRectMake(CGRectGetMaxX(self.inputLabel.frame) + 4, 0,
                                        CGRectGetWidth(self.inputView.bounds) - 4 - CGRectGetWidth(self.inputLabel.frame) - 8 - CGRectGetWidth(self.addFromAddresbookButton.frame) - 4,
                                        CGRectGetHeight(self.inputView.bounds));
    
    
    self.autocompleteTableViewController.view.frame = CGRectMake(CGRectGetMinX(self.view.bounds),
                                                                 CGRectGetMaxY(self.inputView.frame),
                                                                 CGRectGetWidth(self.view.bounds),
                                                                 CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.inputView.frame));
}

- (void)viewDidAppear:(BOOL)animated;
{
	[super viewDidAppear:animated];
	[emailsField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated;
{
	[super viewWillDisappear:animated];
	[autocompleteOperationQueue cancelAllOperations];
}


#pragma mark Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification;
{
    if (![UIDevice isIPad]) {
        NSValue *keyboardFrameValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
        
        CGRect keyboardFrame;
        [keyboardFrameValue getValue:&keyboardFrame];
        
        CGRect convertedKeyboardFrame = [self.view convertRect:keyboardFrame fromView:self.view.window];
        
        CGRect newTableViewFrame = CGRectMake(CGRectGetMinX(self.inputView.frame),
                                              CGRectGetMaxY(self.inputView.frame),
                                              CGRectGetWidth(self.inputView.frame),
                                              CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(self.inputView.frame) - CGRectGetHeight(convertedKeyboardFrame));
        
        [UIView beginAnimations:@"tableViewFrame" context:nil];
        self.autocompleteTableViewController.view.frame = newTableViewFrame;
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    if (![UIDevice isIPad]) {
        [UIView beginAnimations:@"tableViewFrame" context:nil];
        self.autocompleteTableViewController.view.frame = CGRectMake(CGRectGetMinX(inputView.frame),
                                                                     CGRectGetMaxY(inputView.frame),
                                                                     CGRectGetWidth(inputView.frame),
                                                                     CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(inputView.frame));
        [UIView commitAnimations];
    }
}


#pragma mark Actions

- (IBAction)done:(id)sender;
{
    [self updateResult];
	[delegate sharingMailPickerController:self didFinishWithResult:self.currentResult];
}

- (IBAction)cancel:(id)sender;
{
	[delegate sharingMailPickerControllerDidCancel:self];
}

- (IBAction)addFromAB:(id)sender;
{
	ABPeoplePickerNavigationController *controller = [[[ABPeoplePickerNavigationController alloc] init] autorelease];
	controller.navigationBar.barStyle = UIBarStyleBlack;
	[controller setPeoplePickerDelegate:self];
	[controller setDisplayedProperties:[NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonEmailProperty]]];
	controller.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentModalViewController:controller animated:YES];	
}

#pragma mark ViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
    if ([UIDevice isIPad]) {
        return YES;
        
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}

#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
{
	NSMutableString *resultingString = [[textField.text mutableCopy] autorelease];
	[resultingString replaceCharactersInRange:range withString:replacementString];
	
	[self updateAutocompletionWithInputFieldValue:resultingString];
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)_textField;
{
	[self done:_textField];
	return YES;
}


#pragma mark ABPeoplePickerNavigationControllerDelegate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person;
{
	return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
								property:(ABPropertyID)property
							  identifier:(ABMultiValueIdentifier)identifier;
{
	if (property == kABPersonEmailProperty) {
		ABMultiValueRef emailValue = ABRecordCopyValue(person, property);
		CFIndex addressIndex = ABMultiValueGetIndexForIdentifier(emailValue, identifier);
		NSString *emailToShareTo = [(NSString *)ABMultiValueCopyValueAtIndex(emailValue, addressIndex) autorelease];
		CFRelease(emailValue);
		
		NSArray *unparsable = nil;
		NSMutableArray *emails = [[[self arrayOfEmailsInString:emailsField.text unparsebleStrings:&unparsable] mutableCopy] autorelease];
		[emails addObject:emailToShareTo];
		self.emailsField.text = [emails componentsJoinedByString:@", "];
		
		[self dismissModalViewControllerAnimated:YES];
		return NO;
	}
	
	return YES;
}


#pragma mark Private

- (void)updateResult;
{
	if (!self.emailsField)
        return;
	
	NSArray *unparsable = nil;
	[self.currentResult removeAllObjects];
	NSArray *emails = [self arrayOfEmailsInString:self.emailsField.text unparsebleStrings:&unparsable];
	for (NSString *email in emails) {
		if (![self.currentResult containsObject:email])
			[self.currentResult addObject:email];
	}
	
	if (unparsable) {
		NSLog(@"unparsable mail adresses: %@", [unparsable componentsJoinedByString:@", "]);
	}
}

- (NSArray *)arrayOfEmailsInString:(NSString *)string unparsebleStrings:(NSArray **)unparsableRet;
{
	NSMutableArray *emails = [NSMutableArray array];
	NSMutableArray *unparsable = [NSMutableArray array];
	
	NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx]; 
	NSCharacterSet *splitChars = [NSCharacterSet characterSetWithCharactersInString:@", "];
	
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	while (![scanner isAtEnd]) {
		NSString *currentScannedString = nil;
		if ([scanner scanUpToCharactersFromSet:splitChars intoString:&currentScannedString]) {
			if ([emailTest evaluateWithObject:currentScannedString] == YES) 
			{
				[emails addObject:currentScannedString];
			} else {
				[unparsable addObject:currentScannedString];
			}
		} else {
			[scanner setScanLocation: [scanner scanLocation] +1];
		}
	}
	
	if (unparsable.count > 0)
		*unparsableRet = unparsable;
	return emails;
}

- (void)updateAutocompletionWithInputFieldValue:(NSString *)textFieldValue;
{
	if (!textFieldValue)
		textFieldValue = self.emailsField.text;
	assert([NSThread isMainThread]);
	NSArray *unparsable = nil;
	[self arrayOfEmailsInString:textFieldValue unparsebleStrings:&unparsable];
	
	[autocompleteOperationQueue cancelAllOperations];
	NSOperation *autocompleteOperation = [[SCDoAutocompleteionOperation alloc] initWithTarget:self
																					 selector:@selector(setAutocompleteData:)
																			  addressbookData:addressBookData
																		   autocompleteString:[unparsable componentsJoinedByString:@" "]];
	[autocompleteOperationQueue addOperation:autocompleteOperation];
	[autocompleteOperation release];
}


#pragma mark UITableViewDelegate & UITableViewDataSource

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section;
{
	return autocompleteData.count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	NSString *reuseIdentifier = @"NameAndEmailCell";
	SCNameAndEmailCell *cell = (SCNameAndEmailCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (!cell) {
        cell = [[[SCNameAndEmailCell alloc] init] autorelease];
	}
	NSDictionary *personData = [autocompleteData objectAtIndex:indexPath.row];
	cell.name = [personData objectForKey:@"name"];
	cell.email = [personData objectForKey:@"email"];
	cell.mailType = [personData objectForKey:@"mailType"];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
	NSDictionary *personData = [autocompleteData objectAtIndex:indexPath.row];
	
	NSArray *unparsable = nil;
	NSMutableArray *emails = [[[self arrayOfEmailsInString:self.emailsField.text unparsebleStrings:&unparsable] mutableCopy] autorelease];
	[emails addObject:[personData objectForKey:@"email"]];
	
	self.emailsField.text = [NSString stringWithFormat:@"%@, ", [emails componentsJoinedByString:@", "]];
	
	[autocompleteData removeAllObjects];
	[self.autocompleteTableViewController.tableView reloadData];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES]; 
}

@end


#pragma mark -

@implementation SCDoAutocompleteionOperation

#pragma mark Lifecycle

- (id)initWithTarget:(id)target selector:(SEL)selector addressbookData:(NSDictionary *)addressbookData autocompleteString:(NSString *)autocompleteString;
{
	if ((self = [super init])) {
		_target = [target retain];
		_selector = selector;
		_addressbookData = [addressbookData retain];
		_autocompleteString = [autocompleteString retain];
	}
	return self;
}

- (void)dealloc;
{
	[_target release];
	[_addressbookData release];
	[_autocompleteString release];
	[super dealloc];
}

#pragma mark main

static int compareAutocompleteData(id dict1, id dict2, void *context)
{
	NSString *name1 = [dict1 objectForKey:context];
	NSString *name2 = [dict2 objectForKey:context];
	return [name1 caseInsensitiveCompare:name2];
}

- (void)main;
{
	if(self.isCancelled)
		return;
	
	NSString *partialMail = [_autocompleteString lowercaseString];
	NSMutableArray *autocompleteData = [NSMutableArray array];
	
	if (partialMail) {
		for (id searchString in _addressbookData.allKeys) {
			if ([searchString rangeOfString:partialMail].location != NSNotFound) {
				[autocompleteData addObject:[_addressbookData objectForKey:searchString]];
			}
		}
	}
	
	if (!self.isCancelled) {
		[autocompleteData sortUsingFunction:compareAutocompleteData context:@"name"];
		[_target performSelectorOnMainThread:_selector withObject:autocompleteData waitUntilDone:NO];
	}
}


@end


#pragma mark -
#pragma mark SCFetchAddressbookOperation

@implementation SCFetchAddressbookOperation


#pragma mark Lifecycle

- (id)initWithTarget:(id)target selector:(SEL)selector;
{
	if ((self = [super init])) {
		_target = [target retain];
		_selector = selector;
	}
	return self;
}

- (void)dealloc;
{
	[_target release];
	[super dealloc];
}


#pragma mark main

- (void)main;
{
	if (self.isCancelled)
		return;
	
	[NSThread setThreadPriority:0.2];
	
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	
	ABAddressBookRef addressBook = ABAddressBookCreate();
	CFArrayRef allPersons = ABAddressBookCopyArrayOfAllPeople(addressBook);
	CFIndex personCount = ABAddressBookGetPersonCount(addressBook);
	
	for(CFIndex personIx = 0; personIx < personCount; personIx++) {
		
		if ([self isCancelled])
			break;
		
		ABRecordRef record = CFArrayGetValueAtIndex(allPersons, personIx);
		if (ABRecordGetRecordType(record) != kABPersonType)
			continue;
		NSString *compositeName = (NSString *)ABRecordCopyCompositeName(record);
		
		ABMultiValueRef emailValue = ABRecordCopyValue(record, kABPersonEmailProperty);
		CFIndex valueCount = ABMultiValueGetCount(emailValue);
		for (CFIndex valueIx = 0; valueIx < valueCount; valueIx++) {
			NSString *name = compositeName;
			NSString *email = (NSString *)ABMultiValueCopyValueAtIndex(emailValue, valueIx);
			NSString *label = (NSString *)ABMultiValueCopyLabelAtIndex(emailValue, valueIx);
			NSString *mailType = nil;
			if (email) {
				
				if (label) {
					mailType = (NSString *)ABAddressBookCopyLocalizedLabel((CFStringRef)label);
				} else {
					mailType = @"email";
				}
				
				if (!name) {
					name = email;
				}
				
				NSDictionary *personDict = [[NSDictionary alloc] initWithObjectsAndKeys:
											name, @"name",
											email, @"email",
											mailType, @"mailType",
											nil];
				
				[ret setObject:personDict forKey:[[NSString stringWithFormat:@"%@ %@", compositeName, email] lowercaseString]];
				[personDict release];
			}
			
			[label release];
			[email release];
			[mailType release];
		}
		CFRelease(emailValue);
		[compositeName release];
	}
	
	CFRelease(addressBook);
	CFRelease(allPersons);
	
	if (![self isCancelled]) {
		[_target performSelectorOnMainThread:_selector
								  withObject:ret
							   waitUntilDone:YES];
	}
}

@end
