//
//  PulleyViewController.m
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#import "PulleyViewController.h"
#import "UIView+constrainToParent.h"

@implementation PulleyPosition

+ (PulleyPosition *)collapsed {
    static dispatch_once_t onceToken;
    static PulleyPosition *collapse;
    dispatch_once(&onceToken, ^{
        collapse = [[PulleyPosition alloc] initWithRawValue:0];
    });
    return collapse;
    
}

+ (PulleyPosition *)partiallyRevealed {
    static dispatch_once_t onceToken;
    static PulleyPosition *partialReveal;
    dispatch_once(&onceToken, ^{
        partialReveal = [[PulleyPosition alloc] initWithRawValue:1];
    });
    return partialReveal;
    
}

+ (PulleyPosition *)open {
    static dispatch_once_t onceToken;
    static PulleyPosition *opend;
    dispatch_once(&onceToken, ^{
        opend = [[PulleyPosition alloc] initWithRawValue:2];
    });
    return opend;
    
}

+ (PulleyPosition *)closed {
    static dispatch_once_t onceToken;
    static PulleyPosition *closd;
    dispatch_once(&onceToken, ^{
        closd = [[PulleyPosition alloc] initWithRawValue:3];
    });
    return closd;
    
}

- (NSString *)description {
    NSString *sup = [super description];
    NSString *stringDesc = [self stringForPosition];
    if (stringDesc != nil){
       return [NSString stringWithFormat:@"<%@> raw value: %lu: %@", sup, _rawValue, stringDesc];
    }
    return [NSString stringWithFormat:@"<%@> raw value: %lu", sup, _rawValue];
}

+ (NSArray <PulleyPosition *>*)all {
    return @[[PulleyPosition collapsed], [PulleyPosition partiallyRevealed], [PulleyPosition open], [PulleyPosition closed]];
}

- (NSString *)stringForPosition {
    switch (self.rawValue) {
        case PulleyDrawerPositionCollapsed:
            return @"Collapsed";
        case PulleyDrawerPositionPartiallyRevealed:
            return @"PartiallyRevelead";
        case PulleyDrawerPositionOpen:
            return @"Open";
        case PulleyDrawerPositionClosed:
            return @"Closed";
        default:
            break;
    }
    return nil;
}
+ (PulleyPosition *)positionForString:(NSString *)positionString {
    if (positionString == nil) return [PulleyPosition collapsed];
    if ([[positionString lowercaseString] isEqualToString:@"collapsed"]){
        return [PulleyPosition collapsed];
    } else if ([[positionString lowercaseString] isEqualToString:@"partiallyrevealed"]){
        return [PulleyPosition partiallyRevealed];
    } else if ([[positionString lowercaseString] isEqualToString:@"open"]){
        return [PulleyPosition open];
    } else if ([[positionString lowercaseString] isEqualToString:@"closed"]){
        return [PulleyPosition closed];
    }
    return [PulleyPosition collapsed];
}
- (instancetype)initWithRawValue:(NSInteger)rawValue {
    self = [super init];
    if (self){
        if (rawValue < 0 || rawValue > 3) {
            NSLog(@"PulleyViewController: A raw value of %lu is not supported. You have to use one of the predefined values in PulleyPosition. Defaulting to `collapsed`.", rawValue);
            self.rawValue = 0;
        } else {
            self.rawValue = rawValue;
        }
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:self.class]){
        return false;
    }
    return self.rawValue == [object rawValue];
}

@end

@interface PulleyViewController  (){
    CGFloat kPulleyDefaultCollapsedHeight;
    CGFloat kPulleyDefaultPartialRevealHeight;
    BOOL isAnimatingDrawerPosition;
    BOOL isDetailDrawerCollapsing;
    BOOL isChangingDrawerPosition;
}
@property UIView *primaryContentContainer;
@property UIView *drawerContentContainer;
@property UIView *detailsDrawerContentContainer;
@property UIView * drawerShadowView;
@property UIView * detailsDrawerShadowView;
@property PulleyPassthroughScrollView * drawerScrollView;
@property PulleyPassthroughScrollView * detailsDrawerScrollView;
@property UIView * backgroundDimmingView;
@property (nonatomic, strong)NSArray <PulleyPosition *>* supportedPositions;
@property UITapGestureRecognizer * dimmingViewTapRecognizer;

@property CGPoint lastDragTargetContentOffset;
@end

@implementation PulleyViewController

#pragma mark •• Objective-C specific / exclusive code

/**
 
 Any code here is additional convenience code i added that does not exist in the current library, these
 were determined to be necessary for some common code re-use functions for things that dont
 exist 1:1 in swift, ie min() on an NSArray,
 
 */

- (void)hideDrawerAnimated:(BOOL)animated {
    if ([[self supportedPositions] containsObject:[PulleyPosition closed]]){
        [self setDrawerPosition:[PulleyPosition closed] animated:true];
        return;
    }
    if (!self.drawerScrollView.userInteractionEnabled){
        return;
    }
    if (animated){
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.drawerContentViewController.view.alpha = 0;
            self.drawerScrollView.alpha = 0;
            self.drawerScrollView.userInteractionEnabled = false;
        } completion:nil];
    } else {
        self.drawerContentViewController.view.alpha = 0;
        self.drawerScrollView.alpha = 0;
        self.drawerScrollView.userInteractionEnabled = false;
    }
}

- (void)showDrawerAnimated:(BOOL)animated {
    if ([[self supportedPositions] containsObject:[PulleyPosition closed]]){
        [self setDrawerPosition:[PulleyPosition collapsed] animated:true];
        return;
    }
    if (self.drawerScrollView.userInteractionEnabled){
        return;
    }
    if (animated){
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.drawerContentViewController.view.alpha = 1;
            self.drawerScrollView.alpha = 1;
            self.drawerScrollView.userInteractionEnabled = true;
        } completion:nil];
    } else {
        self.drawerContentViewController.view.alpha = 1;
        self.drawerScrollView.alpha = 1;
        self.drawerScrollView.userInteractionEnabled = true;
    }
}

- (CGFloat)lowestStop {
    return [[[self getStopList] valueForKeyPath:@"@min.self"] floatValue];
}

- (CGFloat)highestStop {
    return [[[self getStopList] valueForKeyPath:@"@max.self"] floatValue];
}

//TODO: // smarter name for this
- (UIViewController <PulleyDrawerViewControllerDelegate>*)compliantDrawerContentViewControllerIfApplicable {
    if ([[self drawerContentViewController] conformsToProtocol:@protocol(PulleyDrawerViewControllerDelegate)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
            return drawerVCCompliant;
    }
    return nil;
}

- (void)_initializeDefaults {
    self.lastDragTargetContentOffset = CGPointZero;
    self.primaryContentContainer = [UIView new];
    self.drawerContentContainer = [UIView new];
    self.detailsDrawerContentContainer = [UIView new];
    self.drawerShadowView = [UIView new];
    self.detailsDrawerShadowView = [UIView new];
    self.backgroundDimmingView = [UIView new];
    self.drawerScrollView = [PulleyPassthroughScrollView new];
    self.detailsDrawerScrollView = [PulleyPassthroughScrollView new];
    self.detailsDrawerScrollView.alpha = 0;
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:[self defaultBlurEffect]];
    self.drawerBackgroundVisualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.detailsDrawerBackgroundVisualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    kPulleyDefaultCollapsedHeight = 68.0;
    kPulleyDefaultPartialRevealHeight = 264.0;
    _bounceOverflowMargin = 20.0;
    _panelWidth = 325.0;
    _panelInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    _drawerTopInset = 20.0;
    _drawerPosition = [PulleyPosition collapsed];
    _drawerPositionRaw = PulleyDrawerPositionCollapsed;
    _drawerCornerRadius = 13.0;
    _shadowOpacity = 0.1;
    _shadowRadius = 3.0;
    _shadowOffset = CGSizeMake(0, -3.0);
    _backgroundDimmingColor = [UIColor blackColor];
    _backgroundDimmingOpacity = 0.5;
    _delaysContentTouches = true;
    _canCancelContentTouches = true;
    _initialDrawerPosition = [PulleyPosition collapsed];
    _currentDisplayMode = PulleyDisplayModeAutomatic;
    _panelCornerPlacement = PulleyPanelCornerPlacementTopLeft;
    _allowsUserDrawerPositionChange = true;
    _animationDuration = 0.5;
    _animationDelay = 0.0;
    _animationSpringDamping = 0.75;
    _animationOptions = UIViewAnimationOptionCurveEaseInOut;
    _animationSpringInitialVelocity = 0.0;
    _adjustDrawerHorizontalInsetToSafeArea = true;
    setSnapModeToNearestPositionUnlessExceeded(20);
    isAnimatingDrawerPosition = false;
    [self setSupportedPositions:[PulleyPosition all]];
    _positionWhenDimmingBackgroundIsTapped = [PulleyPosition collapsed];
}

- (NSArray *)supportedPulleyPositionsWithoutClosedAscending:(BOOL)isAscending {
    NSArray *filteredSupportedDrawerPossitions = [[self supportedPositions] filteredArrayUsingPredicate:[self noClosedPredicate]];
    NSSortDescriptor *rawValueAsc = [NSSortDescriptor sortDescriptorWithKey:@"rawValue" ascending:isAscending];
    return [filteredSupportedDrawerPossitions sortedArrayUsingDescriptors:@[rawValueAsc]];
}

- (PulleyPosition *)lowestDrawerState {

    NSArray *orderedSupportedDrawerPositions = [self supportedPulleyPositionsWithoutClosedAscending:true];
    PulleyPosition *lowestDrawerState = [orderedSupportedDrawerPositions valueForKeyPath:@"@min.self"];
    if (lowestDrawerState){
        return lowestDrawerState;
    }
    return [PulleyPosition collapsed];
}

//end obj-c convenience code

