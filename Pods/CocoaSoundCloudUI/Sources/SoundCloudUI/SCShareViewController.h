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


typedef void(^SCSharingViewControllerComletionHandler)(NSDictionary *trackInfo, NSError *error);

@interface SCShareViewController : UINavigationController

#pragma mark Class methods

+ (SCShareViewController *)shareViewControllerWithFileURL:(NSURL *)aFileURL
                                        completionHandler:(SCSharingViewControllerComletionHandler)aCompletionHandler;

+ (SCShareViewController *)shareViewControllerWithFileData:(NSData *)someData
                                         completionHandler:(SCSharingViewControllerComletionHandler)aCompletionHandler;

#pragma mark Accessors

- (void)setPrivate:(BOOL)isPrivate;
- (void)setDownloadable:(BOOL)downloadable;
- (void)setCoverImage:(UIImage *)aCoverImage;
- (void)setTitle:(NSString *)aTitle;
- (void)setCreationDate:(NSDate *)aDate;
- (void)setTags:(NSArray *)someTags;
- (void)setSharingNote:(NSString *)aSharingNote;

#pragma mark Foursquare

- (void)setFoursquareClientID:(NSString *)aClientID
                 clientSecret:(NSString *)aClientSecret;

@end
