//
//  AppDelegate.m
//  Pulley-ObjC
//
//  Created by Kevin Bradley on 6/23/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "AppDelegate.h"
#import "PulleyViewController.h"
#import "DrawerContentViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    /*
    
     initializing completely from storyboard (commented out below)
     currently doesn't work, not sure why. one of only missing
     things for feature parity.
    
     */
    
    self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
    
    // Creating through code is all the works right now.
    /*
    UIViewController *mainContentVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PrimaryContentViewController"];
    
    UIViewController *drawerContentVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DrawerContentViewController"];
 
    UIViewController *drawerContentVC = [UIViewController new];
    
     PulleyViewController *pulleyDrawerVC = [[PulleyViewController alloc] initWithContentViewController:mainContentVC drawerViewController:drawerContentVC];
     
     self.window.rootViewController = pulleyDrawerVC;
*/
    // Uncomment this next line to give the drawer a starting position, in this case: closed.
    //pulleyDrawerVC.initialDrawerPosition = [PulleyPosition closed];
    
    [self.window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
