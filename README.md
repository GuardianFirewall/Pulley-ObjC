# Pulley-ObjC
Objective-C port of https://github.com/52inc/Pulley

This port has one additional feature that doesn't exist in it's Swift inspiration / counterpart: 

```Objective-C
/**
 Show a secondary 'detail' view controller inside a new drawer that is overlayed on top of the current drawer. Similar to the maps application
 
 -parameter detailsViewController: The new drawers content view controller. This view controller is show inside of the new secondary drawer
 
 */
- (void)showDetailsViewInDrawer:(UIViewController *)detailsViewController;

// Dismiss the secondary 'detail' drawer
- (void)dismissDetailViewController;
```

These methods allow you to have a secondary drawer (like in the maps app) instead of replacing your primary content view controllers contents. Replacing your contents is still possible as well!

The only thing missing feature wise is the 'compact' mode for SE devices, will add ASAP. Also needs its own cocoapod, works with carthage now! add github "GuardianFirewall/Pulley-ObjC" to your Cartfile

