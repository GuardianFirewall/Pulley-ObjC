//
//  CustomMaskExample.m
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/28/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "CustomMaskExample.h"

@implementation CustomMaskExample

- (instancetype)init {
    self = [super init];
    if (self){
        _cornerRadius = 8.0;
        _cutoutRadius = 8.0;
        _cutoutDistanceFromEdge = 32.0;
    }
    return self;
}

- (UIBezierPath *)customMaskForBounds:(CGRect)bounds {

    CGFloat maxX = CGRectGetMaxX(bounds);
    CGFloat maxY = CGRectGetMaxY(bounds);
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint:CGPointMake(0, maxY)];
    
    // Left hand edge
    [path addLineToPoint:CGPointMake(0, _cornerRadius)];

    // Top left rounded corner
    [path addArcWithCenter:CGPointMake(_cornerRadius, _cornerRadius)
                    radius:_cornerRadius
                startAngle:M_PI
                  endAngle:1.5 * M_PI
                 clockwise:true];
  
    
    // Top edge left cutout section

    [path addLineToPoint:CGPointMake(_cutoutDistanceFromEdge - _cutoutRadius,  0)];
    [path addArcWithCenter:CGPointMake( _cutoutDistanceFromEdge,  0)
                    radius:_cutoutRadius
                startAngle:M_PI
                  endAngle:2.0 * M_PI
                 clockwise:false];

    [path addLineToPoint:CGPointMake( _cutoutDistanceFromEdge + _cutoutRadius,  0)];

    // Top edge right cutout section
    [path addLineToPoint:CGPointMake(maxX - _cutoutDistanceFromEdge - _cutoutRadius, 0)];
    [path addArcWithCenter:CGPointMake(maxX - _cutoutDistanceFromEdge, 0)
                    radius:_cutoutRadius startAngle:M_PI endAngle:2.0 * M_PI clockwise:false];
    
    [path addLineToPoint:CGPointMake(maxX - _cutoutDistanceFromEdge + _cutoutRadius,  0)];
    [path addLineToPoint:CGPointMake(maxX - _cornerRadius, 0)];
    
    // Top right rounded corner
    [path addArcWithCenter:CGPointMake(maxX - _cornerRadius, _cornerRadius) radius:_cornerRadius startAngle:1.5 * M_PI endAngle:2.0 * M_PI clockwise:true];
    
    // Right hand edge
    [path addLineToPoint:CGPointMake(maxX, maxY)];

    // Bottom edge
    [path addLineToPoint:CGPointMake(0, maxY)];
    [path closePath];
    [path fill];

    return path;
}

@end
