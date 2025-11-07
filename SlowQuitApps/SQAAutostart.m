@import ServiceManagement;
#import "SQAAutostart.h"

@implementation SQAAutostart

NSString * const LauncherBundleIdentifier = @"com.dteoh.SlowQuitAppsLauncher";

+ (BOOL)isEnabled {
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([app.bundleIdentifier isEqualToString:LauncherBundleIdentifier]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)shouldRegisterLoginItem:(BOOL)enabled {
    if(@available(macOS 13.0, *)) {
        NSError *error = nil;
        if(enabled) {
            BOOL result = [SMAppService.mainAppService registerAndReturnError:&error];
            if (!result && error) {
                NSLog(@"Failed to register login item: %@", error.localizedDescription);
            }
            return result;
        } else {
            BOOL result = [SMAppService.mainAppService unregisterAndReturnError:&error];
            if (!result && error) {
                NSLog(@"Failed to unregister login item: %@", error.localizedDescription);
            }
            return result;
        }
    } else {
        return SMLoginItemSetEnabled((__bridge CFStringRef)(LauncherBundleIdentifier), enabled);
    }
}


+ (BOOL)enable {
    return [self shouldRegisterLoginItem:YES];
}

+ (BOOL)disable {
    return [self shouldRegisterLoginItem:NO];
}


@end
