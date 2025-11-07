@import AppKit;
#import "SQADialogs.h"
#import "SQAAutostart.h"

@implementation SQADialogs

- (void)askAboutAutoStart {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = NSLocalizedString(@"Automatically launch SlowQuitApps on login?", nil);
    alert.informativeText = NSLocalizedString(@"Would you like to register SlowQuitApps to automatically launch when you login?", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    if ([alert runModal] != NSAlertFirstButtonReturn) {
        return;
    }

    if ([SQAAutostart isRunningFromReadOnlyLocation]) {
        [self informMoveToApplicationsRequirement];
        return;
    }

    BOOL result = [self registerLoginItem];

    if (result) {
        // Success: silently complete
        return;
    }

    // Failure: must inform user and provide solution!
    [self informLoginItemRegistrationFailure];
}

- (void)informLoginItemRegistrationFailure {
    NSAlert *warning = [[NSAlert alloc] init];
    warning.alertStyle = NSAlertStyleWarning;
    warning.messageText = NSLocalizedString(@"Manual action required to enable auto-start", nil);

    NSString *detail = NSLocalizedString(
        @"macOS 13+ requires approving login items before they can run in the background.\n\n"
        "Click “Open Login Items” below to jump straight to System Settings.\n"
        "In “Allow in the Background”, toggle “SlowQuitAppsLauncher” to Allow.\n\n"
        "This is an Apple security requirement introduced in macOS 13 (Ventura).\n\n"
        "For more help, visit: https://github.com/warkcod/SlowQuitApps", nil);

    warning.informativeText = detail;
    [warning addButtonWithTitle:NSLocalizedString(@"Open Login Items", nil)];
    [warning addButtonWithTitle:NSLocalizedString(@"Close", nil)];

    if ([warning runModal] == NSAlertFirstButtonReturn) {
        [self openLoginItemsPreferences];
    }
}

- (BOOL)registerLoginItem {
    return [SQAAutostart enable];
}

- (void)informHotkeyRegistrationFailure {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    alert.messageText = NSLocalizedString(@"SlowQuitApps cannot register ⌘Q", nil);
    alert.informativeText = NSLocalizedString(@"Another application has exclusive control of ⌘Q, SlowQuitApps cannot continue. SlowQuitApps will exit.", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

- (void)informAccessibilityRequirement {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = NSLocalizedString(@"SlowQuitApps requires permissions to control your computer", nil);
    alert.informativeText = NSLocalizedString(@"SlowQuitApps needs accessibility permissions to handle ⌘Q.\r\rAfter adding SlowQuitApps to System Preferences -> Security & Privacy -> Privacy -> Accessibility, please restart the app.", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

- (void)openLoginItemsPreferences {
    NSURL *loginItemsURL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.LoginItems-Settings.extension"];
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    if (![workspace openURL:loginItemsURL]) {
        NSURL *fallbackURL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.users"];
        [workspace openURL:fallbackURL];
    }
}

- (void)informMoveToApplicationsRequirement {
    NSString *bundlePath = [NSBundle mainBundle].bundlePath ?: @"";
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = NSLocalizedString(@"请先将 SlowQuitApps 拖到“应用程序”文件夹", nil);
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"当前应用正从只读磁盘映像运行（%@）。\n\nmacOS 不允许从只读卷注册登录项，请先将 SlowQuitApps.app 拖到 /Applications ，再重新启用自动启动。", nil), bundlePath];
    [alert addButtonWithTitle:NSLocalizedString(@"知道了", nil)];
    [alert runModal];
}

@end
