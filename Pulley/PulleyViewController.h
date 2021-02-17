//
//  PulleyViewController.h
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PulleyPassthroughScrollView.h"
@class PulleyViewController;

/**
 Represents a Pulley drawer position.
 
 - collapsed:         When the drawer is in its smallest form, at the bottom of the screen.
 - partiallyRevealed: When the drawer is partially revealed.
 - open:              When the drawer is fully open.
 - closed:            When the drawer is off-screen at the bottom of the view. Note: Users cannot close or reopen the drawer on their own. You must set this programatically
 */
@interface PulleyPosition: NSObject
@property NSInteger rawValue;
+(PulleyPosition *)collapsed;
+(PulleyPosition *)partiallyRevealed;
+(PulleyPosition *)open;
+(PulleyPosition *)closed;
+ (NSArray <PulleyPosition *>*)all;

/// Return one of the defined positions for the given string.
///
/// - Parameter string: The string, preferably obtained by `stringFor(position:)`
/// - Returns: The `PulleyPosition` or `.collapsed` if the string didn't match.
+ (PulleyPosition *)positionForString:(NSString *)positionString;
- (instancetype)initWithRawValue:(NSInteger)value;
@end

/**
 *  The base delegate protocol for Pulley delegates.
 */

@protocol PulleyDelegate <NSObject>

@optional

/** This is called after size changes, so if you care about the bottomSafeArea property for custom UI layout, you can use this value.
 * NOTE: It's not called *during* the transition between sizes (such as in an animation coordinator), but rather after the resize is complete.
 */
-(void)drawerPositionDidChange:(PulleyViewController*)drawer bottomSafeArea:(CGFloat)bottomSafeArea;

/**
 *  Make UI adjustments for when Pulley goes to 'fullscreen'. Bottom safe area is provided for your convenience.
 */
-(void)makeUIAdjustmentsForFullscreen:(CGFloat)progress bottomSafeArea:(CGFloat)bottomSafeArea;

/**
 *  Make UI adjustments for changes in the drawer's distance-to-bottom. Bottom safe area is provided for your convenience.
 */
-(void)drawerChangedDistanceFromBottom:(PulleyViewController*)drawer distance:(CGFloat)distance bottomSafeArea:(CGFloat)bottomSafeArea;

/**
 *  Called when the current drawer display mode changes (leftSide vs bottomDrawer). Make UI changes to account for this here.
 */
-(void)drawerDisplayModeDidChange:(PulleyViewController*)drawer;

@end

//These are normally optional, but it seems counterproductive for protocol adherence checks.

/**
 *  View controllers in the drawer can implement this to receive changes in state or provide values for the different drawer positions.
 */
@protocol PulleyDrawerViewControllerDelegate <PulleyDelegate>

/**
 *  Provide the collapsed drawer height for Pulley. Pulley does NOT automatically handle safe areas for you, however: bottom safe area is provided for your convenience in computing a value to return.
 */
-(CGFloat)collapsedDrawerHeight:(CGFloat)bottomSafeArea;

/**
 *  Provide the partialReveal drawer height for Pulley. Pulley does NOT automatically handle safe areas for you, however: bottom safe area is provided for your convenience in computing a value to return.
 */
-(CGFloat)partialRevealDrawerHeight:(CGFloat)bottomSafeArea;

/**
 *  Return the support drawer positions for your drawer.
 */
-(NSArray <PulleyPosition *>*)supportedDrawerPositions;

@end
/**
 *  View controllers that are the main content can implement this to receive changes in state.
 */
// Not currently used for anything, but it's here for parity with the hopes that it'll one day be used.
@protocol PulleyPrimaryContentControllerDelegate <PulleyDelegate>

/**
 *  A completion block used for animation callbacks.
 */

typedef void (^PulleyAnimationCompletionBlock)(BOOL finished);
@end

//obj-c specific, this doesnt exist 1:1 on swift v
typedef NS_ENUM(NSInteger, PulleyDrawerPosition) {
    PulleyDrawerPositionCollapsed,
    PulleyDrawerPositionPartiallyRevealed,
    PulleyDrawerPositionOpen,
    PulleyDrawerPositionClosed
};

