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

#import "SCSwitchLabel.h"


@implementation SCSwitchLabel

#pragma mark Lifecycle

- (id)initWithFrame:(CGRect)frame;
{
	if ((self = [super initWithFrame:frame])) {
		label = [[UILabel alloc] initWithFrame:self.bounds];
		label.backgroundColor = [UIColor clearColor];
		label.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		label.font = [UIFont systemFontOfSize:15];
		label.textColor = [UIColor whiteColor];
		label.shadowColor = [UIColor colorWithWhite:0.2 alpha:0.3];
		label.shadowOffset = CGSizeMake(0, -1);
		label.textAlignment = UITextAlignmentCenter;
		[self addSubview:label];
	}
	return self;
}

- (void)dealloc;
{
	[background release];
	[label release];
	[super dealloc];
}


#pragma mark Accessors

@dynamic text;
@synthesize background;

- (NSString *)text;
{
	return label.text;
}

- (void)setText:(NSString *)value;
{
	label.text = value;
}

- (void)setBackground:(UIImage *)value;
{
	[value retain]; [background release]; background = value;
	[self setNeedsDisplay];
}


#pragma mark UIView

- (void)drawRect:(CGRect)rect;
{
	[super drawRect:rect];
	if (background) {
		[background drawInRect:self.bounds];
	} else {
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(context, [UIColor greenColor].CGColor);
		CGContextFillRect(context, self.bounds);
	}
}

@end
