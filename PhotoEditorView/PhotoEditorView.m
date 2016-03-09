//
//  PhotoEditorView.m
//  BlaBlaCar
//
//  Created by Jean-Pierre on 05/11/2015.
//  Copyright (c) 2015 BlaBlacar. All rights reserved.
//

#import "PhotoEditorView.h"
#import "UIImage+Helper.h"
#import "PhotoEditorConfig.h"

@interface PhotoEditorView ()

@property (nonatomic, strong) UIImageView   *imageView;
@property (nonatomic, strong) UIImage       *orginalImage;

@property (nonatomic, assign) CGPoint       initialTouchPoint;
@property (nonatomic, assign) CGPoint       initialCenterImageView;

@property (nonatomic, strong) CAShapeLayer  *maskLayer;

@end

@implementation PhotoEditorView

#pragma mark - Constructor

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self) {
        self.clipsToBounds          = YES;
        self.exclusiveTouch         = YES;
        
        self.maskShape = PhotoEditorMaskTypeRounded;
        
        self.initialTouchPoint      = CGPointZero;
        self.initialCenterImageView = CGPointZero;
        
        [self imageView];
        [self addMaskLayer];
        
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                                     action:@selector(didPinchView:)];
        
        [self addGestureRecognizer:pinchGestureRecognizer];
    }
    
    return self;
}

#pragma mark - View life cycle

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateMaskLayerPosition];
    
    if (self.imageView.image.size.width > self.frame.size.width) {
        CGRect frame    = self.imageView.frame;
        CGFloat height  = self.imageView.image.size.height * self.frame.size.width / self.imageView.image.size.width;
        frame.size      = CGSizeMake(self.frame.size.width, height);
        
        self.imageView.frame    = frame;
        self.imageView.center   = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        self.imageView.image    = [self.imageView.image imageResizedToSize:frame.size]; // :-(
    }
}

#pragma mark - Public methods -

#pragma mark - Public methods - Setter

- (void)setImage:(UIImage*)image
{
    self.orginalImage = image;
    self.imageView.image = image;
}

- (void)setMaskShape:(PhotoEditorMaskType)maskShape
{
    _maskShape = maskShape;
    if (_hasMaskLayer) {
        [self updateMaskLayerPosition];
    }
}

- (void)setHasMaskLayer:(BOOL)hasMaskLayer
{
    _hasMaskLayer = hasMaskLayer;
    
    if (_hasMaskLayer) {
        [self addMaskLayer];
    }
}

#pragma mark - Public methods - Getter

- (UIImage *)getFinalImage
{
    return [self getFinalImageWithScreenScale:NO];
}

- (UIImage *)getFinalImageWithScreenScale:(BOOL)screenScale
{
    CGFloat sizeFactor = screenScale?[UIScreen mainScreen].scale:1.0f;
    
    if ((self.hasMaskLayer) && (nil != _maskLayer.superlayer)) {
        [self.maskLayer removeFromSuperlayer];
    }
    
    CGSize maskSize     = CGSizeZero;
    CGPoint maskOrigin    = CGPointZero;
    
    if (self.hasMaskLayer) {
        maskSize = [self getMaskLayerSize];
        maskOrigin = CGPointMake((self.frame.size.width - maskSize.width)/2,
                                 (self.frame.size.height - maskSize.height)/2);
    } else {
        maskSize = self.frame.size;
    }
    
    maskSize.width *= sizeFactor;
    maskSize.height *= sizeFactor;
    
    maskOrigin.x *= sizeFactor;
    maskOrigin.y *= sizeFactor;
    
    UIGraphicsBeginImageContextWithOptions(maskSize, NO, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -maskOrigin.x, -maskOrigin.y);
    CGContextScaleCTM(context, sizeFactor, sizeFactor);
    [self.layer renderInContext:context];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    [self addMaskLayer];
    
    return finalImage;
}

- (UIImage *)getFinalFullImage
{
    
    CGSize viewSize = self.bounds.size;
    CGSize maskSize = self.hasMaskLayer?[self getMaskLayerSize]:viewSize;
    
    CGPoint maskOrigin = CGPointMake((self.frame.size.width - maskSize.width)/2,
                             (self.frame.size.height - maskSize.height)/2);
    
    CGFloat zoomRatio = self.orginalImage.size.width / self.imageView.frame.size.width;

    CGSize finalImageSize = CGSizeMake(maskSize.width * zoomRatio, maskSize.height * zoomRatio);
    
    UIGraphicsBeginImageContextWithOptions(finalImageSize, NO, 0.0f);
    
    CGPoint imageOrigin = CGPointZero;
    imageOrigin.x = (self.imageView.frame.origin.x - maskOrigin.x) * zoomRatio;
    imageOrigin.y = (self.imageView.frame.origin.y - maskOrigin.y) * zoomRatio;

    [self.orginalImage drawAtPoint:imageOrigin];
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();

    return finalImage;
}

#pragma mark - Public methods - Rotation methods

- (void)rotateToLeft
{
    [self rotateToOrientation:UIImageOrientationLeft];
}

- (void)rotateToRight
{
    [self rotateToOrientation:UIImageOrientationRight];
}

#pragma mark - Private methods -

#pragma mark - Private methods - Pinch

