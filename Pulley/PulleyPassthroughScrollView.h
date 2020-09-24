//
//  PulleyPassthroughScrollView.h
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PulleyPassthroughScrollView;
@protocol PulleyPassthroughScrollViewDelegate <NSObject>
- (BOOL)shouldTouchPassthroughScrollView:(PulleyPassthroughScrollView *)srollView point:(CGPoint)point;
- (UIView *)viewToReceiveTouch:(PulleyPassthroughScrollView *)scrollView point:(CGPoint)point;

@end

@interface PulleyPassthroughScrollView : UIScrollView

@property (nonatomic, weak) id <PulleyPassthroughScrollViewDelegate> touchDelegate;

@end



