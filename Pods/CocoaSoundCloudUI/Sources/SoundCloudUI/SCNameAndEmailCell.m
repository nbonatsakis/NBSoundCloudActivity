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

#import "UIColor+SoundCloudUI.h"

#import "SCNameAndEmailCell.h"

@interface SCNameAndEmailCell ()
@property (nonatomic, assign) UILabel *nameLabel;
@property (nonatomic, assign) UILabel *emailLabel;
@property (nonatomic, assign) UILabel *mailTypeLabel;
@end

@implementation SCNameAndEmailCell

#pragma mark Lifecycle

- (id)init;
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 44)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        
        self.nameLabel = [[[UILabel alloc] init] autorelease];
        self.nameLabel.opaque = NO;
        self.nameLabel.font = [UIFont boldSystemFontOfSize:15.0];
        self.nameLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.nameLabel];
        
        self.emailLabel = [[[UILabel alloc] init] autorelease];
        self.emailLabel.opaque = NO;
        self.emailLabel.textColor = [UIColor listSubtitleColor];
        self.emailLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.emailLabel];
        
        self.mailTypeLabel = [[[UILabel alloc] init] autorelease];
        self.mailTypeLabel.opaque = NO;
        self.mailTypeLabel.font = [UIFont boldSystemFontOfSize:15.0];
        self.mailTypeLabel.textColor = [UIColor listSubtitleColor];
        self.mailTypeLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.mailTypeLabel];
    }
    return self;
}

#pragma mark Accessors

@synthesize nameLabel;
@synthesize emailLabel;
@synthesize mailTypeLabel;

- (NSString *)name;
{
	return nameLabel.text;
}

- (NSString *)email;
{
	return emailLabel.text;
}

- (NSString *)mailType;
{
	return mailTypeLabel.text;
}

- (void)setName:(NSString *)value;
{
	nameLabel.text = value;
}

- (void)setEmail:(NSString *)value;
{
	emailLabel.text = value;
}

- (void)setMailType:(NSString *)value;
{
	mailTypeLabel.text = value;
}

#pragma mark View

- (void)layoutSubviews;
{
    [super layoutSubviews];
    self.nameLabel.frame = CGRectMake(11, 2, 289, 21);
    self.emailLabel.frame = CGRectMake(76, 20, 224, 21);
    self.mailTypeLabel.frame = CGRectMake(11, 20, 57, 21);
}

@end
