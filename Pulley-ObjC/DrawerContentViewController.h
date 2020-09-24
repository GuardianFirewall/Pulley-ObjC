//
//  DrawerContentViewController.h
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/26/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+PulleyViewController.h"

@interface DrawerContentViewController : UIViewController <PulleyDrawerViewControllerDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

// Pulley can apply a custom mask to the panel drawer. This variable toggles an example.
@property BOOL shouldDisplayCustomMaskExample;// = false

@property IBOutlet UITableView *tableView;
@property IBOutlet UISearchBar *searchBar;
@property IBOutlet UIView *gripperView;
@property IBOutlet UIView *topSeparatorView;
@property IBOutlet UIView * bottomSeperatorView;

@property IBOutlet NSLayoutConstraint *gripperTopConstraint;

// We adjust our 'header' based on the bottom safe area using this constraint
@property IBOutlet NSLayoutConstraint *headerSectionHeightConstraint;
@end