- (void)setDrawerPosition:(PulleyPosition *)drawerPosition {
    if (self.viewLocked) return;
    _drawerPosition = drawerPosition;{
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)setSupportedPositions:(NSArray<PulleyPosition *> *)supportedPositions {
    if (![self isViewLoaded]) return;
    NSArray *oldValue = _supportedPositions;
    _supportedPositions = supportedPositions;
    NSInteger count = _supportedPositions.count;
    if (count < 0) return;
    if (oldValue != supportedPositions){
        [self.view setNeedsLayout];
    }
    if ([supportedPositions containsObject:self.drawerPosition]){
        [self setDrawerPosition:self.drawerPosition animated:false];
    } else {
        PulleyPosition *lowestDrawerState = [self lowestDrawerState];
        [self setDrawerPosition:lowestDrawerState animated:false];
    }
    
    [self enforceCanScrollDrawer];
}

/**
 Update the supported drawer positions allows by the Pulley Drawer
 */

- (void)setNeedsSupportedDrawerPositionsUpdate {
    
    if ([[self drawerContentViewController] conformsToProtocol:@protocol(PulleyDrawerViewControllerDelegate)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
            if ([drawerVCCompliant supportedDrawerPositions]){
                self.supportedPositions = [drawerVCCompliant supportedDrawerPositions];
            } else {
                self.supportedPositions = [PulleyPosition all];
            }
    } else {
        self.supportedPositions = [PulleyPosition all];
    }
}

- (CGFloat)bottomSafeSpace {
    return self.pulleySafeAreaInsets.bottom;
}

- (UIEdgeInsets)pulleySafeAreaInsets {
    CGFloat safeAreaBottomInset = self.view.safeAreaInsets.bottom;
    CGFloat safeAreaLeftInset = self.view.safeAreaInsets.left;
    CGFloat safeAreaRightInset = self.view.safeAreaInsets.right;
    CGFloat safeAreaTopInset = self.view.safeAreaInsets.top;
    return UIEdgeInsetsMake(safeAreaTopInset, safeAreaLeftInset, safeAreaBottomInset, safeAreaRightInset);
}

/// Get the current drawer distance. This value is equivalent in nature to the one delivered by PulleyDelegate's `drawerChangedDistanceFromBottom` callback.

- (CGFloat)drawerDistanceFromBottom:(CGFloat)distance bottomSafeArea:(CGFloat)bottomSafeArea {
    if ([self isViewLoaded]){
        CGFloat lowestStop = [self lowestStop];
        CGFloat drawerDistance = self.drawerScrollView.contentOffset.y + lowestStop;
        NSLog(@"drawerDistance: %.0f", drawerDistance);
        return drawerDistance;
    }
    /*
     
     Honestly not sure what this is doing yet..
     
     if self.isViewLoaded
     {
     let lowestStop = getStopList().min() ?? 0.0
     
     return (distance: drawerScrollView.contentOffset.y + lowestStop, bottomSafeArea: pulleySafeAreaInsets.bottom)
     }
     
     return (distance: 0.0, bottomSafeArea: 0.0)
     
     */
    return 0.0;
}


/// Get all gesture recognizers in the drawer scrollview
- (NSArray <UIGestureRecognizer *> *)drawerGestureRecognizers {
    return self.drawerScrollView.gestureRecognizers;
}

/// Get the drawer scrollview's pan gesture recognizer
- (UIPanGestureRecognizer *) drawerPanGestureRecognizer {
    
    return self.drawerScrollView.panGestureRecognizer;
}

- (void)setPulleyCurrentDisplayMode:(PulleyDisplayMode)currentDisplayMode {
    PulleyDisplayMode oldValue = _currentDisplayMode;
    _currentDisplayMode = currentDisplayMode;
    if (oldValue != currentDisplayMode){
        if (self.isViewLoaded) {
            [self.view setNeedsLayout];
        }
        if ([[self delegate] respondsToSelector:@selector(drawerDisplayModeDidChange:)]){
            [[self delegate] drawerDisplayModeDidChange:self];
            if ([[self drawerContentViewController] respondsToSelector:@selector(drawerDisplayModeDidChange:)]){
                [[self drawerContentViewController] performSelector:@selector(drawerDisplayModeDidChange:) withObject:self];
            }
            if ([[self primaryContentContainer] respondsToSelector:@selector(drawerDisplayModeDidChange:)]){
                [[self primaryContentContainer] performSelector:@selector(drawerDisplayModeDidChange:) withObject:self];
            }
        }
    }
}

- (void)setPanelInsets:(UIEdgeInsets)panelInsets {
    UIEdgeInsets oldValue = _panelInsets;
    _panelInsets = panelInsets;
    if (!UIEdgeInsetsEqualToEdgeInsets(oldValue, panelInsets)){
        if ([self isViewLoaded]){
            [self.view setNeedsLayout];
        }
    }
}

- (void)setPanelWidth:(CGFloat)panelWidth {
    CGFloat oldValue = _panelWidth;
    _panelWidth = panelWidth;
    if (oldValue != panelWidth){
        if ([self isViewLoaded]){
            [self.view setNeedsLayout];
        }
    }
}

- (void)setDrawerTopInset:(CGFloat)drawerTopInset {
    CGFloat oldValue = _drawerTopInset;
    _drawerTopInset = drawerTopInset;
    if (oldValue != drawerTopInset){
        if ([self isViewLoaded]){
            [self.view setNeedsLayout];
        }
    }
}

- (CGFloat)heightOfOpenDrawer {
    
    CGFloat safeAreaTopInset = self.pulleySafeAreaInsets.top;
    CGFloat safeAreaBottomInset = self.pulleySafeAreaInsets.bottom;
    CGFloat height = self.view.bounds.size.height - safeAreaTopInset;
    
    if (self.currentDisplayMode == PulleyDisplayModePanel) {
        height -= (self.panelInsets.top + _bounceOverflowMargin);
        height -= (self.panelInsets.bottom + safeAreaBottomInset);
    } else if (self.currentDisplayMode == PulleyDisplayModeDrawer) {
        height -= self.drawerTopInset;
    }
    
    return height;
}

- (id)init {
    self = [super init];
    [self _initializeDefaults];
    return self;
}

/**
 Initialize the drawer controller from Interface Builder.
 
 - note: Usage notes: Make 2 container views in Interface Builder and connect their outlets to -primaryContentContainerView and -drawerContentContainerView. Then use embed segues to place your content/drawer view controllers into the appropriate container.
 
 - parameter aDecoder: The NSCoder to decode from.
 
 - returns: A newly created Pulley drawer.
 */

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [self _initializeDefaults];
    return self;
}

/**
 Initialize the drawer controller programmtically.
 
 - parameter contentViewController: The content view controller. This view controller is shown behind the drawer.
 - parameter drawerViewController:  The view controller to display inside the drawer.
 
 - note: The drawer VC is 20pts too tall in order to have some extra space for the bounce animation. Make sure your constraints / content layout take this into account.
 
 - returns: A newly created Pulley drawer.
 */

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController drawerViewController:(UIViewController *)drawerViewController {
    
    self = [super initWithNibName:nil bundle:nil];
    [self _initializeDefaults];
    self.primaryContentViewController = contentViewController;
    self.drawerContentViewController = drawerViewController;
    return self;
}

- (void)loadView {
    [super loadView];
    if (self.primaryContentViewController != nil) {
        [self.primaryContentContainerView removeFromSuperview];
    }
    if (self.drawerContentContainerView){
        [self.drawerContentContainerView removeFromSuperview];
    }
    //setup
    self.primaryContentContainer.backgroundColor = [UIColor whiteColor];
    self.definesPresentationContext = true;
    
    self.drawerScrollView.bounces = false;
    self.drawerScrollView.delegate = self;
    self.drawerScrollView.clipsToBounds = false;
    self.drawerScrollView.showsVerticalScrollIndicator = false;
    self.drawerScrollView.showsHorizontalScrollIndicator = false;
    
    self.drawerScrollView.delaysContentTouches = self.delaysContentTouches;
    self.drawerScrollView.canCancelContentTouches = self.canCancelContentTouches;
    
    self.drawerScrollView.backgroundColor = [UIColor clearColor];
    self.drawerScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.drawerScrollView.scrollsToTop = false;
    self.drawerScrollView.touchDelegate = self;
    
    self.detailsDrawerScrollView.bounces = false;
    self.detailsDrawerScrollView.delegate = self;
    self.detailsDrawerScrollView.clipsToBounds = false;
    self.detailsDrawerScrollView.showsVerticalScrollIndicator = false;
    self.detailsDrawerScrollView.showsHorizontalScrollIndicator = false;
    
    self.detailsDrawerScrollView.delaysContentTouches = self.delaysContentTouches;
    self.detailsDrawerScrollView.canCancelContentTouches = self.canCancelContentTouches;
    
    self.detailsDrawerScrollView.backgroundColor = [UIColor clearColor];
    self.detailsDrawerScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.detailsDrawerScrollView.scrollsToTop = false;
    self.detailsDrawerScrollView.touchDelegate = self;
    
    self.drawerShadowView.layer.shadowOpacity = self.shadowOpacity;
    self.drawerShadowView.layer.shadowRadius = self.shadowRadius;
    self.drawerShadowView.layer.shadowOffset = self.shadowOffset;
    self.drawerShadowView.backgroundColor = [UIColor clearColor];
    
    self.detailsDrawerShadowView.layer.shadowOpacity = self.shadowOpacity;
    self.detailsDrawerShadowView.layer.shadowRadius = self.shadowRadius;
    self.detailsDrawerShadowView.layer.shadowOffset = self.shadowOffset;
    self.detailsDrawerShadowView.backgroundColor = [UIColor clearColor];
    
    self.drawerContentContainer.backgroundColor = [UIColor clearColor];
    self.detailsDrawerContentContainer.backgroundColor = [UIColor clearColor];
    self.backgroundDimmingView.backgroundColor = self.backgroundDimmingColor;
    self.backgroundDimmingView.userInteractionEnabled = false;
    self.backgroundDimmingView.alpha = 0.0;
    
    self.drawerBackgroundVisualEffectView.clipsToBounds = true;
    self.detailsDrawerBackgroundVisualEffectView.clipsToBounds = true;
    self.dimmingViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizer:)];
    [self.backgroundDimmingView addGestureRecognizer:self.dimmingViewTapRecognizer];
    
    [self.drawerScrollView addSubview:self.drawerShadowView];
    if (self.drawerBackgroundVisualEffectView){
        
        [self.drawerScrollView addSubview:self.drawerBackgroundVisualEffectView];
        self.drawerBackgroundVisualEffectView.layer.cornerRadius = self.drawerCornerRadius;
    }
    
    [self.drawerScrollView addSubview:self.drawerContentContainer];
    [self.detailsDrawerScrollView addSubview:self.detailsDrawerContentContainer];
    
    self.primaryContentContainer.backgroundColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.primaryContentContainer];
    [self.view addSubview:self.backgroundDimmingView];
    [self.view addSubview:self.drawerScrollView];
    [self.view addSubview:self.detailsDrawerScrollView];
    [self.primaryContentContainer constrainToParent];
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // IB Support
    if (self.primaryContentViewController == nil || self.drawerContentViewController == nil)
    {
        NSAssert((self.primaryContentContainerView != nil && self.drawerContentContainerView != nil), @"When instantiating from Interface Builder you must provide container views with an embedded view controller.");
        
        // Locate main content VC
        for (UIViewController *child in self.childViewControllers){
            if (child.view == self.primaryContentContainerView.subviews.firstObject){
                self.primaryContentViewController = child;
            }
            
            if (child.view == self.drawerContentContainerView.subviews.firstObject){
                self.drawerContentViewController = child;
            }
        }
        
        NSAssert((self.primaryContentViewController != nil && self.drawerContentViewController != nil), @"Container views must contain an embedded view controller.");
    }
    
    [self enforceCanScrollDrawer];
    [self setDrawerPosition:self.initialDrawerPosition animated:false];
    [self scrollViewDidScroll:self.drawerScrollView];
    
    if ([[self delegate] respondsToSelector:@selector(drawerDisplayModeDidChange:)]){
        [self.delegate drawerDisplayModeDidChange:self];
    }
    if ([self.primaryContentContainer respondsToSelector:@selector(drawerDisplayModeDidChange:)]){
        UIViewController <PulleyPrimaryContentControllerDelegate> *primaryContentCont = (UIViewController <PulleyPrimaryContentControllerDelegate> *)[self primaryContentContainer];
        [primaryContentCont drawerDisplayModeDidChange:self];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setNeedsSupportedDrawerPositionsUpdate];
}