/// Represents the current display mode for Pulley
///
/// - panel: Show as a floating panel (replaces: leftSide)
/// - drawer: Show as a bottom drawer (replaces: bottomDrawer)
/// - automatic: Determine it based on device / orientation / size class (like Maps.app)

typedef NS_ENUM(NSInteger, PulleyDisplayMode) {
    PulleyDisplayModePanel = 0,
    PulleyDisplayModeDrawer,
    PulleyDisplayModeAutomatic
};

/// Represents the positioning of the drawer when the `displayMode` is set to either `PulleyDisplayMode.panel` or `PulleyDisplayMode.automatic`.
///
/// - topLeft: The drawer will placed in the upper left corner
/// - topRight: The drawer will placed in the upper right corner
/// - bottomLeft: The drawer will placed in the bottom left corner
/// - bottomRight: The drawer will placed in the bottom right corner

typedef NS_ENUM(NSInteger, PulleyPanelCornerPlacement) {
    PulleyPanelCornerPlacementTopLeft = 0,
    PulleyPanelCornerPlacementTopRight,
    PulleyPanelCornerPlacementBottomLeft,
    PulleyPanelCornerPlacementBottomRight
};

/// Represents the 'snap' mode for Pulley. The default is 'nearest position'. You can use 'nearestPositionUnlessExceeded' to make the drawer feel lighter or heavier.
///
/// - nearestPosition: Snap to the nearest position when scroll stops
/// - nearestPositionUnlessExceeded: Snap to the nearest position when scroll stops, unless the distance is greater than 'threshold', in which case advance to the next drawer position.

typedef NS_ENUM(NSInteger, PulleySnapMode) {
    PulleySnapModeNearestPosition = 0,
    PulleySnapModeNearestPositionUsingThreshold,
};

/// NOTE: use these to change snap modes instead, gets around the enum deficencey in obj-c
#define setSnapModeNearest self.snapMode = PulleySnapModeNearestPosition
#define setSnapModeToNearestPositionUnlessExceeded(T) self.snapMode = PulleySnapModeNearestPositionUsingThreshold; self.threshold = T

@interface PulleyViewController : UIViewController <PulleyDrawerViewControllerDelegate, UIScrollViewDelegate, PulleyPassthroughScrollViewDelegate>

/// The content view controller and drawer controller can receive delegate events already. This lets another object observe the changes, if needed.
@property (weak) id <PulleyDelegate> delegate;
@property (readwrite, assign) NSInteger threshold;
@property (readwrite, assign) CGFloat bounceOverflowMargin;

@property (readwrite, assign) BOOL viewLocked; //prevents any kind of expanding or collapsing from happening at all

// Interface Builder

/// When using with Interface Builder only! Connect a containing view to this outlet.
@property IBOutlet UIView *primaryContentContainerView;
/// When using with Interface Builder only! Connect a containing view to this outlet.
@property IBOutlet UIView *drawerContentContainerView;
/// The current content view controller (shown behind the drawer).
@property (nonatomic, strong) UIViewController *primaryContentViewController;
/// The current drawer view controller (shown in the drawer)
@property (nonatomic, strong) UIViewController *drawerContentViewController;
/// The secondary drawer view controller (shown if there is a second drawer for display detials)
@property (nonatomic, strong) UIViewController *detailsDrawerContentViewController;
/// The current position of the drawer.
@property (nonatomic, strong) PulleyPosition *drawerPosition;
/// The background visual effect layer for the drawer. By default this is the extraLight effect. You can change this if you want, or assign nil to remove it.
@property (nonatomic, strong) UIVisualEffectView *drawerBackgroundVisualEffectView;
/// The background visual effect layer for the details drawer. By default this is the extraLight effect. You can change this if you want, or assign nil to remove it.
@property (nonatomic, strong) UIVisualEffectView *detailsDrawerBackgroundVisualEffectView;
// Obj-C specific raw enum value of current drawer position
@property (nonatomic, readwrite, assign) PulleyDrawerPosition drawerPositionRaw;
/// The currently rendered display mode for Pulley. This will match displayMode unless you have it set to 'automatic'. This will provide the 'actual' display mode (never automatic).
@property (nonatomic, readwrite, assign) PulleyDisplayMode currentDisplayMode;
/// This replaces the previous panelInsetLeft and panelInsetTop properties. Depending on what corner placement is being used, different values from this struct will apply. For example, 'topLeft' corner placement will utilize the .top, .left, and .bottom inset properties and it will ignore the .right property (use panelWidth property to specify width)
@property (nonatomic, readwrite, assign) IBInspectable UIEdgeInsets panelInsets;
/// The inset from the top safe area when the drawer is fully open. This property is only for the 'drawer' displayMode. Use panelInsets to control the top/bottom/left/right insets for the panel.
@property (nonatomic, readwrite, assign) IBInspectable CGFloat drawerTopInset;

