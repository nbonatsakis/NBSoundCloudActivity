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

void SC_CGContextAddRoundedRect(CGContextRef context,
                                CGRect rect,
                                CGFloat radius)
{
    CGMutablePathRef path = CGPathCreateMutable();
    SC_CGPathAddRoundedRect(path, nil, rect, radius);
    CGContextAddPath(context, path);
    CGPathRelease(path);
}


void SC_CGPathAddRoundedRect(CGMutablePathRef path,
                             const CGAffineTransform *m,
                             CGRect rect,
                             CGFloat radius)
{    
    CGPathMoveToPoint(path, m,
                      rect.origin.x, rect.origin.y + radius);
    CGPathAddArcToPoint(path, m,
                        rect.origin.x, rect.origin.y,
                        rect.origin.x + radius, rect.origin.y,
                        radius);
    CGPathAddArcToPoint(path, m,
                        rect.origin.x + rect.size.width, rect.origin.y,
                        rect.origin.x + rect.size.width, rect.origin.y + radius,
                        radius);
    CGPathAddArcToPoint(path, m,
                        rect.origin.x + rect.size.width, rect.origin.y + rect.size.height,
                        rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height,
                        radius);
    CGPathAddArcToPoint(path, m,
                        rect.origin.x, rect.origin.y + rect.size.height,
                        rect.origin.x, rect.origin.y + rect.size.height - radius,
                        radius);
    CGPathCloseSubpath(path);
}
