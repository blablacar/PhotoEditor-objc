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
        
        self.maskShape = PhotoEditorMask_Rounded;
        
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
        self.imageView.image    = [self.imageView.image imageResizedToSize:frame.size];
    }
}

#pragma mark - Public methods -

#pragma mark - Public methods - Setter

- (void)setImage:(UIImage*)image
{
    self.imageView.image = image;
}

- (void)setMaskShape:(NSUInteger)maskShape
{
    _maskShape = maskShape;
    if (_hasMaskLayer)
        [self updateMaskLayerPosition];
}

- (void)setHasMaskLayer:(BOOL)hasMaskLayer
{
    _hasMaskLayer = hasMaskLayer;
    
    if (_hasMaskLayer) {
        [self addMaskLayer];
    }
}

#pragma mark - Public methods - Getter

- (UIImage*)getFinalImage
{
    if ((self.hasMaskLayer) && (nil != _maskLayer.superlayer)) {
        [self.maskLayer removeFromSuperlayer];
    }
    
    CGSize maskSize = CGSizeZero;
    CGPoint position = CGPointZero;
    
    if (self.hasMaskLayer) {
        maskSize = [self getMaskLayerSize];
        position = CGPointMake(self.frame.size.width/2 - maskSize.width/2, self.frame.size.width/2 - maskSize.height/2);
    } else {
        maskSize = self.frame.size;
    }
    
    UIGraphicsBeginImageContextWithOptions(maskSize, NO, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -position.x, -position.y);
    [self.layer renderInContext:context];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    [self addMaskLayer];
    
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

- (CGSize) getMaskLayerSize
{
    switch (self.maskShape) {
        case PhotoEditorMask_Rounded:
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
            break;
            
        case PhotoEditorMask_Rectangle:
        {
            return CGSizeMake(PERCENT_SIZE_FOR_RECTANGLE * self.bounds.size.width / 100,
                              PERCENT_SIZE_FOR_RECTANGLE * self.bounds.size.height / 100);
        }
            break;
        default:
            return CGSizeZero;
            break;
    }

}

- (void)updateMaskLayerPosition
{
    if (NO == self.hasMaskLayer) {
        return;
    }
    
    if (self.maskShape == PhotoEditorMask_Rounded) {
        
        CGSize squareSize = [self getMaskLayerSize];
        CGRect circleFrame = CGRectMake(self.frame.size.width/2 - squareSize.width/2,
                                        self.frame.size.height/2 - squareSize.height/2,
                                        squareSize.width,
                                        squareSize.height);
        
        UIBezierPath *path          = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                                 cornerRadius:0.0f];
        UIBezierPath *circlePath    = [UIBezierPath bezierPathWithRoundedRect:circleFrame
                                                                 cornerRadius:circleFrame.size.width];
        [path appendPath:circlePath];
        [path setUsesEvenOddFillRule:YES];
        
        self.maskLayer.path = path.CGPath;
    }
    
    if (self.maskShape == PhotoEditorMask_Rectangle) {
        
        CGSize rectangleSize = [self getMaskLayerSize];
        CGRect rectangleFrame = CGRectMake(self.bounds.size.width/2 - rectangleSize.width/2,
                                        self.bounds.size.height/2 - rectangleSize.height/2,
                                        rectangleSize.width,
                                        rectangleSize.height);
        UIBezierPath *path          = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:0.0f];
        UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRoundedRect:rectangleFrame cornerRadius:0.0];
        [path appendPath:rectanglePath];

        [path setUsesEvenOddFillRule:YES];
        
        self.maskLayer.path = path.CGPath;
    }
}

#pragma mark - Getter

- (UIImageView*)imageView
{
    if (nil == _imageView) {
        _imageView              = [[UIImageView alloc] initWithImage:nil];
        _imageView.contentMode  = UIViewContentModeCenter;
        
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