/// The width of the panel in panel displayMode
@property (nonatomic, readwrite, assign) IBInspectable CGFloat panelWidth;

/// The corner radius for the drawer.
/// Note: This property is ignored if your drawerContentViewController's view.layer.mask has a custom mask applied using a CAShapeLayer.
/// Note: Custom CAShapeLayer as your drawerContentViewController's view.layer mask will override Pulley's internal corner rounding and use that mask as the drawer mask.
@property (nonatomic, readwrite, assign) IBInspectable CGFloat drawerCornerRadius;

/// The opacity of the drawer shadow.
@property (nonatomic, readwrite, assign) IBInspectable CGFloat shadowOpacity;

/// The radius of the drawer shadow.
@property (nonatomic, readwrite, assign) IBInspectable CGFloat shadowRadius;

/// The offset of the drawer shadow.
@property (nonatomic, readwrite, assign) IBInspectable CGSize shadowOffset;

/// The opaque color of the background dimming view.
@property (nonatomic, strong) IBInspectable UIColor *backgroundDimmingColor;

/// The maximum amount of opacity when dimming.
@property (nonatomic, readwrite, assign) IBInspectable CGFloat backgroundDimmingOpacity;

/// The drawer scrollview's delaysContentTouches setting
@property (nonatomic, readwrite, assign) IBInspectable BOOL delaysContentTouches;

/// The drawer scrollview's canCancelContentTouches setting
@property (nonatomic, readwrite, assign) IBInspectable BOOL canCancelContentTouches;

/// The starting position for the drawer when it first loads
@property (nonatomic, strong) PulleyPosition *initialDrawerPosition;
/// The display mode for Pulley. Default is 'drawer', which preserves the previous behavior of Pulley. If you want it to adapt automatically, choose 'automatic'. The current display mode is available by using the 'currentDisplayMode' property.
@property (nonatomic, readwrite, assign) PulleyDisplayMode displayMode;

/// The Y positioning for Pulley. This property is only oberserved when `displayMode` is set to `.automatic` or `bottom`. Default value is `.topLeft`.
@property (nonatomic, readwrite, assign) PulleyPanelCornerPlacement panelCornerPlacement;

/// This is here exclusively to support IBInspectable in Interface Builder because Interface Builder can't deal with enums. If you're doing this in code use the -initialDrawerPosition property instead. Available strings are: open, closed, partiallyRevealed, collapsed
@property (nonatomic, strong) IBInspectable NSString *initialDrawerPositionFromIB;

/// Whether the drawer's position can be changed by the user. If set to `false`, the only way to move the drawer is programmatically. Defaults to `true`.
@property (nonatomic, readwrite, assign) IBInspectable BOOL allowsUserDrawerPositionChange;

/// The animation duration for setting the drawer position
@property (readwrite, assign) IBInspectable NSTimeInterval animationDuration;

/// The animation delay for setting the drawer position
@property (readwrite, assign) IBInspectable NSTimeInterval animationDelay;

/// The spring damping for setting the drawer position
@property (readwrite, assign) IBInspectable CGFloat animationSpringDamping;

/// The spring's initial velocity for setting the drawer position
@property (readwrite, assign) IBInspectable CGFloat animationSpringInitialVelocity;

/// This setting allows you to enable/disable Pulley automatically insetting the drawer on the left/right when in 'bottomDrawer' display mode in a horizontal orientation on a device with a 'notch' or other left/right obscurement.
@property (nonatomic, readwrite, assign) IBInspectable BOOL adjustDrawerHorizontalInsetToSafeArea;
/// The animation options for setting the drawer position
@property (readwrite, assign) UIViewAnimationOptions animationOptions;

