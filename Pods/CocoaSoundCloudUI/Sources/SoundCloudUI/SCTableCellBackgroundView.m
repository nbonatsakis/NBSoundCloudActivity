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

// http://stackoverflow.com/questions/400965/how-to-customize-the-background-border-colors-of-a-grouped-table-view

#import "QuartzCore+SoundCloudUI.h"

#import "SCTableCellBackgroundView.h"

@implementation SCTableCellBackgroundView

#pragma mark Lifecycle

- (id)initWithFrame:(CGRect)frame;
{
    if ((self = [super initWithFrame:frame])) {
		self.opaque = NO;
    }
    return self;
}

- (void)dealloc;
{
	[borderColor release];
    [backgroundColor release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize borderColor, position;

- (void)setBackgroundColor:(UIColor *)aBackgroundColor;
{
    if (backgroundColor != aBackgroundColor) {
        [backgroundColor release];
        [aBackgroundColor retain];
        backgroundColor = aBackgroundColor;
        [super setBackgroundColor:[UIColor clearColor]];
    }
}


#pragma mark UIView

- (void)drawRect:(CGRect)rect;
{
    CGFloat radius = 10.0;
    CGFloat lineWidth = 1.0;
    CGRect borderRect = CGRectInset(self.bounds, lineWidth/2, lineWidth/2);
    if (position == GPTableCellBackgroundViewPositionBottom || position == GPTableCellBackgroundViewPositionMiddle) {
        borderRect.origin.y -= lineWidth/2;
        borderRect.size.height += lineWidth/2;
    }

    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGMutablePathRef path = CGPathCreateMutable();
    
    if (position == GPTableCellBackgroundViewPositionTop || position == GPTableCellBackgroundViewPositionSingle) { //Round on top
        CGPathMoveToPoint(path, nil,
                          borderRect.origin.x + borderRect.size.width - radius, borderRect.origin.y);
        CGPathAddArcToPoint(path, nil,
                            borderRect.origin.x + borderRect.size.width, borderRect.origin.y,
                            borderRect.origin.x + borderRect.size.width, borderRect.origin.y + radius,
                            radius);
    } else { //Don't round on top
        CGPathMoveToPoint(path, nil,
                          borderRect.origin.x + borderRect.size.width, borderRect.origin.y);
    }

    
    if (position == GPTableCellBackgroundViewPositionBottom || position == GPTableCellBackgroundViewPositionSingle) { //Round on Bottom
        CGPathAddArcToPoint(path, nil,
                            borderRect.origin.x + borderRect.size.width, borderRect.origin.y + borderRect.size.height,
                            borderRect.origin.x + borderRect.size.width - radius, borderRect.origin.y + borderRect.size.height, 
                            radius);
        CGPathAddArcToPoint(path, nil,
                            borderRect.origin.x, borderRect.origin.y + borderRect.size.height,
                            borderRect.origin.x, borderRect.origin.y + borderRect.size.height - radius, 
                            radius);
    } else { //Don't round on Bottom
        CGPathAddLineToPoint(path, nil, borderRect.origin.x + borderRect.size.width, borderRect.origin.y + borderRect.size.height);
        CGPathAddLineToPoint(path, nil, borderRect.origin.x, borderRect.origin.y + borderRect.size.height);
    }
    
    if (position == GPTableCellBackgroundViewPositionTop || position == GPTableCellBackgroundViewPositionSingle) { //Round on top
        CGPathAddArcToPoint(path, nil,
                            borderRect.origin.x, borderRect.origin.y,
                            borderRect.origin.x + radius, borderRect.origin.y,
                            radius);
        CGPathCloseSubpath(path);
    } else { //Don't round on top
        CGPathAddLineToPoint(path, nil, borderRect.origin.x, borderRect.origin.y);
    }
    

    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    CGContextFillPath(context);
    
    CGContextAddPath(context, path);
    CGContextSetStrokeColorWithColor(context, [borderColor CGColor]);
    CGContextStrokePath(context);
    
    CGPathRelease(path);
}


@end


#pragma mark -


@implementation UITableView (GPTableCellBackgroundViewAdditions)

- (GPTableCellBackgroundViewPosition)cellPositionForIndexPath:(NSIndexPath *)indexPath;
{
	if (self.style == UITableViewStylePlain)
		return GPTableCellBackgroundViewPositionMiddle;
	
	BOOL isRoundOnTop = (indexPath.row == 0);
	BOOL isRoundOnBottom = (indexPath.row == ([self.dataSource tableView:self numberOfRowsInSection:indexPath.section] - 1));
	if (isRoundOnTop && isRoundOnBottom) {
		return GPTableCellBackgroundViewPositionSingle;
	} else if (isRoundOnTop) {
		return GPTableCellBackgroundViewPositionTop;
	} else if (isRoundOnBottom) {
		return GPTableCellBackgroundViewPositionBottom;
	} else {
		return GPTableCellBackgroundViewPositionMiddle;
	}
}


@end