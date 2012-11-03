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
#import "UIColor+SoundCloudUI.h"

#import "SCCoverImageButton.h"

@implementation SCCoverImageButton

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 3.0;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor blackColor] setStroke];
    [[UIColor transparentBlack] setFill];
    
    CGContextSetLineWidth(context, 1.0);
    SC_CGContextAddRoundedRect(context, CGRectInset(self.bounds, 0.5, 0.5), 7.0);
    CGContextStrokePath(context);
    SC_CGContextAddRoundedRect(context, CGRectInset(self.bounds, 0.5, 0.5), 7.0);
    CGContextFillPath(context);
}

@end
