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

@implementation SCBundle

+ (NSBundle *)bundle;
{
    static NSBundle *resourceBundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        resourceBundle = [[NSBundle alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"SoundCloud" ofType:@"bundle"]];
        NSAssert(resourceBundle, @"Please move the SoundCloud.bundle into the Resource Directory of your Application!"); 
    });
    return resourceBundle;
}

+ (UIImage *)imageWithName:(NSString *)aName;
{
    NSBundle *bundle = [self bundle];
    NSString *path = [bundle pathForResource:aName ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}


@end
