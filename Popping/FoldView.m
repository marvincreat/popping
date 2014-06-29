//
//  FoldView.m
//  Popping
//
//  Created by André Schneider on 22.06.14.
//  Copyright (c) 2014 André Schneider. All rights reserved.
//

#import "FoldView.h"
#import "UIColor+CustomColors.h"
#import <POP/POP.h>

typedef NS_ENUM(NSInteger, LayerSection) {
    LayerSectionTop,
    LayerSectionBottom
};

@interface FoldView()
- (void)addTopView;
- (void)addBottomView;
- (void)addGestureRecognizers;
- (void)rotateToOrigin;
- (void)poke;
- (void)handlePan:(UIPanGestureRecognizer *)recognizer;
- (CATransform3D)transform3D;
- (UIImage *)imageForSection:(LayerSection)section withImage:(UIImage *)image;
- (CAShapeLayer *)maskForSection:(LayerSection)section withRect:(CGRect)rect;

@property(nonatomic) UIImage *image;
@property(nonatomic) UIImageView *topView;
@end

@implementation FoldView

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self) {
        _image = image;

        [self addBottomView];
        [self addTopView];

        [self addGestureRecognizers];
    }
    return self;
}

#pragma mark - Private Instance methods

- (void)addTopView
{
    UIImage *image = [self imageForSection:LayerSectionTop withImage:self.image];

    self.topView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f,
                                                                 0.f,
                                                                 CGRectGetWidth(self.bounds),
                                                                 CGRectGetMidY(self.bounds))];
    self.topView.image = image;
    self.topView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.topView.layer.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    self.topView.layer.transform = [self transform3D];
    self.topView.layer.mask = [self maskForSection:LayerSectionTop withRect:self.topView.bounds];
    self.topView.userInteractionEnabled = YES;
    self.topView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:self.topView];
}

- (void)addBottomView
{
    UIImage *image = [self imageForSection:LayerSectionBottom withImage:self.image];

    UIImageView *bottomView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f,
                                                                            CGRectGetMidY(self.bounds),
                                                                            CGRectGetWidth(self.bounds),
                                                                            CGRectGetMidY(self.bounds))];
    bottomView.image = image;
    bottomView.contentMode = UIViewContentModeScaleAspectFill;
    bottomView.layer.mask = [self maskForSection:LayerSectionBottom withRect:bottomView.bounds];
    [self addSubview:bottomView];
}

- (void)addGestureRecognizers
{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(handlePan:)];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(poke)];

    [self.topView addGestureRecognizer:panGestureRecognizer];
    [self.topView addGestureRecognizer:tapGestureRecognizer];
}

- (void)poke {
    POPSpringAnimation *rotationAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotationX];
    rotationAnimation.velocity = @(5);
    rotationAnimation.springBounciness = 18.0f;
    rotationAnimation.dynamicsMass = 4.0f;
    rotationAnimation.dynamicsTension = 200;
    rotationAnimation.toValue = @(0);
    [self.topView.layer pop_addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self];

    if ((location.x > 0 && location.x < CGRectGetWidth(self.bounds)) &&
        (location.y > 0 && location.y < CGRectGetHeight(self.bounds))) {
        CGFloat conversionFactor = -M_PI / CGRectGetHeight(self.bounds);
        POPBasicAnimation *rotationAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerRotationX];

        rotationAnimation.duration = 0.01;
        rotationAnimation.toValue = @(location.y*conversionFactor);
        [self.topView.layer pop_addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    } else {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
    }

    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled) {
        [self rotateToOrigin];
    }
}

- (void)rotateToOrigin
{
    POPSpringAnimation *rotationAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotationX];
    rotationAnimation.springBounciness = 18.0f;
    rotationAnimation.dynamicsMass = 2.0f;
    rotationAnimation.dynamicsTension = 200;
    rotationAnimation.toValue = @(0);
    rotationAnimation.delegate = self;
    [self.topView.layer pop_addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (CATransform3D)transform3D
{
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 2.5 / -2000;
    return transform;
}

- (UIImage *)imageForSection:(LayerSection)section withImage:(UIImage *)image
{
    CGRect rect = CGRectMake(0.f, 0.f, image.size.width, image.size.height / 2.f);
    if (section == LayerSectionBottom) {
        rect.origin.y = image.size.height / 2.f;
    }

    CGImageRef imgRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *imagePart = [UIImage imageWithCGImage:imgRef];
    CGImageRelease(imgRef);

    return imagePart;
}

- (CAShapeLayer *)maskForSection:(LayerSection)section withRect:(CGRect)rect
{
    CAShapeLayer *layerMask = [CAShapeLayer layer];
    UIRectCorner corners = (section == LayerSectionTop) ? 3 : 12;

    layerMask.path = [UIBezierPath bezierPathWithRoundedRect:rect
                                           byRoundingCorners:corners
                                                 cornerRadii:CGSizeMake(5, 5)].CGPath;
    return layerMask;
}

@end