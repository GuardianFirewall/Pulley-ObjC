//
//  UIView+constrainToParent.h
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (constrainToParent)
-(void)constrainToParent;
- (void)constrainToParentBySize;
- (void)constrainToParent:(UIEdgeInsets)insets;
@end