//various ways to sort numbers since NSArray doesnt have .min() https://gist.github.com/anonymous/5356982

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Make sure our view controller views are subviews of the right view (Resolves #21 issue with changing the presentation context)
    
    // May be nil during initial layout
    if (self.primaryContentViewController){
        if (self.primaryContentViewController.view.superview != nil && self.primaryContentViewController.view.superview != self.primaryContentContainer) {
            [self.primaryContentContainer addSubview:self.primaryContentViewController.view];
            [self.primaryContentContainer sendSubviewToBack:self.primaryContentViewController.view];
            [self.primaryContentViewController.view constrainToParent];
        }
    }
    
    // May be nil during initial layout
    if(self.drawerContentViewController){
        if (self.drawerContentViewController.view.superview != nil && self.drawerContentViewController.view.superview != self.drawerContentContainer){
            [self.drawerContentContainer addSubview:self.drawerContentViewController.view.superview];
            [self.drawerContentContainer sendSubviewToBack:self.drawerContentViewController.view.superview];
            [self.drawerContentViewController.view.superview constrainToParent];
        }
    }
    
    if(self.detailsDrawerContentViewController){
        if (self.detailsDrawerContentViewController.view.superview != nil && self.detailsDrawerContentViewController.view.superview != self.detailsDrawerContentContainer){
            [self.detailsDrawerContentContainer addSubview:self.detailsDrawerContentViewController.view.superview];
            [self.detailsDrawerContentContainer sendSubviewToBack:self.detailsDrawerContentViewController.view.superview];
            [self.detailsDrawerContentViewController.view.superview constrainToParent];
        }
    }
    
    
    CGFloat safeAreaTopInset = self.pulleySafeAreaInsets.top;
    CGFloat safeAreaBottomInset = self.pulleySafeAreaInsets.bottom;
    CGFloat safeAreaLeftInset = self.pulleySafeAreaInsets.left;
    CGFloat safeAreaRightInset = self.pulleySafeAreaInsets.right;
    
    
    PulleyDisplayMode displayModeForCurrentLayout = self.displayMode != PulleyDisplayModeAutomatic ? self.displayMode : ((self.view.bounds.size.width >= 600.0 || self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) ? PulleyDisplayModePanel : PulleyDisplayModeDrawer);
    
    self.currentDisplayMode = displayModeForCurrentLayout;
    
    if (displayModeForCurrentLayout == PulleyDisplayModeDrawer){
        // Bottom inset for safe area / bottomLayoutGuide
        self.drawerScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentScrollableAxes;
        self.detailsDrawerScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentScrollableAxes;
        CGFloat lowestStop = [self lowestStop];
        
        CGFloat adjustedLeftSafeArea = self.adjustDrawerHorizontalInsetToSafeArea ? safeAreaLeftInset : 0.0;
        CGFloat adjustedRightSafeArea = self.adjustDrawerHorizontalInsetToSafeArea ? safeAreaRightInset : 0.0;
        
        if ([self.supportedPositions containsObject:[PulleyPosition open]]){
            // Layout scrollview
            
            self.drawerScrollView.frame = CGRectMake(adjustedLeftSafeArea, _drawerTopInset + safeAreaTopInset, self.view.bounds.size.width - adjustedLeftSafeArea - adjustedRightSafeArea, self.heightOfOpenDrawer);
            if ([self detailDrawerVisibile]){
                self.detailsDrawerScrollView.frame = self.drawerScrollView.frame;
            }
        } else {
            // Layout scrollview
            CGFloat adjustedTopInset = [self highestStop];
            self.drawerScrollView.frame = CGRectMake(adjustedLeftSafeArea, self.view.bounds.size.height - adjustedTopInset, self.view.bounds.size.width - adjustedLeftSafeArea, adjustedTopInset);//CGRect(x: adjustedLeftSafeArea, y: self.view.bounds.height - adjustedTopInset, width: self.view.bounds.width - adjustedLeftSafeArea - adjustedRightSafeArea, height: adjustedTopInset)
            
            if ([self detailDrawerVisibile]){
                self.detailsDrawerScrollView.frame = self.drawerScrollView.frame;
            } else {
                //self.detailsDrawerScrollView.frame = [self hiddenFrame];
            }
        }
        
        [self.drawerScrollView addSubview:self.drawerShadowView];
        [self.detailsDrawerScrollView addSubview:self.detailsDrawerShadowView];
        
        if (self.drawerBackgroundVisualEffectView) {
            [self.drawerScrollView addSubview:self.drawerBackgroundVisualEffectView];
            self.drawerBackgroundVisualEffectView.layer.cornerRadius = self.drawerCornerRadius;
        }
        
        if (self.detailsDrawerBackgroundVisualEffectView) {
            [self.detailsDrawerScrollView addSubview:self.detailsDrawerBackgroundVisualEffectView];
            self.detailsDrawerBackgroundVisualEffectView.layer.cornerRadius = self.drawerCornerRadius;
        }
        
        [self.drawerScrollView addSubview:self.drawerContentContainer];
        [self.detailsDrawerScrollView addSubview:self.detailsDrawerContentContainer];
        
        self.drawerContentContainer.frame = CGRectMake(0, self.drawerScrollView.bounds.size.height - lowestStop, self.drawerScrollView.bounds.size.width, self.drawerScrollView.bounds.size.height + self.bounceOverflowMargin);
        self.drawerBackgroundVisualEffectView.frame = self.drawerContentContainer.frame;
        self.drawerShadowView.frame = self.drawerContentContainer.frame;
        self.drawerScrollView.contentSize = CGSizeMake(self.drawerScrollView.bounds.size.width, (self.drawerScrollView.bounds.size.height - lowestStop) + self.drawerScrollView.bounds.size.height - safeAreaBottomInset + (self.bounceOverflowMargin - 5.0));
        
       if ([self detailDrawerVisibile]){
           self.detailsDrawerContentContainer.frame = self.drawerContentContainer.frame;
           self.detailsDrawerBackgroundVisualEffectView.frame = self.detailsDrawerContentContainer.frame;
           self.detailsDrawerShadowView.frame = self.detailsDrawerContentContainer.frame;
           self.detailsDrawerScrollView.contentSize = self.drawerScrollView.contentSize;
       }
        
        // Update rounding mask and shadows
        
        CGPathRef borderPath = [self drawerMaskingPathByRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight|UIRectCornerBottomLeft|UIRectCornerBottomRight].CGPath;//drawerMaskingPath(byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight]).cgPath
        
        CAShapeLayer *cardMaskLayer = [CAShapeLayer new];
        cardMaskLayer.path = borderPath;
        cardMaskLayer.frame = self.drawerContentContainer.bounds;
        cardMaskLayer.fillColor = [UIColor whiteColor].CGColor;
        cardMaskLayer.backgroundColor = [UIColor clearColor].CGColor;
        
        CAShapeLayer *cardMaskLayerDetails = [CAShapeLayer new];
        cardMaskLayerDetails.path = borderPath;
        cardMaskLayerDetails.frame = self.drawerContentContainer.bounds;
        cardMaskLayerDetails.fillColor = [UIColor whiteColor].CGColor;
        cardMaskLayerDetails.backgroundColor = [UIColor clearColor].CGColor;
        
        self.drawerContentContainer.layer.mask = cardMaskLayer;
        self.drawerShadowView.layer.shadowPath = borderPath;
        self.detailsDrawerContentContainer.layer.mask = cardMaskLayerDetails;
        self.detailsDrawerShadowView.layer.shadowPath = borderPath;
        
        self.backgroundDimmingView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height + self.drawerScrollView.contentSize.height);
        
        self.drawerScrollView.transform = CGAffineTransformIdentity;
        self.detailsDrawerScrollView.transform = CGAffineTransformIdentity;
        
        self.backgroundDimmingView.hidden = false;
    } else {
        // Bottom inset for safe area / bottomLayoutGuide
        if (@available(iOS 11, *)){
            self.drawerScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentScrollableAxes;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            self.automaticallyAdjustsScrollViewInsets = false;
            self.drawerScrollView.contentInset = UIEdgeInsetsMake(0, 0, 0.0, 0);
            self.detailsDrawerScrollView.contentInset = self.drawerScrollView.contentInset;
            self.drawerScrollView.scrollIndicatorInsets =  UIEdgeInsetsMake(0,0,0.0,0);
            self.detailsDrawerScrollView.scrollIndicatorInsets =  UIEdgeInsetsMake(0,0,0.0,0);
            
#pragma clang diagnostic pop
        }
        
        // Layout container
        CGFloat collapsedHeight = kPulleyDefaultCollapsedHeight;
        CGFloat partialRevealHeight = kPulleyDefaultPartialRevealHeight;
        
        if ([[self drawerContentViewController] conformsToProtocol:@protocol(PulleyDrawerViewControllerDelegate)]){
            UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
            collapsedHeight = [drawerVCCompliant collapsedDrawerHeight:safeAreaBottomInset];
            if (collapsedHeight == 0){
                collapsedHeight = kPulleyDefaultCollapsedHeight;
            }
            partialRevealHeight = [drawerVCCompliant partialRevealDrawerHeight:safeAreaBottomInset];
            if (partialRevealHeight == 0){
                partialRevealHeight = kPulleyDefaultPartialRevealHeight;
            }
        }
        //TODO: there is probably a nice efficient C methods for finding the min value in an array, investigate after things are all working
        NSArray *factors = @[@(self.view.bounds.size.height - self.panelInsets.bottom - safeAreaTopInset), [NSNumber numberWithFloat:collapsedHeight], [NSNumber numberWithFloat:partialRevealHeight]];
        CGFloat lowestStop = [[factors valueForKeyPath:@"@min.self"] floatValue];
        //let lowestStop = [(self.view.bounds.size.height - panelInsets.bottom - safeAreaTopInset), collapsedHeight, partialRevealHeight].min() ?? 0
        
        CGFloat xOrigin = (self.panelCornerPlacement == PulleyPanelCornerPlacementBottomLeft || self.panelCornerPlacement == PulleyPanelCornerPlacementTopLeft ) ? (safeAreaLeftInset + self.panelInsets.left) : (CGRectGetMaxX(self.view.bounds) - (safeAreaRightInset + self.panelInsets.right) - self.panelWidth);
        
        CGFloat yOrigin = (self.panelCornerPlacement == PulleyPanelCornerPlacementBottomLeft || self.panelCornerPlacement == PulleyPanelCornerPlacementTopLeft ) ? (self.panelInsets.top + safeAreaTopInset) : (self.panelInsets.top + safeAreaTopInset + self.bounceOverflowMargin);
        if ([[self supportedPositions] containsObject:[PulleyPosition open]]){
            
            // Layout scrollview
            self.drawerScrollView.frame = CGRectMake(xOrigin, yOrigin, self.panelWidth, self.heightOfOpenDrawer);
            if ([self detailDrawerVisibile]){
                self.detailsDrawerScrollView.frame = self.drawerScrollView.frame;
            }
        } else {
            // Layout scrollview
            CGFloat adjustedTopInset = [self.supportedPositions containsObject:[PulleyPosition partiallyRevealed]] ? partialRevealHeight : collapsedHeight;
            self.drawerScrollView.frame = CGRectMake(xOrigin, yOrigin, self.panelWidth, adjustedTopInset);
            
            if ([self detailDrawerVisibile]){
                self.detailsDrawerScrollView.frame = self.drawerScrollView.frame;
            }
            
        }
        [self syncDrawerContentViewSizeToMatchScrollPositionForSideDisplayMode];
        
        self.drawerScrollView.contentSize = CGSizeMake(self.drawerScrollView.bounds.size.width, self.view.bounds.size.height + (self.view.bounds.size.height - lowestStop));
        if (self.detailDrawerVisibile){
            self.detailsDrawerScrollView.contentSize = self.drawerScrollView.contentSize;
        } else {
            self.detailsDrawerScrollView.contentSize = CGSizeZero;
        }
        switch (self.panelCornerPlacement) {
            case PulleyPanelCornerPlacementTopLeft:
            case PulleyPanelCornerPlacementTopRight:
                //TODO: verify this is the same drawerScrollView.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
                self.drawerScrollView.transform = CGAffineTransformMakeScale(1.0, -1.0);
                self.detailsDrawerScrollView.transform = [self.drawerScrollView transform];
                break;
                
            case PulleyPanelCornerPlacementBottomLeft:
            case PulleyPanelCornerPlacementBottomRight:
                self.drawerScrollView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                self.detailsDrawerScrollView.transform = [self.drawerScrollView transform];
                break;
        }
        
        self.backgroundDimmingView.hidden = true;
    }
    
    self.drawerContentContainer.transform = self.drawerScrollView.transform;
    self.drawerShadowView.transform = self.drawerScrollView.transform;
    self.drawerBackgroundVisualEffectView.transform = self.drawerScrollView.transform;
    
    if ([self detailDrawerVisibile]){
        self.detailsDrawerContentContainer.transform = self.detailsDrawerScrollView.transform;
        self.detailsDrawerShadowView.transform = self.detailsDrawerScrollView.transform;
        self.detailsDrawerBackgroundVisualEffectView.transform = self.drawerScrollView.transform;
    }
    
    CGFloat lowestStop = [self lowestStop];
    
    if ([[self delegate] respondsToSelector:@selector(drawerChangedDistanceFromBottom:distance:bottomSafeArea:)]){
        [[self delegate] drawerChangedDistanceFromBottom:self distance:self.drawerScrollView.contentOffset.y + lowestStop bottomSafeArea:self.pulleySafeAreaInsets.bottom];
    }
    
    if ([[self drawerContentViewController] respondsToSelector:@selector(drawerChangedDistanceFromBottom:distance:bottomSafeArea:)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
        [drawerVCCompliant drawerChangedDistanceFromBottom:self distance:self.drawerScrollView.contentOffset.y + lowestStop bottomSafeArea:self.pulleySafeAreaInsets.bottom];
    }
    
    if ([[self primaryContentViewController] respondsToSelector:@selector(drawerChangedDistanceFromBottom:distance:bottomSafeArea:)]){
        UIViewController <PulleyPrimaryContentControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyPrimaryContentControllerDelegate> *)[self primaryContentViewController];
        [drawerVCCompliant drawerChangedDistanceFromBottom:self distance:self.drawerScrollView.contentOffset.y + lowestStop bottomSafeArea:self.pulleySafeAreaInsets.bottom];
    }
    
    [self maskDrawerVisualEffectView];
    [self maskBackgroundDimmingView];
    
    // Do not need to set the the drawer position in layoutSubview if the position of the drawer is changing
    // and the view is being layed out. If the drawer position is changing and the view is layed out (i.e.
    // a value or constraints are being updated) the drawer is always set to the last position,
    // and no longer scrolls properly.
    if (isChangingDrawerPosition == false) {
        [self setDrawerPosition:self.drawerPosition animated:false];
    }
}

