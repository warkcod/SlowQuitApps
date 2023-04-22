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
//            NSLog(@"Registration failed: %@", error.localizedDescription);
            
            NSAlert *warning = [[NSAlert alloc] init];
            warning.alertStyle = NSAlertStyleWarning;
            if (result) {
                warning.messageText = NSLocalizedString(@"Success", nil);
                warning.informativeText = error.localizedDescription;
            } else {
                warning.messageText = NSLocalizedString(@"Failed", nil);
                warning.informativeText = error.localizedDescription;
            }
           
            [warning addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [warning runModal];
            
            return result;
        } else {
            return [SMAppService.mainAppService unregisterAndReturnError:&error];
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