- (void)didPinchView:(UIPinchGestureRecognizer*)recognizer
{
    CGFloat scale   = recognizer.scale;
    
    CGFloat width   = self.imageView.frame.size.width * scale;
    CGFloat height  = self.imageView.frame.size.height * scale;
    
    CGFloat limitMinWidth   = self.frame.size.width * PERCENT_MIN_SCALE / 100;
    CGFloat limitMaxWidth   = self.frame.size.width * PERCENT_MAX_SCALE / 100;
    
    CGFloat limitMinHeight  = self.frame.size.height * PERCENT_MIN_SCALE / 100;
    CGFloat limitMaxHeight  = self.frame.size.height * PERCENT_MAX_SCALE / 100;
    
    if ((width < limitMinWidth) ||
        (width > limitMaxWidth) ||
        (height < limitMinHeight) ||
        (height > limitMaxHeight)) {
        NSLog(@"[PhotoEditorView] - Stop pinching, limit reached, change the configuration file if you want more/less ;)");
        
        return;
    }
    
    self.imageView.transform    = CGAffineTransformScale(self.imageView.transform, scale, scale);
    recognizer.scale            = 1.0f;
}

#pragma mark - Private methods - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch  = [touches allObjects].firstObject;
    CGPoint point   = [touch locationInView:self];
    
    self.initialTouchPoint      = point;
    self.initialCenterImageView = self.imageView.center;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches allObjects].firstObject;
    CGPoint point = [touch locationInView:self];
    
    CGFloat diffX = fabs(self.initialTouchPoint.x - point.x);
    CGFloat diffY = fabs(self.initialTouchPoint.y - point.y);
    
    if (point.x < self.initialTouchPoint.x) {
        diffX = -diffX;
    }
    
    if (point.y < self.initialTouchPoint.y) {
        diffY = -diffY;
    }
    
    CGFloat centerX = self.initialCenterImageView.x + diffX;
    CGFloat centerY = self.initialCenterImageView.y + diffY;
    
    if ((centerX < 0.0f) ||
        (centerX > self.frame.size.width) ||
        (centerY < 0.0f) ||
        (centerY > self.frame.size.height)) {
        NSLog(@"[PhotoEditorView] - Limit reached for moving the picture");
        
        return;
    }
    
    __weak PhotoEditorView *weakSelf = self;
    
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.imageView.center = CGPointMake(centerX, centerY);
    } completion:nil];
}

#pragma mark - Private methods - Rotation

- (void)rotateToOrientation:(UIImageOrientation)orientation
{    
    CGFloat newWidth    = self.imageView.image.size.height;
    CGFloat newHeight   = self.imageView.image.size.width;
    CGRect frame        = CGRectMake(0.0f, 0.0f, newWidth, newHeight);
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    
    [[UIImage imageWithCGImage:[self.imageView.image CGImage] scale:1.0f orientation:orientation] drawInRect:frame];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    self.imageView.image = newImage;
}

#pragma mark - Private methods - Mask layer methods -

- (void)addMaskLayer
{
    if ((self.hasMaskLayer) && (nil == _maskLayer.superlayer)) {
        [self.layer addSublayer:self.maskLayer];
        [self updateMaskLayerPosition];
    }
}

- (CGSize)getMaskLayerSize
{
    switch (self.maskShape) {
        case PhotoEditorMaskTypeRounded:
        {
            CGSize squareSize = CGSizeZero;
            
            if (self.frame.size.height < self.frame.size.width) {
                squareSize.height = PERCENT_SIZE_FOR_ROUND_INDICATOR * self.frame.size.height / 100;
            } else {
                squareSize.height = PERCENT_SIZE_FOR_ROUND_INDICATOR * self.frame.size.width / 100;
            }
            squareSize.width = squareSize.height;
            
            return squareSize;
        }
            
        case PhotoEditorMaskTypeRectangle:
        {
            return CGSizeMake(PERCENT_SIZE_FOR_RECTANGLE * self.bounds.size.width / 100,
                              PERCENT_SIZE_FOR_RECTANGLE * self.bounds.size.height / 100);
        }

        default:
            return CGSizeZero;
    }
}

- (void)updateMaskLayerPosition
{
    if (NO == self.hasMaskLayer) {
        return;
    }
    
    CGSize maskSize         = [self getMaskLayerSize];
    CGRect maskFrame        = CGRectMake(self.frame.size.width/2 - maskSize.width/2,
                                         self.frame.size.height/2 - maskSize.height/2,
                                         maskSize.width,
                                         maskSize.height);
    UIBezierPath *path      = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                         cornerRadius:0.0f];
    UIBezierPath *maskPath  = nil;
    
    switch (self.maskShape) {
        case PhotoEditorMaskTypeRounded:
            maskPath = [UIBezierPath bezierPathWithRoundedRect:maskFrame cornerRadius:maskFrame.size.width];
            break;
        case PhotoEditorMaskTypeRectangle:
            maskPath = [UIBezierPath bezierPathWithRoundedRect:maskFrame cornerRadius:0.0f];
            break;
        default:
            break;
    }
    
    [path appendPath:maskPath];
    [path setUsesEvenOddFillRule:YES];
    
    self.maskLayer.path = path.CGPath;
}

#pragma mark - Getter

- (UIImageView*)imageView
{
    if (nil == _imageView) {
        _imageView              =       [[UIImageView alloc] initWithImage:nil];
        _imageView.contentMode  =       UIViewContentModeCenter;
        _imageView.contentScaleFactor = [UIScreen mainScreen].scale;
        
        [self addSubview:_imageView];
    }
    
    return _imageView;
}

- (CAShapeLayer*)maskLayer
{
    if (nil == _maskLayer) {
        _maskLayer              = [CAShapeLayer layer];
        _maskLayer.fillRule     = kCAFillRuleEvenOdd;
        _maskLayer.fillColor    = [UIColor blackColor].CGColor;
        _maskLayer.opacity      = 0.8f;
    }
    
    return _maskLayer;
}

@end