- (BOOL)detailDrawerVisibile {
    return (self.detailsDrawerContentViewController != nil);
}

- (void)syncDrawerContentViewSizeToMatchScrollPositionForSideDisplayMode {
    
    if ([self currentDisplayMode] != PulleyDisplayModePanel){
        return;
    }
    CGFloat lowestStop = [self lowestStop];
    
    self.drawerContentContainer.frame = CGRectMake(0.0, self.drawerScrollView.bounds.size.height - lowestStop , self.drawerScrollView.bounds.size.width,  self.drawerScrollView.contentOffset.y + lowestStop + self.bounceOverflowMargin);
    self.drawerBackgroundVisualEffectView.frame = self.drawerContentContainer.frame;
    self.drawerShadowView.frame = self.drawerContentContainer.frame;
    if ([self detailDrawerVisibile]){
        self.detailsDrawerContentContainer.frame = self.drawerContentContainer.frame;
        self.detailsDrawerBackgroundVisualEffectView.frame = self.drawerBackgroundVisualEffectView.frame;
        self.detailsDrawerShadowView.frame = self.drawerShadowView.frame;
    } else {
        self.detailsDrawerContentContainer.frame = [self hiddenFrame];
        self.detailsDrawerBackgroundVisualEffectView.frame = [self tallHiddenFrame];
        self.detailsDrawerShadowView.frame = [self hiddenFrame];
    }
    // Update rounding mask and shadows
    CGPathRef borderPath = [self drawerMaskingPathByRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight|UIRectCornerBottomLeft|UIRectCornerBottomRight].CGPath;
    
    CAShapeLayer *cardMaskLayer = [CAShapeLayer new];
    cardMaskLayer.path = borderPath;
    cardMaskLayer.frame = self.drawerContentContainer.bounds;
    cardMaskLayer.fillColor = [UIColor whiteColor].CGColor;
    cardMaskLayer.backgroundColor = [UIColor clearColor].CGColor;
    
    CAShapeLayer *cardMaskLayerDetails = [CAShapeLayer new];
    cardMaskLayerDetails.path = borderPath;
    cardMaskLayerDetails.frame = self.drawerContentContainer.bounds;
    cardMaskLayerDetails.fillColor = [UIColor whiteColor].CGColor;
    cardMaskLayerDetails.backgroundColor = [UIColor clearColor].CGColor;
    
    self.drawerContentContainer.layer.mask = cardMaskLayer;
    self.detailsDrawerContentContainer.layer.mask = cardMaskLayerDetails;
    [self maskDrawerVisualEffectView];
    
    if (!isAnimatingDrawerPosition || CGPathGetBoundingBox(borderPath).size.height < CGPathGetBoundingBox(self.drawerShadowView.layer.shadowPath).size.height){
        self.drawerShadowView.layer.shadowPath = borderPath;
        self.detailsDrawerShadowView.layer.shadowPath = borderPath;
    }
}

- (void)gestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.dimmingViewTapRecognizer){
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
            [self setDrawerPosition:[self positionWhenDimmingBackgroundIsTapped] animated:true];
        }
    }
}

- (void)setDrawerPosition:(PulleyPosition *)drawerPosition animated:(BOOL)animated {
    if (self.viewLocked) return;
    [self setDrawerPosition:drawerPosition animated:animated completion:nil];
}

