//
//  PhotoEditorView.h
//  BlaBlaCar
//
//  Created by Jean-Pierre on 05/11/2015.
//  Copyright (c) 2015 BlaBlacar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoEditorView : UIView

@property (nonatomic, assign) BOOL hasMaskLayer;

/**
 *
 * Set the image to edit
 *
 * @param UIImage   image to edit
 *
 */
- (void)setImage:(UIImage*)image;

/**
 *
 * Rotate the image to the left (90 degrees)
 *
 */
- (void)rotateToLeft;

/**
 *
 * Rotate the image to the right (90 degrees)
 *
 */
- (void)rotateToRight;

/**
 *
 * Get the image cropped.
 *
 * @warning It will be a squared image cropped from the cropped circle zone
 *
 * @return UIImage  image cropped
 *
 */
- (UIImage*)getFinalImage;

@end
