#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <AdpPushClient/AdpPushClient.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [PushClientManager.defaultManager setLogLevel:ChabokLogLevelVerbose];
    [PushClientManager.defaultManager configureEnvironment:Sandbox];
    
    [GeneratedPluginRegistrant registerWithRegistry:self];
    // Override point for customization after application launch.
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
