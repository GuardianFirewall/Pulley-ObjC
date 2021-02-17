//
//  PrimaryContentViewController.h
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <Pulley/UIViewController+PulleyViewController.h>

@interface PrimaryContentViewController : UIViewController <PulleyPrimaryContentControllerDelegate>
@property IBOutlet MKMapView *mapView;
@property IBOutlet UIView *controlsContainer;
@property IBOutlet UILabel *temperatureLabel;
/**
 * IMPORTANT! If you have constraints that you use to 'follow' the drawer (like the temperature label in the demo)...
 * Make sure you constraint them to the bottom of the superview and NOT the superview's bottom margin. Double click the constraint, and you can change it in the dropdown in the right-side panel. If you don't, you'll have varying spacings to the drawer depending on the device.
 */
@property IBOutlet NSLayoutConstraint *temperatureLabelBottomConstraint;
@property CGFloat temperatureLabelBottomDistance; // = 8.0
@end

