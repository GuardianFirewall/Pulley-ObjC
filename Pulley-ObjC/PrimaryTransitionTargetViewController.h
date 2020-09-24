//
//  PrimaryTransitionTargetViewController.h
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/27/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PrimaryTransitionTargetViewController : UIViewController
@property IBOutlet UIView *gripperView;
- (IBAction)goBackButtonPressedWithSender:(id)sender;
@end
