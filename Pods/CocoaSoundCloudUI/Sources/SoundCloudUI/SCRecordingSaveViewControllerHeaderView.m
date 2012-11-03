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

#import "QuartzCore+SoundCloudUI.h"
#import "UIImage+SoundCloudUI.h"
#import "UIColor+SoundCloudUI.h"

#import "SCHorizontalLineView.h"
#import "SCUnderlinedButton.h"
#import "SCCoverImageButton.h"
#import "SCSwitch.h"
#import "SCBundle.h"
#import "SCTextField.h"

#import "UIDevice+SoundCloudUI.h"

#import "SCRecordingSaveViewControllerHeaderView.h"

#define TEXTBOX_LEFT 102.0
#define TEXTBOX_RIGHT 9.0
#define TEXTBOX_TOP 9.0 + 55.0
#define TEXTBOX_HEIGHT 84.0

#define SPACING 10.0

#define COVER_IMAGE_CENTER_X 50 
#define COVER_IMAGE_CENTER_Y 95

#define COVER_IMAGE_SIZE 82

@interface SCRecordingSaveViewControllerHeaderView () <UITextFieldDelegate>

- (void)commonAwake;

#pragma mark Accessors
@property (nonatomic, readwrite, assign) SCHorizontalLineView *firstHR;
@property (nonatomic, readwrite, assign) SCHorizontalLineView *secondHR;
@property (nonatomic, readwrite, assign) UIImageView *avatarImageView;
@property (nonatomic, readwrite, assign) UILabel *userNameLabel;
@property (nonatomic, readwrite, assign) UIButton *logoutButton;
@property (nonatomic, readwrite, assign) UIView *logoutSeparator;
@property (nonatomic, readwrite, assign) UIButton *coverImageButton;
@property (nonatomic, readwrite, assign) UITextField *whatTextField;
@property (nonatomic, readwrite, assign) UITextField *whereTextField;
@property (nonatomic, readwrite, assign) UIButton *disclosureButton;
@property (nonatomic, readwrite, assign) SCSwitch *privateSwitch;

@property (nonatomic, readonly) CGRect textRect;

#pragma mark Helper

- (float)margin;

@end


@implementation SCRecordingSaveViewControllerHeaderView

#pragma mark Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonAwake];
    }
    return self;
}

- (void)awakeFromNib;
{
    [super awakeFromNib];
    [self commonAwake];
}

