//
//  PhotoEditorView.h
//  BlaBlaCar
//
//  Created by Jean-Pierre on 05/11/2015.
//  Copyright (c) 2015 BlaBlacar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EnumPhotoEditorMaskType.h"

@interface PhotoEditorView : UIView

@property (nonatomic) PhotoEditorMaskType   maskShape;
@property (nonatomic, assign) BOOL          hasMaskLayer;

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
 * @warning It will be a squared image cropped from the mask zone
 *
 * @return UIImage  image cropped
 *
 */
- (UIImage*)getFinalImage;

/**
 *
 * Get the image cropped using scale factor.
 *
 * @warning It will be a squared image cropped from the mask zone
 *
 * @param BOOL  booloean set to YES if you want to extract the pixels, NO to extract the points
 *
 * @return UIImage  image cropped
 *
 */
- (UIImage *)getFinalImageWithScreenScale:(BOOL)screenScale;

/**
 *
 * Get the most optimized image cropped, depending on the original one
 *
 * @warning Can give huge images. Be careful
 *
 * @return UIImage  image cropped
 *
 */
- (UIImage *)getFinalFullImage;

@end