- (void)setDrawerPosition:(PulleyPosition *)drawerPosition animated:(BOOL)animated completion:(PulleyAnimationCompletionBlock)block {
    if (self.viewLocked) {
        if (block){
            block(false);
            return;
        }
        return;
    }
    if (![self.supportedPositions containsObject:drawerPosition]){
        NSLog(@"PulleyViewController: You can't set the drawer position to something not supported by the current view controller contained in the drawer. If you haven't already, you may need to implement the PulleyDrawerViewControllerDelegate.");
        return;
    }
    
    self.drawerPosition = drawerPosition;
    self.drawerPositionRaw = drawerPosition.rawValue;
    CGFloat collapsedHeight = kPulleyDefaultCollapsedHeight;
    CGFloat partialRevealHeight = kPulleyDefaultPartialRevealHeight;
    if ([[self drawerContentViewController] conformsToProtocol:@protocol(PulleyDrawerViewControllerDelegate)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
        
        collapsedHeight = [drawerVCCompliant collapsedDrawerHeight:self.pulleySafeAreaInsets.bottom];
        if (collapsedHeight == 0){
            collapsedHeight = kPulleyDefaultCollapsedHeight;
        }
        partialRevealHeight = [drawerVCCompliant partialRevealDrawerHeight:self.pulleySafeAreaInsets.bottom];
        if (partialRevealHeight == 0){
            partialRevealHeight = kPulleyDefaultPartialRevealHeight;
        }
        
    }
    CGFloat stopToMoveTo = 0;
    switch (self.drawerPositionRaw){
        case PulleyDrawerPositionCollapsed:
            stopToMoveTo = collapsedHeight;
            break;
            
        case PulleyDrawerPositionPartiallyRevealed:
            stopToMoveTo = partialRevealHeight;
            break;
            
        case PulleyDrawerPositionOpen:
            stopToMoveTo = self.heightOfOpenDrawer;
            break;
            
        case PulleyDrawerPositionClosed:
            stopToMoveTo = 0;
            break;
            
        default:
            stopToMoveTo = 0;
            break;
    }
    
    CGFloat lowestStop = [self lowestStop];
    
    [self triggerFeedbackGenerator];
    
    if (animated && self.view.window != nil){
        isAnimatingDrawerPosition = true;
        [UIView animateWithDuration:self.animationDuration delay:self.animationDelay usingSpringWithDamping:self.animationSpringDamping initialSpringVelocity:self.animationSpringInitialVelocity options:self.animationOptions animations:^{
            
            [self.drawerScrollView setContentOffset:CGPointMake(0, stopToMoveTo - lowestStop) animated:false];
            if ([self detailDrawerVisibile]){
                [self.detailsDrawerScrollView setContentOffset:CGPointMake(0, stopToMoveTo - lowestStop) animated:false];
            }
            // Move backgroundimmingView to avoid drawer background being darkened
            self.backgroundDimmingView.frame = [self backgroundDimmingViewFrameForDrawerPosition:stopToMoveTo];
            //self?.backgroundDimmingView.frame = self?.backgroundDimmingViewFrameForDrawerPosition(stopToMoveTo) ?? CGRect.zero
            if ([[self delegate] respondsToSelector:@selector(drawerPositionDidChange:bottomSafeArea:)]){
                [self.delegate drawerPositionDidChange:self bottomSafeArea:self.pulleySafeAreaInsets.bottom];
            }
            
            if ([[self drawerContentViewController] respondsToSelector:@selector(drawerPositionDidChange:bottomSafeArea:)]){
                UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
                [drawerVCCompliant drawerPositionDidChange:self bottomSafeArea:self.pulleySafeAreaInsets.bottom];
                
            }
            if ([[self primaryContentViewController] respondsToSelector:@selector(drawerPositionDidChange:bottomSafeArea:)]){
                UIViewController <PulleyPrimaryContentControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyPrimaryContentControllerDelegate> *)[self primaryContentViewController];
                [drawerVCCompliant drawerPositionDidChange:self bottomSafeArea:self.pulleySafeAreaInsets.bottom];
                
            }
            
            [self.view layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            
            NSLog(@"new offset:%f", self.drawerScrollView.contentOffset.y);
            
            self->isAnimatingDrawerPosition = false;
            [self syncDrawerContentViewSizeToMatchScrollPositionForSideDisplayMode];
            if (block){
                block(finished);
            }
        }];
        
    } else { //(animated && self.view.window != nil){
        
        [self.drawerScrollView setContentOffset:CGPointMake(0, stopToMoveTo - lowestStop) animated:false];
        if ([self detailDrawerVisibile]){
            [self.detailsDrawerScrollView setContentOffset:CGPointMake(0, stopToMoveTo - lowestStop) animated:false];
        }
        // Move backgroundDimmingView to avoid drawer background being darkened
        self.backgroundDimmingView.frame =
        [self backgroundDimmingViewFrameForDrawerPosition:stopToMoveTo];
        [self.delegate drawerPositionDidChange:self bottomSafeArea:self.pulleySafeAreaInsets.bottom];

        if ([[self drawerContentViewController] respondsToSelector:@selector(drawerPositionDidChange:bottomSafeArea:)]){
            UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
            [drawerVCCompliant drawerPositionDidChange:self bottomSafeArea:self.pulleySafeAreaInsets.bottom];
            
        }
        if ([[self primaryContentViewController] respondsToSelector:@selector(drawerPositionDidChange:bottomSafeArea:)]){
            UIViewController <PulleyPrimaryContentControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyPrimaryContentControllerDelegate> *)[self primaryContentViewController];
            [drawerVCCompliant drawerPositionDidChange:self bottomSafeArea:self.pulleySafeAreaInsets.bottom];
            
        }
        
        if (block){
            block(true);
        }
    }
}

/**
 Change the current drawer content view controller (The one inside the drawer)
 
 - parameter controller: The controller to replace it with
 - parameter animated:   Whether or not to animate the change.
 - parameter completion: A block object to be executed when the animation sequence ends. The Bool indicates whether or not the animations actually finished before the completion handler was called.
 */


- (void)setDrawerContentViewController:(UIViewController *)controller animated:(BOOL)animated completion: (PulleyAnimationCompletionBlock)block {
    // Account for transition issue in iOS 11
    controller.view.frame = self.drawerContentContainer.bounds;
    [controller.view layoutIfNeeded];
    
    if (animated){
        [UIView transitionWithView:self.drawerContentContainer duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            
            self.drawerContentViewController = controller;
            if ([self drawerPosition]){
                [self setDrawerPosition:[self drawerPosition] animated:false];
            } else {
                [self setDrawerPosition:[PulleyPosition collapsed] animated:false completion:nil];
            }
        } completion:^(BOOL finished) {
            if (block){
                block(finished);
            }
        }];
    } else {
        self.drawerContentViewController = controller;
        [self setDrawerPosition:_drawerPosition animated:false completion:nil];
        if (block){
            block(true);
        }
        
    }
}

/**
 Change the current drawer content view controller (The one inside the drawer). This method exists for backwards compatibility.
 
 - parameter controller: The controller to replace it with
 - parameter animated:   Whether or not to animate the change.
 */

- (void) setDrawerContentViewController:(UIViewController*)controller animated:(BOOL)animated {
    [self setDrawerContentViewController:controller animated:animated completion:nil];
}

- (void)setDrawerContentViewController:(UIViewController *)controller {
    
    UIViewController *old = _drawerContentViewController;
    if (old){
        [old willMoveToParentViewController:nil];
        [[old view] removeFromSuperview];
        [old removeFromParentViewController];
    }
    
    [controller willMoveToParentViewController:nil];
    [[controller view] removeFromSuperview];
    [controller removeFromParentViewController];
    _drawerContentViewController = controller;
    [self addChildViewController:controller];
    [self.drawerContentContainer addSubview:controller.view];
    [controller.view constrainToParent];
    if ([self isViewLoaded]){
        [self.view setNeedsLayout];
        [self setNeedsSupportedDrawerPositionsUpdate];
    }
}
- (UIBlurEffectStyle)defaultBlurEffect {
    if (@available(iOS 13, *)){
        //return UIBlurEffectStyleSystemUltraThinMaterial;
    } else {
        return UIBlurEffectStyleExtraLight;
    }
    return UIBlurEffectStyleExtraLight;
}

- (CGFloat)visibleDrawerHeight {
    if (self.drawerPosition == [PulleyPosition closed]){
        return 0.0;
    }
    return self.drawerScrollView.bounds.size.height;
}

/**
 Change the current primary content view controller (The one behind the drawer)
 
 - parameter controller: The controller to replace it with
 - parameter animated:   Whether or not to animate the change. Defaults to true.
 - parameter completion: A block object to be executed when the animation sequence ends. The Bool indicates whether or not the animations actually finished before the completion handler was called.
 */
 - (void)setPrimaryContentViewController:(UIViewController*)controller animated:(BOOL)animated completion:(PulleyAnimationCompletionBlock)block {
     
    // Account for transition issue in iOS 11
    controller.view.frame = self.primaryContentContainer.bounds;
    [controller.view layoutIfNeeded];

    if (animated){
        
        [UIView transitionWithView:self.primaryContentContainer duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            //
            self.primaryContentViewController = controller;
        } completion:^(BOOL finished) {
            
            if (block){
                block(finished);
            }
            
        }];
        
    } else { //is not animated
        self.primaryContentViewController = controller;
        if (block){
            block(true);
        }
    }
}

- (void)setPrimaryContentViewController:(UIViewController*)controller animated:(BOOL)animated {
    [self setPrimaryContentViewController:controller animated:animated completion:nil];
}

- (void)setPrimaryContentViewController:(UIViewController *)controller {
    
    UIViewController *old = _primaryContentViewController;
    if (old){
        [old willMoveToParentViewController:nil];
        [[old view] removeFromSuperview];
        [old removeFromParentViewController];
    }
    [controller willMoveToParentViewController:nil];
    [[controller view] removeFromSuperview];
    [controller removeFromParentViewController];
    _primaryContentViewController = controller;
    [self addChildViewController:controller];
    [self.primaryContentContainer addSubview:controller.view];
    [controller.view constrainToParent];
    if ([self isViewLoaded]){
        [self.view setNeedsLayout];
        [self setNeedsSupportedDrawerPositionsUpdate];
    }
}

- (void)setDetailsDrawerContentViewController:(UIViewController *)controller animated:(BOOL)animated completion: (PulleyAnimationCompletionBlock)block {
    // Account for transition issue in iOS 11
    controller.view.frame = self.detailsDrawerContentContainer.bounds;
    [controller.view layoutIfNeeded];
    
    if (animated){
        [UIView transitionWithView:self.detailsDrawerContentContainer duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            
            self.detailsDrawerContentViewController = controller;
            if ([self drawerPosition]){
                [self setDrawerPosition:[self drawerPosition] animated:false];
            } else {
                [self setDrawerPosition:[PulleyPosition collapsed] animated:false completion:nil];
            }
        } completion:^(BOOL finished) {
            if (block){
                block(finished);
            }
        }];
    } else {
        self.detailsDrawerContentViewController = controller;
        [self setDrawerPosition:_drawerPosition animated:false completion:nil];
        if (block){
            block(true);
        }
        
    }
}

- (void)setDetailsDrawerContentViewController:(UIViewController *)controller animated:(BOOL)animated {
    [self setDetailsDrawerContentViewController:controller animated:animated completion:nil];
}

- (CGRect)tallHiddenFrame {
    return CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 0);
}

- (CGRect)hiddenFrame {
    return CGRectMake(0,0, self.view.frame.size.width, 0);
}

- (void)dismissDetailViewController {
    
    UIViewController *old = _detailsDrawerContentViewController;
    isDetailDrawerCollapsing = true;
    CGFloat lowestStop = [self lowestStop];
    [UIView animateWithDuration:self.animationDuration delay:self.animationDelay usingSpringWithDamping:self.animationSpringDamping initialSpringVelocity:self.animationSpringInitialVelocity options:self.animationOptions animations:^{
        
        [self.detailsDrawerScrollView setContentOffset:CGPointMake(0, -lowestStop) animated:false];
        [self.view layoutIfNeeded];
        self->isDetailDrawerCollapsing = false;
    } completion:^(BOOL finished) {
        if (old){
            [old willMoveToParentViewController:nil];
            [[old view] removeFromSuperview];
            [old removeFromParentViewController];
        }
        self.detailsDrawerContentViewController = nil;
        self.detailsDrawerScrollView.frame = CGRectZero;
        self.detailsDrawerScrollView.contentSize = CGSizeZero;
        
    }];
    
}