- (void)commonAwake;
{
    self.backgroundColor = [UIColor clearColor]; 
    
    // Horizontal Lines
    self.firstHR = [[[SCHorizontalLineView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    [self addSubview:self.firstHR];
    self.secondHR = [[[SCHorizontalLineView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    [self addSubview:self.secondHR];
    
    // Avatar Image
    self.avatarImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    [self addSubview:self.avatarImageView];

    // User Name
    self.userNameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    self.userNameLabel.opaque = NO;
    self.userNameLabel.backgroundColor = [UIColor clearColor];
    self.userNameLabel.textColor = [UIColor whiteColor];
    self.userNameLabel.font = [UIFont systemFontOfSize:15.0];
    [self addSubview:self.userNameLabel];

    // Separator
    self.logoutSeparator =  [[[UIView alloc] init] autorelease];
    self.logoutSeparator.backgroundColor = [UIColor blackColor];
    [self addSubview:self.logoutSeparator];
    
    // Logout Button
    self.logoutButton = [[[SCUnderlinedButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    self.logoutButton.backgroundColor = [UIColor clearColor];
    self.logoutButton.titleLabel.textColor = [UIColor whiteColor];
    self.logoutButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [self.logoutButton setTitle:SCLocalizedString(@"record_save_logout", @"Log out") forState:UIControlStateNormal];
    [self.logoutButton setShowsTouchWhenHighlighted:YES];
    [self.logoutButton sizeToFit];
    [self addSubview:self.logoutButton];
    
    // Cover Image
    self.coverImageButton = [[[SCCoverImageButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    self.coverImageButton.opaque = NO;
    self.coverImageButton.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.coverImageButton.titleLabel.textAlignment = UITextAlignmentCenter;
    self.coverImageButton.titleLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    [self.coverImageButton setShowsTouchWhenHighlighted:YES];
    [self addSubview:self.coverImageButton];
    
    // What
    self.whatTextField = [[[SCTextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    self.whatTextField.opaque = NO;
    self.whatTextField.textAlignment = UITextAlignmentLeft;
    self.whatTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.whatTextField.textColor = [UIColor whiteColor];
    self.whatTextField.font = [UIFont systemFontOfSize:15.0];
    self.whatTextField.placeholder = SCLocalizedString(@"record_save_what", @"What");
    self.whatTextField.returnKeyType = UIReturnKeyDone;
    self.whatTextField.delegate = self;
    [self addSubview:self.whatTextField];
    
    // Where
    self.whereTextField = [[[SCTextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    self.whereTextField.opaque = NO;
    self.whereTextField.textAlignment = UITextAlignmentLeft;
    self.whereTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.whereTextField.textColor = [UIColor whiteColor];
    self.whereTextField.font = [UIFont systemFontOfSize:15.0];
    self.whereTextField.placeholder = SCLocalizedString(@"record_save_where", @"Where");
    self.whereTextField.returnKeyType = UIReturnKeyDone;
    self.whereTextField.delegate = self;
    [self addSubview:self.whereTextField];
    
    // Disclosure Indicator
    self.disclosureButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    [self.disclosureButton setImage:[SCBundle imageWithName:@"DisclosureIndicator"] forState:UIControlStateNormal];
    [self.disclosureButton sizeToFit];
    [self.disclosureButton setShowsTouchWhenHighlighted:NO];
    [self addSubview:self.disclosureButton];
    
    // Privacy Switch
    self.privateSwitch = [[[SCSwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    self.privateSwitch.onText = SCLocalizedString(@"sc_upload_public", @"Public");
    self.privateSwitch.offText = SCLocalizedString(@"sc_upload_private", @"Private");
    [self addSubview:self.privateSwitch];
    
    [self setUserName:nil];
    [self setAvatarImage:nil];
    [self setCoverImage:nil];
}

- (void)dealloc;
{
    self.avatarImageView = nil;
    [super dealloc];
}

#pragma mark Accessors

@synthesize firstHR;
@synthesize secondHR;
@synthesize avatarImageView;
@synthesize userNameLabel;
@synthesize logoutButton;
@synthesize logoutSeparator;
@synthesize coverImageButton;
@synthesize whatTextField;
@synthesize whereTextField;
@synthesize disclosureButton;
@synthesize privateSwitch;

- (void)setAvatarImage:(UIImage *)anImage;
{
    if (anImage) {
        self.avatarImageView.image = [anImage imageByResizingTo:self.avatarImageView.bounds.size forRetinaDisplay:YES];
    } else {
        self.avatarImageView.image = [[SCBundle imageWithName:@"default-avatar"] imageByResizingTo:self.avatarImageView.bounds.size forRetinaDisplay:YES];
    }
}

- (void)setUserName:(NSString *)aUserName;
{
    self.userNameLabel.text = aUserName;
    [self layoutSubviews];
}

- (void)setCoverImage:(UIImage *)aCoverImage;
{
    if (aCoverImage) {
        [self.coverImageButton setTitle:nil forState:UIControlStateNormal];
    } else {
        [self.coverImageButton setTitle:SCLocalizedString(@"record_save_add_cover_artwork", @"Add\nimage") forState:UIControlStateNormal];
    }
    
    [self.coverImageButton setImage:[aCoverImage imageByResizingTo:self.coverImageButton.bounds.size forRetinaDisplay:YES] forState:UIControlStateNormal];
}

- (CGRect)textRect;
{
    CGRect textRect = self.coverImageButton.frame;
    
    textRect.origin.x = CGRectGetMaxX(textRect) + 11;
    textRect.size.width = CGRectGetWidth(self.bounds) - [self margin] - textRect.origin.x;
    
    return textRect;
}

#pragma mark -

- (void)layoutSubviews;
{
    [super layoutSubviews];
    
    self.avatarImageView.frame = CGRectMake([self margin] + 3, SPACING, 20, 20);
    
    CGFloat maxUserLabelWidth = CGRectGetWidth(self.bounds)
    - 2 * [self margin]
    - 3 * SPACING
    - CGRectGetWidth(self.avatarImageView.bounds)
    - CGRectGetWidth(self.logoutSeparator.bounds)
    - CGRectGetWidth(self.logoutButton.bounds);
    
    CGSize userLabelSize = self.userNameLabel.text ? [self.userNameLabel.text sizeWithFont:self.userNameLabel.font] : CGSizeZero;
    userLabelSize.width = MIN(userLabelSize.width, maxUserLabelWidth);
    CGRect labelRect = CGRectZero;
    labelRect.size = userLabelSize;
    labelRect.origin = CGPointMake(CGRectGetMaxX(self.avatarImageView.frame) + SPACING, SPACING);
    self.userNameLabel.frame = labelRect;
    
    CGFloat fontSize = 16;
    
    if (self.userNameLabel.text) {
        self.logoutSeparator.frame = CGRectMake(CGRectGetMaxX(self.userNameLabel.frame) + SPACING,
                                                CGRectGetMidY(self.userNameLabel.frame) - fontSize / 2,
                                                1.0,
                                                fontSize);
    } else {

        self.logoutSeparator.frame = CGRectMake(CGRectGetMaxX(self.avatarImageView.frame) + SPACING,
                                                CGRectGetMidY(self.avatarImageView.frame) - fontSize / 2,
                                                1.0,
                                                fontSize);
    }
    
    
    
    CGRect logoutButtonFrame = CGRectZero;
    if (self.logoutButton.titleLabel.text) {
        logoutButtonFrame.size = [self.logoutButton.titleLabel.text sizeWithFont:self.logoutButton.titleLabel.font];
        logoutButtonFrame.origin = CGPointMake(CGRectGetMaxX(self.logoutSeparator.frame) + SPACING, SPACING);
    }
    self.logoutButton.frame = logoutButtonFrame;
    
    self.firstHR.frame = CGRectMake(0, CGRectGetMaxY(self.avatarImageView.frame) + SPACING, CGRectGetWidth(self.bounds), 2.0);
    
    self.coverImageButton.frame = CGRectMake([self margin], CGRectGetMaxY(self.firstHR.frame) + 13, COVER_IMAGE_SIZE, COVER_IMAGE_SIZE);
    
    CGRect whatTextFieldFrame;
    CGRect whereTextFieldFrame;
    CGRectDivide(self.textRect, &whatTextFieldFrame, &whereTextFieldFrame, CGRectGetHeight(self.textRect) / 2, CGRectMinYEdge);
    self.whatTextField.frame = CGRectInset(whatTextFieldFrame, SPACING, 0);
    
    whereTextFieldFrame = CGRectInset(whereTextFieldFrame, SPACING, 0);
    whereTextFieldFrame.size.width -= self.disclosureButton.bounds.size.width / 2 + SPACING;
    self.whereTextField.frame = whereTextFieldFrame;
    
    self.disclosureButton.center = CGPointMake(CGRectGetMaxX(self.whereTextField.frame) + SPACING, CGRectGetMidY(self.whereTextField.frame));
    
    self.privateSwitch.frame = CGRectMake([self margin], CGRectGetMaxY(self.coverImageButton.frame) + 15.0, CGRectGetWidth(self.bounds) - 2 * [self margin], 30);
    
    self.secondHR.frame = CGRectMake(0, CGRectGetMaxY(self.privateSwitch.frame) + 15.0, CGRectGetWidth(self.bounds), 2.0);
    
    self.bounds = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetMaxY(self.secondHR.frame));
    
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect;
{
    [super drawRect:rect];

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 1.0);
    [[UIColor blackColor] setStroke];
    [[UIColor transparentBlack] setFill];
    
    CGRect textRect = self.textRect;
    
    SC_CGContextAddRoundedRect(context, CGRectInset(textRect, 0.5, 0.5), 7.0);
    CGContextFillPath(context);
    
    SC_CGContextAddRoundedRect(context, CGRectInset(textRect, 0.5, 0.5), 7.0);
    CGContextMoveToPoint(context, CGRectGetMinX(textRect), CGRectGetMidY(textRect)+0.5);
    CGContextAddLineToPoint(context, CGRectGetMaxX(textRect), CGRectGetMidY(textRect)+0.5);
    CGContextStrokePath(context);
}


#pragma mark Helper

- (float)margin;
{
    if ([UIDevice isIPad]) {
        return 30.0;
    } else {
        return 9.0;
    }
}

@end
