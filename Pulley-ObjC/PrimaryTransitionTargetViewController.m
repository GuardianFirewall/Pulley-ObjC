//
//  PrimaryTransitionTargetViewController.m
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/27/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <Pulley/PulleyViewController.h>
#import "PrimaryTransitionTargetViewController.h"
//#import "PulleyViewController.h"
#import <Pulley/UIViewController+PulleyViewController.h>

@interface PrimaryTransitionTargetViewController ()

@end

@implementation PrimaryTransitionTargetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
     self.gripperView.layer.cornerRadius = 2.5;
    // Do any additional setup after loading the view.
}

- (IBAction)goBackButtonPressedWithSender:(id)sender {
    
    [[self pulleyViewController] dismissDetailViewController];

}

@end