- (void)setDetailsDrawerContentViewController:(UIViewController *)controller {
    
    UIViewController *old = _detailsDrawerContentViewController;
    if (old){
        [old willMoveToParentViewController:nil];
        [[old view] removeFromSuperview];
        [old removeFromParentViewController];
    }
    
    [controller willMoveToParentViewController:nil];
    [[controller view] removeFromSuperview];
    [controller removeFromParentViewController];
    _detailsDrawerContentViewController = controller;
    if (controller != nil){
        [self addChildViewController:controller];
        [self.detailsDrawerContentContainer addSubview:controller.view];
        [controller.view constrainToParentBySize];
        self.detailsDrawerScrollView.alpha = 1.0;
        self.detailsDrawerShadowView.alpha = 1.0;
        self.detailsDrawerBackgroundVisualEffectView.alpha = 1.0;
        
    } else {
        self.detailsDrawerScrollView.alpha = 0.0;
        self.detailsDrawerShadowView.alpha = 0.0;
        self.detailsDrawerBackgroundVisualEffectView.alpha = 0.0;
    }
    if ([self isViewLoaded]){
        [self.view setNeedsLayout];
    }
}

- (void)setDetailsDrawerBackgroundVisualEffectView:(UIVisualEffectView *)detailsDrawerBackgroundVisualEffectView {
    if ([self detailsDrawerBackgroundVisualEffectView] != nil){
        [[self detailsDrawerBackgroundVisualEffectView] removeFromSuperview];
    }
    _detailsDrawerBackgroundVisualEffectView = detailsDrawerBackgroundVisualEffectView;
    if ([self isViewLoaded]){
        [[self detailsDrawerScrollView] insertSubview:_detailsDrawerBackgroundVisualEffectView aboveSubview:self.detailsDrawerShadowView];
        _detailsDrawerBackgroundVisualEffectView.clipsToBounds = true;
        _detailsDrawerBackgroundVisualEffectView.layer.cornerRadius = self.drawerCornerRadius;
        [self.view setNeedsLayout];
    }
    
}