/// The drawer snap mode
@property (readwrite, assign) PulleySnapMode snapMode;

// The feedback generator to use for drawer positon changes. Note: This is 'Any' to preserve iOS 9 compatibilty. Assign a UIFeedbackGenerator to this property. Anything else will be ignored.
@property (nonatomic, strong) UIFeedbackGenerator *feedbackGenerator;

// The position the pulley should animate to when the background is tapped. Default is collapsed.
@property (nonatomic, strong) PulleyPosition *positionWhenDimmingBackgroundIsTapped;

// Tracks whether or not the optional detail drawer is visible
- (BOOL)detailDrawerVisibile;

/// Get the current bottom safe area for Pulley. This is a convenience accessor. Most delegate methods where you'd need it will deliver it as a parameter.
- (CGFloat)bottomSafeSpace;

//new additions
- (void)hideDrawerAnimated:(BOOL)animated;
- (void)showDrawerAnimated:(BOOL)animated;
/**
 Change the current primary content view controller (The one behind the drawer). This method exists for backwards compatibility.
 
 - parameter controller: The controller to replace it with
 - parameter animated:   Whether or not to animate the change. Defaults to true.
 */
- (void)setPrimaryContentViewController:(UIViewController*)controller animated:(BOOL)animated;
/**
 Change the current primary content view controller (The one behind the drawer)
 
 - parameter controller: The controller to replace it with
 - parameter animated:   Whether or not to animate the change. Defaults to true.
 - parameter completion: A block object to be executed when the animation sequence ends. The Bool indicates whether or not the animations actually finished before the completion handler was called.
 */
- (void)setPrimaryContentViewController:(UIViewController*)controller animated:(BOOL)animated completion:(PulleyAnimationCompletionBlock)block;
/**
Change the current drawer content view controller (The one inside the drawer)

- parameter controller: The controller to replace it with
- parameter position: The initial position of the contoller
- parameter animated:   Whether or not to animate the change.
- parameter completion: A block object to be executed when the animation sequence ends. The Bool indicates whether or not the animations actually finished before the completion handler was called.
*/

- (void)setDrawerContentViewController:(UIViewController *)controller position:(PulleyPosition *)position animated:(BOOL)animated completion: (PulleyAnimationCompletionBlock)block;

/**
 Set the drawer position, by default the change will be animated. Deprecated. Recommend switching to the other setDrawerPosition method, this one will be removed in a future release.
 
 - parameter position: The position to set the drawer to.
 - parameter isAnimated: Whether or not to animate the change. Default: true
 */

- (void)setDrawerPosition:(PulleyPosition *)drawerPosition animated:(BOOL)animated;

/**
 Change the current drawer content view controller (The one inside the drawer)
 
 - parameter controller: The controller to replace it with
 - parameter animated:   Whether or not to animate the change.
 - parameter completion: A block object to be executed when the animation sequence ends. The Bool indicates whether or not the animations actually finished before the completion handler was called.
 */
- (void)setDrawerPosition:(PulleyPosition *)drawerPosition animated:(BOOL)animated completion:(PulleyAnimationCompletionBlock)block;

// The visible height of the drawer. Useful for adjusting the display of content in the main content view.
- (CGFloat)visibleDrawerHeight;
// Returns default blur style depends on iOS version.
- (UIBlurEffectStyle)defaultBlurEffect;
// Bounce the drawer to get user attention
- (void)bounceDrawer;
/**
 Initialize the drawer controller programmtically.
 
 - parameter contentViewController: The content view controller. This view controller is shown behind the drawer.
 - parameter drawerViewController:  The view controller to display inside the drawer.
 
 - note: The drawer VC is 20pts too tall in order to have some extra space for the bounce animation. Make sure your constraints / content layout take this into account.
 
 - returns: A newly created Pulley drawer.
 */
- (instancetype)initWithContentViewController:(UIViewController *)contentViewController drawerViewController:(UIViewController *)drawerViewController;

- (void)showDetailsViewInDrawer:(UIViewController *)detailsViewController;
- (void)dismissDetailViewController;
@end

