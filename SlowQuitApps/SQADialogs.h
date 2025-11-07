@import Foundation;

@interface SQADialogs : NSObject

- (void)askAboutAutoStart;
- (void)informHotkeyRegistrationFailure;
- (void)informAccessibilityRequirement;
- (void)informMoveToApplicationsRequirement;
- (void)informAutoStartDisabled;
- (void)promptToReEnableAutoStart;

@end
