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

#import "SCBundle.h"

#import "SCShareToSoundCloudTitleView.h"

@implementation SCShareToSoundCloudTitleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor blackColor];
        
        self.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
        
        UIImageView *cloudImageView = [[UIImageView alloc] init];
//        cloudImageView.backgroundColor = [UIColor greenColor];
        cloudImageView.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);
        cloudImageView.image = [SCBundle imageWithName:@"cloud"];
        [cloudImageView sizeToFit];
        cloudImageView.frame = CGRectMake(9, 7, CGRectGetWidth(cloudImageView.frame), CGRectGetHeight(cloudImageView.frame));
        [self addSubview:cloudImageView];
        [cloudImageView release];
        
        UIImageView *titleImageView = [[UIImageView alloc] init];
//        titleImageView.backgroundColor = [UIColor yellowColor];
        titleImageView.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);
        titleImageView.image = [SCBundle imageWithName:@"sharetosc"];
        [titleImageView sizeToFit];
        titleImageView.frame = CGRectMake(43, 7, CGRectGetWidth(titleImageView.frame), CGRectGetHeight(titleImageView.frame));
        [self addSubview:titleImageView];
        [titleImageView release];
    }
    return self;
}

- (void)drawRect:(CGRect)rect;
{
    CGRect topLineRect;
    CGRect gradientRect;
    CGRect bottomLineRect;
    CGRectDivide(self.bounds, &topLineRect, &gradientRect, 0.0, CGRectMinYEdge);
    CGRectDivide(gradientRect, &bottomLineRect, &gradientRect, 1.0, CGRectMaxYEdge);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace,
                                                                 (CGFloat[]){1.0,0.40,0.0,1.0,  1.0,0.21,0.0,1.0},
                                                                 (CGFloat[]){0.0, 1.0},
                                                                 2);
    CGContextDrawLinearGradient(context, gradient, gradientRect.origin, CGPointMake(gradientRect.origin.x, CGRectGetMaxY(gradientRect)), 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    CGContextSetFillColor(context, (CGFloat[]){0.0,0.0,0.0,1.0});
    CGContextFillRect(context, topLineRect);
}

@end
