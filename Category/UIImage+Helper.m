//
//  UIImage+Helper.m
//  BlaBlaCar
//
//  Created by Jean-Pierre on 05/11/2015.
//  Copyright (c) 2015 BlaBlacar. All rights reserved.
//

#import "UIImage+Helper.h"

@implementation UIImage (Helper)

- (UIImage *)imageResizedToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0f);
    
    [self drawInRect:CGRectMake(0.0f, 0.0f, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end