- (void)setDrawerBackgroundVisualEffectView:(UIVisualEffectView *)drawerBackgroundVisualEffectView {
    if ([self drawerBackgroundVisualEffectView] != nil){
        [[self drawerBackgroundVisualEffectView] removeFromSuperview];
    }
    _drawerBackgroundVisualEffectView = drawerBackgroundVisualEffectView;
    if ([self isViewLoaded]){
        [[self drawerScrollView] insertSubview:_drawerBackgroundVisualEffectView aboveSubview:self.drawerShadowView];
        _drawerBackgroundVisualEffectView.clipsToBounds = true;
        _drawerBackgroundVisualEffectView.layer.cornerRadius = self.drawerCornerRadius;
        [self.view setNeedsLayout];
    }
    
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity {
    CGFloat oldValue = _shadowOpacity;
    _shadowOpacity = shadowOpacity;
    if (self.isViewLoaded) {
        self.drawerShadowView.layer.shadowOpacity = shadowOpacity;
        self.detailsDrawerShadowView.layer.shadowOpacity = shadowOpacity;
        if (oldValue != shadowOpacity){
            [self.view setNeedsLayout];
        }
    }
}

- (void)setDrawerCornerRadius:(CGFloat)drawerCornerRadius  {
    CGFloat oldValue = _drawerCornerRadius;
    _drawerCornerRadius = drawerCornerRadius;
    if (oldValue != drawerCornerRadius){
        if (self.isViewLoaded){
            [self.view setNeedsLayout];
            self.drawerBackgroundVisualEffectView.layer.cornerRadius = drawerCornerRadius;
            self.detailsDrawerBackgroundVisualEffectView.layer.cornerRadius = drawerCornerRadius;
        }
    }
}

- (void)setShadowRadius:(CGFloat)shadowRadius {
    CGFloat oldValue = _shadowRadius;
    _shadowRadius = shadowRadius;
    if (oldValue != shadowRadius){
        if (self.isViewLoaded){
            self.drawerShadowView.layer.shadowRadius = shadowRadius;
            self.detailsDrawerShadowView.layer.shadowRadius = shadowRadius;
            [self.view setNeedsLayout];
        }
    }
}

- (void)setShadowOffset:(CGSize)shadowOffset {
    CGSize oldValue = _shadowOffset;
    _shadowOffset = shadowOffset;
    if (!CGSizeEqualToSize(oldValue, shadowOffset)){
        if (self.isViewLoaded) {
            self.drawerShadowView.layer.shadowOffset = shadowOffset;
            self.detailsDrawerShadowView.layer.shadowOffset = shadowOffset;
            [self.view setNeedsLayout];
        }
    }
}

- (void)setBackgroundDimmingColor:(UIColor *)backgroundDimmingColor {
    _backgroundDimmingColor = backgroundDimmingColor;
    if (self.isViewLoaded){
        self.backgroundDimmingView.backgroundColor = backgroundDimmingColor;
    }
}

- (NSArray <NSNumber *>*)getStopList {
    
    NSMutableArray <NSNumber *> * drawerStops = [NSMutableArray new];
    CGFloat collapsedHeight = kPulleyDefaultCollapsedHeight;
    CGFloat partialRevealHeight = kPulleyDefaultPartialRevealHeight;
    if ([[self drawerContentViewController] conformsToProtocol:@protocol(PulleyDrawerViewControllerDelegate)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
        collapsedHeight = [drawerVCCompliant collapsedDrawerHeight:self.pulleySafeAreaInsets.bottom];
        partialRevealHeight = [drawerVCCompliant partialRevealDrawerHeight:self.pulleySafeAreaInsets.bottom];
    }
    if ([[self supportedPositions] containsObject:[PulleyPosition collapsed]]){
        [drawerStops addObject:[NSNumber numberWithFloat:collapsedHeight]];
    }
    if ([[self supportedPositions] containsObject:[PulleyPosition partiallyRevealed]]){
        [drawerStops addObject:[NSNumber numberWithFloat:partialRevealHeight]];
    }
    if ([[self supportedPositions] containsObject:[PulleyPosition open]]){
        double openDouble = (self.view.bounds.size.height - self.drawerTopInset - self.pulleySafeAreaInsets.top);
        [drawerStops addObject:[NSNumber numberWithDouble:openDouble]];
    }
    return drawerStops;
}

/**
 Returns a masking path appropriate for the drawer content. Either
 an existing user-supplied mask from the `drawerContentViewController's`
 view will be returned, or the default Pulley mask with the requested
 rounded corners will be used.
 
 - parameter corners: The corners to round if there is no custom mask
 already applied to the `drawerContentViewController` view. If the
 `drawerContentViewController` has a custom mask (supplied by the
 user of this library), then the corners parameter will be ignored.
 */

- (UIBezierPath *)drawerMaskingPathByRoundingCorners:(UIRectCorner)corners {
    
    // In lue of drawerContentViewController.view.layoutIfNeeded() when ever this function is called, if the viewController is loaded setNeedsLayout
    if ([_drawerContentViewController isViewLoaded]){
        [_drawerContentViewController.view setNeedsLayout];
    }
    UIBezierPath *path = [UIBezierPath new];
    CAShapeLayer *customMask = self.drawerContentViewController.view.layer.mask;
    if (customMask.path){
        path = [UIBezierPath bezierPathWithCGPath:customMask.path];
    } else {
        path = [UIBezierPath bezierPathWithRoundedRect:self.drawerContentContainer.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(self.drawerCornerRadius, self.drawerCornerRadius)];
    }
    return path;
}

- (void) maskDrawerVisualEffectView {
    if (self.drawerBackgroundVisualEffectView){
        //let path = drawerMaskingPath(byRoundingCorners: [.topLeft, .topRight]) i THINK this is the right way to do this
        UIBezierPath *path = [self drawerMaskingPathByRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
        CAShapeLayer *maskLayer = [CAShapeLayer new];
        maskLayer.path = path.CGPath;
        self.drawerBackgroundVisualEffectView.layer.mask = maskLayer;
    }
    if (self.detailsDrawerBackgroundVisualEffectView){
        //let path = drawerMaskingPath(byRoundingCorners: [.topLeft, .topRight]) i THINK this is the right way to do this
        UIBezierPath *path = [self drawerMaskingPathByRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
        CAShapeLayer *maskLayer = [CAShapeLayer new];
        maskLayer.path = path.CGPath;
        self.detailsDrawerBackgroundVisualEffectView.layer.mask = maskLayer;
    }
}

/**
 Mask backgroundDimmingView layer to avoid drawer background beeing darkened.
 */

- (void)maskBackgroundDimmingView {
    CGFloat cutoutHeight = 2 * self.drawerCornerRadius;
    CGFloat maskHeight = self.backgroundDimmingView.bounds.size.height - cutoutHeight - self.drawerScrollView.contentSize.height;
    UIBezierPath *borderPath = [self drawerMaskingPathByRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
    
    // This applys the boarder path transform to the minimum x of the content container for iPhone X size devices
    CGRect frame = [[self.drawerContentContainerView superview] convertRect:self.drawerContentContainer.frame toView:self.view];
    if (!CGRectIsNull(frame)){
        [borderPath applyTransform:CGAffineTransformMakeTranslation(CGRectGetMinX(frame), maskHeight)];
    } else {
        [borderPath applyTransform:CGAffineTransformMakeTranslation(0.0, maskHeight)];
    }
    
    CAShapeLayer *maskLayer = [CAShapeLayer new];
    
    // Invert mask to cut away the bottom part of the dimming view
    [borderPath appendPath:[UIBezierPath bezierPathWithRect:self.backgroundDimmingView.bounds]];
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    maskLayer.path = borderPath.CGPath;
    self.backgroundDimmingView.layer.mask = maskLayer;
}

- (void)prepareFeedbackGenerator {
    self.feedbackGenerator = [UIFeedbackGenerator new];
    [self.feedbackGenerator prepare];
}

- (void)triggerFeedbackGenerator {
    [self prepareFeedbackGenerator];
    if ([[self feedbackGenerator] respondsToSelector:@selector(impactOccurred)]){
        [(UIImpactFeedbackGenerator *)self.feedbackGenerator impactOccurred];
    }
    if ([[self feedbackGenerator] respondsToSelector:@selector(selectionChanged)]){
        [(UISelectionFeedbackGenerator *)self.feedbackGenerator selectionChanged];
    }
    if ([[self feedbackGenerator] respondsToSelector:@selector(notificationOccurred:)]){
        [(UINotificationFeedbackGenerator *)self.feedbackGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
    }
}

/// Add a gesture recognizer to the drawer scrollview
///
/// - Parameter gestureRecognizer: The gesture recognizer to add
- (void) addDrawerGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
    [self.drawerScrollView addGestureRecognizer:gestureRecognizer];
}

/// Remove a gesture recognizer from the drawer scrollview
///
/// - Parameter gestureRecognizer: The gesture recognizer to remove
- (void) removeDrawerGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
    [self.drawerScrollView removeGestureRecognizer:gestureRecognizer];
}

- (void)bounceDrawer {
    [self bounceDrawerWithBounceHeight:50 speedMultiplier:0.75];
}

/// Bounce the drawer to get user attention. Note: Only works in .drawer display mode and when the drawer is in .collapsed or .partiallyRevealed position.
///
/// - Parameters:
///   - bounceHeight: The height to bounce
///   - speedMultiplier: The multiplier to apply to the default speed of the animation. Note, default speed is 0.75.
- (void) bounceDrawerWithBounceHeight: (CGFloat)bounceHeight speedMultiplier:( double)speedMultiplier {
    
    if ([self drawerPosition] != [PulleyPosition collapsed] && [self drawerPosition] != [PulleyPosition partiallyRevealed]){
        
        NSLog(@"Pulley: Error: You can only bounce the drawer when it's in the collapsed or partially revealed position.");
        return;
    }
    if ([self currentDisplayMode] != PulleyDisplayModeDrawer){
        NSLog(@"Pulley: Error: You can only bounce the drawer when it's in the .drawer display mode.");
        return;
    }
    CGRect drawerStartingBounds = self.drawerScrollView.bounds;
    // Adapted from https://www.cocoanetics.com/2012/06/lets-bounce;
    
    CGFloat factors[32] = {0, 32, 60, 83, 100, 114, 124, 128, 128, 124, 114, 100, 83, 60, 32,
        0, 24, 42, 54, 62, 64, 62, 54, 42, 24, 0, 18, 28, 32, 28, 18, 0};
    
    NSMutableArray *values = [NSMutableArray array];
    
    for (int i=0; i<32; i++)
    {
        CGFloat positionOffset = factors[i]/128.0f * bounceHeight;
        CGFloat newValue = drawerStartingBounds.origin.y + positionOffset;
        [values addObject:[NSNumber numberWithFloat:newValue]];
    }
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"bounds.origin.y"];
    animation.repeatCount = 1;
    animation.duration = 32.0f/30.0f * speedMultiplier;
    animation.fillMode = kCAFillModeForwards;
    animation.values = values;
    animation.removedOnCompletion = YES; // final stage is equal to starting stage
    animation.autoreverses = NO;
    [self.drawerScrollView.layer addAnimation:animation forKey:@"bounceAnimation"];
}

/**
 Get a frame for moving backgroundDimmingView according to drawer position.
 
 - parameter drawerPosition: drawer position in points
 
 - returns: a frame for moving backgroundDimmingView according to drawer position
 */
- (CGRect) backgroundDimmingViewFrameForDrawerPosition:(CGFloat)drawerPosition {
    CGFloat cutoutHeight = (2 * self.drawerCornerRadius);
    CGRect backgroundDimmingViewFrame = self.backgroundDimmingView.frame;
    backgroundDimmingViewFrame.origin.y = 0 - drawerPosition + cutoutHeight;
    return backgroundDimmingViewFrame;
}

- (void)setBackgroundDimmingOpacity:(CGFloat)backgroundDimmingOpacity {
    _backgroundDimmingOpacity = backgroundDimmingOpacity;
    if (self.isViewLoaded){
        [self scrollViewDidScroll:self.drawerScrollView];
    }
}

- (void)setDelaysContentTouches:(BOOL)delaysContentTouches {
    _delaysContentTouches = delaysContentTouches;
    if (self.isViewLoaded){
        self.drawerScrollView.delaysContentTouches = delaysContentTouches;
    }
}

- (void)setCanCancelContentTouches:(BOOL)canCancelContentTouches {
    _canCancelContentTouches = canCancelContentTouches;
    if (self.isViewLoaded){
        self.drawerScrollView.canCancelContentTouches = canCancelContentTouches;
    }
}

- (void)setDisplayMode:(PulleyDisplayMode)displayMode {
    _displayMode = displayMode;
    if (self.isViewLoaded){
        [self.view setNeedsLayout];
    }
}

- (void)setInitialDrawerPositionFromIB:(NSString *)initialDrawerPositionFromIB {
    self.initialDrawerPosition = [PulleyPosition positionForString:initialDrawerPositionFromIB];
}

- (void)setPanelCornerPlacement:(PulleyPanelCornerPlacement)panelCornerPlacement {
    _panelCornerPlacement = panelCornerPlacement;
    if (self.isViewLoaded){
        [self.view setNeedsLayout];
    }
}

- (void)enforceCanScrollDrawer {
    if (![self isViewLoaded]){
        return;
    }
    self.drawerScrollView.scrollEnabled = ([self allowsUserDrawerPositionChange] && [[self supportedPositions] count] > 1);
}

- (void)setAllowsUserDrawerPositionChange:(BOOL)allowsUserDrawerPositionChange {
    _allowsUserDrawerPositionChange = allowsUserDrawerPositionChange;
    [self enforceCanScrollDrawer];
}

- (void)setAdjustDrawerHorizontalInsetToSafeArea:(BOOL)adjustDrawerHorizontalInsetToSafeArea {
    _adjustDrawerHorizontalInsetToSafeArea = adjustDrawerHorizontalInsetToSafeArea;
    if (self.isViewLoaded){
        [self.view setNeedsLayout];
    }
}




- (CGFloat)collapsedDrawerHeight:(CGFloat)bottomSafeArea {
    if ([[self drawerContentViewController] conformsToProtocol:@protocol(PulleyDrawerViewControllerDelegate)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
        return [drawerVCCompliant collapsedDrawerHeight:bottomSafeArea];
    }
    return 68 + bottomSafeArea;
}

- (CGFloat)partialRevealDrawerHeight:(CGFloat)bottomSafeArea {
    if ([[self drawerContentViewController] conformsToProtocol:@protocol(PulleyDrawerViewControllerDelegate)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
        return [drawerVCCompliant partialRevealDrawerHeight:bottomSafeArea];
    }
    return 264.0 + bottomSafeArea;
}

- (NSArray<PulleyPosition *> *)supportedDrawerPositions {
    return [PulleyPosition all];
}

- (void)drawerPositionDidChange:(PulleyViewController*)drawer bottomSafeArea:(CGFloat)bottomSafeArea {
    if ([[self drawerContentViewController] respondsToSelector:@selector(drawerPositionDidChange:bottomSafeArea:)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
        [drawerVCCompliant drawerPositionDidChange:self bottomSafeArea:bottomSafeArea];
    }
}

- (void)makeUIAdjustmentsForFullscreen:(CGFloat)progress bottomSafeArea:(CGFloat)bottomSafeArea {
    if ([[self drawerContentViewController] respondsToSelector:@selector(makeUIAdjustmentsForFullscreen:bottomSafeArea:)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
        [drawerVCCompliant makeUIAdjustmentsForFullscreen:progress bottomSafeArea:bottomSafeArea];
    }
    
}

- (void)drawerChangedDistanceFromBottom:(PulleyViewController*)drawer distance:(CGFloat)distance bottomSafeArea:(CGFloat)bottomSafeArea {
    if ([[self drawerContentViewController] respondsToSelector:@selector(drawerChangedDistanceFromBottom:distance:bottomSafeArea:)]){
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = (UIViewController <PulleyDrawerViewControllerDelegate> *)[self drawerContentViewController];
        [drawerVCCompliant drawerChangedDistanceFromBottom:drawer distance:distance bottomSafeArea:bottomSafeArea];
    }
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(id<UIContentContainer>)container {
    [super preferredContentSizeDidChangeForChildContentContainer:container];
}

- (CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
    return [super sizeForChildContentContainer:container withParentContainerSize:parentSize];
}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(id<UIContentContainer>)container {
    [super systemLayoutFittingSizeDidChangeForChildContentContainer:container];
}

// MARK: Propogate child view controller style / status bar presentation based on drawer state

-(UIViewController *)childForStatusBarStyle {
    
    if (self.drawerPosition == [PulleyPosition open]) {
        return self.drawerContentViewController;
    }
    return self.primaryContentViewController;
}

-(UIViewController *)childForStatusBarHidden {
    
    if (self.drawerPosition == [PulleyPosition open]) {
        return self.drawerContentViewController;
    }
    return self.primaryContentViewController;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    PulleyPosition *currentPosition = [self drawerPosition];
    if (@available(iOS 10.0, *)){
        [coordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _context) {
            if (currentPosition){
                [self setDrawerPosition:currentPosition animated:false];
            }
        }];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [coordinator notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _context) {
            if (currentPosition){
                [self setDrawerPosition:currentPosition animated:false];
            }
        }];
#pragma clang diagnostic pop
    }
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
}

- (void)setNeedsFocusUpdate {
    [super setNeedsFocusUpdate];
}

- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context {
    return [super shouldUpdateFocusInContext:context];
}

- (void)updateFocusIfNeeded {
    [super updateFocusIfNeeded];
}

- (BOOL)shouldTouchPassthroughScrollView:(PulleyPassthroughScrollView *)scrollView point:(CGPoint)point {
    CGPoint convertedPoint = [self.drawerContentContainer convertPoint:point fromView:scrollView];
     return !CGRectContainsPoint(self.drawerContentContainer.bounds, convertedPoint);
}

- (UIView *)viewToReceiveTouch:(PulleyPassthroughScrollView *)scrollView point:(CGPoint)point {
    if (self.currentDisplayMode == PulleyDisplayModeDrawer){
        if (self.drawerPosition == [PulleyPosition open]){
            return self.backgroundDimmingView;
        }
        
        return self.primaryContentContainer;
    } else {
        
        CGPoint convertedPoint = [self.drawerContentContainer convertPoint:point fromView:scrollView];
        
        if (CGRectContainsPoint(self.drawerContentContainer.bounds, convertedPoint)){
            
            return self.drawerContentViewController.view;
        }
        
        return self.primaryContentContainer;
    }
}

- (NSPredicate *)noClosedPredicate {
    NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        if (evaluatedObject != [PulleyPosition closed]){
            return true;
        } else {
            return false;
        }
    }];
    return pred;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    if (scrollView == self.drawerScrollView || scrollView == self.detailsDrawerScrollView) {
        // Find the closest anchor point and snap there.
        CGFloat collapsedHeight = kPulleyDefaultCollapsedHeight;
        CGFloat partialRevealHeight = kPulleyDefaultPartialRevealHeight;
        UIViewController <PulleyDrawerViewControllerDelegate> *drawerVCCompliant = [self compliantDrawerContentViewControllerIfApplicable];
        if(drawerVCCompliant) {
            collapsedHeight = [drawerVCCompliant collapsedDrawerHeight:self.pulleySafeAreaInsets.bottom];
            partialRevealHeight = [drawerVCCompliant partialRevealDrawerHeight:self.pulleySafeAreaInsets.bottom];
        }
        
        NSMutableArray <NSNumber *>* drawerStops = [NSMutableArray new];//: [CGFloat] = [CGFloat]()
        CGFloat currentDrawerPositionStop = 0.0;
        if ([self.supportedPositions containsObject:[PulleyPosition open]]){
            
            [drawerStops addObject:[NSNumber numberWithFloat:self.heightOfOpenDrawer]];
            
            if (self.drawerPosition == [PulleyPosition open]){
                currentDrawerPositionStop = drawerStops.lastObject.floatValue;
            }
        }
        if ([self.supportedPositions containsObject:[PulleyPosition partiallyRevealed]]){
            [drawerStops addObject:[NSNumber numberWithFloat:partialRevealHeight]];
            
            if (self.drawerPosition == [PulleyPosition partiallyRevealed]){
                currentDrawerPositionStop = drawerStops.lastObject.floatValue;
            }
        }
        if ([self.supportedPositions containsObject:[PulleyPosition collapsed]]){
            [drawerStops addObject:[NSNumber numberWithFloat:collapsedHeight]];
            if (self.drawerPosition == [PulleyPosition collapsed]){
                currentDrawerPositionStop = drawerStops.lastObject.floatValue;
            }
        }
        
        CGFloat lowestStop = [[drawerStops valueForKeyPath:@"@min.self"] floatValue];
        CGFloat distanceFromBottomOfView = lowestStop + self.lastDragTargetContentOffset.y;
        CGFloat currentClosestStop = lowestStop;
        
        for (NSNumber *currentStop in drawerStops){
            if (fabs(currentStop.floatValue - distanceFromBottomOfView) < fabs(currentClosestStop - distanceFromBottomOfView)){
                currentClosestStop = currentStop.floatValue;
            }
        }
     
        PulleyPosition *closestValidDrawerPosition = self.drawerPosition;
        
        if (fabs(currentClosestStop - self.heightOfOpenDrawer) <= FLT_EPSILON && [[self supportedPositions] containsObject:[PulleyPosition open]]){
            closestValidDrawerPosition = [PulleyPosition open];
        } else if (fabs(currentClosestStop - collapsedHeight) <= FLT_EPSILON && [[self supportedPositions] containsObject:[PulleyPosition collapsed]]){
            closestValidDrawerPosition = [PulleyPosition collapsed];
        }
        else if ([[self supportedPositions] containsObject:[PulleyPosition partiallyRevealed]]) {
            closestValidDrawerPosition = [PulleyPosition partiallyRevealed];
        }
        PulleySnapMode snapModeToUse = closestValidDrawerPosition == self.drawerPosition ? self.snapMode : PulleySnapModeNearestPosition;
        
        switch (snapModeToUse) {
            case PulleySnapModeNearestPosition:
                
                [self setDrawerPosition:closestValidDrawerPosition animated:true];
                break;
                
            case PulleySnapModeNearestPositionUsingThreshold:
            {
                CGFloat distance = currentClosestStop - distanceFromBottomOfView;
                PulleyPosition *positionToSnapTo = self.drawerPosition;
                if (fabs(distance) > self.threshold){
                    if (distance < 0){
                        //lowest->highest raw value
                        NSArray *orderedSupportedDrawerPositions = [self supportedPulleyPositionsWithoutClosedAscending:true];
                        for (PulleyPosition *position in orderedSupportedDrawerPositions){
                            if (position.rawValue > self.drawerPosition.rawValue){
                                positionToSnapTo = position;
                                break;
                            }
                        }
                    } else {
                     
                        //highest->lowest raw value
                        //2->0
                        NSArray *orderedSupportedDrawerPositions = [self supportedPulleyPositionsWithoutClosedAscending:false];

                        for (PulleyPosition *position in orderedSupportedDrawerPositions){
                            if (position.rawValue < self.drawerPosition.rawValue){
                                positionToSnapTo = position;
                                break;
                            }
                        }
                    }
                }
                
                [self setDrawerPosition: positionToSnapTo animated:true completion:nil];
            }
                break;
                
            default:
                break;
        }
        
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView == _drawerScrollView){
        isChangingDrawerPosition = true;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    [self prepareFeedbackGenerator];
    
    if (scrollView == self.drawerScrollView || scrollView == self.detailsDrawerScrollView){
        self.lastDragTargetContentOffset = *targetContentOffset;
        
        // Halt intertia
        *targetContentOffset = scrollView.contentOffset;
        isChangingDrawerPosition = false;
        //targetContentOffset.pointee = scrollView.contentOffset
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView == self.drawerScrollView || scrollView == self.detailsDrawerScrollView){
        
        UIViewController <PulleyDrawerViewControllerDelegate> *compliantVC = [self compliantDrawerContentViewControllerIfApplicable];
        
        UIViewController <PulleyDelegate> *primaryVC = (UIViewController <PulleyDelegate> *)[self primaryContentViewController];
        
        CGFloat partialRevealHeight = [compliantVC partialRevealDrawerHeight:self.pulleySafeAreaInsets.bottom];
        if (partialRevealHeight == 0){
            partialRevealHeight = kPulleyDefaultPartialRevealHeight;
        }
        
        CGFloat lowestStop = [self lowestStop];
        if (scrollView == self.detailsDrawerScrollView && !isDetailDrawerCollapsing){
            self.drawerScrollView.contentOffset = scrollView.contentOffset; //keep them in sync!
        }
        if ((scrollView.contentOffset.y - self.pulleySafeAreaInsets.bottom) > partialRevealHeight - lowestStop && [self.supportedPositions containsObject:[PulleyPosition open]]){
            // Calculate percentage between partial and full reveal
            CGFloat fullRevealHeight = self.heightOfOpenDrawer;
            CGFloat progress = 0;
            if (fullRevealHeight == partialRevealHeight) {
                progress = 1.0;
            } else {
                progress = (scrollView.contentOffset.y - (partialRevealHeight - lowestStop)) / (fullRevealHeight - (partialRevealHeight));
            }
            
            if ([self.delegate respondsToSelector:@selector(makeUIAdjustmentsForFullscreen:bottomSafeArea:)]){
                [self.delegate makeUIAdjustmentsForFullscreen:progress bottomSafeArea:self.pulleySafeAreaInsets.bottom];
            }
            
            if (compliantVC && [compliantVC respondsToSelector:@selector(makeUIAdjustmentsForFullscreen:bottomSafeArea:)]) {
                [compliantVC makeUIAdjustmentsForFullscreen:progress bottomSafeArea:self.pulleySafeAreaInsets.bottom];
            }
      
            if (primaryVC && [primaryVC respondsToSelector:@selector(makeUIAdjustmentsForFullscreen:bottomSafeArea:)]) {
                [primaryVC makeUIAdjustmentsForFullscreen:progress bottomSafeArea:self.pulleySafeAreaInsets.bottom];
            }
        
            self.backgroundDimmingView.alpha = progress * self.backgroundDimmingOpacity;
            
            self.backgroundDimmingView.userInteractionEnabled = true;
        }
        else {
            if (self.backgroundDimmingView.alpha >= 0.001){
                self.backgroundDimmingView.alpha = 0.0;
                
                if ([self.delegate respondsToSelector:@selector(makeUIAdjustmentsForFullscreen:bottomSafeArea:)]){
                    [self.delegate makeUIAdjustmentsForFullscreen:0.0 bottomSafeArea:self.pulleySafeAreaInsets.bottom];
                }
                
                if (compliantVC && [compliantVC respondsToSelector:@selector(makeUIAdjustmentsForFullscreen:bottomSafeArea:)]){
                    [compliantVC makeUIAdjustmentsForFullscreen:0.0 bottomSafeArea:self.pulleySafeAreaInsets.bottom];
                }
                
                if (primaryVC && [primaryVC respondsToSelector:@selector(makeUIAdjustmentsForFullscreen:bottomSafeArea:)]){
                    [primaryVC makeUIAdjustmentsForFullscreen:0.0 bottomSafeArea:self.pulleySafeAreaInsets.bottom];
                }
                self.backgroundDimmingView.userInteractionEnabled = false;
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(drawerChangedDistanceFromBottom:distance:bottomSafeArea:)]){
            if (scrollView == self.drawerScrollView || (scrollView == self.detailsDrawerScrollView && !isDetailDrawerCollapsing)){
                [self.delegate drawerChangedDistanceFromBottom:self distance:scrollView.contentOffset.y + lowestStop bottomSafeArea:self.pulleySafeAreaInsets.bottom];
                
            }
        }
        
        if (compliantVC && [compliantVC respondsToSelector:@selector(drawerChangedDistanceFromBottom:distance:bottomSafeArea:)]){
            if (scrollView == self.drawerScrollView || (scrollView == self.detailsDrawerScrollView && !isDetailDrawerCollapsing)){
                [compliantVC drawerChangedDistanceFromBottom:self distance:scrollView.contentOffset.y + lowestStop bottomSafeArea:self.pulleySafeAreaInsets.bottom];
            }
        }
        
        if (primaryVC && [primaryVC respondsToSelector:@selector(drawerChangedDistanceFromBottom:distance:bottomSafeArea:)]){
            if (scrollView == self.drawerScrollView || (scrollView == self.detailsDrawerScrollView && !isDetailDrawerCollapsing)){
                [primaryVC drawerChangedDistanceFromBottom:self distance:scrollView.contentOffset.y + lowestStop bottomSafeArea:self.pulleySafeAreaInsets.bottom];
            }
        }
        
        // Move backgroundDimmingView to avoid drawer background beeing darkened
        
        self.backgroundDimmingView.frame = [self backgroundDimmingViewFrameForDrawerPosition:scrollView.contentOffset.y + lowestStop];
        [self syncDrawerContentViewSizeToMatchScrollPositionForSideDisplayMode];
    }
}

- (void)showDetailsViewInDrawer:(UIViewController *)detailsViewController {
    
    [self setDetailsDrawerContentViewController:detailsViewController];
    [UIView animateWithDuration:self.animationDuration delay:self.animationDelay usingSpringWithDamping:self.animationSpringDamping initialSpringVelocity:self.animationSpringInitialVelocity options:self.animationOptions animations:^{
        [self.detailsDrawerScrollView setContentOffset:self.drawerScrollView.contentOffset animated:false];
    } completion:^(BOOL finished) {
        
    }];
}

@end

