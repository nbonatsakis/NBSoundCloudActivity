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

#import "UIView+SoundCloudUI.h"
#import "UIImage+SoundCloudUI.h"
#import "SCBundle.h"
#import "SCSwitchLabel.h"

#import "SCSwitch.h"


@interface SCSwitch ()
- (CGFloat)handleOffsetForValue:(BOOL)value;
- (CGFloat)lableWidth;
- (CGFloat)handleWidth;
- (CGFloat)handleHeight;
- (CGRect)handleRect;
- (CGRect)onRect;
- (CGRect)offRect;
@end


@implementation SCSwitch

#pragma mark Lifecycle

- (void)commonAwake;
{
	handleRatio = (CGFloat)9 / 4;
	on = YES;
	isDragging = NO;
	handleOffset = [self handleOffsetForValue:self.on];
    
    self.clipsToBounds = YES;
    self.opaque = NO;
	
	// set up own controlls
	handleView = [[UIImageView alloc] initWithImage:[UIImage imageWithColor:[UIColor grayColor]]
								   highlightedImage:[UIImage imageWithColor:[UIColor darkGrayColor]]];
	handleView.frame = [self handleRect];
	handleView.opaque = NO;
	handleView.backgroundColor = [UIColor clearColor];
	
	onLabel = [[SCSwitchLabel alloc] initWithFrame:[self onRect]];
	onLabel.text = @"ON";
	onLabel.background = [UIImage imageWithColor:[UIColor colorWithRed:0.082 green:0.416 blue:0.792 alpha:1.000]];
	
	offLabel = [[SCSwitchLabel alloc] initWithFrame:[self offRect]];
	offLabel.text = @"OFF";
	offLabel.background = [UIImage imageWithColor:[UIColor colorWithRed:0.984 green:0.388 blue:0.102 alpha:1.000]];
	
	overlayView = [[UIImageView alloc] initWithImage:nil];
	overlayView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	overlayView.frame = self.bounds;
	
	[self addSubview:onLabel];
	[self addSubview:offLabel];
	[self addSubview:handleView];
	[self addSubview:overlayView];
	
	CALayer *maskLayer = [CALayer layer];
	maskLayer.needsDisplayOnBoundsChange = YES;
	maskLayer.delegate = self;
	self.layer.mask = maskLayer;
    
    self.onBackgroundImage = [[SCBundle imageWithName:@"switch_blue"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
    self.offBackgroundImage = [[SCBundle imageWithName:@"switch_orange"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
    self.handleImage = [[SCBundle imageWithName:@"switch_slider"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
    self.handleHighlightImage = [[SCBundle imageWithName:@"switch_slider-down"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
    self.overlayImage = [[SCBundle imageWithName:@"switch_filter"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
    self.maskImage = [[SCBundle imageWithName:@"switch_mask"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
}

- (void)awakeFromNib;
{
	[self commonAwake];
}

- (id)initWithFrame:(CGRect)frame;
{
	if ((self = [super initWithFrame:frame])) {
		[self commonAwake];
	}
	return self;
}

- (id)init;
{
	if ((self = [super initWithFrame:CGRectMake(0, 0, 105, 28)])) {
		[self commonAwake];
	}
	return self;
}

- (void)dealloc;
{
	[onLabel release];
	[offLabel release];
	[handleView release];
	[overlayView release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize on;
@synthesize handleRatio;

- (void)setOn:(BOOL)value;
{
	[self setOn:value animated:NO];
}

- (void)setOn:(BOOL)value animated:(BOOL)animated;
{
	on = value;
	
	handleOffset = [self handleOffsetForValue:self.on];
	if (animated) {
		[UIView beginAnimations:@"GPSwitchAnimation" context:nil];
		[self layoutSubviews];
		[UIView commitAnimations];
	} else {
		[self setNeedsLayout];
	}
}

- (void)setHandleRatio:(CGFloat)value;
{
	handleRatio = value;
	[self setNeedsLayout];
}

- (NSString *)onText;
{
	return onLabel.text;
}

- (void)setOnText:(NSString *)value;
{
	onLabel.text = value;
}

- (NSString *)offText;
{
	return offLabel.text;
}

- (void)setOffText:(NSString *)value;
{
	offLabel.text = value;
}

- (UIImage *)handleImage;
{
	return handleView.image;
}

- (void)setHandleImage:(UIImage *)value;
{
	handleView.image = value;
}

- (UIImage *)handleHighlightImage;
{
	return handleView.highlightedImage;
}

- (void)setHandleHighlightImage:(UIImage *)value;
{
	handleView.highlightedImage = value;
}

- (UIImage *)onBackgroundImage;
{
	return onLabel.background;
}

- (void)setOnBackgroundImage:(UIImage *)value;
{
	onLabel.background = value;
}

- (UIImage *)offBackgroundImage;
{
	return offLabel.background;
}

- (void)setOffBackgroundImage:(UIImage *)value;
{
	offLabel.background = value;
}

- (UIImage *)overlayImage;
{
	return overlayView.image;
}

- (void)setOverlayImage:(UIImage *)value;
{
	overlayView.image = value;
}

- (void)setMaskImage:(UIImage *)value;
{
	[value retain]; [maskImage release]; maskImage = value;
	[self.layer.mask setNeedsDisplay];
}

- (UIImage *)maskImage;
{
	if (!self.layer.contents) return nil;
	return [UIImage imageWithCGImage:(CGImageRef)self.layer.contents];
}

- (void)setFrame:(CGRect)value;
{
	[super setFrame:value];
	handleOffset = [self handleOffsetForValue:self.on];
}

- (void)setEnabled:(BOOL)value;
{
    [super setEnabled:value];
    self.userInteractionEnabled = value;
    
    onLabel.alpha = (value) ? 1.0 : 0.5;
    offLabel.alpha = (value) ? 1.0 : 0.5;
}


#pragma mark UIView

- (void)layoutSubviews;
{
	onLabel.frame = [self onRect];
	offLabel.frame = [self offRect];
	handleView.frame = [self handleRect];
	overlayView.frame = self.bounds;
	
	self.layer.mask.frame = self.bounds;
}

- (CGSize)sizeThatFits:(CGSize)size;
{
	return size;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event;
{
    if (!self.userInteractionEnabled) return nil;
    
	CGSize minTouchSize = CGSizeMake(120.0f, 45.0f);
	CGFloat xInset = CGRectGetWidth(self.bounds) - minTouchSize.width;
	xInset = fminf(xInset, 0.0f);
	CGFloat yInset = CGRectGetHeight(self.bounds) - minTouchSize.height;
	yInset = fminf(yInset, 0.0f);
	
	CGRect touchRect = CGRectInset(self.bounds, xInset / 2, yInset / 2);
	if (CGRectContainsPoint(touchRect, point)) {
		return self;
	}
	
	return [super hitTest:point withEvent:event];
}


#pragma mark Layer

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
{
	if (layer == self.layer) {
		[super drawLayer:layer inContext:ctx];
	} else if (layer == self.layer.mask) {
		if (maskImage) {
			UIGraphicsPushContext(ctx);
			[maskImage drawInRect:layer.bounds];
			UIGraphicsPopContext();
		} else {
			CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
			CGContextFillRect(ctx, layer.bounds);
		}
	}
}


#pragma mark Private

- (CGFloat)handleOffsetForValue:(BOOL)value;
{
	return ((value)
			? CGRectGetMaxX(self.bounds) - [self handleWidth]
			: 0.0f);
}

- (CGFloat)handleWidth;
{
	return CGRectGetWidth(self.bounds) / handleRatio;
}

- (CGFloat)handleHeight;
{
	return (handleView) ? CGRectGetHeight(self.bounds) : CGRectGetHeight(self.bounds);
}

- (CGFloat)lableWidth;
{
	return CGRectGetWidth(self.bounds);
}

- (CGRect)handleRect;
{
	return CGRectMake(handleOffset,
					  CGRectGetMinY(self.bounds),
					  [self handleWidth],
					  [self handleHeight]);
}

- (CGRect)onRect;
{
	return CGRectMake(CGRectGetMinX(self.bounds) + handleOffset - [self lableWidth] + [self handleWidth] / 2,
					  CGRectGetMinY(self.bounds),
					  [self lableWidth],
					  CGRectGetHeight(self.bounds));
}

- (CGRect)offRect;
{
	return CGRectMake(CGRectGetMinX(self.bounds) + handleOffset + [self handleWidth] / 2,
					  CGRectGetMinY(self.bounds),
					  [self lableWidth],
					  CGRectGetHeight(self.bounds));
}


#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (touches.count == 1) {
		self.enclosingScrollView.scrollEnabled = NO;
		isDragging = NO;
		
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView:self];
		if (CGRectContainsPoint(handleView.frame, point)) {
			handleView.highlighted = YES;
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	if (touches.count == 1) {
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView:self];
		
		if (point.x >= CGRectGetMinX(handleView.frame) &&
			point.x <= CGRectGetMaxX(handleView.frame)) {
			isDragging = YES;
		}
		if (isDragging) {
			handleOffset = point.x - [self handleWidth] / 2;
			handleOffset = fminf(handleOffset, CGRectGetWidth(self.bounds) - [self handleWidth]);
			handleOffset = fmaxf(handleOffset, 0.0);
		}
		
		[self setNeedsLayout];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	if (touches.count == 1) {
		self.enclosingScrollView.scrollEnabled = YES;
		handleView.highlighted = NO;
		
		BOOL oldValue = self.on;
		BOOL newValue = !self.on;
		
		if (isDragging) {
			// only switch if dragged far enough (more than 10%)
			CGFloat maxHandleOffset = CGRectGetWidth(self.bounds) - [self handleWidth];
			CGFloat offsetPercentage = handleOffset / maxHandleOffset;
			CGFloat requiredOffsetPercentage = 0.1;
			
			if (offsetPercentage < requiredOffsetPercentage) {
				newValue = NO;
				handleOffset = 0.0;
			} else if (offsetPercentage > (1.0 - requiredOffsetPercentage)) {
				newValue = YES;
				handleOffset = maxHandleOffset;
			}
		}
		
		if (oldValue != newValue) {
			self.on = newValue;
			[self sendActionsForControlEvents:UIControlEventValueChanged];
		}
		
		[UIView beginAnimations:@"GPSwitchAnimation" context:nil];
		[self layoutSubviews];
		[UIView commitAnimations];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
	if (touches.count == 1) {
		self.enclosingScrollView.scrollEnabled = YES;
		handleView.highlighted = NO;
		
		[UIView beginAnimations:@"GPSwitchAnimation" context:nil];
		[self layoutSubviews];
		[UIView commitAnimations];
	}
}


@end
