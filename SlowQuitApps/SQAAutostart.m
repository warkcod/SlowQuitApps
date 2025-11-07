#import <Foundation/Foundation.h>
@import ServiceManagement;
#import "SQAAutostart.h"

@implementation SQAAutostart

NSString * const LauncherBundleIdentifier = @"com.dteoh.SlowQuitAppsLauncher";

+ (SMAppService *)launcherService API_AVAILABLE(macos(13.0)) {
    return [SMAppService loginItemServiceWithIdentifier:LauncherBundleIdentifier];
}

+ (BOOL)isEnabled {
    if (@available(macOS 13.0, *)) {
        SMAppService *service = [self launcherService];
        switch (service.status) {
            case SMAppServiceStatusEnabled:
                return YES;
            case SMAppServiceStatusRequiresApproval:
                NSLog(@"Login item %@ requires user approval in System Settings -> General -> Login Items", LauncherBundleIdentifier);
                return NO;
            default:
                return NO;
        }
    } else {
        for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
            if ([app.bundleIdentifier isEqualToString:LauncherBundleIdentifier]) {
                return YES;
            }
        }
        return NO;
    }
}

+ (BOOL)shouldRegisterLoginItem:(BOOL)enabled {
    // macOS 13+ requires SMAppService - SMLoginItemSetEnabled is no longer effective
    if (@available(macOS 13.0, *)) {
        if ([self isRunningFromReadOnlyLocation]) {
            NSLog(@"Cannot register login item while SlowQuitApps is running from a read-only volume. Please move the app to /Applications first.");
            return NO;
        }

        NSError *error = nil;
        SMAppService *service = [self launcherService];
        if (enabled) {
            BOOL result = [service registerAndReturnError:&error];
            if (!result && error) {
                NSLog(@"SMAppService registration failed: %@ (code: %ld)",
                      error.localizedDescription, (long)error.code);
            } else if (service.status == SMAppServiceStatusRequiresApproval) {
                NSLog(@"SMAppService registered but needs approval in Login Items -> Allow in Background");
            }
            return result;
        } else {
            BOOL result = [service unregisterAndReturnError:&error];
            if (!result && error) {
                NSLog(@"SMAppService unregistration failed: %@", error.localizedDescription);
            }
            return result;
        }
    } else {
        // macOS < 13.0: SMLoginItemSetEnabled still works
        return SMLoginItemSetEnabled((__bridge CFStringRef)(LauncherBundleIdentifier), enabled);
    }
}


+ (BOOL)enable {
    return [self shouldRegisterLoginItem:YES];
}

+ (BOOL)disable {
    return [self shouldRegisterLoginItem:NO];
}

+ (BOOL)isRunningFromReadOnlyLocation {
    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;
    if (!bundleURL) { return NO; }

    NSNumber *readOnly = nil;
    [bundleURL getResourceValue:&readOnly forKey:NSURLVolumeIsReadOnlyKey error:nil];
    if (readOnly.boolValue) {
        return YES;
    }

    NSString *bundlePath = bundleURL.path;
    return [bundlePath hasPrefix:@"/Volumes/"];
}


@end
