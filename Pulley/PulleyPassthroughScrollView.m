//
//  PulleyPassthroughScrollView.m
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "PulleyPassthroughScrollView.h"

@implementation PulleyPassthroughScrollView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (self.touchDelegate){
        if ([self.touchDelegate shouldTouchPassthroughScrollView:self point:point]){
            
            //get the view that is recieving the touch
            UIView *touchView = [[self touchDelegate] viewToReceiveTouch:self point:point];
            //convert the test point to convert our current point to the new view coordinate space
            CGPoint convertedPoint = [touchView convertPoint:point fromView:self];
            //run a hit test on the touch view with the updated CGPoint.
            return [touchView hitTest:convertedPoint withEvent:event];
        }
    }
    
    return [super hitTest:point withEvent:event];
}

@end
