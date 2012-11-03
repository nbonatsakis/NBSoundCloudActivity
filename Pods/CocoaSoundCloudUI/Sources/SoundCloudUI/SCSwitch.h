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
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class SCSwitchLabel;

@interface SCSwitch : UIControl {
	BOOL on;
	
	UIImageView		*handleView;
	SCSwitchLabel	*onLabel;
	SCSwitchLabel	*offLabel;
	UIImageView		*overlayView;
	
	UIImage			*maskImage;
	
	CGFloat	handleRatio;
	CGFloat handleOffset; // 0.0 to 1.0 relative to width of bounds
	BOOL	isDragging;
}
@property(nonatomic,getter=isOn) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;

@property (nonatomic,copy) NSString		*onText;
@property (nonatomic,copy) NSString		*offText;
@property (nonatomic,retain) UIImage	*handleImage;
@property (nonatomic,retain) UIImage	*handleHighlightImage;
@property (nonatomic,retain) UIImage	*onBackgroundImage;
@property (nonatomic,retain) UIImage	*offBackgroundImage;
@property (nonatomic,retain) UIImage	*overlayImage;
@property (nonatomic,retain) UIImage	*maskImage;

@property (nonatomic, assign) CGFloat	handleRatio;	// 0.0 .. 1.0 - as a percentage of the total width of thw switch


- (void)commonAwake;


@end
