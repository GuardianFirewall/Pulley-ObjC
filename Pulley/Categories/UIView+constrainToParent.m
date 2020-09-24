//
//  UIView+constrainToParent.m
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "UIView+constrainToParent.h"

@implementation UIView (constrainToParent)

-(void)constrainToParent {
    [self constrainToParent:UIEdgeInsetsZero];
}

- (void)constrainToParentBySize {
    
    UIView *parent = [self superview];
    if (!parent) return;
    self.translatesAutoresizingMaskIntoConstraints = false;
    [self.widthAnchor constraintEqualToAnchor:parent.widthAnchor].active = true;
    [self.heightAnchor constraintEqualToAnchor:parent.heightAnchor].active = true;
}

- (void)constrainToParent:(UIEdgeInsets)insets {

    UIView *parent = [self superview];
    if (!parent) return;
    self.translatesAutoresizingMaskIntoConstraints = false;
    [self.leftAnchor constraintEqualToAnchor:parent.leftAnchor constant:insets.left].active = true;
    [self.rightAnchor constraintEqualToAnchor:parent.rightAnchor constant:insets.right].active = true;
    [self.topAnchor constraintEqualToAnchor:parent.topAnchor constant:insets.top].active = true;
    [self.bottomAnchor constraintEqualToAnchor:parent.bottomAnchor constant:insets.bottom].active = true;
}

@end
