//
//  PrimaryContentViewController.m
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "PrimaryContentViewController.h"

@interface PrimaryContentViewController ()

@end

@implementation PrimaryContentViewController

- (void)controlsContainerTouched:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded){
        
        if ([[self pulleyViewController] drawerPositionRaw] == PulleyDrawerPositionClosed){
            [[self pulleyViewController] setDrawerPosition:[PulleyPosition collapsed] animated:true];
        } else {
            [[self pulleyViewController] setDrawerPosition:[PulleyPosition closed] animated:true];
            
        }
        
    
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.temperatureLabelBottomDistance = 8.0;
    
    self.controlsContainer.layer.cornerRadius = 10.0;
    self.temperatureLabel.layer.cornerRadius = 7.0;
    
    UITapGestureRecognizer *tapGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(controlsContainerTouched:)];
    [self.controlsContainer addGestureRecognizer:tapGest];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Customize Pulley in viewWillAppear, as the view controller's viewDidLoad will run *before* Pulley's and some changes may be overwritten.
    // Uncomment if you want to change the visual effect style to dark. Note: The rest of the sample app's UI isn't made for dark theme. This just shows you how to do it.
    // drawer.drawerBackgroundVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    // We want the 'side panel' layout in landscape iPhone / iPad, so we set this to 'automatic'. The default is 'bottomDrawer' for compatibility with older Pulley versions.
    self.pulleyViewController.displayMode = PulleyDisplayModeAutomatic;
}

- (void)runPrimaryContentTransitionWithoutAnimation:(id)sender {

    UIViewController *primaryContent = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PrimaryTransitionTargetViewController"];
    
    [[self pulleyViewController] setPrimaryContentViewController:primaryContent animated:false completion:nil];
    
}

-(IBAction) runPrimaryContentTransition:(id)sender {
    UIViewController *primaryContent = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PrimaryTransitionTargetViewController"];
    
    [[self pulleyViewController] setPrimaryContentViewController:primaryContent animated:true completion:nil];
}

- (void)makeUIAdjustmentsForFullscreen:(CGFloat)progress bottomSafeArea:(CGFloat)bottomSafeArea {
    PulleyViewController *drawer = [self pulleyViewController];
    if (drawer){
        if ([drawer currentDisplayMode] != PulleyDisplayModeDrawer){
            self.controlsContainer.alpha = 1.0;
            return;
        }
        self.controlsContainer.alpha = 1.0 - progress;
    }
}

- (void)drawerChangedDistanceFromBottom:(PulleyViewController *)drawer distance:(CGFloat)distance bottomSafeArea:(CGFloat)bottomSafeArea {
    
    if ([drawer currentDisplayMode] != PulleyDisplayModeDrawer){
        self.temperatureLabelBottomConstraint.constant = self.temperatureLabelBottomDistance;
        return;
    }
    
    if (distance <= 268.0 + bottomSafeArea)
    {
        self.temperatureLabelBottomConstraint.constant = distance + self.temperatureLabelBottomDistance;
    }
    else
    {
        self.temperatureLabelBottomConstraint.constant = 268.0 + self.temperatureLabelBottomDistance;
    }
}


@end
