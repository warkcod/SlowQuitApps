@import Foundation;

@interface SQAPreferences : NSObject

+ (NSInteger)delay;
+ (NSArray<NSString *> *)whitelist;
+ (BOOL)invertList;
+ (BOOL)displayOverlay;
+ (BOOL)disableAutostart;
+ (void)setDisableAutostart:(BOOL)value;
+ (BOOL)pendingAutoEnable;
+ (void)setPendingAutoEnable:(BOOL)value;

@end
