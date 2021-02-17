# Pulley-ObjC
Objective-C port of https://github.com/52inc/Pulley

This port has one additional feature that doesn't exist in it's Swift inspiration / counterpart: 

```Objective-C
- (void)showDetailsViewInDrawer:(UIViewController *)detailsViewController;
- (void)dismissDetailViewController;
```

These methods allow you to have a secondary drawer (like in the maps app) instead of replacing your primary content view controllers contents. Replacing your contents is still possible as well!

The only thing missing feature wise is the 'compact' mode for SE devices, will add ASAP. Also needs its own cocoapod, works with carthage now! add github "GuardianFirewall/Pulley-ObjC" to your Cartfile

