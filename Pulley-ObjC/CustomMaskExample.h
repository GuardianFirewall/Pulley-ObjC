//
//  CustomMaskExample.h
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/28/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@interface CustomMaskExample : NSObject

@property CGFloat cornerRadius;
@property CGFloat cutoutDistanceFromEdge;
@property CGFloat cutoutRadius;
- (UIBezierPath *)customMaskForBounds:(CGRect)bounds;

@end
