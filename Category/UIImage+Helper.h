//
//  UIImage+Helper.h
//  BlaBlaCar
//
//  Created by Jean-Pierre on 05/11/2015.
//  Copyright (c) 2015 BlaBlacar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Helper)

/**
 *
 * Resize self to size given in parameter
 *
 * @param CGSize    new size
 *
 * @return UIImage  the image resized
 *
 */
- (UIImage *)imageResizedToSize:(CGSize)newSize;

@end
