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

@implementation UIColor (SoundCloudUI)

+ (UIColor *)transparentBlack;
{
    return [UIColor colorWithWhite:0 alpha:0.2];
}

+ (UIColor *)almostBlackColor;
{
    return [UIColor colorWithWhite:0.200 alpha:1.0];
}


+ (UIColor *)listSubtitleColor;
{
    return [UIColor colorWithWhite:0.510 alpha:1.000];
}

+ (UIColor *)soundCloudOrangeWithAlpha:(CGFloat)alpha;
{
   return [UIColor colorWithRed:0.984 green:0.388 blue:0.106 alpha:alpha]; 
}

+ (UIColor *)soundCloudOrange;
{
    return [UIColor soundCloudOrangeWithAlpha:1.0];
}

+ (UIColor *)soundCloudListShineThroughWhite;
{
    return [UIColor colorWithWhite:1.0 alpha:0.8];
}

@end
