//
//  UIViewController+PulleyViewController.m
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "UIViewController+PulleyViewController.h"

@implementation UIViewController (PulleyViewController)

- (PulleyViewController *)pulleyViewController {
    if ([self isKindOfClass:PulleyViewController.class]) return (PulleyViewController*)self;
    UIViewController *parentVC = [self parentViewController];
    while (parentVC != nil){
        if ([parentVC isKindOfClass:PulleyViewController.class]){
            return (PulleyViewController*)parentVC;
        }
        parentVC = [parentVC parentViewController];
    }
    parentVC = [self presentingViewController];
    if ([parentVC isKindOfClass:PulleyViewController.class]){
        return (PulleyViewController*)parentVC;
    }
    return nil;
}

@end
