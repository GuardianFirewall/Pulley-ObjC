//
//  DrawerContentViewController.m
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/26/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "DrawerContentViewController.h"
#import "CustomMaskExample.h"

@interface DrawerContentViewController ()
@property (nonatomic) CGFloat drawerBottomSafeArea;
// Pulley can apply a custom mask to the panel drawer. This variable toggles an example.
@end

@implementation DrawerContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.gripperView.layer.cornerRadius = 2.5;

    // Comment this in to see a custom mask example in action
    //self.shouldDisplayCustomMaskExample = true;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // You must wait until viewWillAppear -or- later in the view controller lifecycle in order to get a reference to Pulley via self.parent for customization.
    
    // UIFeedbackGenerator is only available iOS 10+. Since Pulley works back to iOS 9, the .feedbackGenerator property is "Any" and managed internally as a feedback generator.
    
    if (@available(iOS 10.0, *)){
        UISelectionFeedbackGenerator *feedbackGenerator = [UISelectionFeedbackGenerator new];
        self.pulleyViewController.feedbackGenerator = feedbackGenerator;
    }
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (_shouldDisplayCustomMaskExample){
        CAShapeLayer *maskLayer = [CAShapeLayer new];
        maskLayer.path = [[CustomMaskExample new] customMaskForBounds:self.view.bounds].CGPath;
        self.view.layer.mask = maskLayer;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:false block:^(NSTimer * _Nonnull timer) {
       [self.pulleyViewController bounceDrawer];
    }];
}

- (void)setDrawerBottomSafeArea:(CGFloat)drawerBottomSafeArea {
        _drawerBottomSafeArea = drawerBottomSafeArea;
    [self loadViewIfNeeded];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, drawerBottomSafeArea, 0);
}


- (CGFloat)collapsedDrawerHeight:(CGFloat)bottomSafeArea {
    return 68 + (self.pulleyViewController.currentDisplayMode == PulleyDisplayModeDrawer ? bottomSafeArea : 0);
}

- (CGFloat)partialRevealDrawerHeight:(CGFloat)bottomSafeArea {
    return 264.0 + (self.pulleyViewController.currentDisplayMode == PulleyDisplayModeDrawer ? bottomSafeArea : 0);
}

- (NSArray<PulleyPosition *> *)supportedDrawerPositions {
    return [PulleyPosition all];
}

/// This function is called when the current drawer display mode changes. Make UI customizations here.
- (void)drawerDisplayModeDidChange:(PulleyViewController *)drawer {

    NSLog(@"Drawer: %lu", drawer.currentDisplayMode);
    self.gripperTopConstraint.active = drawer.currentDisplayMode == PulleyDisplayModeDrawer;
}

- (void)drawerPositionDidChange:(PulleyViewController *)drawer bottomSafeArea:(CGFloat)bottomSafeArea {
    // We want to know about the safe area to customize our UI. Our UI customization logic is in the didSet for this variable.
    self.drawerBottomSafeArea = bottomSafeArea;
    
    /*
     Some explanation for what is happening here:
     1. Our drawer UI needs some customization to look 'correct' on devices like the iPhone X, with a bottom safe area inset.
     2. We only need this when it's in the 'collapsed' position, so we'll add some safe area when it's collapsed and remove it when it's not.
     3. These changes are captured in an animation block (when necessary) by Pulley, so these changes will be animated along-side the drawer automatically.
     */
    if (drawer.drawerPosition == [PulleyPosition collapsed])
    {
        self.headerSectionHeightConstraint.constant = 68.0 + self.drawerBottomSafeArea;
    }
    else
    {
        self.headerSectionHeightConstraint.constant = 68.0;
    }
    
    // Handle tableview scrolling / searchbar editing
    
    self.tableView.scrollEnabled = drawer.drawerPosition == [PulleyPosition open] || drawer.currentDisplayMode == PulleyDisplayModePanel;
    
    if (drawer.drawerPosition != [PulleyPosition open]){
        [self.searchBar resignFirstResponder];
    }
    
    if (drawer.currentDisplayMode == PulleyDisplayModePanel){
        self.topSeparatorView.hidden = drawer.drawerPosition == [PulleyPosition collapsed];
        self.bottomSeperatorView.hidden = drawer.drawerPosition == [PulleyPosition collapsed];
    }
    else
    {
        self.topSeparatorView.hidden = false;
        self.bottomSeperatorView.hidden = true;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [tableView dequeueReusableCellWithIdentifier:@"SampleCell" forIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 81.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    UIViewController *primaryContent = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PrimaryTransitionTargetViewController"];
    [[self pulleyViewController] showDetailsViewInDrawer:primaryContent];
    //[[self pulleyViewController] setDrawerPosition:[PulleyPosition collapsed] animated:true];
    //[[self pulleyViewController] setPrimaryContentViewController:primaryContent animated:false];
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
        [[self pulleyViewController] setDrawerPosition:[PulleyPosition open] animated:true];
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [super encodeWithCoder:coder];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    [super preferredContentSizeDidChangeForChildContentContainer:container];
}

- (CGSize)sizeForChildContentContainer:(nonnull id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
    return [super sizeForChildContentContainer:container withParentContainerSize:parentSize];
}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    [super systemLayoutFittingSizeDidChangeForChildContentContainer:container];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
}

- (void)setNeedsFocusUpdate {
    [super setNeedsFocusUpdate];
}
- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    return [super shouldUpdateFocusInContext:context];
}

- (void)updateFocusIfNeeded {
    
    [super updateFocusIfNeeded];
}

@end
