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

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@protocol SCSharingMailPickerControllerDelegate;

@interface SCSharingMailPickerController : UIViewController <UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource>

#pragma mark Lifecycle

- (id)initWithDelegate:(id<SCSharingMailPickerControllerDelegate>)delegate;

#pragma mark Accessors

@property (nonatomic, retain) id userInfo;
@property (nonatomic, retain) NSArray *result;

@end

#pragma mark Delegate Protocol

@protocol SCSharingMailPickerControllerDelegate <NSObject>
- (void)sharingMailPickerController:(SCSharingMailPickerController *)controller didFinishWithResult:(NSArray *)emailAdresses;
- (void)sharingMailPickerControllerDidCancel:(SCSharingMailPickerController *)controller;
@end
